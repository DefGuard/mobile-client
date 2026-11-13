group = "net.defguard.device_identity_plugin"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
    }
}

val keyAttestationMavenRepo = providers.gradleProperty("keyAttestationMavenRepo").orNull

allprojects {
    repositories {
        google()
        mavenCentral()
        if (keyAttestationMavenRepo != null) {
            maven { url = uri(keyAttestationMavenRepo) }
        }
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "net.defguard.device_identity_plugin"
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 31
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
}

dependencies {
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("com.android.keyattestation:keyattestation:0.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
