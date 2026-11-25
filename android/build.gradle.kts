// Flutter 3.50 / recent plugin AARs require compileSdk 36. Some pub plugins
// still declare compileSdk 34 (e.g. file_picker), which fails AAR metadata checks.
// Register afterEvaluate in beforeProject so it is in place before
// evaluationDependsOn(":app") evaluates plugin modules, and so it runs
// after each plugin's own android { compileSdk ... } block.
gradle.beforeProject {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.LibraryExtension) {
            if ((android.compileSdk ?: 0) < 36) {
                android.compileSdk = 36
            }
            // AGP 9 lintVital can crash in plugins (CommentDetector / List.removeLast
            // on image_picker_android). Don't fail a release APK on plugin lint.
            android.lint {
                checkReleaseBuilds = false
                abortOnError = false
            }
        }
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

