plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "net.defguard.mobile"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "net.defguard.mobile"
        minSdk = 31
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // let r0adkll/sign-android-release@v1 in CI do the signing
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}


kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // NOTE: do NOT declare a Cronet artifact here. The `cronet_http` plugin
    // (pulled in via `native_dio_adapter`) declares it itself and picks between
    // `play-services-cronet` and `cronet-embedded` from the
    // `cronetHttpNoPlay` dart-define. Adding one here fights that choice.
    implementation(files("../../../lib/tunnel.aar"))
}

flutter {
    source = "../.."
}
