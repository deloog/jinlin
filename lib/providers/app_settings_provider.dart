import 'package:flutter/material.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用程序设置提供者
///
/// 管理应用程序的设置，包括语言、主题等
class AppSettingsProvider extends ChangeNotifier {
  // 当前语言环境
  Locale? _locale;
  Locale? get locale => _locale;

  // 是否跟随系统语言
  bool _followSystemLanguage = true;
  bool get followSystemLanguage => _followSystemLanguage;

  // 当前主题模式
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // 是否显示农历
  bool _showLunarCalendar = false;
  bool get showLunarCalendar => _showLunarCalendar;

  // 是否显示节气
  bool _showSolarTerms = false;
  bool get showSolarTerms => _showSolarTerms;

  // 是否显示国际节日
  bool _showInternationalHolidays = true;
  bool get showInternationalHolidays => _showInternationalHolidays;

  // 是否显示宗教节日
  bool _showReligiousHolidays = false;
  bool get showReligiousHolidays => _showReligiousHolidays;

  // 是否显示职业节日
  bool _showProfessionalHolidays = false;
  bool get showProfessionalHolidays => _showProfessionalHolidays;

  // 是否显示文化节日
  bool _showCulturalHolidays = true;
  bool get showCulturalHolidays => _showCulturalHolidays;

  // 是否启用AI功能
  bool _enableAIFeatures = true;
  bool get enableAIFeatures => _enableAIFeatures;

  // 是否启用云同步
  bool _enableCloudSync = false;
  bool get enableCloudSync => _enableCloudSync;

  // 是否启用通知
  bool _enableNotifications = true;
  bool get enableNotifications => _enableNotifications;

  // 特殊纪念日显示范围
  int _specialDaysRange = 10; // 默认显示10天内的特殊纪念日
  int get specialDaysRange => _specialDaysRange;

  // 初始化
  Future<void> initialize() async {
    await _loadSettings();
  }

  // 从SharedPreferences加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载语言设置
      final String? languageCode = prefs.getString('languageCode');
      final bool followSystemLanguage = prefs.getBool('followSystemLanguage') ?? true; // 默认跟随系统语言

      if (languageCode != null && !followSystemLanguage) {
        // 如果用户已经设置了语言且不跟随系统语言，则使用用户设置的语言
        _locale = Locale(languageCode);
      } else if (followSystemLanguage) {
        // 如果跟随系统语言，则使用系统语言
        _locale = null; // 设置为null，让系统自动选择语言
      }

      // 保存跟随系统语言的设置
      _followSystemLanguage = followSystemLanguage;

      // 加载主题设置
      final String? themeModeString = prefs.getString('themeMode');
      if (themeModeString != null) {
        _themeMode = _parseThemeMode(themeModeString);
      }

      // 加载其他设置
      _showLunarCalendar = prefs.getBool('showLunarCalendar') ?? false;
      _showSolarTerms = prefs.getBool('showSolarTerms') ?? false;
      _showInternationalHolidays = prefs.getBool('showInternationalHolidays') ?? true;
      _showReligiousHolidays = prefs.getBool('showReligiousHolidays') ?? false;
      _showProfessionalHolidays = prefs.getBool('showProfessionalHolidays') ?? false;
      _showCulturalHolidays = prefs.getBool('showCulturalHolidays') ?? true;
      _enableAIFeatures = prefs.getBool('enableAIFeatures') ?? true;
      _enableCloudSync = prefs.getBool('enableCloudSync') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _specialDaysRange = prefs.getInt('specialDaysRange') ?? 10;

      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  // 更新语言设置
  Future<void> updateLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    // 当手动设置语言时，自动关闭跟随系统语言
    _followSystemLanguage = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', newLocale.languageCode);
      await prefs.setBool('followSystemLanguage', false);
      if (newLocale.countryCode != null) {
        await prefs.setString('countryCode', newLocale.countryCode!);
      } else {
        await prefs.remove('countryCode');
      }
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }
  }

  // 更新是否跟随系统语言
  Future<void> updateFollowSystemLanguage(bool value) async {
    if (_followSystemLanguage == value) return;

    _followSystemLanguage = value;

    if (value) {
      // 如果开启跟随系统语言，则清除当前语言设置
      _locale = null;
    } else if (_locale == null) {
      // 如果关闭跟随系统语言，但没有设置过语言，则使用当前系统语言
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = systemLocale;
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('followSystemLanguage', value);

      if (!value && _locale != null) {
        // 如果关闭跟随系统语言，则保存当前语言设置
        await prefs.setString('languageCode', _locale!.languageCode);
        if (_locale!.countryCode != null) {
          await prefs.setString('countryCode', _locale!.countryCode!);
        } else {
          await prefs.remove('countryCode');
        }
      }
    } catch (e) {
      debugPrint('保存跟随系统语言设置失败: $e');
    }
  }

  // 更新主题设置
  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', newThemeMode.toString().split('.').last);
    } catch (e) {
      debugPrint('保存主题设置失败: $e');
    }
  }

  // 更新是否显示农历
  Future<void> updateShowLunarCalendar(bool value) async {
    if (_showLunarCalendar == value) return;

    _showLunarCalendar = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showLunarCalendar', value);
    } catch (e) {
      debugPrint('保存农历设置失败: $e');
    }
  }

  // 更新是否显示节气
  Future<void> updateShowSolarTerms(bool value) async {
    if (_showSolarTerms == value) return;

    _showSolarTerms = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showSolarTerms', value);
    } catch (e) {
      debugPrint('保存节气设置失败: $e');
    }
  }

  // 更新是否显示国际节日
  Future<void> updateShowInternationalHolidays(bool value) async {
    if (_showInternationalHolidays == value) return;

    _showInternationalHolidays = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showInternationalHolidays', value);
    } catch (e) {
      debugPrint('保存国际节日设置失败: $e');
    }
  }

  // 更新是否显示宗教节日
  Future<void> updateShowReligiousHolidays(bool value) async {
    if (_showReligiousHolidays == value) return;

    _showReligiousHolidays = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showReligiousHolidays', value);
    } catch (e) {
      debugPrint('保存宗教节日设置失败: $e');
    }
  }

  // 更新是否显示职业节日
  Future<void> updateShowProfessionalHolidays(bool value) async {
    if (_showProfessionalHolidays == value) return;

    _showProfessionalHolidays = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showProfessionalHolidays', value);
    } catch (e) {
      debugPrint('保存职业节日设置失败: $e');
    }
  }

  // 更新是否显示文化节日
  Future<void> updateShowCulturalHolidays(bool value) async {
    if (_showCulturalHolidays == value) return;

    _showCulturalHolidays = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showCulturalHolidays', value);
    } catch (e) {
      debugPrint('保存文化节日设置失败: $e');
    }
  }

  // 更新是否启用AI功能
  Future<void> updateEnableAIFeatures(bool value) async {
    if (_enableAIFeatures == value) return;

    _enableAIFeatures = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableAIFeatures', value);
    } catch (e) {
      debugPrint('保存AI功能设置失败: $e');
    }
  }

  // 更新是否启用云同步
  Future<void> updateEnableCloudSync(bool value) async {
    if (_enableCloudSync == value) return;

    _enableCloudSync = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableCloudSync', value);
    } catch (e) {
      debugPrint('保存云同步设置失败: $e');
    }
  }

  // 更新是否启用通知
  Future<void> updateEnableNotifications(bool value) async {
    if (_enableNotifications == value) return;

    _enableNotifications = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableNotifications', value);
    } catch (e) {
      debugPrint('保存通知设置失败: $e');
    }
  }

  // 更新特殊纪念日显示范围
  Future<void> updateSpecialDaysRange(int range) async {
    if (_specialDaysRange == range) return;

    _specialDaysRange = range;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('specialDaysRange', range);
    } catch (e) {
      debugPrint('保存特殊纪念日显示范围失败: $e');
    }
  }

  // 解析主题模式
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
