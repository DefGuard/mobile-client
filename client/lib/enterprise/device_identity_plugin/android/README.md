# Android device identity contract tests

These instrumented tests run the plugin's Kotlin code on an emulator or phone and check what Core will rely on: each attestation chain is bound to the challenge and to this app, each identity gets its own key, signatures verify against that key, and deleting an identity makes signing fail with `IDENTITY_LOST`.

The chains are checked with Google's verifier library, `com.android.keyattestation:keyattestation:0.4`. It is a test-only dependency and is not shipped with the plugin. Gradle takes it from Google Maven and from no other repository, so another repository cannot supply a substitute.

## Prerequisites

- The Flutter and Android SDK setup used for normal client builds, including `adb`.
- An Android emulator or phone running API 31 or later.

You do not need to install a JDK for these tests: the client's Gradle wrapper downloads the one listed in `client/android/gradle/gradle-daemon-jvm.properties`.

## Run on an emulator

Create an Android Virtual Device (AVD) for API 31 or later in Android Studio's Device Manager, then start it there or with `emulator -avd <name>`. Keep it running and confirm `adb devices -l` lists it as `device`.

## Run on a phone

Connect a phone running API 31 or later, unlock it, and allow USB debugging. Stop any emulator and confirm `adb devices -l` lists only the phone as `device`.

## Run the tests

Run this from the repository root. If several devices are connected, the tests run on each of them.

```sh
cd client/android
adb devices -l
./gradlew :device_identity_plugin:connectedDebugAndroidTest
```

## What an emulator run proves

An emulator signs its chains with a software key, not one from Google's hardware attestation roots. The tests first verify against Google's roots. If that fails, they also accept Android's known software roots or the chain's own last certificate as the root, but only when the verifier reports the security level as `SOFTWARE`. That run still checks the certificate signatures, the challenge and the app identity, but not that the key sits in secure hardware. The tests that need hardware, which check for the Trusted Execution Environment (TEE) security level and a Google root, are skipped on an emulator and must pass on a real phone.

The tests do not exercise the retry in `KeystoreIdentity.generate` that drops device properties after a `ProviderException`. `chainGeneratedWithoutDevicePropertiesPassesIndependentVerification` generates a chain without device properties directly.
