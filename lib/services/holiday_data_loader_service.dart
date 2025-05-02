import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';

/// 节日数据加载服务
///
/// 负责从JSON文件加载预设节日数据并导入数据库
/// 只在应用首次安装或数据库重置时运行
class HolidayDataLoaderService {
  static final HolidayDataLoaderService _instance = HolidayDataLoaderService._internal();

  factory HolidayDataLoaderService() {
    return _instance;
  }

  HolidayDataLoaderService._internal();

  /// 数据库管理器
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();

  /// 加载预设节日数据
  ///
  /// 从JSON文件加载预设节日数据并导入数据库
  Future<void> loadPresetHolidays() async {
    try {
      // 初始化数据库
      await _dbManager.initialize(null);

      // 检查是否是首次启动
      final isFirstLaunch = await _dbManager.isFirstLaunch();

      // 获取当前数据版本
      final dataVersion = await _dbManager.getDataVersion();
      const currentDataVersion = 1; // 当前数据版本

      // 首次启动或数据版本更新时加载预设节日数据
      if (isFirstLaunch || dataVersion < currentDataVersion) {
        debugPrint('首次启动或数据版本更新，加载预设节日数据');

        // 加载全球节日数据
        final globalHolidays = await _loadGlobalHolidays();
        await _dbManager.saveHolidays(globalHolidays);

        // 加载中国节日数据
        final chineseHolidays = await _loadRegionalHolidays('cn');
        await _dbManager.saveHolidays(chineseHolidays);

        // 加载美国节日数据
        final usHolidays = await _loadRegionalHolidays('us');
        await _dbManager.saveHolidays(usHolidays);

        // 加载日本节日数据
        final japaneseHolidays = await _loadRegionalHolidays('jp');
        await _dbManager.saveHolidays(japaneseHolidays);

        // 加载韩国节日数据
        final koreanHolidays = await _loadRegionalHolidays('kr');
        await _dbManager.saveHolidays(koreanHolidays);

        // 加载法国节日数据
        final frenchHolidays = await _loadRegionalHolidays('fr');
        await _dbManager.saveHolidays(frenchHolidays);

        // 加载德国节日数据
        final germanHolidays = await _loadRegionalHolidays('de');
        await _dbManager.saveHolidays(germanHolidays);

        // 标记首次启动完成
        if (isFirstLaunch) {
          await _dbManager.markFirstLaunchComplete();
        }

        // 更新数据版本
        if (dataVersion < currentDataVersion) {
          await _dbManager.updateDataVersion(currentDataVersion);
        }

        debugPrint('预设节日数据加载完成');
      } else {
        debugPrint('非首次启动且数据版本最新，跳过预设节日数据加载');
      }
    } catch (e) {
      debugPrint('加载预设节日数据失败: $e');
      rethrow;
    }
  }

  /// 从JSON文件加载全球节日数据
  Future<List<Holiday>> _loadGlobalHolidays() async {
    try {
      // 加载JSON文件
      final jsonString = await rootBundle.loadString('assets/data/preset_holidays.json');
      final jsonData = json.decode(jsonString);

      // 解析全球节日数据
      final List<dynamic> holidaysJson = jsonData['global_holidays'];
      final List<Holiday> holidays = [];

      for (final holidayJson in holidaysJson) {
        final holiday = _parseHolidayJson(holidayJson);
        holidays.add(holiday);
      }

      debugPrint('从JSON文件加载了 ${holidays.length} 个全球节日');
      return holidays;
    } catch (e) {
      debugPrint('加载全球节日数据失败: $e');
      return [];
    }
  }

  /// 从JSON文件加载地区节日数据
  Future<List<Holiday>> _loadRegionalHolidays(String region) async {
    try {
      // 加载JSON文件
      final jsonString = await rootBundle.loadString('assets/data/holidays_$region.json');
      final jsonData = json.decode(jsonString);

      // 解析地区节日数据
      final List<dynamic> holidaysJson = jsonData['holidays'];
      final List<Holiday> holidays = [];

      for (final holidayJson in holidaysJson) {
        final holiday = _parseHolidayJson(holidayJson);
        holidays.add(holiday);
      }

      debugPrint('从JSON文件加载了 ${holidays.length} 个 $region 地区节日');
      return holidays;
    } catch (e) {
      debugPrint('加载 $region 地区节日数据失败: $e');
      return [];
    }
  }

  /// 解析节日JSON数据
  Holiday _parseHolidayJson(Map<String, dynamic> json) {
    // 解析多语言名称
    final Map<String, String> names = {};
    (json['names'] as Map<String, dynamic>).forEach((key, value) {
      names[key] = value.toString();
    });

    // 解析多语言描述
    final Map<String, String> descriptions = {};
    if (json['descriptions'] != null) {
      (json['descriptions'] as Map<String, dynamic>).forEach((key, value) {
        descriptions[key] = value.toString();
      });
    }

    // 解析多语言习俗
    final Map<String, String>? customs = json['customs'] != null
        ? (json['customs'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言食物
    final Map<String, String>? foods = json['foods'] != null
        ? (json['foods'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言祝福语
    final Map<String, String>? greetings = json['greetings'] != null
        ? (json['greetings'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言活动
    final Map<String, String>? activities = json['activities'] != null
        ? (json['activities'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言历史
    final Map<String, String>? history = json['history'] != null
        ? (json['history'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 创建节日对象
    return Holiday(
      id: json['id'],
      isSystemHoliday: true,
      names: names,
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculation_type']),
      calculationRule: json['calculation_rule'],
      descriptions: descriptions,
      importanceLevel: _parseImportanceLevel(json['importance_level']),
      customs: customs,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
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
        return DateCalculationType.variableRule;
      case 'custom_rule':
        return DateCalculationType.custom;
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
}
