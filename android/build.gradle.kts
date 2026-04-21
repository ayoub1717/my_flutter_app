import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ====== تغيير مجلد build ======
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ====== clean task ======
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ====== buildscript ======
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("com.google.gms:google-services:4.3.15") // Firebase
    }
}

// ====== allprojects ======
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}