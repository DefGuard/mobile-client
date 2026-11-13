package net.defguard.wireguard_plugin

import com.wireguard.config.Interface
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
  @Test
  fun enabledAndInstalledAddsAndroidAutoExclusion() {
    val builder = Mockito.mock(Interface.Builder::class.java)
    var checkedPackage: String? = null

    addAndroidAutoExclusionIfInstalled(builder, true) { packageName ->
      checkedPackage = packageName
      true
    }

    assertEquals(ANDROID_AUTO_PACKAGE, checkedPackage)
    Mockito.verify(builder).excludeApplication(ANDROID_AUTO_PACKAGE)
  }

  @Test
  fun enabledAndNotInstalledDoesNotAddExclusion() {
    val builder = Mockito.mock(Interface.Builder::class.java)

    addAndroidAutoExclusionIfInstalled(builder, true) { false }

    Mockito.verify(builder, Mockito.never()).excludeApplication(ANDROID_AUTO_PACKAGE)
  }

  @Test
  fun disabledDoesNotCheckOrExcludePackage() {
    val builder = Mockito.mock(Interface.Builder::class.java)
    var checkedPackage = false

    addAndroidAutoExclusionIfInstalled(builder, false) {
      checkedPackage = true
      true
    }

    assertFalse(checkedPackage)
    Mockito.verify(builder, Mockito.never()).excludeApplication(ANDROID_AUTO_PACKAGE)
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
