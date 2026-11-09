package net.defguard.device_identity_plugin

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

class DeviceIdentityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var keystoreExecutor: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            "net.defguard.device_identity_plugin",
        )
        channel.setMethodCallHandler(this)
        keystoreExecutor = Executors.newSingleThreadExecutor()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        keystoreExecutor?.shutdown()
        keystoreExecutor = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateAttestedIdentity" -> generateAttestedIdentity(call, result)
            "signPossession", "hasIdentity", "deleteIdentity" ->
                result.error("UNSUPPORTED", "Device identity is not implemented", null)
            else -> result.notImplemented()
        }
    }

    private fun generateAttestedIdentity(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val alias = arguments?.get("alias") as? String
        if (alias.isNullOrBlank()) {
            result.error(IdentityErrorCode.BACKEND_FAILURE.name, "Identity alias is required", null)
            return
        }

        val challengeData = arguments?.get("challengeData") as? ByteArray
        if (challengeData == null) {
            result.error(
                IdentityErrorCode.INVALID_CHALLENGE.name,
                "Challenge data must be a byte array",
                null,
            )
            return
        }

        val executor = keystoreExecutor
        if (executor == null) {
            result.error(IdentityErrorCode.UNAVAILABLE.name, "Android Keystore is unavailable", null)
            return
        }

        try {
            executor.execute {
                try {
                    val chain = KeystoreIdentity.generate(alias, challengeData)
                    mainHandler.post { result.success(chain) }
                } catch (error: IdentityFailure) {
                    mainHandler.post { result.error(error.code.name, error.message, null) }
                } catch (_: Exception) {
                    mainHandler.post {
                        result.error(
                            IdentityErrorCode.BACKEND_FAILURE.name,
                            "Android Keystore operation failed",
                            null,
                        )
                    }
                }
            }
        } catch (_: RejectedExecutionException) {
            result.error(
                IdentityErrorCode.TEMPORARILY_UNAVAILABLE.name,
                "Android Keystore is temporarily unavailable",
                null,
            )
        }
    }
}
