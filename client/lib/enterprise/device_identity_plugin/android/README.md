# Android device identity contract tests

The instrumented tests use `android/keyattestation` v0.4 only as an independent verifier. The upstream project does not publish a Maven artifact for this version, so build it from pinned commit `621149c4ebaeeea844d6f43098687c73c4d370a3` into a local Maven repository. It is an Android test dependency only and is not included in the plugin's runtime dependencies.

## Prerequisites

- Git.
- JDK 21 selected in `JAVA_HOME` and `PATH` to build the verifier source.
- The Flutter and Android SDK setup used for normal client builds, including `adb`.
- An API 31 or later Android emulator or device.

The client Gradle wrapper uses the JVM settings in `client/android/gradle/gradle-daemon-jvm.properties`.

## Build the verifier dependency

Run from the workspace root with JDK 21 active:

```sh
KEY_ATTESTATION_SRC="$(mktemp -d "${TMPDIR:-/tmp}/defguard-keyattestation-src.XXXXXX")"
KEY_ATTESTATION_MAVEN_REPO="${TMPDIR:-/tmp}/defguard-keyattestation-m2-v0.4"
mkdir -p "$KEY_ATTESTATION_MAVEN_REPO"
git clone --filter=blob:none https://github.com/android/keyattestation.git "$KEY_ATTESTATION_SRC"
git -C "$KEY_ATTESTATION_SRC" checkout --detach 621149c4ebaeeea844d6f43098687c73c4d370a3
test "$(git -C "$KEY_ATTESTATION_SRC" rev-parse HEAD)" = 621149c4ebaeeea844d6f43098687c73c4d370a3
(
  cd "$KEY_ATTESTATION_SRC"
  ./gradlew \
    -PkeyAttestationReleaseVersion=v0.4 \
    "-PKeyAttestationMavenRepo=$KEY_ATTESTATION_MAVEN_REPO" \
    publishKeyattestationPublicationToLocalDirRepository
)
```

## Run on an emulator

Start an API 31 or later AVD with Android Studio's Device Manager, or start one with the Android SDK emulator command. Keep the emulator running and confirm `adb devices -l` lists it as `device`.

## Run on a physical TEE device

Connect a TEE-only Android device running API 31 or later, unlock it, and authorize USB debugging. Stop the emulator and confirm `adb devices -l` lists only the phone as `device`.

## Run the instrumented tests

Run this from the workspace root after building the verifier dependency and connecting one emulator or phone. The Gradle task runs on every connected device.

```sh
KEY_ATTESTATION_MAVEN_REPO="${TMPDIR:-/tmp}/defguard-keyattestation-m2-v0.4"
GRADLE_PROJECT_CACHE="${TMPDIR:-/tmp}/defguard-android-attestation-gradle-cache"
cd src/mobile-client/android-attestation/client/android
adb devices -l
./gradlew \
  --project-cache-dir="$GRADLE_PROJECT_CACHE" \
  "-PkeyAttestationMavenRepo=$KEY_ATTESTATION_MAVEN_REPO" \
  :device_identity_plugin:connectedDebugAndroidTest
```

NixOS users can use `nix develop ./src/mobile-client/android-attestation` from the workspace root to provide the Flutter and Android tools; Nix is not required by these instructions.

The emulator may return a software attestation chain that is not rooted in Google's production anchors. The test first tries Google roots; only after a path-validation failure does it retry with the returned chain endpoint as a test trust anchor, and it requires the verifier to report `SOFTWARE`. This checks the certificate path signatures, challenge, and app identity, but does not establish a trusted hardware root. JUnit skips the TEE and Google-root assertions for software-level chains. A physical TEE run must execute those assertions rather than skip them.
