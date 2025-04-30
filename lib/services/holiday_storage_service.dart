import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';

/// 节日存储服务
///
/// 这是一个简单的本地存储服务，用于存储节日信息。
/// 它使用 SharedPreferences 来存储节日重要性信息。
/// 在未来，这个服务可以被替换为真正的数据库实现。
class HolidayStorageService {
  static const String _holidayImportanceKey = 'holidayImportance';

  /// 获取节日重要性
  static Future<Map<String, int>> getHolidayImportance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? importanceStr = prefs.getString(_holidayImportanceKey);

      if (importanceStr == null) {
        return {};
      }

      try {
        // 解析字符串格式 {key1: value1, key2: value2}
        final String cleanStr = importanceStr.replaceAll('{', '').replaceAll('}', '');
        final List<String> pairs = cleanStr.split(',');

        final Map<String, int> importanceMap = {};
        for (final pair in pairs) {
          if (pair.trim().isEmpty) continue;
          final List<String> keyValue = pair.split(':');
          if (keyValue.length == 2) {
            final String key = keyValue[0].trim();
            final int value = int.tryParse(keyValue[1].trim()) ?? 0;
            importanceMap[key] = value;
          }
        }

        return importanceMap;
      } catch (parseError) {
        debugPrint("解析节日重要性字符串失败: $parseError");
        return {};
      }
    } catch (e) {
      debugPrint("获取节日重要性失败: $e");
      return {};
    }
  }

  /// 保存节日重要性
  static Future<bool> saveHolidayImportance(Map<String, int> importance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_holidayImportanceKey, importance.toString());
      return true;
    } catch (e) {
      debugPrint("保存节日重要性失败: $e");
      return false;
    }
  }

  /// 更新单个节日的重要性
  static Future<bool> updateHolidayImportance(String holidayId, int importanceLevel) async {
    try {
      final importance = await getHolidayImportance();
      importance[holidayId] = importanceLevel;
      return await saveHolidayImportance(importance);
    } catch (e) {
      debugPrint("更新节日重要性失败: $e");
      return false;
    }
  }

  /// 获取用户所在地区的节日
  static List<HolidayModel> getHolidaysForRegion(BuildContext context, String region) {
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';

    // 从数据库获取所有节日
    return HiveDatabaseService.getHolidaysByRegion(region, isChineseLocale: isChinese);
  }

  /// 根据语言环境获取用户所在地区
  static String getUserRegion(BuildContext context) {
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
    } else {
      return 'INTL'; // 其他语言用户显示国际节日
    }
  }
}
