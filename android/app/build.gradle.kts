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
        // ID unique de l'application (doit matcher la Play Console)
        applicationId = "com.totumapp.totum"

        // Ces valeurs sont gérées par Flutter (depuis ton pubspec)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 🔐 Utilise la config de signature "release"
            signingConfig = signingConfigs.getByName("release")

            // Nettoyage de code activé (nécessaire si on enlève les ressources inutiles)
            isMinifyEnabled = true
            // Tu peux ajouter aussi :
            // isShrinkResources = true
            // si tu veux encore réduire la taille plus tard.
        }
        debug {
            // Config debug par défaut
        }
    }
}

// ⚙️ Dit au plugin Flutter où se trouve ton code Dart
flutter {
    source = "../.."
}
