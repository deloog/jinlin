import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';

/// 节日数据导入工具
///
/// 用于向数据库中导入各国节日数据
class HolidayDataImporter {
  final DatabaseManagerUnified _dbManager;

  HolidayDataImporter(this._dbManager);

  /// 导入法国节日数据
  Future<void> importFranceHolidays(BuildContext context) async {
    debugPrint('开始导入法国节日数据...');
    
    // 初始化数据库
    await _dbManager.initialize(context);
    
    // 法国节日列表
    final holidays = [
      // 法国国庆日（巴士底日）
      Holiday(
        id: 'fr_bastille_day',
        isSystemHoliday: true,
        names: {
          'zh': '法国国庆日',
          'en': 'Bastille Day',
          'fr': 'Fête nationale française',
          'de': 'Französischer Nationalfeiertag',
        },
        type: HolidayType.statutory,
        regions: ['FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '07-14',
        descriptions: {
          'zh': '法国国庆日纪念1789年巴士底狱的攻陷，象征着法国大革命的开始和法兰西共和国的诞生。',
          'en': 'Bastille Day commemorates the Storming of the Bastille in 1789, which marked the beginning of the French Revolution and the birth of the French Republic.',
          'fr': 'La Fête nationale française commémore la prise de la Bastille en 1789, qui marque le début de la Révolution française et la naissance de la République française.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '阅兵、烟花表演、舞会',
          'en': 'Military parade, fireworks, public dances',
          'fr': 'Défilé militaire, feux d\'artifice, bals populaires',
        },
        userImportance: 2,
      ),

      // 劳动节
      Holiday(
        id: 'fr_labor_day',
        isSystemHoliday: true,
        names: {
          'zh': '法国劳动节',
          'en': 'Labor Day',
          'fr': 'Fête du Travail',
          'de': 'Tag der Arbeit',
        },
        type: HolidayType.statutory,
        regions: ['FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '05-01',
        descriptions: {
          'zh': '法国劳动节是法定假日，人们通常会赠送铃兰花，象征幸福和好运。',
          'en': 'Labor Day in France is a public holiday where people traditionally give lily of the valley flowers as a symbol of good luck and happiness.',
          'fr': 'La Fête du Travail en France est un jour férié où l\'on offre traditionnellement du muguet comme symbole de bonheur et de porte-bonheur.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '赠送铃兰花、工会游行',
          'en': 'Giving lily of the valley flowers, trade union demonstrations',
          'fr': 'Offrir du muguet, manifestations syndicales',
        },
        userImportance: 2,
      ),

      // 胜利日
      Holiday(
        id: 'fr_victory_day',
        isSystemHoliday: true,
        names: {
          'zh': '胜利日',
          'en': 'Victory in Europe Day',
          'fr': 'Jour de la Victoire',
          'de': 'Tag des Sieges',
        },
        type: HolidayType.memorial,
        regions: ['FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '05-08',
        descriptions: {
          'zh': '胜利日纪念1945年5月8日纳粹德国在第二次世界大战中向盟军投降。',
          'en': 'Victory in Europe Day commemorates the formal acceptance by the Allies of Nazi Germany\'s unconditional surrender on May 8, 1945.',
          'fr': 'Le Jour de la Victoire commémore l\'acceptation formelle par les Alliés de la capitulation sans condition de l\'Allemagne nazie le 8 mai 1945.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '纪念仪式、向阵亡将士致敬',
          'en': 'Commemorative ceremonies, honoring fallen soldiers',
          'fr': 'Cérémonies commémoratives, hommage aux soldats tombés',
        },
        userImportance: 2,
      ),

      // 圣母升天节
      Holiday(
        id: 'fr_assumption_day',
        isSystemHoliday: true,
        names: {
          'zh': '圣母升天节',
          'en': 'Assumption Day',
          'fr': 'Assomption',
          'de': 'Mariä Himmelfahrt',
        },
        type: HolidayType.religious,
        regions: ['FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '08-15',
        descriptions: {
          'zh': '圣母升天节是天主教重要节日，纪念圣母玛利亚升天。在法国，这是一个法定假日。',
          'en': 'Assumption Day is a significant Catholic feast day commemorating the assumption of Mary into Heaven. It is a public holiday in France.',
          'fr': 'L\'Assomption est une fête catholique importante commémorant l\'assomption de Marie au ciel. C\'est un jour férié en France.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '教堂弥撒、宗教游行',
          'en': 'Church masses, religious processions',
          'fr': 'Messes à l\'église, processions religieuses',
        },
        userImportance: 1,
      ),

      // 诸圣节
      Holiday(
        id: 'fr_all_saints_day',
        isSystemHoliday: true,
        names: {
          'zh': '诸圣节',
          'en': 'All Saints\' Day',
          'fr': 'Toussaint',
          'de': 'Allerheiligen',
        },
        type: HolidayType.religious,
        regions: ['FR'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '11-01',
        descriptions: {
          'zh': '诸圣节是天主教节日，纪念所有圣人。在法国，人们通常会在这一天前往墓地悼念逝去的亲人。',
          'en': 'All Saints\' Day is a Catholic holiday honoring all saints. In France, people typically visit cemeteries to pay respects to deceased family members.',
          'fr': 'La Toussaint est une fête catholique honorant tous les saints. En France, les gens visitent généralement les cimetières pour rendre hommage aux membres décédés de leur famille.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '扫墓、献花、点蜡烛',
          'en': 'Visiting graves, laying flowers, lighting candles',
          'fr': 'Visite des tombes, dépôt de fleurs, allumage de bougies',
        },
        userImportance: 1,
      ),
    ];
    
    // 保存节日数据到数据库
    await _dbManager.saveHolidays(holidays);
    
    debugPrint('法国节日数据导入完成，共导入 ${holidays.length} 个节日');
  }

  /// 导入德国节日数据
  Future<void> importGermanyHolidays(BuildContext context) async {
    debugPrint('开始导入德国节日数据...');
    
    // 初始化数据库
    await _dbManager.initialize(context);
    
    // 德国节日列表
    final holidays = [
      // 德国统一日
      Holiday(
        id: 'de_unity_day',
        isSystemHoliday: true,
        names: {
          'zh': '德国统一日',
          'en': 'German Unity Day',
          'de': 'Tag der Deutschen Einheit',
          'fr': 'Jour de l\'Unité allemande',
        },
        type: HolidayType.statutory,
        regions: ['DE'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '10-03',
        descriptions: {
          'zh': '德国统一日纪念1990年东德和西德重新统一，是德国的国庆节。',
          'en': 'German Unity Day commemorates the reunification of East and West Germany in 1990. It is the national day of Germany.',
          'de': 'Der Tag der Deutschen Einheit erinnert an die Wiedervereinigung von Ost- und Westdeutschland im Jahr 1990. Es ist der Nationalfeiertag Deutschlands.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '官方庆典、音乐会、游行',
          'en': 'Official celebrations, concerts, parades',
          'de': 'Offizielle Feierlichkeiten, Konzerte, Paraden',
        },
        userImportance: 2,
      ),

      // 复活节
      Holiday(
        id: 'de_easter',
        isSystemHoliday: true,
        names: {
          'zh': '复活节',
          'en': 'Easter',
          'de': 'Ostern',
          'fr': 'Pâques',
        },
        type: HolidayType.religious,
        regions: ['DE'],
        calculationType: DateCalculationType.custom,
        calculationRule: 'easter',
        descriptions: {
          'zh': '复活节是基督教最重要的节日之一，纪念耶稣基督的复活。在德国，复活节有许多传统习俗，如装饰彩蛋和复活节兔子。',
          'en': 'Easter is one of the most important Christian holidays, commemorating the resurrection of Jesus Christ. In Germany, Easter has many traditional customs such as decorating eggs and the Easter Bunny.',
          'de': 'Ostern ist eines der wichtigsten christlichen Feste und erinnert an die Auferstehung Jesu Christi. In Deutschland gibt es viele traditionelle Osterbräuche wie das Bemalen von Eiern und den Osterhasen.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '装饰彩蛋、复活节兔子、复活节篝火',
          'en': 'Decorating eggs, Easter Bunny, Easter bonfires',
          'de': 'Eier bemalen, Osterhase, Osterfeuer',
        },
        foods: {
          'zh': '复活节面包、巧克力彩蛋',
          'en': 'Easter bread, chocolate eggs',
          'de': 'Osterbrot, Schokoladeneier',
        },
        userImportance: 2,
      ),

      // 圣诞市场
      Holiday(
        id: 'de_christmas_market',
        isSystemHoliday: true,
        names: {
          'zh': '德国圣诞市场',
          'en': 'German Christmas Market',
          'de': 'Weihnachtsmarkt',
          'fr': 'Marché de Noël allemand',
        },
        type: HolidayType.cultural,
        regions: ['DE'],
        calculationType: DateCalculationType.custom,
        calculationRule: 'advent',
        descriptions: {
          'zh': '德国圣诞市场是德国传统的户外圣诞集市，通常从11月底的降临节开始，一直持续到圣诞节。市场上有各种手工艺品、食物和热红酒。',
          'en': 'German Christmas Markets are traditional outdoor Christmas fairs that usually start from Advent in late November and last until Christmas. The markets offer various handicrafts, food, and mulled wine.',
          'de': 'Weihnachtsmärkte sind traditionelle Freiluftmärkte in Deutschland, die in der Regel vom Advent Ende November bis Weihnachten dauern. Auf den Märkten werden verschiedene Handwerkskunst, Speisen und Glühwein angeboten.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '喝热红酒、购买手工艺品、欣赏圣诞装饰',
          'en': 'Drinking mulled wine, buying handicrafts, enjoying Christmas decorations',
          'de': 'Glühwein trinken, Handwerkskunst kaufen, Weihnachtsdekorationen genießen',
        },
        foods: {
          'zh': '热红酒、烤香肠、姜饼',
          'en': 'Mulled wine, grilled sausages, gingerbread',
          'de': 'Glühwein, Bratwurst, Lebkuchen',
        },
        userImportance: 1,
      ),

      // 啤酒节
      Holiday(
        id: 'de_oktoberfest',
        isSystemHoliday: true,
        names: {
          'zh': '慕尼黑啤酒节',
          'en': 'Oktoberfest',
          'de': 'Oktoberfest',
          'fr': 'Oktoberfest',
        },
        type: HolidayType.cultural,
        regions: ['DE'],
        calculationType: DateCalculationType.custom,
        calculationRule: 'september-third-saturday',
        descriptions: {
          'zh': '慕尼黑啤酒节是世界上最大的民间节日，每年在德国慕尼黑举行，为期16天，通常从9月中旬持续到10月初。',
          'en': 'Oktoberfest is the world\'s largest folk festival, held annually in Munich, Germany. It lasts for 16 days, usually from mid-September to early October.',
          'de': 'Das Oktoberfest ist das größte Volksfest der Welt und findet jährlich in München statt. Es dauert 16 Tage, in der Regel von Mitte September bis Anfang Oktober.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '穿传统服装、喝啤酒、听民间音乐',
          'en': 'Wearing traditional costumes, drinking beer, listening to folk music',
          'de': 'Tragen traditioneller Trachten, Biertrinken, Volksmusik hören',
        },
        foods: {
          'zh': '啤酒、烤鸡、椒盐脆饼',
          'en': 'Beer, roast chicken, pretzels',
          'de': 'Bier, Brathähnchen, Brezeln',
        },
        userImportance: 2,
      ),
    ];
    
    // 保存节日数据到数据库
    await _dbManager.saveHolidays(holidays);
    
    debugPrint('德国节日数据导入完成，共导入 ${holidays.length} 个节日');
  }

  /// 导入英国节日数据
  Future<void> importUKHolidays(BuildContext context) async {
    debugPrint('开始导入英国节日数据...');
    
    // 初始化数据库
    await _dbManager.initialize(context);
    
    // 英国节日列表
    final holidays = [
      // 女王/国王官方生日
      Holiday(
        id: 'uk_royal_birthday',
        isSystemHoliday: true,
        names: {
          'zh': '英国君主官方生日',
          'en': 'Sovereign\'s Official Birthday',
          'fr': 'Anniversaire officiel du souverain britannique',
          'de': 'Offizieller Geburtstag des britischen Monarchen',
        },
        type: HolidayType.statutory,
        regions: ['GB'],
        calculationType: DateCalculationType.custom,
        calculationRule: 'june-second-saturday',
        descriptions: {
          'zh': '英国君主官方生日是英国的公共假日，通常在6月的第二个星期六庆祝，不论现任君主的实际生日是哪一天。',
          'en': 'The Sovereign\'s Official Birthday is a public holiday in the UK, usually celebrated on the second Saturday in June, regardless of the actual birthday of the reigning monarch.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '阅兵仪式、军旗分列式',
          'en': 'Trooping the Colour ceremony, military parade',
        },
        userImportance: 2,
      ),

      // 篝火之夜
      Holiday(
        id: 'uk_bonfire_night',
        isSystemHoliday: true,
        names: {
          'zh': '篝火之夜',
          'en': 'Bonfire Night',
          'fr': 'Nuit de Guy Fawkes',
          'de': 'Guy Fawkes Night',
        },
        type: HolidayType.cultural,
        regions: ['GB'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '11-05',
        descriptions: {
          'zh': '篝火之夜，也称为盖伊·福克斯之夜，纪念1605年"火药阴谋"的失败，当时盖伊·福克斯试图炸毁英国议会大厦。',
          'en': 'Bonfire Night, also known as Guy Fawkes Night, commemorates the failure of the Gunpowder Plot of 1605, when Guy Fawkes attempted to blow up the Houses of Parliament.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '点篝火、放烟花、烧盖伊·福克斯模型',
          'en': 'Lighting bonfires, fireworks displays, burning effigies of Guy Fawkes',
        },
        foods: {
          'zh': '烤土豆、焦糖苹果、篝火蛋糕',
          'en': 'Baked potatoes, toffee apples, parkin cake',
        },
        userImportance: 1,
      ),

      // 银行假日
      Holiday(
        id: 'uk_spring_bank_holiday',
        isSystemHoliday: true,
        names: {
          'zh': '春季银行假日',
          'en': 'Spring Bank Holiday',
          'fr': 'Jour férié bancaire de printemps',
          'de': 'Bankfeiertag im Frühling',
        },
        type: HolidayType.statutory,
        regions: ['GB'],
        calculationType: DateCalculationType.variableRule,
        calculationRule: '05-5-1', // 5月最后一个星期一
        descriptions: {
          'zh': '春季银行假日是英国的公共假日，在5月的最后一个星期一。这一天大多数企业和学校都会休息。',
          'en': 'The Spring Bank Holiday is a public holiday in the UK on the last Monday of May. Most businesses and schools are closed on this day.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '户外活动、家庭聚会、短途旅行',
          'en': 'Outdoor activities, family gatherings, short trips',
        },
        userImportance: 1,
      ),

      // 夏至
      Holiday(
        id: 'uk_summer_solstice',
        isSystemHoliday: true,
        names: {
          'zh': '夏至',
          'en': 'Summer Solstice',
          'fr': 'Solstice d\'été',
          'de': 'Sommersonnenwende',
        },
        type: HolidayType.cultural,
        regions: ['GB'],
        calculationType: DateCalculationType.custom,
        calculationRule: 'summer-solstice',
        descriptions: {
          'zh': '夏至是一年中白昼最长的一天，在英国尤其是在巨石阵，人们会聚集在一起庆祝这一天。',
          'en': 'The Summer Solstice is the longest day of the year. In the UK, especially at Stonehenge, people gather to celebrate this day.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '在巨石阵观看日出、举行庆祝活动',
          'en': 'Watching the sunrise at Stonehenge, holding celebrations',
        },
        userImportance: 1,
      ),
    ];
    
    // 保存节日数据到数据库
    await _dbManager.saveHolidays(holidays);
    
    debugPrint('英国节日数据导入完成，共导入 ${holidays.length} 个节日');
  }
}
