// 文件： lib/services/localization_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 多语言服务类
///
/// 用于处理应用程序中的多语言相关功能，包括：
/// 1. 语言切换和保存
/// 2. 多语言文本获取
/// 3. 多语言数据模型支持
/// 4. 区域和语言环境检测
class LocalizationService {
  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh'), // 中文
    Locale('en'), // 英文
    Locale('ja'), // 日文
    Locale('ko'), // 韩文
    Locale('fr'), // 法文
    Locale('de'), // 德文
  ];

  // 语言名称映射
  static const Map<String, String> languageNames = {
    'zh': '中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  /// 获取当前语言环境是否为中文
  static bool isChineseLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'zh';
  }

  /// 获取当前语言环境是否为日文
  static bool isJapaneseLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ja';
  }

  /// 获取当前语言环境是否为韩文
  static bool isKoreanLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ko';
  }

  /// 获取当前语言环境是否为法文
  static bool isFrenchLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'fr';
  }

  /// 获取当前语言环境是否为德文
  static bool isGermanLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de';
  }

  /// 获取当前语言环境代码
  static String getCurrentLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  /// 获取当前语言环境的国家代码
  static String? getCurrentCountryCode(BuildContext context) {
    return Localizations.localeOf(context).countryCode;
  }

  /// 获取当前语言的名称
  static String getCurrentLanguageName(BuildContext context) {
    final languageCode = getCurrentLanguageCode(context);
    return languageNames[languageCode] ?? 'English';
  }

  /// 保存语言设置
  static Future<bool> saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', languageCode);
      return true;
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
      return false;
    }
  }

  /// 获取保存的语言设置
  static Future<String?> getSavedLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('languageCode');
    } catch (e) {
      debugPrint('获取语言设置失败: $e');
      return null;
    }
  }

  /// 根据语言环境选择合适的文本
  static String getLocalizedText({
    required BuildContext context,
    required String textZh,
    required String textEn,
    String? textJa,
    String? textKo,
    String? textFr,
    String? textDe,
    String? fallbackText,
  }) {
    final languageCode = getCurrentLanguageCode(context);

    switch (languageCode) {
      case 'zh':
        return textZh;
      case 'en':
        return textEn;
      case 'ja':
        return textJa ?? textEn;
      case 'ko':
        return textKo ?? textEn;
      case 'fr':
        return textFr ?? textEn;
      case 'de':
        return textDe ?? textEn;
      default:
        return fallbackText ?? textEn;
    }
  }

  /// 根据语言环境获取用户所在地区
  static String getUserRegion(BuildContext? context) {
    if (context == null) {
      return 'CN'; // 如果 context 为 null，默认返回中国地区
    }

    final locale = Localizations.localeOf(context);

    if (locale.languageCode == 'zh') {
      return 'CN'; // 中文用户显示中国节日
    } else if (locale.languageCode == 'en') {
      if (locale.countryCode == 'US') {
        return 'US'; // 美国英语用户显示美国节日
      } else if (locale.countryCode == 'GB') {
        return 'UK'; // 英国英语用户显示英国节日
      } else {
        return 'US'; // 默认英语用户显示美国节日
      }
    } else if (locale.languageCode == 'ja') {
      return 'JP'; // 日语用户显示日本节日
    } else if (locale.languageCode == 'ko') {
      return 'KR'; // 韩语用户显示韩国节日
    } else if (locale.languageCode == 'fr') {
      return 'FR'; // 法语用户显示法国节日
    } else if (locale.languageCode == 'de') {
      return 'DE'; // 德语用户显示德国节日
    } else {
      return 'INTL'; // 其他语言用户显示国际节日
    }
  }

  /// 获取节日类型的本地化名称
  static String getLocalizedHolidayType(BuildContext context, String typeId) {
    final languageCode = getCurrentLanguageCode(context);

    switch (typeId) {
      case 'statutory':
        switch (languageCode) {
          case 'zh': return '法定节日';
          case 'ja': return '法定祝日';
          case 'ko': return '법정 공휴일';
          case 'fr': return 'Jour férié légal';
          case 'de': return 'Gesetzlicher Feiertag';
          default: return 'Statutory Holiday';
        }
      case 'traditional':
        switch (languageCode) {
          case 'zh': return '传统节日';
          case 'ja': return '伝統的な祝日';
          case 'ko': return '전통 공휴일';
          case 'fr': return 'Fête traditionnelle';
          case 'de': return 'Traditioneller Feiertag';
          default: return 'Traditional Holiday';
        }
      case 'memorial':
        switch (languageCode) {
          case 'zh': return '纪念日';
          case 'ja': return '記念日';
          case 'ko': return '기념일';
          case 'fr': return 'Jour commémoratif';
          case 'de': return 'Gedenktag';
          default: return 'Memorial Day';
        }
      case 'solarTerm':
        switch (languageCode) {
          case 'zh': return '节气';
          case 'ja': return '二十四節気';
          case 'ko': return '절기';
          case 'fr': return 'Termes solaires';
          case 'de': return 'Solartermine';
          default: return 'Solar Term';
        }
      case 'custom':
        switch (languageCode) {
          case 'zh': return '自定义';
          case 'ja': return 'カスタム';
          case 'ko': return '사용자 정의';
          case 'fr': return 'Personnalisé';
          case 'de': return 'Benutzerdefiniert';
          default: return 'Custom';
        }
      case 'religious':
        switch (languageCode) {
          case 'zh': return '宗教节日';
          case 'ja': return '宗教的な祝日';
          case 'ko': return '종교 공휴일';
          case 'fr': return 'Fête religieuse';
          case 'de': return 'Religiöser Feiertag';
          default: return 'Religious Holiday';
        }
      case 'international':
        switch (languageCode) {
          case 'zh': return '国际节日';
          case 'ja': return '国際的な祝日';
          case 'ko': return '국제 공휴일';
          case 'fr': return 'Fête internationale';
          case 'de': return 'Internationaler Feiertag';
          default: return 'International Holiday';
        }
      case 'professional':
        switch (languageCode) {
          case 'zh': return '职业节日';
          case 'ja': return '職業の祝日';
          case 'ko': return '직업 공휴일';
          case 'fr': return 'Fête professionnelle';
          case 'de': return 'Beruflicher Feiertag';
          default: return 'Professional Holiday';
        }
      case 'cultural':
        switch (languageCode) {
          case 'zh': return '文化节日';
          case 'ja': return '文化的な祝日';
          case 'ko': return '문화 공휴일';
          case 'fr': return 'Fête culturelle';
          case 'de': return 'Kultureller Feiertag';
          default: return 'Cultural Holiday';
        }
      default:
        switch (languageCode) {
          case 'zh': return '其他节日';
          case 'ja': return 'その他の祝日';
          case 'ko': return '기타 공휴일';
          case 'fr': return 'Autre jour férié';
          case 'de': return 'Anderer Feiertag';
          default: return 'Other Holiday';
        }
    }
  }

  /// 获取重要性的本地化名称
  static String getLocalizedImportanceLevel(BuildContext context, int importanceLevel) {
    final l10n = AppLocalizations.of(context);

    switch (importanceLevel) {
      case 1:
        return l10n.importanceHigh;
      case 2:
        return l10n.importanceVeryHigh;
      default:
        return l10n.importanceNormal;
    }
  }

  /// 获取计算类型的本地化名称
  static String getLocalizedCalculationType(BuildContext context, String calculationType) {
    final languageCode = getCurrentLanguageCode(context);

    switch (calculationType) {
      case 'fixedGregorian':
        switch (languageCode) {
          case 'zh': return '固定公历日期';
          case 'ja': return '固定グレゴリオ暦日付';
          case 'ko': return '고정 그레고리안 날짜';
          case 'fr': return 'Date grégorienne fixe';
          case 'de': return 'Festes gregorianisches Datum';
          default: return 'Fixed Gregorian Date';
        }
      case 'fixedLunar':
        switch (languageCode) {
          case 'zh': return '固定农历日期';
          case 'ja': return '固定旧暦日付';
          case 'ko': return '고정 음력 날짜';
          case 'fr': return 'Date lunaire fixe';
          case 'de': return 'Festes Monddatum';
          default: return 'Fixed Lunar Date';
        }
      case 'nthWeekdayOfMonth':
        switch (languageCode) {
          case 'zh': return '某月第n个星期几';
          case 'ja': return '月の第n曜日';
          case 'ko': return '월의 n번째 요일';
          case 'fr': return 'Nième jour de semaine du mois';
          case 'de': return 'N-ter Wochentag des Monats';
          default: return 'Nth Weekday of Month';
        }
      case 'solarTermBased':
        switch (languageCode) {
          case 'zh': return '基于节气';
          case 'ja': return '二十四節気ベース';
          case 'ko': return '절기 기준';
          case 'fr': return 'Basé sur le terme solaire';
          case 'de': return 'Basierend auf Solartermin';
          default: return 'Based on Solar Term';
        }
      case 'relativeTo':
        switch (languageCode) {
          case 'zh': return '相对日期';
          case 'ja': return '相対日付';
          case 'ko': return '상대 날짜';
          case 'fr': return 'Date relative';
          case 'de': return 'Relatives Datum';
          default: return 'Relative Date';
        }
      case 'lastWeekdayOfMonth':
        switch (languageCode) {
          case 'zh': return '某月最后一个星期几';
          case 'ja': return '月の最後の曜日';
          case 'ko': return '월의 마지막 요일';
          case 'fr': return 'Dernier jour de semaine du mois';
          case 'de': return 'Letzter Wochentag des Monats';
          default: return 'Last Weekday of Month';
        }
      case 'easterBased':
        switch (languageCode) {
          case 'zh': return '基于复活节';
          case 'ja': return 'イースターベース';
          case 'ko': return '부활절 기준';
          case 'fr': return 'Basé sur Pâques';
          case 'de': return 'Basierend auf Ostern';
          default: return 'Easter Based';
        }
      case 'lunarPhase':
        switch (languageCode) {
          case 'zh': return '基于月相';
          case 'ja': return '月相ベース';
          case 'ko': return '달의 위상 기준';
          case 'fr': return 'Basé sur la phase lunaire';
          case 'de': return 'Basierend auf Mondphase';
          default: return 'Lunar Phase Based';
        }
      case 'seasonBased':
        switch (languageCode) {
          case 'zh': return '基于季节';
          case 'ja': return '季節ベース';
          case 'ko': return '계절 기준';
          case 'fr': return 'Basé sur la saison';
          case 'de': return 'Basierend auf Jahreszeit';
          default: return 'Season Based';
        }
      case 'weekOfYear':
        switch (languageCode) {
          case 'zh': return '基于年份周数';
          case 'ja': return '年の週ベース';
          case 'ko': return '연간 주 기준';
          case 'fr': return 'Basé sur la semaine de l\'année';
          case 'de': return 'Basierend auf Kalenderwoche';
          default: return 'Week of Year';
        }
      default:
        return 'Unknown';
    }
  }

  /// 从多语言Map中获取本地化文本
  static String getTextFromMultilingualMap(Map<String, String>? textMap, BuildContext context) {
    if (textMap == null || textMap.isEmpty) return '';

    final languageCode = getCurrentLanguageCode(context);

    // 尝试获取完全匹配的语言代码
    if (textMap.containsKey(languageCode)) {
      return textMap[languageCode]!;
    }

    // 尝试获取带国家代码的语言
    final countryCode = getCurrentCountryCode(context);
    if (countryCode != null) {
      final fullCode = '${languageCode}_$countryCode';
      if (textMap.containsKey(fullCode)) {
        return textMap[fullCode]!;
      }
    }

    // 尝试获取英文版本
    if (textMap.containsKey('en')) {
      return textMap['en']!;
    }

    // 尝试获取中文版本
    if (textMap.containsKey('zh')) {
      return textMap['zh']!;
    }

    // 返回第一个可用的文本
    return textMap.values.first;
  }

  /// 创建多语言文本Map
  static Map<String, String> createMultilingualText({
    required String zhText,
    required String enText,
    String? jaText,
    String? koText,
    String? frText,
    String? deText,
  }) {
    final Map<String, String> result = {
      'zh': zhText,
      'en': enText,
    };

    if (jaText != null) result['ja'] = jaText;
    if (koText != null) result['ko'] = koText;
    if (frText != null) result['fr'] = frText;
    if (deText != null) result['de'] = deText;

    return result;
  }

  /// 更新多语言文本Map中的特定语言
  static Map<String, String> updateMultilingualText(Map<String, String>? original, String languageCode, String text) {
    final Map<String, String> result = original != null
        ? Map<String, String>.from(original)
        : {};

    result[languageCode] = text;
    return result;
  }

  /// 合并两个多语言文本Map
  static Map<String, String> mergeMultilingualText(Map<String, String>? map1, Map<String, String>? map2) {
    if (map1 == null || map1.isEmpty) return map2 ?? {};
    if (map2 == null || map2.isEmpty) return map1;

    final Map<String, String> result = Map<String, String>.from(map1);
    map2.forEach((key, value) {
      result[key] = value;
    });

    return result;
  }

  /// 检查多语言文本Map是否包含指定语言
  static bool hasLanguage(Map<String, String>? textMap, String languageCode) {
    if (textMap == null || textMap.isEmpty) return false;
    return textMap.containsKey(languageCode);
  }

  /// 获取多语言文本Map中的所有语言代码
  static List<String> getAvailableLanguages(Map<String, String>? textMap) {
    if (textMap == null || textMap.isEmpty) return [];
    return textMap.keys.toList();
  }

  /// 检查多语言文本Map是否完整（包含所有支持的语言）
  static bool isMultilingualTextComplete(Map<String, String>? textMap) {
    if (textMap == null) return false;

    // 检查是否包含所有支持的语言
    for (final locale in supportedLocales) {
      if (!textMap.containsKey(locale.languageCode)) {
        return false;
      }
    }

    return true;
  }

  /// 获取多语言文本Map的完整度百分比
  static double getMultilingualCompletionPercentage(Map<String, String>? textMap) {
    if (textMap == null || textMap.isEmpty) return 0.0;

    int supportedCount = 0;
    for (final locale in supportedLocales) {
      if (textMap.containsKey(locale.languageCode)) {
        supportedCount++;
      }
    }

    return supportedCount / supportedLocales.length * 100;
  }
}
