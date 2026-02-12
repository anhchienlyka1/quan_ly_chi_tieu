allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define kotlin_version for legacy plugins that depend on it
val kotlin_version by extra("2.2.20")

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

subprojects {
    val project = this
    val configureAndroidProject = {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // 1. Configure Namespace (Fix for AGP 8+)
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    
                    if (getNamespace.invoke(android) == null) {
                        val groupName = project.group.toString()
                        val fallbackNamespace = if (groupName.isEmpty() || groupName == "null") "com.example.${project.name}" else groupName
                        setNamespace.invoke(android, fallbackNamespace)
                        println("Set namespace for ${project.name} to $fallbackNamespace")
                    }
                } catch (e: Exception) {
                    println("Could not set namespace for ${project.name}: ${e.message}")
                }

                // 2. Configure versions per module
                val useLegacyJava = project.name == "flutter_notification_listener"
                val targetVersionStr = if (useLegacyJava) "1.8" else "17"
                val targetJavaVersion = if (useLegacyJava) org.gradle.api.JavaVersion.VERSION_1_8 else org.gradle.api.JavaVersion.VERSION_17

                if (project.name != "app") {
                    // Only force compileSdk 34 for modern plugins (Java 17 require compileSdk 30+)
                    // Legacy plugins keep their default compileSdk (safe with Java 1.8)
                    if (!useLegacyJava) {
                        try {
                            val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                            setCompileSdkVersion.invoke(android, 34)
                            println("Forced compileSdkVersion to 34 for ${project.name}")
                        } catch(e: Exception) {
                            try {
                                 val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                                 setCompileSdkVersion.invoke(android, 34)
                            } catch(e2: Exception) {
                                println("Could not force compileSdkVersion for ${project.name}: ${e.message}")
                            }
                        }
                    }

                    try {
                         val getCompileOptions = android.javaClass.getMethod("getCompileOptions")
                         val compileOptions = getCompileOptions.invoke(android)
                         
                         val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", org.gradle.api.JavaVersion::class.java)
                         val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", org.gradle.api.JavaVersion::class.java)
                         
                         setSourceCompatibility.invoke(compileOptions, targetJavaVersion)
                         setTargetCompatibility.invoke(compileOptions, targetJavaVersion)
                         println("Forced Java $targetVersionStr for ${project.name}")
                    } catch(e: Exception) {
                         println("Could not force Java $targetVersionStr for ${project.name}: ${e.message}")
                    }
                }
            }
        }
        
        // 3. Configure Kotlin JVM Target
        project.tasks.configureEach {
            if (this.name.startsWith("compile") && this.name.contains("Kotlin")) {
                try {
                    val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
                    val kotlinOptions = getKotlinOptions.invoke(this)
                    val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                    
                    val useLegacyJava = project.name == "flutter_notification_listener"
                    val target = if (useLegacyJava) "1.8" else "17"
                    
                    // App -> default/detected (usually 17).
                    // Subprojects -> forced above.
                    
                    setJvmTarget.invoke(kotlinOptions, target)
                    println("Set jvmTarget to $target for ${this.name} in ${project.name}")
                } catch (e: Exception) {
                    // Ignore
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroidProject()
    } else {
        project.afterEvaluate {
            configureAndroidProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
