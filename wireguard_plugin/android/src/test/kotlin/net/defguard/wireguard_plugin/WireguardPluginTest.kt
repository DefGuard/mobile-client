package net.defguard.wireguard_plugin

import com.wireguard.config.Interface
import com.wireguard.crypto.KeyPair
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.decodeFromString
import kotlin.test.Ignore
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class WireguardPluginTest {
  private fun newInterfaceBuilder() =
    Interface.Builder().parsePrivateKey(KeyPair().privateKey.toBase64())

  @Test
  fun enabledAndInstalledAddsAndroidAutoExclusion() {
    val builder = newInterfaceBuilder()
    var checkedPackage: String? = null

    addAndroidAutoExclusionIfInstalled(builder, true) { packageName ->
      checkedPackage = packageName
      true
    }

    assertEquals(ANDROID_AUTO_PACKAGE, checkedPackage)
    assertEquals(setOf(ANDROID_AUTO_PACKAGE), builder.build().excludedApplications)
  }

  @Test
  fun enabledAndNotInstalledDoesNotAddExclusion() {
    val builder = newInterfaceBuilder()

    addAndroidAutoExclusionIfInstalled(builder, true) { false }

    assertEquals(emptySet<String>(), builder.build().excludedApplications)
  }

  @Test
  fun disabledDoesNotCheckOrExcludePackage() {
    val builder = newInterfaceBuilder()
    var checkedPackage = false

    addAndroidAutoExclusionIfInstalled(builder, false) {
      checkedPackage = true
      true
    }

    assertFalse(checkedPackage)
    assertEquals(emptySet<String>(), builder.build().excludedApplications)
  }

  @Test
  fun missingExcludeAndroidAutoFieldDefaultsToFalse() {
    val config = json.decodeFromString<TunnelStartData>(
      """{
        "public_key": "location-key",
        "private_key": "private-key",
        "address": "10.0.0.2/32",
        "endpoint": "vpn.example:51820",
        "allowed_ips": "10.0.0.0/24",
        "keepalive": 25,
        "preshared_key": null,
        "traffic": "all",
        "location_name": "office",
        "location_id": 1,
        "instance_id": 1
      }""",
    )

    assertFalse(config.excludeAndroidAuto)
  }

  // TODO: WireguardPlugin does not handle "getPlatformVersion" (onMethodCall returns notImplemented),
  // so this template test always fails. Adjust the plugin before re-enabling it.
  @Ignore
  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val plugin = WireguardPlugin()

    val call = MethodCall("getPlatformVersion", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }
}
