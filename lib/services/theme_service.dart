// 文件： lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题服务
///
/// 用于管理应用程序的主题设置
class ThemeService {
  // 单例模式
  static final ThemeService _instance = ThemeService._internal();
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal();
  
  // 主题模式
  ThemeMode _themeMode = ThemeMode.system;
  
  // 获取当前主题模式
  ThemeMode get themeMode => _themeMode;
  
  // 是否使用系统主题
  bool get isUsingSystemTheme => _themeMode == ThemeMode.system;
  
  // 是否使用暗色主题
  bool get isUsingDarkTheme => _themeMode == ThemeMode.dark;
  
  // 初始化主题服务
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
  }
  
  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }
  
  // 切换主题模式
  Future<void> toggleThemeMode() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
  
  // 获取主题模式的本地化名称
  String getThemeModeName(BuildContext context, bool isChinese) {
    switch (_themeMode) {
      case ThemeMode.light:
        return isChinese ? '浅色模式' : 'Light Mode';
      case ThemeMode.dark:
        return isChinese ? '深色模式' : 'Dark Mode';
      case ThemeMode.system:
        return isChinese ? '跟随系统' : 'System Mode';
    }
  }
  
  // 获取主题模式的图标
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
  
  // 自定义浅色主题
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
  
  // 自定义深色主题
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
