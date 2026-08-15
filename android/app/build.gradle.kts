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

        // Health Connect (androidx.health.connect) exige minSdk 26 —
        // remplace la valeur par défaut de Flutter (souvent 21/24).
        minSdk = 26

        // >> Option recommandé :
        // targetSdk 36 pour cohérence, mais succès possible avec 35
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            // Priorité 58 (14/08/2026) : Play Console signale l'app comme non
            // conforme aux tailles de page mémoire 16 ko (bloquant à partir du
            // 01/02/2027). Cause identifiée : un ancien `packagingOptions {
            // jniLibs { useLegacyPackaging = true } }` ici (retiré), pensé à
            // tort comme une "tolérance 16 ko" — c'est l'inverse : la
            // compression legacy des .so empêche justement leur alignement
            // 16 ko. Le défaut AGP (non compressés, alignés) est ce qu'il
            // faut ; AGP 8.9.1 le fait déjà nativement.
            // R8 : réduction des ressources activée en plus du minify déjà en
            // place (recommandation du rapport de conformité).
            isShrinkResources = true
        }
        debug { }
    }
}

flutter {
    source = "../.."
}
