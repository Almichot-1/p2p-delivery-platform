allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val sharedBuildDir = File("C:/MBapp_build")
rootProject.buildDir = File(sharedBuildDir, "android")

subprojects {
    buildDir = File(rootProject.buildDir, name)

    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.api.dsl.ApplicationExtension>("android") {
            compileSdk = 36
            defaultConfig {
                targetSdk = 36
            }
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
            compileSdk = 36
            defaultConfig {
                targetSdk = 36
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
