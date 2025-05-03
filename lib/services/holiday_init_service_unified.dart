import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/database/database_factory.dart';
import 'package:jinlin_app/services/localization_service.dart';

/// 节日数据初始化服务
///
/// 负责初始化系统预设节日数据，只在首次启动或数据版本更新时执行
class HolidayInitServiceUnified {
  static final HolidayInitServiceUnified _instance = HolidayInitServiceUnified._internal();

  factory HolidayInitServiceUnified() {
    return _instance;
  }

  HolidayInitServiceUnified._internal();

  // 数据库服务
  final DatabaseInterface _db = kIsWeb
      ? DatabaseFactory.create(DatabaseType.hive)
      : DatabaseFactory.create(DatabaseType.sqlite);

  // UUID生成器 - 在将来的功能中会使用
  // final Uuid _uuid = Uuid();

  /// 当前数据版本
  /// 每次更新节日数据时递增
  static const int currentDataVersion = 1;

  /// 初始化节日数据
  ///
  /// 只在首次启动或数据版本更新时执行
  Future<void> initializeHolidayData(BuildContext? context) async {
    try {
      // 初始化数据库
      await _db.initialize();

      // 检查是否是首次启动
      final isFirstLaunch = await _db.isFirstLaunch();

      // 获取当前数据版本
      final dataVersion = await _db.getDataVersion();

      // 首次启动或数据版本更新时初始化/更新系统节日
      if (isFirstLaunch || dataVersion < currentDataVersion) {
        debugPrint('首次启动或数据版本更新，初始化系统节日数据');

        // 获取用户地区
        final String userRegion;
        if (context != null && context.mounted) {
          userRegion = LocalizationService.getUserRegion(context);
        } else {
          userRegion = 'CN'; // 默认使用中国地区
          debugPrint('警告：BuildContext为null或已失效，使用默认地区(CN)');
        }

        // 加载适合该地区的系统节日
        final systemHolidays = await _getSystemHolidays(userRegion);

        // 保存系统节日到数据库
        await _db.saveHolidays(systemHolidays);

        // 标记首次启动完成
        if (isFirstLaunch) {
          await _db.markFirstLaunchComplete();
        }

        // 更新数据版本
        if (dataVersion < currentDataVersion) {
          await _db.updateDataVersion(currentDataVersion);
        }

        debugPrint('系统节日数据初始化完成');
      } else {
        debugPrint('非首次启动且数据版本最新，跳过系统节日数据初始化');
      }
    } catch (e) {
      debugPrint('初始化节日数据失败: $e');
      rethrow;
    }
  }

  /// 获取系统预设节日
  ///
  /// 根据用户地区返回适合的系统预设节日
  Future<List<Holiday>> _getSystemHolidays(String region) async {
    // 全球通用节日
    final globalHolidays = await _loadGlobalHolidays();

    // 地区特定节日
    final regionHolidays = await _loadRegionalHolidays(region.toLowerCase());

    // 合并节日列表
    return [...globalHolidays, ...regionHolidays];
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
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
        } catch (e) {
          debugPrint('解析节日数据失败: $e');
        }
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
