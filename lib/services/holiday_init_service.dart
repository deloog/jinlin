// 文件： lib/services/holiday_init_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 节日初始化服务
///
/// 用于初始化基础节日数据
class HolidayInitService {
  // 单例模式
  static final HolidayInitService _instance = HolidayInitService._internal();

  factory HolidayInitService() {
    return _instance;
  }

  HolidayInitService._internal();

  /// 检查是否已初始化基础节日数据
  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('global_holidays_initialized') ?? false;
  }

  /// 标记为已初始化
  Future<void> _markAsInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_holidays_initialized', true);
  }

  /// 初始化基础节日数据
  Future<void> initializeGlobalHolidays() async {
    try {
      // 检查是否已初始化
      final initialized = await isInitialized();
      if (initialized) {
        debugPrint('全球节日数据已初始化，跳过');
        return;
      }

      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 从JSON文件加载全球节日数据
      final globalHolidays = await _loadGlobalHolidaysFromJson();

      // 保存节日数据
      int count = 0;
      for (final holiday in globalHolidays) {
        // 检查节日是否已存在
        final existingHoliday = HiveDatabaseService.getHolidayById(holiday.id);
        if (existingHoliday == null) {
          await HiveDatabaseService.saveHoliday(holiday);
          count++;
        }
      }

      // 标记为已初始化
      await _markAsInitialized();

      debugPrint('成功初始化 $count 个全球节日');
    } catch (e) {
      debugPrint('初始化全球节日数据失败: $e');
      rethrow;
    }
  }

  /// 从JSON文件加载全球节日数据
  Future<List<HolidayModel>> _loadGlobalHolidaysFromJson() async {
    try {
      // 加载JSON文件
      final jsonString = await rootBundle.loadString('assets/data/preset_holidays.json');
      final jsonData = json.decode(jsonString);

      // 解析全球节日数据
      final List<dynamic> holidaysJson = jsonData['global_holidays'];
      final List<HolidayModel> holidays = [];

      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
        } catch (e) {
          debugPrint('解析节日数据失败: $e');
        }
      }

      debugPrint('从JSON文件加载了 ${holidays.length} 个全球节日');
      return holidays;
    } catch (e) {
      debugPrint('加载全球节日数据失败: $e');
      return [];
    }
  }

  /// 解析节日JSON数据
  HolidayModel _parseHolidayJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'],
      name: json['names']['zh'],
      nameEn: json['names']['en'],
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculation_type']),
      calculationRule: json['calculation_rule'],
      description: json['descriptions']?['zh'],
      descriptionEn: json['descriptions']?['en'],
      importanceLevel: _parseImportanceLevel(json['importance_level']),
      userImportance: 0,
    );
  }

  /// 解析节日类型
  HolidayType _parseHolidayType(String type) {
    switch (type) {
      case 'statutory':
        return HolidayType.statutory;
      case 'traditional':
        return HolidayType.traditional;
      case 'memorial':
        return HolidayType.memorial;
      case 'religious':
        return HolidayType.religious;
      case 'professional':
        return HolidayType.professional;
      case 'international':
        return HolidayType.international;
      default:
        return HolidayType.other;
    }
  }

  /// 解析日期计算类型
  DateCalculationType _parseCalculationType(String type) {
    switch (type) {
      case 'fixed_gregorian':
        return DateCalculationType.fixedGregorian;
      case 'fixed_lunar':
        return DateCalculationType.fixedLunar;
      case 'variable_rule':
      case 'nth_weekday_of_month':
        return DateCalculationType.nthWeekdayOfMonth;
      case 'custom_rule':
      case 'custom':
        return DateCalculationType.relativeTo;
      default:
        return DateCalculationType.fixedGregorian;
    }
  }

  /// 解析重要性级别
  ImportanceLevel _parseImportanceLevel(String level) {
    switch (level) {
      case 'high':
        return ImportanceLevel.high;
      case 'medium':
        return ImportanceLevel.medium;
      case 'low':
        return ImportanceLevel.low;
      default:
        return ImportanceLevel.medium;
    }
  }

  /// 初始化节日数据
  Future<void> initializeHolidayData([BuildContext? context]) async {
    try {
      // 检查是否已初始化
      final initialized = await isInitialized();
      if (initialized) {
        debugPrint('节日数据已初始化，跳过');
        return;
      }

      // 初始化全球节日数据
      await initializeGlobalHolidays();

      debugPrint('节日数据初始化成功');
    } catch (e) {
      debugPrint('节日数据初始化失败: $e');
      rethrow;
    }
  }

  /// 重置基础节日数据
  Future<void> resetGlobalHolidays() async {
    try {
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 从JSON文件加载全球节日数据
      final globalHolidays = await _loadGlobalHolidaysFromJson();

      // 删除现有的全球节日
      for (final holiday in globalHolidays) {
        await HiveDatabaseService.deleteHoliday(holiday.id);
      }

      // 重新保存节日数据
      for (final holiday in globalHolidays) {
        await HiveDatabaseService.saveHoliday(holiday);
      }

      // 标记为已初始化
      await _markAsInitialized();

      debugPrint('成功重置 ${globalHolidays.length} 个全球节日');
    } catch (e) {
      debugPrint('重置全球节日数据失败: $e');
      rethrow;
    }
  }
}
