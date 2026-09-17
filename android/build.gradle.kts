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

// Some plugin builds (e.g. package_info_plus 10.2.1) assume AGP 9+ applies
// the Kotlin Android extension on its own and skip applying
// org.jetbrains.kotlin.android themselves in that case, then immediately
// try to configure KotlinAndroidProjectExtension anyway — which fails here
// because our AGP 9.1.0 does not, in fact, auto-apply it. Force it onto
// every Android-library subproject that doesn't already have it, before
// that subproject's own build script runs the rest of its configuration.
subprojects {
    plugins.withId("com.android.library") {
        if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
