plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Android setup: only apply Google Services plugin when the config file exists.
// This keeps debug builds working before you add `android/app/google-services.json`.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.diaspora.delivery.diaspora_delivery"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.diaspora.delivery.diaspora_delivery"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

afterEvaluate {
    tasks.matching { it.name == "assembleDebug" }.configureEach {
        doLast {
            val sourceDir = File(project.buildDir, "outputs/flutter-apk")
            val destinationDir = File(rootProject.projectDir.parentFile, "build/app/outputs/flutter-apk")

            if (!sourceDir.exists()) return@doLast

            destinationDir.mkdirs()

            val apks = sourceDir.listFiles { file -> file.isFile && file.extension.equals("apk", ignoreCase = true) }
                ?: return@doLast

            for (apk in apks) {
                apk.copyTo(File(destinationDir, apk.name), overwrite = true)
            }
        }
    }
}
