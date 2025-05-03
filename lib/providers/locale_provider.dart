import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/language/language.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言提供者
///
/// 管理应用程序的语言设置
class LocaleProvider extends ChangeNotifier {
  // 日志服务
  final LoggingService _logger = LoggingService();

  // 当前语言
  Locale? _locale;

  // 是否使用系统语言
  bool _useSystemLocale = true;

  // 支持的语言
  final List<Locale> _supportedLocales = Language.supportedLanguages.map((lang) => lang.toLocale()).toList();

  /// 构造函数
  LocaleProvider() {
    _logger.debug('初始化语言提供者');

    // 加载语言设置
    _loadLocaleSettings();
  }

  /// 获取当前语言
  Locale? get locale => _locale;

  /// 获取是否使用系统语言
  bool get useSystemLocale => _useSystemLocale;

  /// 获取支持的语言
  List<Locale> get supportedLocales => _supportedLocales;

  /// 获取当前语言代码
  String get currentLanguageCode => _locale?.languageCode ?? 'zh';

  /// 获取当前国家代码
  String get currentCountryCode => _locale?.countryCode ?? 'CN';

  /// 获取当前语言名称
  String get currentLanguageName {
    if (_locale == null) return Language.supportedLanguages.first.nameLocal;

    final language = Language.fromLocale(_locale!);
    return language.nameLocal;
  }

  /// 获取语言名称
  String getLanguageName(Locale locale) {
    final language = Language.fromLocale(locale);
    return language.nameLocal;
  }

  /// 设置语言
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    _locale = locale;
    _useSystemLocale = locale == null;
    notifyListeners();

    // 保存语言设置
    await _saveLocaleSettings();
  }

  /// 设置是否使用系统语言
  Future<void> setUseSystemLocale(bool useSystemLocale) async {
    if (_useSystemLocale == useSystemLocale) return;

    _useSystemLocale = useSystemLocale;
    if (useSystemLocale) {
      _locale = null;
    }
    notifyListeners();

    // 保存语言设置
    await _saveLocaleSettings();
  }

  /// 加载语言设置
  Future<void> _loadLocaleSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载是否使用系统语言
      final useSystemLocale = prefs.getBool('use_system_locale');
      if (useSystemLocale != null) {
        _useSystemLocale = useSystemLocale;
      }

      // 如果不使用系统语言，加载语言设置
      if (!_useSystemLocale) {
        final languageCode = prefs.getString('language_code');
        final countryCode = prefs.getString('country_code');

        if (languageCode != null) {
          _locale = Locale(languageCode, countryCode);
        }
      }

      _logger.debug('加载语言设置完成');
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载语言设置失败', e, stack);
    }
  }

  /// 保存语言设置
  Future<void> _saveLocaleSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存是否使用系统语言
      await prefs.setBool('use_system_locale', _useSystemLocale);

      // 保存语言设置
      if (_locale != null) {
        await prefs.setString('language_code', _locale!.languageCode);
        if (_locale!.countryCode != null) {
          await prefs.setString('country_code', _locale!.countryCode!);
        } else {
          await prefs.remove('country_code');
        }
      } else {
        await prefs.remove('language_code');
        await prefs.remove('country_code');
      }

      _logger.debug('保存语言设置完成');
    } catch (e, stack) {
      _logger.error('保存语言设置失败', e, stack);
    }
  }

  /// 重置语言设置
  Future<void> resetLocaleSettings() async {
    _locale = null;
    _useSystemLocale = true;

    notifyListeners();

    // 保存语言设置
    await _saveLocaleSettings();
  }

  /// 获取系统语言
  Locale? getSystemLocale() {
    final systemLocales = PlatformDispatcher.instance.locales;
    if (systemLocales.isEmpty) return null;

    // 尝试找到匹配的语言
    for (final locale in systemLocales) {
      for (final supportedLocale in _supportedLocales) {
        if (locale.languageCode == supportedLocale.languageCode) {
          return supportedLocale;
        }
      }
    }

    // 如果没有匹配的语言，返回第一个支持的语言
    return _supportedLocales.first;
  }

  /// 获取实际使用的语言
  Locale getEffectiveLocale() {
    if (_useSystemLocale) {
      return getSystemLocale() ?? _supportedLocales.first;
    }
    return _locale ?? _supportedLocales.first;
  }
}
