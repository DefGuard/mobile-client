package net.defguard.fido2_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.nfc.NfcAdapter
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyManager
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.fido.CtapException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.fido.ctap.ClientPin
import com.yubico.yubikit.fido.ctap.Ctap2Session
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocol
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocolV1
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocolV2
import com.yubico.yubikit.fido.webauthn.PublicKeyCredentialDescriptor
import com.yubico.yubikit.fido.webauthn.PublicKeyCredentialType
import com.yubico.yubikit.fido.webauthn.SerializationType
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean

// Long enough for ClientPIN plus getAssertion on slower keys; yubikit's 1 s default is not.
private const val ISO_DEP_TIMEOUT_MS = 5000

private class AssertionRequest(
    val rpId: String,
    val clientDataHash: ByteArray,
    val allowCredentials: List<ByteArray>,
    val pin: String?,
)

private class PinInvalid(val retries: Int?) : Exception("PIN invalid")

private class Ceremony(val result: MethodChannel.Result, val manager: NfcYubiKeyManager, val activity: Activity) {
    val tagClaimed = AtomicBoolean(false)
}

class Fido2Plugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private var context: Context? = null
    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var pending: Ceremony? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val timeout =
        Runnable { pending?.let { finish(it) { r -> r.error("timeout", "No security key was tapped", null) } } }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "net.defguard.fido2_plugin").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cancelPending()
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "nfcStatus" -> result.success(nfcStatus())

            "openNfcSettings" -> {
                val activity = activity ?: return result.error("nfcUnavailable", "No host activity", null)
                activity.startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                result.success(null)
            }

            "getAssertion" -> getAssertion(call, result)

            "cancel" -> {
                cancelPending()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun nfcStatus(): String {
        val adapter = context?.let { NfcAdapter.getDefaultAdapter(it) } ?: return "unsupported"
        return if (adapter.isEnabled) "enabled" else "disabled"
    }

    private fun getAssertion(call: MethodCall, result: MethodChannel.Result) {
        val context = context ?: return result.error("nfcUnavailable", "Plugin detached from engine", null)
        val activity = activity ?: return result.error("nfcUnavailable", "No host activity", null)
        val request = AssertionRequest(
            rpId = call.argument<String>("rpId")!!,
            clientDataHash = call.argument<ByteArray>("clientDataHash")!!,
            allowCredentials = call.argument<List<ByteArray>>("allowCredentials")!!,
            pin = call.argument<String>("pin"),
        )
        val timeoutMs = call.argument<Int>("timeoutMs")!!.toLong()

        cancelPending()

        val manager = try {
            NfcYubiKeyManager(context, null)
        } catch (e: NfcNotAvailable) {
            return result.error("nfcUnavailable", e.message, null)
        }
        val ceremony = Ceremony(result, manager, activity)
        pending = ceremony

        try {
            val config = NfcConfiguration().timeout(ISO_DEP_TIMEOUT_MS).skipNdefCheck(true)
            manager.enable(activity, config) { device -> onTag(ceremony, device, request) }
        } catch (e: NfcNotAvailable) {
            pending = null
            return result.error(if (e.isDisabled) "nfcDisabled" else "nfcUnavailable", e.message, null)
        } catch (e: Exception) {
            pending = null
            runCatching { manager.disable(activity) }
            return result.error("nfcUnavailable", e.message, null)
        }
        mainHandler.postDelayed(timeout, timeoutMs)
    }

    private fun onTag(ceremony: Ceremony, device: NfcYubiKeyDevice, request: AssertionRequest) {
        if (!ceremony.tagClaimed.compareAndSet(false, true)) return
        // Every exchange from here on is bounded by the IsoDep timeout, so the tap wait no longer applies.
        mainHandler.post { if (pending === ceremony) mainHandler.removeCallbacks(timeout) }
        try {
            device.requestConnection(SmartCardConnection::class.java) { connection ->
                val outcome = runCatching { performAssertion(connection.value, request) }
                mainHandler.post {
                    finish(ceremony) { r ->
                        outcome.fold(
                            onSuccess = { r.success(it) },
                            onFailure = { reportError(r, it) },
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // The ceremony finished while this tap was being dispatched, and its executor is shut down.
            mainHandler.post { finish(ceremony) { r -> reportError(r, e) } }
        }
    }

    private fun performAssertion(connection: SmartCardConnection, request: AssertionRequest): Map<String, ByteArray> {
        val session = Ctap2Session(connection)
        val info = session.cachedInfo

        var protocol: PinUvAuthProtocol? = null
        var pinUvAuthParam: ByteArray? = null
        if (request.pin != null) {
            if (!ClientPin.isSupported(info)) throw CtapException(CtapException.ERR_PIN_NOT_SET)
            val chosen = if (info.pinUvAuthProtocols.contains(2)) PinUvAuthProtocolV2() else PinUvAuthProtocolV1()
            val clientPin = ClientPin(session, chosen)
            val token = try {
                clientPin.getPinToken(request.pin.toCharArray(), ClientPin.PIN_PERMISSION_GA, request.rpId)
            } catch (e: CtapException) {
                if (e.ctapError != CtapException.ERR_PIN_INVALID) throw e
                throw PinInvalid(runCatching { clientPin.pinRetries.count }.getOrNull())
            }
            protocol = chosen
            pinUvAuthParam = chosen.authenticate(token, request.clientDataHash)
        }

        val descriptors = request.allowCredentials.map {
            PublicKeyCredentialDescriptor(PublicKeyCredentialType.PUBLIC_KEY, it)
        }
        val chunkSize = (info.maxCredentialCountInList ?: 1).coerceAtLeast(1)
        for (chunk in descriptors.chunked(chunkSize)) {
            try {
                val assertion = session.getAssertions(
                    request.rpId,
                    request.clientDataHash,
                    chunk.map { it.toMap(SerializationType.CBOR) },
                    null,
                    null,
                    pinUvAuthParam,
                    protocol?.version,
                    null,
                ).first()
                return mapOf(
                    "authenticatorData" to assertion.authenticatorData,
                    "signature" to assertion.signature,
                    "credentialId" to assertion.getCredentialId(chunk),
                )
            } catch (e: CtapException) {
                if (e.ctapError != CtapException.ERR_NO_CREDENTIALS) throw e
            }
        }
        // A key with a PIN set may be hiding a credential registered with credProtect=3.
        if (request.pin == null && info.options["clientPin"] == true) {
            throw CtapException(CtapException.ERR_PUAT_REQUIRED)
        }
        throw CtapException(CtapException.ERR_NO_CREDENTIALS)
    }

    private fun reportError(result: MethodChannel.Result, error: Throwable) {
        when (error) {
            is PinInvalid -> result.error("pinInvalid", error.message, mapOf("pinRetries" to error.retries))

            is CtapException -> result.error(
                ctapCode(error.ctapError),
                error.message,
                mapOf("ctapError" to error.ctapError.toInt()),
            )

            is ApplicationNotAvailableException -> result.error("unsupportedKey", error.message, null)

            is IOException -> result.error("tagLost", error.message, null)

            else -> result.error("unknown", error.message, null)
        }
    }

    private fun ctapCode(error: Byte): String = when (error) {
        CtapException.ERR_NO_CREDENTIALS -> "noCredentials"
        CtapException.ERR_PUAT_REQUIRED -> "pinRequired"
        CtapException.ERR_PIN_INVALID -> "pinInvalid"
        CtapException.ERR_PIN_BLOCKED, CtapException.ERR_UV_BLOCKED -> "pinBlocked"
        CtapException.ERR_PIN_AUTH_BLOCKED -> "pinAuthBlocked"
        CtapException.ERR_PIN_NOT_SET -> "pinNotSet"
        else -> "unknown"
    }

    private fun finish(ceremony: Ceremony, deliver: (MethodChannel.Result) -> Unit) {
        if (pending !== ceremony) return
        pending = null
        mainHandler.removeCallbacks(timeout)
        runCatching { ceremony.manager.disable(ceremony.activity) }
        deliver(ceremony.result)
    }

    private fun cancelPending() {
        pending?.let { finish(it) { r -> r.error("cancelled", "Cancelled", null) } }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        cancelPending()
        activity = null
    }

    override fun onDetachedFromActivity() {
        cancelPending()
        activity = null
    }
}
