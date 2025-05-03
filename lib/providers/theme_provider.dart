import 'package:flutter/material.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题提供者
///
/// 管理应用程序的主题设置
class ThemeProvider extends ChangeNotifier {
  // 日志服务
  final LoggingService _logger = LoggingService();

  // 当前主题模式
  ThemeMode _themeMode = ThemeMode.system;

  // 主题色
  Color _primaryColor = Colors.blue;

  // 是否使用Material 3
  bool _useMaterial3 = true;

  // 是否使用动态颜色
  bool _useDynamicColors = true;

  /// 构造函数
  ThemeProvider() {
    _logger.debug('初始化主题提供者');

    // 加载主题设置
    _loadThemeSettings();
  }

  /// 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 获取主题色
  Color get primaryColor => _primaryColor;

  /// 获取是否使用Material 3
  bool get useMaterial3 => _useMaterial3;

  /// 获取是否使用动态颜色
  bool get useDynamicColors => _useDynamicColors;

  /// 获取当前是否是深色主题
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// 获取浅色主题
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: _useMaterial3,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      brightness: Brightness.light,
    );
  }

  /// 获取深色主题
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: _useMaterial3,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      brightness: Brightness.dark,
    );
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    // 保存主题设置
    await _saveThemeSettings();
  }

  /// 设置主题色
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;

    _primaryColor = color;
    notifyListeners();

    // 保存主题设置
    await _saveThemeSettings();
  }

  /// 设置是否使用Material 3
  Future<void> setUseMaterial3(bool useMaterial3) async {
    if (_useMaterial3 == useMaterial3) return;

    _useMaterial3 = useMaterial3;
    notifyListeners();

    // 保存主题设置
    await _saveThemeSettings();
  }

  /// 设置是否使用动态颜色
  Future<void> setUseDynamicColors(bool useDynamicColors) async {
    if (_useDynamicColors == useDynamicColors) return;

    _useDynamicColors = useDynamicColors;
    notifyListeners();

    // 保存主题设置
    await _saveThemeSettings();
  }

  /// 切换主题模式
  Future<void> toggleThemeMode() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// 加载主题设置
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载主题模式
      final themeModeString = prefs.getString('theme_mode');
      if (themeModeString != null) {
        switch (themeModeString) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
            break;
        }
      }

      // 加载主题色
      final primaryColorValue = prefs.getInt('primary_color');
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }

      // 加载是否使用Material 3
      final useMaterial3 = prefs.getBool('use_material3');
      if (useMaterial3 != null) {
        _useMaterial3 = useMaterial3;
      }

      // 加载是否使用动态颜色
      final useDynamicColors = prefs.getBool('use_dynamic_colors');
      if (useDynamicColors != null) {
        _useDynamicColors = useDynamicColors;
      }

      _logger.debug('加载主题设置完成');
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载主题设置失败', e, stack);
    }
  }

  /// 保存主题设置
  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存主题模式
      String themeModeString;
      switch (_themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        default:
          themeModeString = 'system';
          break;
      }
      await prefs.setString('theme_mode', themeModeString);

      // 保存主题色
      await prefs.setInt('primary_color', _primaryColor.toARGB32());

      // 保存是否使用Material 3
      await prefs.setBool('use_material3', _useMaterial3);

      // 保存是否使用动态颜色
      await prefs.setBool('use_dynamic_colors', _useDynamicColors);

      _logger.debug('保存主题设置完成');
    } catch (e, stack) {
      _logger.error('保存主题设置失败', e, stack);
    }
  }

  /// 重置主题设置
  Future<void> resetThemeSettings() async {
    _themeMode = ThemeMode.system;
    _primaryColor = Colors.blue;
    _useMaterial3 = true;
    _useDynamicColors = true;

    notifyListeners();

    // 保存主题设置
    await _saveThemeSettings();
  }
}
