# Android device identity contract tests

The instrumented tests use Google's `com.android.keyattestation:keyattestation:0.4` from Google Maven only as an independent verifier. It is an Android test dependency only and is not included in the plugin's runtime dependencies. The build resolves that group from Google Maven alone, so another repository cannot substitute it.

## Prerequisites

- The Flutter and Android SDK setup used for normal client builds, including `adb`.
- An API 31 or later Android emulator or device.

The client Gradle wrapper uses the JVM settings in `client/android/gradle/gradle-daemon-jvm.properties`.

## Run on an emulator

Start an API 31 or later AVD with Android Studio's Device Manager, or start one with the Android SDK emulator command. Keep the emulator running and confirm `adb devices -l` lists it as `device`.

## Run on a physical TEE device

Connect a TEE-only Android device running API 31 or later, unlock it, and authorize USB debugging. Stop the emulator and confirm `adb devices -l` lists only the phone as `device`.

## Run the instrumented tests

Run this from the repository root after connecting one emulator or phone. The Gradle task runs on every connected device.

```sh
GRADLE_PROJECT_CACHE="${TMPDIR:-/tmp}/defguard-android-attestation-gradle-cache"
cd client/android
adb devices -l
./gradlew \
  --project-cache-dir="$GRADLE_PROJECT_CACHE" \
  :device_identity_plugin:connectedDebugAndroidTest
```

The emulator may return a software attestation chain that is not rooted in Google's production anchors. The test first tries Google roots; only after a path-validation failure does it retry with the returned chain endpoint as a test trust anchor, and it requires the verifier to report `SOFTWARE`. This checks the certificate path signatures, challenge, and app identity, but does not establish a trusted hardware root. JUnit skips the TEE and Google-root assertions for software-level chains. A physical TEE run must execute those assertions rather than skip them.

The tests do not exercise the `ProviderException` retry inside `KeystoreIdentity.generate`. `chainGeneratedWithoutDevicePropertiesPassesIndependentVerification` tests a chain generated without device properties directly, not the retry path.
