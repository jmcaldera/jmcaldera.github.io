---
layout: post
title: "Gradle: Taming the Beast"
author: jose
categories: [ Post ]
tags: [ Gradle, Android, Kotlin ]
image: assets/images/gradle_beast_header.jpg

---

When we start our Android programming journey we just want to build new and awesome stuffs, beautiful and robust apps. We get to a point where we start to learn about design patterns, architecture and best practices, but often we dedicate less time to learn about Gradle. For me, this was one of my duty points in my career as an Android Developer. Well... not anymore, and if you're in the same situation, I hope this starts to change now.

Each time I started a new project o had to make some changes to a current one related to gradle, what I did was open an old project or go to StackOverflow and copy-paste small code snippets without fully understanding what that piece of code was doing. Some times this was a matter of trial and error. Also, the fact that Groovy was needed (which I don't like so much) made it more complicated.

In this article I'll show you that Gradle is not so terrible as you may think. Yo don't need to know Groovy and there's a simpler way to work with it and finally Tame the Beast.

# Lifecycle {#lifecycle}

The first thing you should know is that every time we start a build, gradle goes through three phases of its lifecycle, and in each of those phases several things happen.

### Initialization

This is the first lifecycle phase that gets executed. What it does is basically "prepare" the project for the build. For this, it takes the so-called init scripts located in the `.gradle/init.d` folder (if present), going through them in alphabetical order. In these scripts, we could add custom initial configurations like setting properties or a specific ambient where we are going to run our build, like our Dev or CI server. It also uses the `settings.gradle` file to determine the projects that will be part of the build, creating an instance of each project.

### Configuration

During this phase, the build script of *all* the project that were created before are executed. For that reason, each project needs a `build.gradle` file, where we can configure the project itself, add tasks, dependencies, and so on.

### Execution

Gradle determines the subset of the tasks, created and configured during the configuration phase, to be executed. The subset is determined by the task name arguments passed to the `gradle` command and the current directory. Gradle then executes each of the selected tasks.



# Interfaces {#interfaces}

Now that we are familiar with the build lifecycle, let's see where all those methods and properties that we have in our scripts come from and where can we find what we need.

If you've used Gradle in a Java or Android project you may have noticed that there are a few files with `.gradle` extension. We previously mentioned two of them, `settings.gradle` and `build.gradle`. As part of the init scripts we also have `init.gradle` or any other that's inside the same folder.

Each of these scripts extends from an Interface. In some cases more than one. That's why we can access its methods and properties, which before you knew there were interfaces, they may have looked like magic :smile:. Fear no more!

What you should know is that **all scripts** that we have in our project implement the [Script](https://docs.gradle.org/current/javadoc/org/gradle/api/Script.html) interface. If we go through its definition we can that it has a public method called [getBuildscript()](https://docs.gradle.org/current/javadoc/org/gradle/api/Script.html#getBuildscript--). Wondering where have you seen this? Correct, we find this in the top-level build.gradle file.

```groovy
buildscript { 
    repositories {
        ...
    }
    dependencies {
       ...
    }
}
```

You see, this method returns a `ScriptHandler` which also exposes `getRepositories()` and `getDependencies()`. Note that in Groovy, similar to Kotlin, we don't need to use the full getter method, instead we can use the "property syntax" as shown above. This doesn't look like magic now!

We can keep going through the docs all we want, but what we usually find in a project are the build.gradle files that implement the [Project](https://docs.gradle.org/current/javadoc/org/gradle/api/Project.html) interface and the settings.gradle implementing... (you guessed) [Settings](https://docs.gradle.org/current/javadoc/org/gradle/api/initialization/Settings.html)! There's also a less common case in the Android world and that's init.gradle, which implements [Gradle](https://docs.gradle.org/current/javadoc/org/gradle/api/invocation/Gradle.html).

# Properties {#properties}

You may have noticed that we also have files with `.properties` extension such as `gradle.properties`. In this file we can define our own properties as a key-value pair.

```properties
some_custom_property_key=some_custom_property_value
```

And we can access to it from our script file like this:

```groovy
println some_custom_property_key
```

But we can also define our own properties in a script file. In fact, many of you might be familiar with managing dependency versions in your projects in a single place using **"ext"**. If you've never seen this before, let me show you what it is.

The keen eye may have noticed that some of the interfaces mentioned before also extend from `ExtensionAware` that expose an [ExtraPropertiesExtension]([ExtraPropertiesExtension (Gradle API 6.5)](https://docs.gradle.org/current/javadoc/org/gradle/api/plugins/ExtraPropertiesExtension.html)), which according to the docs *"is always present in the container, with the name “ext”"*. This allows us to add our properties directly in the following way.

```groovy
project.ext.custom_property = "some_value"

// another way of doing the same
project.ext {
    custom_property = "some_value"
    another_property = "another_value"
}
```

Note that I used `project.ext`. In this case `project` is our "delegate object" that will resolve any property or method that our current *scope* doesn't know about and it also exposes all its properties to use them in our script. Having said that, in this scope, we can use `ext` directly.

The delegate object will be different for each type of scripts. The following table shows the delegate type for each script.

```
|---------------------------|
| Type of Script | Delegate |
|---------------------------|
|    Build       | Project  | 
|    Init        | Gradle   |
|    Settings    | Settings |
|---------------------------|
```

# Plugins {#plugins}

Gradle also allows us to extend its capabilities with plugins. A plugin packages functionality that can be reused in many projects, it can add new DSLs, be configured, add tasks, and more.

For example in an Android app project, in our `app/build.gradle` file we have some plugins applied to it with `apply plugin: 'my-plugin'`. One of them is `'com.android.application'` which comes from [Android Gradle Plugin](https://google.github.io/android-gradle-dsl/current/index.html). This is why we can add the `android` block and configure our project 

```groovy
android {
    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 29
        ...
    }
    signingConfigs { }
    buildTypes { }
    ...
}
```

There are many plugins out there that we can apply to our project, and we can also create our own! But we will leave that for another article :wink:.



# Tasks {#tasks}

What I find very powerful and is something that took me some time to understand is the use of Tasks. By default, gradle registers a series of tasks like build, assemble, dependencies, test, and many others. In the configuration phase, gradle goes through each script and creates a task list and then determines the execution order generating a *taskGraph*. We can query this taskGraph and print it to console. For this, we will use the `getTaskGraph()` method.

```groovy
gradle.taskGraph.whenReady { graph ->
    logger.info ">>> taskGraph: ${graph.allTasks}"
}
```

When executing a build we will see the taskGraph printed.

```bash
./gradlew build -i | grep taskGraph
>>> taskGraph: [task ':app:preBuild', task ':app:preDebugBuild', ... ]
```

Note that in this case the delegate object is `project` but we can skip it in this case and use `gradle` directly. If we don't specify gradle, we will get the following error:

> Could not get unknown property 'taskGraph' for root project 'MyProject' of type org.gradle.api.Project.

It is also possible to get a list of all tasks and perform operations. For example, if we want to change the information that's printed when running tests, we can get the tasks with `getTasks()`, filter the ones we're interested in by type and apply new configurations.

```groovy
tasks.withType(Test) {
    testLogging {
        events "skipped", "failed", "passed"
    }
}
```

Another example would be to change the Java version we use when building our project. We can do this by checking the applied plugins. For android modules, we can change it like this.

```groovy
// Application
plugins.withType(com.android.build.gradle.AppPlugin)
    .configureEach { plugin ->
        plugin.extension.compileOptions {
            sourceCompatibility = "$java_version"
            targetCompatibility = "$java_version"
        }
    }

// Android library
plugins.withType(com.android.build.gradle.LibraryPlugin)
    .configureEach { plugin ->
        plugin.extension.compileOptions {
            sourceCompatibility = "$java_version"
            targetCompatibility = "$java_version"
        }
    }
```

We can also create our own tasks, set the execution order and dependencies. It's worth mentioning that gradle doesn't allow circular dependencies, so if we define **four** tasks: A, B, C, D, where B depends on A, C depends on B, D depends on B and C, and A depends on C, gradle will not allow us to this and will detect that there's a circular dependency. It is also smart to know that there are two tasks depending on one (C and D depend on B) so it will only execute B once.

```groovy
task doA { }
task doB(dependsOn: 'doA') { }
task doC(dependsOn: 'doB') { }
task doD(dependsOn: ['doB', 'doC']) { } // this task depends on two tasks []
```

There are other ways to create Tasks, and we can even use Java or Kotlin for it. If you want to know more about it I recommend you to check this [document](https://docs.gradle.org/current/userguide/more_about_tasks.html), where you'll find a few examples.



# Conclusion

Thanks for reading until the end. As I mentioned at the beginning, Gradle is not so terrible and all that "magic" that we see in our scripts is not so complicated. The documentation explains it very well so we should not be afraid to create our own solutions.

Now that we now about Gradle's [lifecycle](#lifecycle), base scripts [interfaces](#interfaces), how can we access to methods and [properties](#properties) that these interfaces expose, what a [plugin](#plugins) is, a [task](#tasks), and how we can create our own, we are now ready to face problems with greater confidence. Don't hesitate to try new things. Create plugins that add value to your project and improve as a developer because from this moment, you have tamed the beast.



### Reference

Photo by [Blake Connally](https://unsplash.com/@blakeconnally?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/programming?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
