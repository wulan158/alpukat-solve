# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# TensorFlow Lite - Keep all classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# TensorFlow Lite GPU Delegate - More specific rules
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate$* { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$* { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options$* { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend { *; }

# TensorFlow Lite NNAPI Delegate
-keep class org.tensorflow.lite.nnapi.NnApiDelegate { *; }
-keep class org.tensorflow.lite.nnapi.NnApiDelegate$* { *; }

# Keep all TensorFlow Lite model files
-keep class org.tensorflow.lite.model.** { *; }

# Flutter TensorFlow Lite plugin
-keep class io.flutter.plugins.tflite.** { *; }
-keep class org.tensorflow.lite.flutter.** { *; }

# TensorFlow Lite C++ interface
-keep class org.tensorflow.lite.NativeInterpreterWrapper { *; }
-keep class org.tensorflow.lite.NativeInterpreterWrapper$* { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Firebase dependencies (if using Firebase with TensorFlow Lite)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Suppress warnings for missing classes
-dontwarn org.tensorflow.lite.**
