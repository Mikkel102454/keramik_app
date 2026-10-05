plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release credentials are supplied by the operator's secret store, never by Git.
val uploadStore = System.getenv("CLAYDOCK_UPLOAD_KEYSTORE")
val uploadAlias = System.getenv("CLAYDOCK_UPLOAD_KEY_ALIAS")
val uploadStorePassword = System.getenv("CLAYDOCK_UPLOAD_STORE_PASSWORD")
val uploadKeyPassword = System.getenv("CLAYDOCK_UPLOAD_KEY_PASSWORD")
val signingReady = listOf(uploadStore, uploadAlias, uploadStorePassword, uploadKeyPassword)
    .all { !it.isNullOrBlank() }
if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
    require(signingReady && file(uploadStore!!).isFile) {
        "ClayDock release signing requires CLAYDOCK_UPLOAD_KEYSTORE, CLAYDOCK_UPLOAD_KEY_ALIAS, " +
        "CLAYDOCK_UPLOAD_STORE_PASSWORD and CLAYDOCK_UPLOAD_KEY_PASSWORD; no debug fallback."
    }
}
// Generic aggregate tasks must enforce the same rule when their graph includes release.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("release", ignoreCase = true) }) {
        require(signingReady && file(uploadStore!!).isFile) {
            "ClayDock release signing inputs are required; unsigned/debug release fallback is disabled."
        }
    }
}

android {
    namespace = "nu.miguel.claydock"
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
        applicationId = "nu.miguel.claydock"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingReady) {
            create("upload") {
                storeFile = file(uploadStore!!)
                keyAlias = uploadAlias
                storePassword = uploadStorePassword
                keyPassword = uploadKeyPassword
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
        }
    }
}

dependencies {
    implementation("com.android.billingclient:billing:9.1.0")
    // A media plugin requests vulnerable 2.6; keep its compatible API on a reviewed release.
    implementation("commons-io:commons-io:2.22.0")
}

flutter {
    source = "../.."
}

tasks.register("dependencyInventory") {
    doLast {
        val modules = configurations.getByName("debugRuntimeClasspath").incoming.resolutionResult.allComponents
            .mapNotNull { it.id as? org.gradle.api.artifacts.component.ModuleComponentIdentifier }
        val rows = modules.distinct().sortedBy { it.toString() }.map {
            "{\"group\":\"${it.group}\",\"name\":\"${it.module}\",\"version\":\"${it.version}\"}"
        }
        val output = layout.buildDirectory.file("android-dependencies.json").get().asFile
        output.parentFile.mkdirs()
        output.writeText(rows.joinToString(",\n", "[\n", "\n]\n"))
    }
}
