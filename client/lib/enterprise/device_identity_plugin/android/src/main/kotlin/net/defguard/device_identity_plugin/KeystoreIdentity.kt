package net.defguard.device_identity_plugin

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.InvalidAlgorithmParameterException
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.security.PrivateKey
import java.security.Signature
import java.security.NoSuchProviderException
import java.security.ProviderException
import java.security.spec.ECGenParameterSpec

internal enum class IdentityErrorCode {
    UNSPECIFIED,
    UNAVAILABLE,
    TEMPORARILY_UNAVAILABLE,
    TIMEOUT,
    RATE_LIMITED,
    PERMISSION_DENIED,
    UNSUPPORTED,
    IDENTITY_LOST,
    INVALID_CHALLENGE,
    BACKEND_FAILURE,
    INVALID_EVIDENCE,
    CHALLENGE_EXPIRED,
}

internal class IdentityFailure(
    val code: IdentityErrorCode,
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause)

internal object KeystoreIdentity {
    private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
    private const val CURVE = "secp256r1"
    private const val MAX_CHALLENGE_DATA_SIZE = 4 * 1024

    fun generate(alias: String, challengeData: ByteArray): List<ByteArray> {
        if (alias.isBlank()) {
            throw IdentityFailure(IdentityErrorCode.BACKEND_FAILURE, "Identity alias is required")
        }
        if (challengeData.isEmpty() || challengeData.size > MAX_CHALLENGE_DATA_SIZE) {
            throw IdentityFailure(
                IdentityErrorCode.INVALID_CHALLENGE,
                "Challenge data must be between 1 and 4096 bytes",
            )
        }

        val attestationChallenge = try {
            MessageDigest.getInstance(KeyProperties.DIGEST_SHA256).digest(challengeData)
        } catch (error: Exception) {
            throw failure(error)
        }

        try {
            generateKeyPair(alias, attestationChallenge, includeDeviceProperties = true)
        } catch (_: ProviderException) {
            try {
                generateKeyPair(alias, attestationChallenge, includeDeviceProperties = false)
            } catch (error: Exception) {
                throw failure(error)
            }
        } catch (error: Exception) {
            throw failure(error)
        }

        return try {
            val chain = keyStore().getCertificateChain(alias)
            if (chain.isNullOrEmpty()) {
                throw IdentityFailure(
                    IdentityErrorCode.UNAVAILABLE,
                    "Android Keystore returned no certificate chain",
                )
            }
            chain.map { it.encoded }
        } catch (error: IdentityFailure) {
            throw error
        } catch (error: Exception) {
            throw failure(error)
        }
    }

    fun sign(alias: String, data: ByteArray): ByteArray {
        return try {
            val privateKey = keyStore().getKey(alias, null) as? PrivateKey
                ?: throw IdentityFailure(
                    IdentityErrorCode.IDENTITY_LOST,
                    "Identity key is missing",
                )
            Signature.getInstance("SHA256withECDSA").run {
                initSign(privateKey)
                update(data)
                sign()
            }
        } catch (error: IdentityFailure) {
            throw error
        } catch (error: Exception) {
            throw failure(error)
        }
    }

    fun exists(alias: String): Boolean {
        return try {
            keyStore().getKey(alias, null) is PrivateKey
        } catch (error: Exception) {
            throw failure(error)
        }
    }

    fun delete(alias: String) {
        try {
            keyStore().deleteEntry(alias)
        } catch (error: Exception) {
            throw failure(error)
        }
    }

    private fun keyStore(): KeyStore =
        KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }

    private fun generateKeyPair(
        alias: String,
        attestationChallenge: ByteArray,
        includeDeviceProperties: Boolean,
    ) {
        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec(CURVE))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAttestationChallenge(attestationChallenge)
        if (includeDeviceProperties) {
            spec.setDevicePropertiesAttestationIncluded(true)
        }

        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, KEYSTORE_PROVIDER).run {
            initialize(spec.build())
            generateKeyPair()
        }
    }

    private fun failure(error: Exception): IdentityFailure {
        if (error is IdentityFailure) return error

        val causes = generateSequence(error as Throwable?) { it.cause }.toList()
        val code = when {
            causes.any(::isTransientKeystoreFailure) -> IdentityErrorCode.TEMPORARILY_UNAVAILABLE
            causes.any { it is SecurityException } -> IdentityErrorCode.PERMISSION_DENIED
            causes.any { it is InvalidAlgorithmParameterException || it is NoSuchAlgorithmException } ->
                IdentityErrorCode.UNSUPPORTED
            causes.any { it is NoSuchProviderException || it is KeyStoreException } ->
                IdentityErrorCode.UNAVAILABLE
            else -> IdentityErrorCode.BACKEND_FAILURE
        }
        val message = when (code) {
            IdentityErrorCode.UNAVAILABLE -> "Android Keystore is unavailable"
            IdentityErrorCode.TEMPORARILY_UNAVAILABLE -> "Android Keystore is temporarily unavailable"
            IdentityErrorCode.PERMISSION_DENIED -> "Android Keystore denied the request"
            IdentityErrorCode.UNSUPPORTED -> "Android Keystore does not support the requested key"
            else -> "Android Keystore operation failed"
        }
        return IdentityFailure(code, message, error)
    }

    private fun isTransientKeystoreFailure(error: Throwable): Boolean {
        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            error.javaClass.name != "android.security.KeyStoreException"
        ) {
            return false
        }
        return runCatching {
            error.javaClass.getMethod("isTransientFailure").invoke(error) == true
        }.getOrDefault(false)
    }
}
