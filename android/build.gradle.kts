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
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    namespace = project.group.toString()  // Set namespace as fallback
                }
                project.tasks.whenTaskAdded { task ->
                    if (task.name.contains('processDebugManifest') || task.name.contains('processReleaseManifest')) {
                        task.doFirst {
                            File manifestFile = file("${projectDir}/src/main/AndroidManifest.xml")
                            if (manifestFile.exists()) {
                                String manifestContent = manifestFile.text
                                if (manifestContent.contains('package=')) {
                                    manifestContent = manifestContent.replaceAll(/package="[^"]*"/, "")
                                    manifestFile.write(manifestContent)
                                    println "Removed 'package' attribute from ${manifestFile}"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
