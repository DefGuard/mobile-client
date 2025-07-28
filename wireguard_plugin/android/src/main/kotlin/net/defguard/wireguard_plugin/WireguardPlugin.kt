package net.defguard.wireguard_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import com.wireguard.config.Interface
import com.wireguard.config.Peer
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy
import java.util.Timer
import java.util.TimerTask

@OptIn(ExperimentalSerializationApi::class)
val json = Json {
    ignoreUnknownKeys = true
    namingStrategy = JsonNamingStrategy.SnakeCase
}

const val METHOD_CHANNEL_NAME = "net.defguard.wireguard_plugin/channel"
const val METHOD_EVENT_NAME = "net.defguard.wireguard_plugin/event"
const val DEFAULT_ROUTE_IPV4 = "0.0.0.0/0"
const val DEFAULT_ROUTE_IPV6 = "::/0"
const val VPN_PERMISSION_REQUEST_CODE = 1001
const val LOG_TAG = "DG"
const val HEALTH_CHECK_INTERVAL = 30000L // 30 seconds
// const val DISCONNECTION_THRESHOLD = 3 * 60 * 1000L // 3 minutes
const val DISCONNECTION_THRESHOLD = 45 * 1000L // 45 seconds


/** WireguardPlugin */
class WireguardPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    
    companion object {
        // Shared state across all plugin instances
        @JvmStatic
        private var sharedActiveTunnel: Tunnel? = null
        @JvmStatic  
        private var sharedActiveTunnelData: ActiveTunnelData? = null
        @JvmStatic
        private var sharedBackend: GoBackend? = null
        @JvmStatic
        private var sharedFutureBackend: CompletableDeferred<GoBackend>? = null
        @JvmStatic
        private var sharedHavePermission = false
        @JvmStatic
        private var sharedLastTrafficTimestamp: Long = 0
        @JvmStatic
        private var sharedIsHealthy = false
        @JvmStatic
        private var sharedHealthCheckTimer: Timer? = null
        @JvmStatic
        private var sharedLastTrafficBytes = Pair(0L, 0L)
        @JvmStatic
        private var sharedIsInitialized = false
        @JvmStatic
        private var pendingRecoveryEvent: ActiveTunnelData? = null
    }
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private val scope = CoroutineScope(Job() + Dispatchers.Main.immediate)
    
    // Properties that delegate to shared state
    private var havePermission: Boolean
        get() = sharedHavePermission
        set(value) { sharedHavePermission = value }
    
    private var activeTunnel: Tunnel?
        get() = sharedActiveTunnel
        set(value) { sharedActiveTunnel = value }
        
    private var activeTunnelData: ActiveTunnelData?
        get() = sharedActiveTunnelData
        set(value) { sharedActiveTunnelData = value }
        
    private var backend: GoBackend?
        get() = sharedBackend
        set(value) { sharedBackend = value }
        
    private var futureBackend: CompletableDeferred<GoBackend>
        get() = sharedFutureBackend ?: CompletableDeferred<GoBackend>().also { sharedFutureBackend = it }
        set(value) { sharedFutureBackend = value }
        
    private var isInitialized: Boolean
        get() = sharedIsInitialized
        set(value) { sharedIsInitialized = value }
        
    // Connection health monitoring - delegate to shared state
    private var lastTrafficTimestamp: Long
        get() = sharedLastTrafficTimestamp
        set(value) { sharedLastTrafficTimestamp = value }
        
    private var isHealthy: Boolean
        get() = sharedIsHealthy
        set(value) { sharedIsHealthy = value }
        
    private var healthCheckTimer: Timer?
        get() = sharedHealthCheckTimer
        set(value) { sharedHealthCheckTimer = value }
        
    private var lastTrafficBytes: Pair<Long, Long>
        get() = sharedLastTrafficBytes
        set(value) { sharedLastTrafficBytes = value }
        
    private var pendingRecoveryEvent: ActiveTunnelData?
        get() = Companion.pendingRecoveryEvent
        set(value) { Companion.pendingRecoveryEvent = value }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(LOG_TAG, "Plugin onAttachedToEngine - isInitialized: $isInitialized")
        
        // Always update method channels and event sink for Flutter communication
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, METHOD_EVENT_NAME)
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(LOG_TAG, "Event sink connected")
                
                // Check if we have a pending recovery event to send
                pendingRecoveryEvent?.let { tunnelData ->
                    Log.i(LOG_TAG, "Sending pending recovery event for active tunnel")
                    scope.launch(Dispatchers.Main) {
                        delay(50) // Small delay to ensure event sink is ready
                        emitEvent(WireguardPluginEvent.TUNNEL_UP, json.encodeToString(tunnelData))
                        pendingRecoveryEvent = null // Clear after sending
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(LOG_TAG, "Event sink disconnected")
            }
        })
        
        if (!isInitialized) {
            // First time initialization
            Log.d(LOG_TAG, "Performing initial plugin initialization")
            context = flutterPluginBinding.applicationContext
            scope.launch(Dispatchers.IO) {
                try {
                    backend = createBackend()
                    futureBackend.complete(backend!!)
                } catch (e: Throwable) {
                    Log.e(LOG_TAG, Log.getStackTraceString(e));
                }
            }
            isInitialized = true
        } else {
            // Reconnection after app restart
            Log.d(LOG_TAG, "Plugin reconnecting after app restart")
            
            // If we have an active tunnel, queue it for recovery when event listener connects
            activeTunnelData?.let { tunnelData ->
                Log.i(LOG_TAG, "Active tunnel detected on reconnection: instance=${tunnelData.instanceId}, location=${tunnelData.locationId}")
                pendingRecoveryEvent = tunnelData
                Log.i(LOG_TAG, "Queued TUNNEL_UP event for when Flutter event listener connects")
            } ?: run {
                Log.d(LOG_TAG, "No active tunnel found on reconnection")
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestPermissions" -> requestPermissions(result)
            "startTunnel" -> {
                val args = call.arguments as? String
                if (args != null) {
                    try {
                        val tunnelConfig = json.decodeFromString<TunnelStartData>(args)
                        startTunnel(tunnelConfig, result);
                    } catch (e: SerializationException) {
                        result.error("INVALID_ARGS", "Error: ${e.message}", null);
                    }
                }
            }

            "closeTunnel" -> {
                if (activeTunnel != null) {
                    scope.launch(Dispatchers.IO) {
                        activeTunnel?.let {
                            closeTunnel(it);
                            result.success(null);
                        }
                    }
                } else {
                    result.error(
                        "TUNNEL_NOT_RUNNING",
                        "Error disconnect command sent when no tunnel was active",
                        null
                    );
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun createBackend(): GoBackend {
        if (backend == null) {
            backend = GoBackend(context);
        }
        return backend as GoBackend;
    }

    private fun emitEvent(eventType: WireguardPluginEvent, data: String?) {
        scope.launch(Dispatchers.Main) {
            val message = mapOf(
                "event" to eventType.value,
                "data" to data
            )
            Log.d(LOG_TAG, "Emitting event: ${eventType.value}, eventSink available: ${eventSink != null}")
            if (eventSink != null) {
                eventSink?.success(message)
                Log.d(LOG_TAG, "Event ${eventType.value} sent successfully")
            } else {
                Log.w(LOG_TAG, "Cannot emit event ${eventType.value} - eventSink is null")
            }
        }
    }

    private fun requestPermissions(result: Result) {
        if (havePermission) {
            result.success(true)
        } else {
            scope.launch(Dispatchers.Main) {
                val intent = GoBackend.VpnService.prepare(activity)
                if (intent == null) {
                    havePermission = true
                    result.success(true)
                } else {
                    pendingResult = result
                    activity?.startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
                }
            }
        }
    }

    private suspend fun closeTunnel(tunnel: Tunnel) {
        futureBackend.await().setState(tunnel, Tunnel.State.DOWN, null)
        activeTunnel = null
        activeTunnelData = null
        
        stopHealthMonitoring()
        
        // inform ui
        emitEvent(WireguardPluginEvent.TUNNEL_DOWN, null)
    }

    private fun startTunnel(configData: TunnelStartData, result: Result) {
        scope.launch(Dispatchers.IO) {
            try {
                // Stop previous tunnel if one is running
                activeTunnel?.let {
                    closeTunnel(it);
                }

                val interfaceBuilder = Interface.Builder()
                    .parsePrivateKey(configData.privateKey)
                    .parseAddresses(configData.address)

                if (!configData.dns.isNullOrBlank()) {
                    interfaceBuilder.parseDnsServers(configData.dns)
                }

                val iface = interfaceBuilder.build()

                val allowedIps: String = when (configData.traffic) {
                    TunnelTraffic.ALL -> "$DEFAULT_ROUTE_IPV4,$DEFAULT_ROUTE_IPV6"
                    TunnelTraffic.PREDEFINED -> configData.allowedIps
                }

                val peerBuilder = Peer.Builder()
                    .parsePublicKey(configData.publicKey)
                    .parseEndpoint(configData.endpoint)
                    .parseAllowedIPs(allowedIps)
                    .setPersistentKeepalive(configData.keepalive)

                if (!configData.presharedKey.isNullOrBlank()) {
                    peerBuilder.parsePreSharedKey(configData.presharedKey)
                }

                val peer = peerBuilder.build()
                val tunnel = SimpleTunnel("dg0")
                val config = Config.Builder()
                    .setInterface(iface)
                    .addPeer(peer)
                    .build()
                val tunnelData = ActiveTunnelData(
                    locationId = configData.locationId,
                    instanceId = configData.instanceId,
                    traffic = configData.traffic,
                    mfaEnabled = !configData.presharedKey.isNullOrBlank(),
                )

                futureBackend.await().setState(tunnel, Tunnel.State.UP, config)
                activeTunnel = tunnel
                activeTunnelData = tunnelData

                // only monitor MFA connections
                if (tunnelData.mfaEnabled) {
                    startHealthMonitoring()
                }

                // send event to UI and update traffic timestamp
                updateTrafficTimestamp()
                emitEvent(WireguardPluginEvent.TUNNEL_UP, json.encodeToString(tunnelData));

                result.success(null)

            } catch (e: Exception) {
                e.printStackTrace()
                result.error("TUNNEL_ERROR", e.message, null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE && pendingResult != null) {
            val granted = resultCode == Activity.RESULT_OK
            if (granted) {
                havePermission = true
            }
            pendingResult?.success(granted);
            pendingResult = null
            return true
        }
        return false
    }

    private fun startHealthMonitoring() {
        Log.d(LOG_TAG, "Starting connection health monitoring")
        
        // Initialize health state
        lastTrafficTimestamp = System.currentTimeMillis()
        isHealthy = true
        lastTrafficBytes = Pair(0L, 0L)
        
        // Stop any existing timer
        stopHealthMonitoring()
        
        // Start periodic health checks
        healthCheckTimer = Timer("HealthCheckTimer", true)
        healthCheckTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                performHealthCheck()
            }
        }, HEALTH_CHECK_INTERVAL, HEALTH_CHECK_INTERVAL)
        
        Log.d(LOG_TAG, "Health monitoring started - check interval: ${HEALTH_CHECK_INTERVAL}ms, disconnect threshold: ${DISCONNECTION_THRESHOLD}ms")
    }
    
    private fun stopHealthMonitoring() {
        healthCheckTimer?.cancel()
        healthCheckTimer = null
        isHealthy = false
        Log.d(LOG_TAG, "Health monitoring stopped")
    }
    
    private fun performHealthCheck() {
        val currentTime = System.currentTimeMillis()
        
        // Check for tunnel activity by examining stats if available
        activeTunnel?.let { tunnel ->
            try {
                // Try to get tunnel stats from the backend
                scope.launch(Dispatchers.IO) {
                    val stats = futureBackend.await().getStatistics(tunnel)
                    stats?.let { tunnelStats ->
                        val currentBytes = Pair(tunnelStats.totalRx(), tunnelStats.totalTx())
                        
                        // Check if there's been any data transfer since last check
                        if (currentBytes.first > lastTrafficBytes.first || currentBytes.second > lastTrafficBytes.second) {
                            lastTrafficBytes = currentBytes
                            updateTrafficTimestamp()
                            Log.d(LOG_TAG, "Traffic detected - RX: ${currentBytes.first}, TX: ${currentBytes.second}")
                        } else {
                            Log.d(LOG_TAG, "No traffic detected - RX: ${currentBytes.first}, TX: ${currentBytes.second}")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error checking tunnel stats: ${e.message}")
            }
        }
        
        val timeSinceLastTraffic = currentTime - lastTrafficTimestamp
        val newHealthy = activeTunnel != null && timeSinceLastTraffic <= DISCONNECTION_THRESHOLD
        if (newHealthy != isHealthy) {
            val oldHealthy = isHealthy
            isHealthy = newHealthy
            
            Log.d(LOG_TAG, "Connection health changed: ${if (oldHealthy) "HEALTHY" else "DISCONNECTED"} -> ${if (newHealthy) "HEALTHY" else "DISCONNECTED"} (traffic silence: ${timeSinceLastTraffic}ms)")
            
            // Log specific threshold crosses
            if (newHealthy) {
                Log.i(LOG_TAG, "Connection restored to HEALTHY")
            } else {
                Log.w(LOG_TAG, "Connection considered DISCONNECTED - no traffic for ${timeSinceLastTraffic}ms (threshold: ${DISCONNECTION_THRESHOLD}ms)")
                emitEvent(WireguardPluginEvent.MFA_SESSION_EXPIRED, null)
            }
        } else if (activeTunnel != null) {
            // Log periodic status when tunnel is active but health hasn't changed
            Log.d(LOG_TAG, "Health check: ${if (isHealthy) "HEALTHY" else "DISCONNECTED"} (traffic silence: ${timeSinceLastTraffic}ms)")
        }
    }
    
    private fun updateTrafficTimestamp() {
        lastTrafficTimestamp = System.currentTimeMillis()
        
        // If we were disconnected and now have traffic, update immediately
        if (!isHealthy) {
            Log.d(LOG_TAG, "Traffic detected - updating health status")
            isHealthy = true
        }
    }
}
