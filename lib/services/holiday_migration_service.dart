import 'package:flutter/material.dart';
import 'package:jinlin_app/data/holidays_cn.dart' as cn_holidays;
import 'package:jinlin_app/data/holidays_intl.dart' as intl_holidays;
import 'package:jinlin_app/data/holidays_asia.dart' as asia_holidays;
import 'package:jinlin_app/data/special_days.dart' as special_days;
import 'package:jinlin_app/services/hive_database_service.dart';

/// 节日数据迁移服务
///
/// 用于将硬编码的节日信息导入到Hive数据库中。
class HolidayMigrationService {
  /// 检查数据迁移是否完成
  static bool isMigrationComplete() {
    return HiveDatabaseService.isMigrationComplete();
  }

  /// 迁移节日数据
  static Future<void> migrateHolidays(BuildContext context) async {
    // 检查是否已经迁移过
    if (isMigrationComplete()) {
      return;
    }

    debugPrint('开始节日数据迁移...');

    // 在异步操作前保存BuildContext相关数据
    final cnHolidays = cn_holidays.getChineseHolidays(context);
    final intlHolidays = intl_holidays.getInternationalHolidays(context);
    final asiaHolidays = asia_holidays.getAsianHolidays(context);
    final specialDays = special_days.getSpecialDays(context);

    try {
      // 清理数据库中的所有节日，确保没有重复
      await HiveDatabaseService.clearHolidays();

      // 创建一个集合，用于存储已处理的计算规则
      final Set<String> processedRules = {};

      // 预处理节日列表，去除重复的计算规则
      final List<dynamic> allHolidays = [];

      // 处理中国节日（优先级最高）
      for (var holiday in cnHolidays) {
        final rule = holiday.calculationRule;
        if (!processedRules.contains(rule)) {
          allHolidays.add(holiday);
          processedRules.add(rule);
        }
      }

      // 处理国际节日
      for (var holiday in intlHolidays) {
        final rule = holiday.calculationRule;
        if (!processedRules.contains(rule)) {
          allHolidays.add(holiday);
          processedRules.add(rule);
        }
      }

      // 处理亚洲节日
      for (var holiday in asiaHolidays) {
        final rule = holiday.calculationRule;
        if (!processedRules.contains(rule)) {
          allHolidays.add(holiday);
          processedRules.add(rule);
        }
      }

      // 处理特殊纪念日
      for (var holiday in specialDays) {
        final rule = holiday.calculationRule;
        if (!processedRules.contains(rule)) {
          allHolidays.add(holiday);
          processedRules.add(rule);
        }
      }

      // 迁移所有节日
      debugPrint('迁移所有节日...');
      await HiveDatabaseService.migrateFromSpecialDates(allHolidays);

      // 标记迁移完成
      await HiveDatabaseService.setMigrationComplete(true);
      debugPrint('节日数据迁移完成');
    } catch (e) {
      debugPrint('节日数据迁移失败: $e');
      // 迁移失败，清空数据库
      await HiveDatabaseService.clearAll();
      // 重新初始化数据库
      await HiveDatabaseService.initialize();
      // 标记迁移未完成
      await HiveDatabaseService.setMigrationComplete(false);
      // 抛出异常
      rethrow;
    }
  }

  /// 重置数据库
  static Future<void> resetDatabase() async {
    debugPrint('开始重置数据库...');
    await HiveDatabaseService.clearAll();
    await HiveDatabaseService.initialize();
    await HiveDatabaseService.setMigrationComplete(false);
    debugPrint('数据库重置完成');
  }
}
