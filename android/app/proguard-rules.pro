# Flutter関連のProGuardルール
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin関連
-keep class kotlin.** { *; }
-keep class org.jetbrains.** { *; }

# BLE関連（flutter_blue_plus）
-keep class com.lib.flutter_blue_plus.** { *; }

# Audio関連（audioplayers）
-keep class xyz.luan.audioplayers.** { *; }

# 一般的なルール
-dontwarn com.google.android.gms.**
-dontwarn org.conscrypt.**
