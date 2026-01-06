allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Windows workaround: avoid spaces in build path (Flutter/Gradle can mis-handle them).
val newBuildDir = File("C:/Users/Public/DiasporaDeliveryBuild")
rootProject.buildDir = newBuildDir

subprojects {
    project.buildDir = File(newBuildDir, project.name)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
