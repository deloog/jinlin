// 文件： lib/data/global_holidays.dart
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:uuid/uuid.dart';

/// 全球重要节日数据
///
/// 包含10个全球性重要节日，这些节日在大多数国家/地区都有庆祝或认可
class GlobalHolidays {
  static final Uuid _uuid = Uuid();
  
  /// 获取全球重要节日列表
  static List<HolidayModel> getGlobalHolidays() {
    return [
      // 1. 新年 (全球性)
      HolidayModel(
        id: 'global_new_year',
        name: '新年',
        type: HolidayType.statutory,
        regions: ['INTL', 'CN', 'US', 'JP', 'KR', 'FR', 'DE'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '01-01',
        description: '新年是世界各地普遍庆祝的节日，标志着新一年的开始。人们通常会举行各种庆祝活动，如烟花表演、家庭聚会等。',
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
        nameEn: "New Year's Day",
        descriptionEn: "New Year's Day is a global holiday celebrating the beginning of a new calendar year. People typically celebrate with fireworks, parties, and family gatherings.",
      ),
      
      // 2. 情人节 (全球性)
      HolidayModel(
        id: 'global_valentines_day',
        name: '情人节',
        type: HolidayType.traditional,
        regions: ['INTL', 'US', 'UK', 'FR', 'DE'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '02-14',
        description: '情人节是恋人之间互表爱意的节日，通常会赠送鲜花、巧克力和贺卡。',
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
        nameEn: "Valentine's Day",
        descriptionEn: "Valentine's Day is a holiday when lovers express their affection with greetings and gifts. It is celebrated in many countries around the world.",
      ),
      
      // 3. 国际妇女节 (全球性)
      HolidayModel(
        id: 'global_womens_day',
        name: '国际妇女节',
        type: HolidayType.international,
        regions: ['INTL', 'CN', 'RU', 'DE', 'FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '03-08',
        description: '国际妇女节是纪念妇女权利和世界和平的节日，在许多国家被定为法定假日。',
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
        nameEn: "International Women's Day",
        descriptionEn: "International Women's Day is a global day celebrating the social, economic, cultural, and political achievements of women.",
      ),
      
      // 4. 地球日 (全球性)
      HolidayModel(
        id: 'global_earth_day',
        name: '世界地球日',
        type: HolidayType.international,
        regions: ['INTL'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '04-22',
        description: '世界地球日旨在提高人们对环境保护的意识，鼓励人们采取行动保护地球环境。',
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
        nameEn: "Earth Day",
        descriptionEn: "Earth Day is an annual event celebrated around the world to demonstrate support for environmental protection.",
      ),
      
      // 5. 国际劳动节 (全球性)
      HolidayModel(
        id: 'global_labor_day',
        name: '国际劳动节',
        type: HolidayType.statutory,
        regions: ['INTL', 'CN', 'FR', 'DE', 'RU'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '05-01',
        description: '国际劳动节是世界上许多国家的法定假日，旨在庆祝工人阶级的贡献和成就。',
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
        nameEn: "International Labor Day",
        descriptionEn: "International Labor Day, also known as May Day, is a celebration of laborers and the working classes.",
      ),
      
      // 6. 国际儿童节 (全球性)
      HolidayModel(
        id: 'global_childrens_day',
        name: '国际儿童节',
        type: HolidayType.international,
        regions: ['INTL', 'CN', 'RU'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '06-01',
        description: '国际儿童节旨在促进儿童之间的相互了解和友谊，并促进儿童的福利。',
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
        nameEn: "International Children's Day",
        descriptionEn: "International Children's Day is a day to promote mutual understanding among children and to promote children's welfare worldwide.",
      ),
      
      // 7. 中秋节 (亚洲地区)
      HolidayModel(
        id: 'asia_mid_autumn',
        name: '中秋节',
        type: HolidayType.traditional,
        regions: ['CN', 'TW', 'HK', 'SG', 'MY', 'JP', 'KR'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: '08-15L',
        description: '中秋节是东亚地区的传统节日，人们会赏月、吃月饼，象征着团圆和丰收。',
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
        nameEn: "Mid-Autumn Festival",
        descriptionEn: "The Mid-Autumn Festival is a traditional festival celebrated in East Asian countries. People gather for family reunions, eat mooncakes, and appreciate the full moon.",
      ),
      
      // 8. 万圣节 (西方国家)
      HolidayModel(
        id: 'western_halloween',
        name: '万圣节',
        type: HolidayType.traditional,
        regions: ['US', 'UK', 'CA', 'AU', 'FR', 'DE'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '10-31',
        description: '万圣节起源于古凯尔特人的传统，现在主要在西方国家庆祝，人们会装扮成各种角色，孩子们会挨家挨户要糖果。',
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
        nameEn: "Halloween",
        descriptionEn: "Halloween is a celebration observed in many Western countries, where people dress up in costumes, carve pumpkins, and children go trick-or-treating.",
      ),
      
      // 9. 感恩节 (美国)
      HolidayModel(
        id: 'us_thanksgiving',
        name: '感恩节',
        type: HolidayType.statutory,
        regions: ['US', 'CA'],
        calculationType: DateCalculationType.nthWeekdayOfMonth,
        calculationRule: '11,4,4', // 11月第4个星期四
        description: '感恩节是美国和加拿大的重要节日，人们会与家人团聚，享用火鸡大餐，表达对生活的感恩之情。',
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
        nameEn: "Thanksgiving",
        descriptionEn: "Thanksgiving is a national holiday celebrated in the United States and Canada, where people gather with family for a traditional turkey dinner and express gratitude.",
      ),
      
      // 10. 圣诞节 (全球性)
      HolidayModel(
        id: 'global_christmas',
        name: '圣诞节',
        type: HolidayType.statutory,
        regions: ['INTL', 'US', 'UK', 'CA', 'AU', 'FR', 'DE'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '12-25',
        description: '圣诞节是基督教纪念耶稣诞生的节日，现已成为全球性的文化节日，人们会交换礼物、装饰圣诞树，与家人团聚。',
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
        nameEn: "Christmas",
        descriptionEn: "Christmas is an annual festival commemorating the birth of Jesus Christ. It is widely celebrated around the world, both as a religious and cultural event.",
      ),
    ];
  }
  
  /// 生成随机ID
  static String _generateId() {
    return _uuid.v4();
  }
}
