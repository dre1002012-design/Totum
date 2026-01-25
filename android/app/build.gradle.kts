plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Le plugin Flutter doit être appliqué après les plugins Android et Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    // 🔐 Config de signature RELEASE (utilise key.properties)
    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            }

            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    // 🆔 Identité de ton appli sur Android
    namespace = "com.totumapp.totum"

    // ✅ Correction : compileSdk 36 (requis par tes plugins)
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.totumapp.totum"

        minSdk = flutter.minSdkVersion

        // >> Option recommandé :
        // targetSdk 36 pour cohérence, mais succès possible avec 35
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Packaging legacy (tolérance 16 ko)
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
        }
        debug { }
    }
}

flutter {
    source = "../.."
}
