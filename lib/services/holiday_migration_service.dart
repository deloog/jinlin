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

  /// 创建默认节假日数据
  ///
  /// 创建常见的节假日数据，根据用户的语言环境自动显示
  static Future<void> createSampleHolidays(BuildContext context) async {
    debugPrint('开始创建默认节假日数据...');

    try {
      // 清空数据库
      await HiveDatabaseService.clearHolidays();

      // 创建默认节假日数据
      final List<SpecialDate> defaultHolidays = [
        // 中国法定节假日
        SpecialDate(
          id: 'CN_NewYearDay',
          name: '元旦',
          nameEn: 'New Year\'s Day',
          type: SpecialDateType.statutory,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '01-01', // MM-DD
          description: '元旦是公历新年的第一天，标志着新一年的开始。在中国，元旦是法定假日，人们通常会举行各种庆祝活动，如观看烟花表演、参加新年派对等。',
          descriptionEn: 'New Year\'s Day marks the beginning of the new year in the Gregorian calendar. In China, it\'s a public holiday when people celebrate with fireworks, parties, and family gatherings.',
          importanceLevel: ImportanceLevel.high,
        ),
        SpecialDate(
          id: 'CN_SpringFestival',
          name: '春节',
          nameEn: 'Spring Festival',
          type: SpecialDateType.statutory,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '01-01L', // LMM-LDD (农历正月初一)
          description: '春节是中国最重要的传统节日，农历正月初一，象征着新的一年开始。人们会贴春联、放鞭炮、吃团圆饭，还有舞龙舞狮等传统活动。春节期间，全国各地都会举行丰富多彩的庆祝活动。',
          descriptionEn: 'Spring Festival is the most important traditional holiday in China, marking the beginning of the lunar new year. People celebrate with family reunions, red decorations, fireworks, and traditional performances like dragon and lion dances.',
          importanceLevel: ImportanceLevel.high,
          customs: '贴春联、放鞭炮、吃团圆饭、发红包、舞龙舞狮',
          foods: '饺子、年糕、鱼、汤圆',
          taboos: '打破物品、使用负面词语、在初一洗头发、在初一打扫、借钱给他人',
        ),
        SpecialDate(
          id: 'CN_QingmingFestival',
          name: '清明节',
          nameEn: 'Qingming Festival',
          type: SpecialDateType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '04-05', // MM-DD
          description: '清明节是中国传统节日，也是重要的祭祀节日，人们会扫墓祭祖、踏青郊游。清明节也是二十四节气之一，标志着春季的到来。',
          descriptionEn: 'Qingming Festival is a traditional Chinese holiday for paying respects to ancestors by visiting their graves. It\'s also a time for spring outings as it marks the arrival of spring.',
          importanceLevel: ImportanceLevel.high,
        ),
        SpecialDate(
          id: 'CN_DragonBoatFestival',
          name: '端午节',
          nameEn: 'Dragon Boat Festival',
          type: SpecialDateType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '05-05L', // LMM-LDD (农历五月初五)
          description: '端午节是中国传统节日，农历五月初五。人们会赛龙舟、吃粽子、挂艾草，纪念爱国诗人屈原。',
          descriptionEn: 'Dragon Boat Festival is a traditional Chinese holiday celebrated on the 5th day of the 5th lunar month. People race dragon boats, eat sticky rice dumplings (zongzi), and hang mugwort to commemorate the poet Qu Yuan.',
          importanceLevel: ImportanceLevel.high,
          foods: '粽子、咸鸭蛋、雄黄酒',
        ),
        SpecialDate(
          id: 'CN_MidAutumnFestival',
          name: '中秋节',
          nameEn: 'Mid-Autumn Festival',
          type: SpecialDateType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '08-15L', // LMM-LDD (农历八月十五)
          description: '中秋节是中国传统节日，农历八月十五。这一天，人们会赏月、吃月饼、团圆聚会，象征着团圆和丰收。',
          descriptionEn: 'Mid-Autumn Festival is a traditional Chinese holiday celebrated on the 15th day of the 8th lunar month. People gather for family reunions, admire the full moon, and eat mooncakes, symbolizing reunion and harvest.',
          importanceLevel: ImportanceLevel.high,
          foods: '月饼、柚子、芋头',
        ),
        SpecialDate(
          id: 'CN_NationalDay',
          name: '国庆节',
          nameEn: 'National Day',
          type: SpecialDateType.statutory,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '10-01', // MM-DD
          description: '国庆节是中华人民共和国成立的纪念日，10月1日。这一天，全国各地都会举行庆祝活动，如升国旗、阅兵式等。',
          descriptionEn: 'National Day of China commemorates the founding of the People\'s Republic of China on October 1st. Celebrations include flag-raising ceremonies, military parades, and various festivities across the country.',
          importanceLevel: ImportanceLevel.high,
        ),

        // 国际节日
        SpecialDate(
          id: 'INTL_NewYearDay',
          name: '新年',
          nameEn: 'New Year\'s Day',
          type: SpecialDateType.statutory,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '01-01', // MM-DD
          description: '新年是公历新年的第一天，标志着新一年的开始。世界各地的人们都会举行各种庆祝活动，如烟花表演、派对等。',
          descriptionEn: 'New Year\'s Day marks the beginning of the new year in the Gregorian calendar. People worldwide celebrate with fireworks, parties, and various festivities.',
          importanceLevel: ImportanceLevel.high,
        ),
        SpecialDate(
          id: 'INTL_ValentinesDay',
          name: '情人节',
          nameEn: 'Valentine\'s Day',
          type: SpecialDateType.traditional,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '02-14', // MM-DD
          description: '情人节是一个庆祝爱情和浪漫的节日。人们通常会互赠礼物、卡片和鲜花，表达爱意。',
          descriptionEn: 'Valentine\'s Day is a celebration of love and romance. People typically exchange gifts, cards, and flowers to express their affection for one another.',
          importanceLevel: ImportanceLevel.medium,
        ),
        SpecialDate(
          id: 'INTL_EarthDay',
          name: '世界地球日',
          nameEn: 'Earth Day',
          type: SpecialDateType.memorial,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '04-22', // MM-DD
          description: '世界地球日旨在提高人们对环境保护的意识。这一天，世界各地都会举行各种环保活动，如植树、清理垃圾等。',
          descriptionEn: 'Earth Day aims to raise awareness about environmental protection. Various activities like tree planting and clean-up campaigns are organized worldwide on this day.',
          importanceLevel: ImportanceLevel.medium,
        ),
        SpecialDate(
          id: 'INTL_LabourDay',
          name: '劳动节',
          nameEn: 'Labour Day',
          type: SpecialDateType.statutory,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '05-01', // MM-DD
          description: '劳动节是为了纪念劳动人民的贡献而设立的节日。在许多国家，这一天是法定假日，人们会举行游行、集会等活动。',
          descriptionEn: 'Labour Day honors the contributions of workers and the labor movement. It\'s a public holiday in many countries, often marked by parades and rallies.',
          importanceLevel: ImportanceLevel.high,
        ),
        SpecialDate(
          id: 'INTL_ChildrensDay',
          name: '儿童节',
          nameEn: 'Children\'s Day',
          type: SpecialDateType.memorial,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '06-01', // MM-DD
          description: '儿童节是为了庆祝儿童而设立的节日。这一天，各地都会举行各种活动，如游戏、表演等，让儿童度过快乐的一天。',
          descriptionEn: 'Children\'s Day celebrates children and their rights. Various activities like games and performances are organized to bring joy to children on this day.',
          importanceLevel: ImportanceLevel.medium,
        ),
        SpecialDate(
          id: 'INTL_Christmas',
          name: '圣诞节',
          nameEn: 'Christmas',
          type: SpecialDateType.traditional,
          regions: ['INTL', 'ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '12-25', // MM-DD
          description: '圣诞节是基督教纪念耶稣诞生的节日，12月25日。这一天，人们会装饰圣诞树、互赠礼物、举行家庭聚会等。',
          descriptionEn: 'Christmas is a Christian holiday celebrating the birth of Jesus Christ on December 25th. People decorate Christmas trees, exchange gifts, and gather for family celebrations.',
          importanceLevel: ImportanceLevel.high,
          customs: '装饰圣诞树、挂袜子、互赠礼物',
          foods: '火鸡、姜饼、圣诞布丁',
        ),
      ];

      // 迁移默认节日到数据库
      await HiveDatabaseService.migrateFromSpecialDates(defaultHolidays);
      debugPrint('成功创建 ${defaultHolidays.length} 个默认节日');

      // 标记迁移完成
      await HiveDatabaseService.setMigrationComplete(true);
      debugPrint('默认节假日数据创建完成');
    } catch (e) {
      debugPrint('创建默认节假日数据失败: $e');
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
