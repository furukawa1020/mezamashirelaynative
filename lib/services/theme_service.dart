import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// テーマ管理サービス
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';

  AppThemeMode _themeMode = AppThemeMode.system;
  AppColorTheme _colorTheme = AppColorTheme.blue;

  AppThemeMode get themeMode => _themeMode;
  AppColorTheme get colorTheme => _colorTheme;

  // 現在のThemeDataを取得
  ThemeData getTheme(Brightness systemBrightness) {
    final isDark =
        _themeMode == AppThemeMode.dark ||
        (_themeMode == AppThemeMode.system &&
            systemBrightness == Brightness.dark);

    switch (_colorTheme) {
      case AppColorTheme.blue:
        return isDark ? AppTheme.dark() : AppTheme.light();
      case AppColorTheme.orange:
        return AppTheme.orange(isDark: isDark);
      case AppColorTheme.green:
        return AppTheme.green(isDark: isDark);
      case AppColorTheme.purple:
        return AppTheme.purple(isDark: isDark);
    }
  }

  // テーマモードを設定
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  // カラーテーマを設定
  Future<void> setColorTheme(AppColorTheme theme) async {
    _colorTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorThemeKey, theme.toString());
    notifyListeners();
  }

  // 設定を読み込み
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // テーマモード読み込み
    final themeModeStr = prefs.getString(_themeModeKey);
    if (themeModeStr != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeStr,
        orElse: () => AppThemeMode.system,
      );
    }

    // カラーテーマ読み込み
    final colorThemeStr = prefs.getString(_colorThemeKey);
    if (colorThemeStr != null) {
      _colorTheme = AppColorTheme.values.firstWhere(
        (e) => e.toString() == colorThemeStr,
        orElse: () => AppColorTheme.blue,
      );
    }

    notifyListeners();
  }

  // テーマモードの表示名
  String getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'ライトモード';
      case AppThemeMode.dark:
        return 'ダークモード';
      case AppThemeMode.system:
        return 'システム設定';
    }
  }

  // カラーテーマの表示名
  String getColorThemeName(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.blue:
        return 'ブルー';
      case AppColorTheme.orange:
        return 'オレンジ';
      case AppColorTheme.green:
        return 'グリーン';
      case AppColorTheme.purple:
        return 'パープル';
    }
  }

  // カラーテーマのアイコンカラー
  Color getColorThemeColor(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.blue:
        return Colors.blue;
      case AppColorTheme.orange:
        return Colors.orange;
      case AppColorTheme.green:
        return Colors.green;
      case AppColorTheme.purple:
        return Colors.purple;
    }
  }
}
