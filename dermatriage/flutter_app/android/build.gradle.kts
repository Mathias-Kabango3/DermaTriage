allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. tflite_flutter) hardcode an old compileSdk (31) that is
// too low for the AndroidX versions pulled in by the app. Force every Android
// subproject to compile against a modern SDK.
subprojects {
    // Only the not-yet-evaluated plugin modules need this; :app is already
    // evaluated with a correct compileSdk, so skip it (setting it would be
    // "too late").
    if (!state.executed) {
        afterEvaluate {
            extensions.findByName("android")?.withGroovyBuilder {
                "compileSdkVersion"(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
