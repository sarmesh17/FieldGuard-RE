# ProGuard / R8 keep rules for release builds (isMinifyEnabled + isShrinkResources).
#
# Flutter and most plugins ship their own "consumer" ProGuard rules inside their
# AARs, which R8 applies automatically. The rules below cover the gaps that are
# known to cause runtime crashes in *release* builds when code shrinking is on —
# mostly classes reached via reflection or from native code, which R8 can't see.

# --- Flutter embedding (defensive; normally provided by the Flutter tooling) ---
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Flutter's embedding references Google Play Core (deferred components /
# Play Feature Delivery). This app does NOT use deferred components, so the
# Play Core library is not a dependency and R8 flags those references as
# missing classes (build error with minify on). These code paths are never
# executed, so it is safe to tell R8 to ignore them.
-dontwarn com.google.android.play.core.**

# --- flutter_local_notifications -------------------------------------------------
# The plugin serializes notification/scheduling details with Gson via reflection.
# Without these, scheduled/queued notifications crash on deserialization in release.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
# Keep generic signatures of model classes used with Gson (TypeToken).
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- core library desugaring (java.time backport used by notifications) ----------
-keep class j$.** { *; }
-dontwarn j$.**

# --- Mapbox ----------------------------------------------------------------------
# Mapbox ships consumer rules, but keep its packages defensively since the native
# map engine resolves Java classes via JNI.
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# --- General: keep enum + native-method plumbing R8 sometimes over-strips --------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
