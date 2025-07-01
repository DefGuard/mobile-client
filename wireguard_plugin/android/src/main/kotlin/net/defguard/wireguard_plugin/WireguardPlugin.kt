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
import kotlinx.coroutines.launch
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy

@OptIn(ExperimentalSerializationApi::class)
val json = Json {
    ignoreUnknownKeys = true
    namingStrategy = JsonNamingStrategy.SnakeCase
}

const val METHOD_CHANNEL_NAME = "net.defguard.wireguard_plugin/channel"
const val METHOD_EVENT_NAME = "net.defguard.wireguard_plugin/event"
const val VPN_PERMISSION_REQUEST_CODE = 1001
const val LOG_TAG = "DG"

/** WireguardPlugin */
class WireguardPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var havePermission = false
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activeTunnel: Tunnel? = null
    private var futureBackend = CompletableDeferred<GoBackend>()
    private var backend: GoBackend? = null
    private lateinit var context: Context
    private val scope = CoroutineScope(Job() + Dispatchers.Main.immediate)
    private var activeInstanceId: Int? = null;
    private var activeLocationId: Int? = null;

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, METHOD_EVENT_NAME)
        scope.launch(Dispatchers.IO) {
            try {
                backend = createBackend()
                futureBackend.complete(backend!!)
            } catch (e: Throwable) {
                Log.e(LOG_TAG, Log.getStackTraceString(e));
            }
        }
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
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

            else -> result.notImplemented()
        }
    }

    private fun createBackend(): GoBackend {
        if(backend == null) {
            backend = GoBackend(context);
        }
        return backend as GoBackend;
    }

    private fun getActiveTunnelContext(): TunnelEventData? {
        if(activeLocationId != null && activeInstanceId != null) {
            val data = TunnelEventData(activeInstanceId!!, activeLocationId!!);
            return data;
        }
        return null
    }

    private fun emitEvent(eventType: WireguardPluginEvent, data: String?) {
        scope.launch(Dispatchers.Main) {
            val message = mapOf(
                "event" to eventType,
                "data" to data
            )
            eventSink?.success(message)
        }
    }

    private fun updateTunnelStatusWithState(status: Tunnel.State) {
        scope.launch(Dispatchers.Main) {
            val eventData: String? = getActiveTunnelContext()?.let {Json.encodeToString(it)};
            when (status) {
                Tunnel.State.UP -> emitEvent(WireguardPluginEvent.TUNNEL_UP, eventData)
                Tunnel.State.DOWN -> emitEvent(WireguardPluginEvent.TUNNEL_DOWN, eventData)
                Tunnel.State.TOGGLE -> emitEvent(WireguardPluginEvent.TUNNEL_WAITING, eventData)
            }
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
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

    private fun startTunnel(configData: TunnelStartData, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {

                // Stop previous tunnel if one is running
                activeTunnel?.let {
                    futureBackend.await().setState(it, Tunnel.State.DOWN, null)
                }

                // Build Interface config
                val interfaceBuilder = Interface.Builder()
                    .parsePrivateKey(configData.privateKey)
                    .parseAddresses(configData.address)

                // set DNS for interface
                if (!configData.dns.isNullOrBlank()) {
                    interfaceBuilder.parseDnsServers(configData.dns)
                }

                val iface = interfaceBuilder.build()

                // Build Peer config
                val peerBuilder = Peer.Builder()
                    .parsePublicKey(configData.publicKey)
                    .parseEndpoint(configData.endpoint)
                    .parseAllowedIPs(configData.allowedIps)
                    .setPersistentKeepalive(configData.keepalive)

                if (!configData.presharedKey.isNullOrBlank()) {
                    peerBuilder.parsePreSharedKey(configData.presharedKey)
                }

                val peer = peerBuilder.build()

                val tunnel = SimpleTunnel("dg0")

                // Compose full config
                val config = Config.Builder()
                    .setInterface(iface)
                    .addPeer(peer)
                    .build()

                // Use locationName as the tunnel identifier
                futureBackend.await().setState(tunnel, Tunnel.State.UP, config)

                activeTunnel = tunnel

                result.success(true)

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
}
