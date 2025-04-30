import 'package:flutter/material.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/special_date.dart';

/// 节日数据管理服务
///
/// 用于管理数据库中的节日信息
class HolidayMigrationService {
  /// 检查数据迁移是否完成
  static bool isMigrationComplete() {
    return HiveDatabaseService.isMigrationComplete();
  }

  /// 重置数据库
  static Future<void> resetDatabase() async {
    debugPrint('开始重置数据库...');
    await HiveDatabaseService.clearAll();
    await HiveDatabaseService.initialize();
    await HiveDatabaseService.setMigrationComplete(false);
    debugPrint('数据库重置完成');
  }

  /// 创建示例节假日数据
  ///
  /// 创建一些示例节假日数据，用于测试
  static Future<void> createSampleHolidays(BuildContext context) async {
    debugPrint('开始创建示例节假日数据...');

    try {
      // 清空数据库
      await HiveDatabaseService.clearHolidays();

      // 创建示例节假日数据
      final List<SpecialDate> sampleHolidays = [
        // 中国法定节假日
        SpecialDate(
          id: 'CN_NewYearDay',
          name: '元旦',
          nameEn: 'New Year\'s Day',
          type: SpecialDateType.statutory,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '01-01', // MM-DD
          description: '元旦是公历新年的第一天，标志着新一年的开始。',
          descriptionEn: 'New Year\'s Day marks the beginning of the new year in the Gregorian calendar.',
        ),
        SpecialDate(
          id: 'CN_SpringFestival',
          name: '春节',
          nameEn: 'Spring Festival',
          type: SpecialDateType.statutory,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '01-01L', // LMM-LDD (农历正月初一)
          description: '春节是中国最重要的传统节日，农历正月初一，象征着新的一年开始。',
          descriptionEn: 'Spring Festival is the most important traditional holiday in China, marking the beginning of the lunar new year.',
        ),

        // 国际节日
        SpecialDate(
          id: 'INTL_ValentinesDay',
          name: '情人节',
          nameEn: 'Valentine\'s Day',
          type: SpecialDateType.traditional,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '02-14', // MM-DD
          description: '情人节是一个庆祝爱情和浪漫的节日。',
          descriptionEn: 'Valentine\'s Day is a celebration of love and romance.',
        ),
        SpecialDate(
          id: 'INTL_WorldDanceDay',
          name: '国际舞蹈日',
          nameEn: 'World Dance Day',
          type: SpecialDateType.memorial,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '04-29', // MM-DD
          description: '国际舞蹈日旨在庆祝舞蹈艺术，促进不同文化间的交流。',
          descriptionEn: 'World Dance Day celebrates the art of dance and promotes cultural exchange.',
        ),
        SpecialDate(
          id: 'INTL_LabourDay',
          name: '劳动节',
          nameEn: 'Labour Day',
          type: SpecialDateType.statutory,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '05-01', // MM-DD
          description: '劳动节是为了纪念劳动人民的贡献而设立的节日。',
          descriptionEn: 'Labour Day honors the contributions of workers and the labor movement.',
        ),
      ];

      // 迁移示例节日到数据库
      await HiveDatabaseService.migrateFromSpecialDates(sampleHolidays);
      debugPrint('成功创建 ${sampleHolidays.length} 个示例节日');

      // 标记迁移完成
      await HiveDatabaseService.setMigrationComplete(true);
      debugPrint('示例节假日数据创建完成');
    } catch (e) {
      debugPrint('创建示例节假日数据失败: $e');
      rethrow;
    }
  }

  /// 从JSON导入节假日数据
  ///
  /// 从JSON文件导入节假日数据到数据库
  static Future<void> importHolidaysFromJson(String jsonString) async {
    debugPrint('开始从JSON导入节假日数据...');

    try {
      // TODO: 实现从JSON导入节假日数据的功能
      debugPrint('从JSON导入节假日数据功能尚未实现');
    } catch (e) {
      debugPrint('从JSON导入节假日数据失败: $e');
      rethrow;
    }
  }

  /// 导出节假日数据到JSON
  ///
  /// 将数据库中的节假日数据导出为JSON格式
  static Future<String> exportHolidaysToJson() async {
    debugPrint('开始导出节假日数据到JSON...');

    try {
      // TODO: 实现导出节假日数据到JSON的功能
      debugPrint('导出节假日数据到JSON功能尚未实现');
      return '{}'; // 返回空的JSON对象
    } catch (e) {
      debugPrint('导出节假日数据到JSON失败: $e');
      rethrow;
    }
  }

  /// 迁移节日数据（兼容旧版本）
  static Future<void> migrateHolidays(BuildContext context) async {
    // 检查是否已经迁移过
    if (isMigrationComplete()) {
      return;
    }

    // 直接创建示例节假日数据
    await createSampleHolidays(context);
  }
}
