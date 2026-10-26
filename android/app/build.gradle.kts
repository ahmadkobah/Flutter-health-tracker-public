plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.company.MedicarePlus"
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
        applicationId = "com.company.MedicarePlus"
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

    // Enable core library desugaring required by some plugins (e.g., flutter_local_notifications)
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // existing settings above already set Java 11 compatibility
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM (updated to a newer stable version to ensure consistency)
    // If build issues arise, you can roll back one version.
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries

    // Core library desugaring dependency (keep version aligned with AGP recommendations)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")

    // (Optional explicit dependency) Ensure firebase-messaging present (the plugin adds it implicitly).
    // implementation("com.google.firebase:firebase-messaging")
}

// Exclude deprecated firebase-iid to resolve duplicate class (FirebaseInstanceIdReceiver) conflicts.
// Some transitive dependency (older plugin artifact) is pulling in firebase-iid:20.1.5 which
// duplicates classes now bundled inside firebase-messaging 23+.
configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}
