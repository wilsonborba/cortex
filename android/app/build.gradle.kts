plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.asodya.cortex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.asodya.cortex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePath = System.getenv("CORTEX_RELEASE_KEYSTORE_PATH")
    val keystorePassword = System.getenv("CORTEX_RELEASE_KEYSTORE_PASSWORD")
    val keyAlias = System.getenv("CORTEX_RELEASE_KEY_ALIAS")
    val keyPassword = System.getenv("CORTEX_RELEASE_KEY_PASSWORD")
    val hasReleaseSigning = !keystorePath.isNullOrBlank() &&
        !keystorePassword.isNullOrBlank() &&
        !keyAlias.isNullOrBlank() &&
        !keyPassword.isNullOrBlank()

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword
                keyAlias = keyAlias
                keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
                tasks.matching {
                    it.name.contains("Release", ignoreCase = true) &&
                        (it.name.startsWith("assemble") || it.name.startsWith("bundle"))
                }.configureEach {
                    doFirst {
                        throw GradleException(
                            "Release build requires CORTEX_RELEASE_KEYSTORE_PATH, " +
                                "CORTEX_RELEASE_KEYSTORE_PASSWORD, CORTEX_RELEASE_KEY_ALIAS, " +
                                "and CORTEX_RELEASE_KEY_PASSWORD environment variables. " +
                                "Silent debug signing for release builds is forbidden."
                        )
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
