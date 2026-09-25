plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Signing release permanen: semua build (lokal & CI) memakai keystore
// yang sama supaya update APK bisa menimpa langsung tanpa uninstall.
// Kredensial di android/key.properties (JANGAN commit file itu).
// Kalau file tidak ada (mis. clone baru), fallback ke debug key.
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties()
if (keyPropsFile.exists()) keyProps.load(keyPropsFile.inputStream())

android {
    namespace = "com.example.exam_brow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.exam_brow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Spesifikasi minimal: Android 10 (API 29). Perangkat di bawah ini
        // tidak akan bisa menginstall APK.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Pakai key permanen bila key.properties ada, kalau tidak pakai debug key.
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.create("exambrowRelease") {
                    storeFile = file(keyProps.getProperty("storeFile") ?: "exambrow-release.jks")
                    storePassword = keyProps.getProperty("storePassword")
                    keyAlias = keyProps.getProperty("keyAlias") ?: "exambrow"
                    keyPassword = keyProps.getProperty("keyPassword")
                }
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
