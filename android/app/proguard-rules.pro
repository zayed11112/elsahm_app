# Flutter ProGuard Rules
# This file contains ProGuard rules for Flutter applications

# Keep Flutter Engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }

# Keep Google Play Core classes (for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Supabase/PostgreSQL classes
-keep class io.supabase.** { *; }
-keep class org.postgresql.** { *; }
-dontwarn io.supabase.**
-dontwarn org.postgresql.**

# Keep OneSignal classes
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Keep video player classes
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**
-dontwarn com.google.android.exoplayer2.**

# Keep WebView classes
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn io.flutter.plugins.webviewflutter.**

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# Keep URL launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# Keep package info classes
-keep class io.flutter.plugins.packageinfo.** { *; }
-dontwarn io.flutter.plugins.packageinfo.**

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Keep connectivity classes
-keep class com.baseflow.connectivity.** { *; }
-dontwarn com.baseflow.connectivity.**

# Keep device info classes
-keep class io.flutter.plugins.deviceinfo.** { *; }
-dontwarn io.flutter.plugins.deviceinfo.**

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Keep share plus classes
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# Keep wakelock classes
-keep class creativemaybeno.wakelock.** { *; }
-dontwarn creativemaybeno.wakelock.**

# Keep Rive animation classes
-keep class app.rive.** { *; }
-dontwarn app.rive.**

# Keep HTTP classes
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }
-dontwarn io.flutter.plugins.flutter_plugin_android_lifecycle.**

# Keep Gson classes (if used)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep OkHttp classes (if used)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.squareup.okhttp.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.squareup.okhttp.**

# Keep Retrofit classes (if used)
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# Keep gRPC classes
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# General Android rules
-keep class android.support.** { *; }
-keep class androidx.** { *; }
-dontwarn android.support.**
-dontwarn androidx.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize and obfuscate
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Don't warn about missing classes
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe

# Additional rules for R8 compatibility
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep all classes that might be referenced by Flutter
-keep class * extends java.lang.Object { *; }

# Disable R8 full mode for compatibility
-dontoptimize
-dontobfuscate
