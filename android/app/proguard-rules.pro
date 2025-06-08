# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

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

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core classes (for Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep ML Kit language models and components
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Keep classes related to text recognition
-keep class * extends com.google.mlkit.vision.text.TextRecognizer { *; }
-keep class * extends com.google.mlkit.vision.text.TextRecognizerOptions { *; }

# Keep Latin script and other language scripts
-keep class com.google.mlkit.vision.text.latin.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep serialization related for ML Kit
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep camera and image processing related classes
-keep class androidx.camera.** { *; }
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Flutter related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep camera and image processing related classes
-keep class androidx.camera.** { *; }
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
