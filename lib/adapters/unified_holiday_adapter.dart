import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart' as unified;
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/special_date.dart' as special_date;
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/services/hive_database_service.dart';

/// 统一节日数据适配器
///
/// 用于连接统一数据模型和旧数据模型，使它们能够协同工作
class UnifiedHolidayAdapter {
  final DatabaseManagerUnified _dbManager;

  UnifiedHolidayAdapter(this._dbManager);

  /// 将用户设置的节日重要性同步到统一数据库
  Future<void> syncHolidayImportance(BuildContext context) async {
    debugPrint('开始同步节日重要性...');

    try {
      // 初始化数据库
      await _dbManager.initialize(context);

      // 获取旧数据库中的节日重要性
      await HiveDatabaseService.initialize();
      final oldImportance = HiveDatabaseService.getHolidayImportance();

      // 获取统一数据库中的所有节日
      final holidays = await _dbManager.getAllHolidays();

      // 更新节日重要性
      for (final holiday in holidays) {
        if (oldImportance.containsKey(holiday.id)) {
          final importance = oldImportance[holiday.id] ?? 0;
          await _dbManager.updateHolidayImportance(holiday.id, importance);
          debugPrint('更新节日 ${holiday.id} 的重要性为 $importance');
        }
      }

      debugPrint('节日重要性同步完成');
    } catch (e) {
      debugPrint('同步节日重要性失败: $e');
      rethrow;
    }
  }

  /// 将统一数据库中的节日重要性同步到旧数据库
  Future<void> syncHolidayImportanceToOldDb(BuildContext context) async {
    debugPrint('开始将节日重要性同步到旧数据库...');

    try {
      // 初始化数据库
      await _dbManager.initialize(context);

      // 获取统一数据库中的所有节日
      final holidays = await _dbManager.getAllHolidays();

      // 初始化旧数据库
      await HiveDatabaseService.initialize();

      // 创建重要性映射
      final Map<String, int> importanceMap = {};

      // 提取节日重要性
      for (final holiday in holidays) {
        importanceMap[holiday.id] = holiday.userImportance;
      }

      // 保存到旧数据库
      await HiveDatabaseService.saveHolidayImportance(importanceMap);

      debugPrint('节日重要性已同步到旧数据库');
    } catch (e) {
      debugPrint('同步节日重要性到旧数据库失败: $e');
      rethrow;
    }
  }

  /// 将统一模型的Holiday转换为旧模型的SpecialDate
  special_date.SpecialDate convertToSpecialDate(unified.Holiday holiday) {
    // 获取中文名称和描述
    final name = holiday.names['zh'] ?? holiday.names['en'] ?? '';
    final description = holiday.descriptions['zh'] ?? holiday.descriptions['en'] ?? '';

    // 获取英文名称和描述
    final nameEn = holiday.names['en'] ?? '';
    final descriptionEn = holiday.descriptions['en'] ?? '';

    // 转换类型
    final type = _convertToSpecialDateType(holiday.type);

    // 转换计算类型
    final calculationType = _convertToSpecialDateCalculationType(holiday.calculationType);

    // 转换重要性级别
    final importanceLevel = _convertToSpecialImportanceLevel(holiday.importanceLevel);

    // 创建SpecialDate对象
    return special_date.SpecialDate(
      id: holiday.id,
      name: name,
      nameEn: nameEn,
      type: type,
      regions: holiday.regions,
      calculationType: calculationType,
      calculationRule: holiday.calculationRule,
      description: description,
      descriptionEn: descriptionEn,
      importanceLevel: importanceLevel,
      customs: holiday.customs?['zh'],
      taboos: holiday.taboos?['zh'],
      foods: holiday.foods?['zh'],
      greetings: holiday.greetings?['zh'],
      activities: holiday.activities?['zh'],
      history: holiday.history?['zh'],
      imageUrl: holiday.imageUrl,
    );
  }

  /// 将旧模型的HolidayModel转换为统一模型的Holiday
  unified.Holiday convertFromHolidayModel(HolidayModel model) {
    // 创建名称映射
    final Map<String, String> names = {
      'zh': model.name,
    };

    // 如果有英文名称，添加到映射
    if (model.nameEn != null && model.nameEn!.isNotEmpty) {
      names['en'] = model.nameEn!;
    }

    // 创建描述映射
    final Map<String, String> descriptions = {};

    // 如果有中文描述，添加到映射
    if (model.description != null && model.description!.isNotEmpty) {
      descriptions['zh'] = model.description!;
    }

    // 如果有英文描述，添加到映射
    if (model.descriptionEn != null && model.descriptionEn!.isNotEmpty) {
      descriptions['en'] = model.descriptionEn!;
    }

    // 创建自定义映射
    Map<String, String>? customs;
    if (model.customs != null && model.customs!.isNotEmpty) {
      customs = {'zh': model.customs!};
    }

    // 创建禁忌映射
    Map<String, String>? taboos;
    if (model.taboos != null && model.taboos!.isNotEmpty) {
      taboos = {'zh': model.taboos!};
    }

    // 创建食物映射
    Map<String, String>? foods;
    if (model.foods != null && model.foods!.isNotEmpty) {
      foods = {'zh': model.foods!};
    }

    // 创建祝福语映射
    Map<String, String>? greetings;
    if (model.greetings != null && model.greetings!.isNotEmpty) {
      greetings = {'zh': model.greetings!};
    }

    // 创建活动映射
    Map<String, String>? activities;
    if (model.activities != null && model.activities!.isNotEmpty) {
      activities = {'zh': model.activities!};
    }

    // 创建历史映射
    Map<String, String>? history;
    if (model.history != null && model.history!.isNotEmpty) {
      history = {'zh': model.history!};
    }

    // 转换类型
    final type = _convertFromHolidayType(model.type);

    // 转换计算类型
    final calculationType = _convertFromHolidayCalculationType(model.calculationType);

    // 转换重要性级别
    final importanceLevel = _convertFromHolidayImportanceLevel(model.importanceLevel);

    // 创建Holiday对象
    return unified.Holiday(
      id: model.id,
      isSystemHoliday: model.isSystemHoliday,
      names: names,
      type: type,
      regions: model.regions,
      calculationType: calculationType,
      calculationRule: model.calculationRule,
      descriptions: descriptions,
      importanceLevel: importanceLevel,
      customs: customs,
      taboos: taboos,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
      imageUrl: model.imageUrl,
      userImportance: model.userImportance,
      contactId: model.contactId,
      createdAt: model.createdAt,
      lastModified: model.lastModified,
    );
  }

  /// 将统一模型的Holiday类型转换为旧模型的SpecialDateType类型
  special_date.SpecialDateType _convertToSpecialDateType(unified.HolidayType type) {
    switch (type) {
      case unified.HolidayType.statutory:
        return special_date.SpecialDateType.statutory;
      case unified.HolidayType.traditional:
        return special_date.SpecialDateType.traditional;
      case unified.HolidayType.solarTerm:
        return special_date.SpecialDateType.solarTerm;
      case unified.HolidayType.memorial:
        return special_date.SpecialDateType.memorial;
      case unified.HolidayType.custom:
        return special_date.SpecialDateType.custom;
      default:
        return special_date.SpecialDateType.other;
    }
  }

  /// 将统一模型的DateCalculationType类型转换为旧模型的DateCalculationType类型
  special_date.DateCalculationType _convertToSpecialDateCalculationType(unified.DateCalculationType type) {
    switch (type) {
      case unified.DateCalculationType.fixedGregorian:
        return special_date.DateCalculationType.fixedGregorian;
      case unified.DateCalculationType.fixedLunar:
        return special_date.DateCalculationType.fixedLunar;
      case unified.DateCalculationType.variableRule:
        return special_date.DateCalculationType.nthWeekdayOfMonth;
      case unified.DateCalculationType.custom:
        return special_date.DateCalculationType.relativeTo;
    }
  }

  /// 将统一模型的ImportanceLevel类型转换为旧模型的ImportanceLevel类型
  special_date.ImportanceLevel _convertToSpecialImportanceLevel(unified.ImportanceLevel level) {
    switch (level) {
      case unified.ImportanceLevel.low:
        return special_date.ImportanceLevel.low;
      case unified.ImportanceLevel.medium:
        return special_date.ImportanceLevel.medium;
      case unified.ImportanceLevel.high:
        return special_date.ImportanceLevel.high;
    }
  }

  /// 将旧模型的HolidayType类型转换为统一模型的HolidayType类型
  unified.HolidayType _convertFromHolidayType(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return unified.HolidayType.statutory;
      case HolidayType.traditional:
        return unified.HolidayType.traditional;
      case HolidayType.solarTerm:
        return unified.HolidayType.solarTerm;
      case HolidayType.memorial:
        return unified.HolidayType.memorial;
      case HolidayType.custom:
        return unified.HolidayType.custom;
      case HolidayType.religious:
        return unified.HolidayType.religious;
      case HolidayType.international:
        return unified.HolidayType.international;
      case HolidayType.professional:
        return unified.HolidayType.professional;
      case HolidayType.cultural:
        return unified.HolidayType.cultural;
      default:
        return unified.HolidayType.other;
    }
  }

  /// 将旧模型的DateCalculationType类型转换为统一模型的DateCalculationType类型
  unified.DateCalculationType _convertFromHolidayCalculationType(DateCalculationType type) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        return unified.DateCalculationType.fixedGregorian;
      case DateCalculationType.fixedLunar:
        return unified.DateCalculationType.fixedLunar;
      case DateCalculationType.nthWeekdayOfMonth:
        return unified.DateCalculationType.variableRule;
      default:
        return unified.DateCalculationType.custom;
    }
  }

  /// 将旧模型的ImportanceLevel类型转换为统一模型的ImportanceLevel类型
  unified.ImportanceLevel _convertFromHolidayImportanceLevel(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.low:
        return unified.ImportanceLevel.low;
      case ImportanceLevel.medium:
        return unified.ImportanceLevel.medium;
      case ImportanceLevel.high:
        return unified.ImportanceLevel.high;
    }
  }
}
