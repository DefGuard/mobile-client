package net.defguard.device_identity_plugin

import android.content.pm.PackageManager
import android.os.Process
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.android.keyattestation.verifier.AttestationApplicationId
import com.android.keyattestation.verifier.AttestationApplicationIdConstraint
import com.android.keyattestation.verifier.AttestationPackageInfo
import com.android.keyattestation.verifier.ConstraintConfig
import com.android.keyattestation.verifier.GoogleTrustAnchors
import com.android.keyattestation.verifier.IgnoredConstraint
import com.android.keyattestation.verifier.SecurityLevel
import com.android.keyattestation.verifier.SoftwareRoot
import com.android.keyattestation.verifier.VerificationResult
import com.android.keyattestation.verifier.Verifier
import com.android.keyattestation.verifier.challengecheckers.ChallengeMatcher
import com.google.protobuf.ByteString
import java.math.BigInteger
import java.security.MessageDigest
import java.security.PublicKey
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.TrustAnchor
import java.security.cert.X509Certificate
import java.time.Instant
import java.util.UUID
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class DeviceIdentityContractTest {
    @Test
    fun attestationBindsChallengeAndApplicationIdentity() {
        val alias = uniqueAlias()
        try {
            val verified = generateAndVerify(alias, challengeData)
            assertNotNull(verified.chain.first().getExtensionValue(ATTESTATION_EXTENSION_OID))
        } finally {
            KeystoreIdentity.delete(alias)
        }
    }

    @Test
    fun emptyAndOversizedPossessionDataAreInvalidChallenges() {
        val invalidData =
            listOf(
                byteArrayOf(),
                ByteArray(KeystoreIdentity.MAX_IDENTITY_DATA_SIZE + 1),
            )

        for (data in invalidData) {
            try {
                KeystoreIdentity.sign(uniqueAlias(), data)
                throw AssertionError("Signing invalid possession data succeeded")
            } catch (error: IdentityFailure) {
                assertEquals(IdentityErrorCode.INVALID_CHALLENGE, error.code)
            }
        }
    }

    @Test
    fun generatingWithAnExistingAliasFailsAndKeepsTheOriginalKeyUsable() {
        val alias = uniqueAlias()
        val data = byteArrayOf(9, 8, 7)

        try {
            val identity = generateAndVerify(alias, challengeData)
            try {
                KeystoreIdentity.generate(alias, challengeData)
                throw AssertionError("Generating with an existing alias succeeded")
            } catch (error: IdentityFailure) {
                assertEquals(IdentityErrorCode.BACKEND_FAILURE, error.code)
            }

            val signature = KeystoreIdentity.sign(alias, data)
            assertTrue(verifySignature(identity.chain.first().publicKey, data, signature))
        } finally {
            KeystoreIdentity.delete(alias)
        }
    }

    @Test
    fun signaturesUseDistinctAttestedKeysAndDeletionLosesIdentity() {
        val aliasA = uniqueAlias()
        val aliasB = uniqueAlias()
        val data = byteArrayOf(0, 1, 2, 3, 0x7f)

        try {
            val identityA = generateAndVerify(aliasA, challengeData)
            val identityB = generateAndVerify(aliasB, challengeData)
            val publicKeyA = identityA.chain.first().publicKey
            val publicKeyB = identityB.chain.first().publicKey

            assertFalse(publicKeyA.encoded.contentEquals(publicKeyB.encoded))
            assertTrue(KeystoreIdentity.exists(aliasA))
            assertTrue(KeystoreIdentity.exists(aliasB))

            val signatureA = KeystoreIdentity.sign(aliasA, data)
            assertTrue(verifySignature(publicKeyA, data, signatureA))
            assertFalse(verifySignature(publicKeyB, data, signatureA))
            assertFalse(
                verifySignature(
                    publicKeyA,
                    data.copyOf().also { it[0] = (it[0] + 1).toByte() },
                    signatureA,
                ),
            )

            val signatureB = KeystoreIdentity.sign(aliasB, data)
            assertTrue(verifySignature(publicKeyB, data, signatureB))

            KeystoreIdentity.delete(aliasA)
            assertFalse(KeystoreIdentity.exists(aliasA))
            assertTrue(KeystoreIdentity.exists(aliasB))
            try {
                KeystoreIdentity.sign(aliasA, data)
                throw AssertionError("Signing after deletion succeeded")
            } catch (error: IdentityFailure) {
                assertEquals(IdentityErrorCode.IDENTITY_LOST, error.code)
            }
        } finally {
            KeystoreIdentity.delete(aliasA)
            KeystoreIdentity.delete(aliasB)
        }
    }

    @Test
    fun chainGeneratedWithoutDevicePropertiesPassesIndependentVerification() {
        val alias = uniqueAlias()
        try {
            val chain = KeystoreIdentity.generateWithoutDeviceProperties(alias, challengeData)
            val verified = verifyChain(chain, challengeData)
            assertNotNull(verified.chain.first().getExtensionValue(ATTESTATION_EXTENSION_OID))
        } finally {
            KeystoreIdentity.delete(alias)
        }
    }

    @Test
    fun trustedEnvironmentAndGoogleRootAssertionsRequireHardwareAttestation() {
        val alias = uniqueAlias()
        try {
            val verified = generateAndVerify(alias, challengeData)
            assumeTrue(
                "Software-level attestation; skipping hardware assertions",
                verified.result.securityLevel != SecurityLevel.SOFTWARE,
            )
            assertEquals(SecurityLevel.TRUSTED_ENVIRONMENT, verified.result.securityLevel)
            assertTrue("Attestation chain did not verify against Google roots", verified.googleRooted)
        } finally {
            KeystoreIdentity.delete(alias)
        }
    }

    private fun generateAndVerify(alias: String, challenge: ByteArray): VerifiedChain =
        verifyChain(KeystoreIdentity.generate(alias, challenge), challenge)

    private fun verifyChain(encodedChain: List<ByteArray>, challenge: ByteArray): VerifiedChain {
        val certificateFactory = CertificateFactory.getInstance("X.509")
        val chain =
            encodedChain.map {
                certificateFactory.generateCertificate(it.inputStream()) as X509Certificate
            }
        assertTrue("Attestation chain is empty", chain.isNotEmpty())

        val googleAnchors = GoogleTrustAnchors()
        val expectedAppId = expectedApplicationId()
        val expectedChallenge = MessageDigest.getInstance("SHA-256").digest(challenge)
        val challengeMatcher = ChallengeMatcher(expectedChallenge)
        val googleResult =
            verifier(expectedAppId, googleAnchors)
                .verify(chain, challengeMatcher)
        if (googleResult is VerificationResult.Success) {
            assertArrayEquals(expectedChallenge, googleResult.challenge.toByteArray())
            return VerifiedChain(chain, googleResult, googleRooted = true)
        }
        assertTrue(
            "Google-root verification failed for a reason other than the software chain root: $googleResult",
            googleResult is VerificationResult.PathValidationFailure,
        )

        val fallbackAnchors =
            googleAnchors +
                SoftwareRoot.SOFTWARE_ROOTS.map { TrustAnchor(it, null) } +
                TrustAnchor(chain.last(), null)
        val fallbackResult =
            verifier(expectedAppId, fallbackAnchors)
                .verify(chain, challengeMatcher)
        assertTrue(
            "Independent verifier rejected generated chain: $fallbackResult",
            fallbackResult is VerificationResult.Success,
        )
        fallbackResult as VerificationResult.Success
        assertEquals(SecurityLevel.SOFTWARE, fallbackResult.securityLevel)
        assertArrayEquals(expectedChallenge, fallbackResult.challenge.toByteArray())
        return VerifiedChain(chain, fallbackResult, googleRooted = false)
    }

    private fun verifier(expectedAppId: AttestationApplicationId, trustAnchors: Set<TrustAnchor>) = Verifier(
        trustAnchorsSource = { trustAnchors },
        // The contract tests check path and attestation claims without a network revocation lookup.
        revokedSerialsSource = { emptySet() },
        instantSource = { Instant.now() },
        expectedAttestationApplicationId = expectedAppId,
        constraintConfig =
            ConstraintConfig(
                allowSoftwareRoot = true,
                attestationApplicationId = AttestationApplicationIdConstraint.STRICT,
                keyOrigin = IgnoredConstraint,
                securityLevel = IgnoredConstraint,
                rootOfTrust = IgnoredConstraint,
            ),
    )

    @Suppress("DEPRECATION")
    private fun expectedApplicationId(): AttestationApplicationId {
        val packageManager = InstrumentationRegistry.getInstrumentation().context.packageManager
        val packageNames = checkNotNull(packageManager.getPackagesForUid(Process.myUid()))
        val packageInfos =
            packageNames.map {
                packageManager.getPackageInfo(it, PackageManager.GET_SIGNING_CERTIFICATES)
            }
        val signatures =
            packageInfos
                .flatMap { packageInfo ->
                    checkNotNull(packageInfo.signingInfo).apkContentsSigners.map { signer ->
                        ByteString.copyFrom(
                            MessageDigest.getInstance("SHA-256").digest(signer.toByteArray()),
                        )
                    }
                }.toSet()

        assertTrue("No package signing certificates found for the test UID", signatures.isNotEmpty())
        return AttestationApplicationId(
            packages =
                packageInfos
                    .map {
                        AttestationPackageInfo(it.packageName, BigInteger.valueOf(it.longVersionCode))
                    }.toSet(),
            signatures = signatures,
        )
    }

    private fun verifySignature(publicKey: PublicKey, data: ByteArray, signature: ByteArray): Boolean =
        Signature.getInstance("SHA256withECDSA").run {
            initVerify(publicKey)
            update(data)
            verify(signature)
        }

    private fun uniqueAlias() = "device-identity-contract-${UUID.randomUUID()}"

    private data class VerifiedChain(
        val chain: List<X509Certificate>,
        val result: VerificationResult.Success,
        val googleRooted: Boolean,
    )

    private companion object {
        const val ATTESTATION_EXTENSION_OID = "1.3.6.1.4.1.11129.2.1.17"
        val challengeData = byteArrayOf(3, 1, 4, 1, 5)
    }
}
