import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';

/// 节日数据导入服务
///
/// 用于向数据库中导入各国节日数据
class HolidayDataImportService {
  final DatabaseManagerUnified _dbManager;

  HolidayDataImportService(this._dbManager);

  /// 导入法国节日数据
  Future<int> importFranceHolidays(BuildContext context) async {
    debugPrint('开始导入法国节日数据...');

    // 初始化数据库
    await _dbManager.initialize(context);

    // 法国节日列表
    final holidays = _getFranceHolidays();

    // 保存节日数据到数据库
    await _dbManager.saveHolidays(holidays);

    debugPrint('法国节日数据导入完成，共导入 ${holidays.length} 个节日');
    return holidays.length;
  }

  /// 导入德国节日数据
  Future<int> importGermanyHolidays(BuildContext context) async {
    debugPrint('开始导入德国节日数据...');

    // 初始化数据库
    await _dbManager.initialize(context);

    // 德国节日列表
    final holidays = _getGermanyHolidays();

    // 保存节日数据到数据库
    await _dbManager.saveHolidays(holidays);

    debugPrint('德国节日数据导入完成，共导入 ${holidays.length} 个节日');
    return holidays.length;
  }

  /// 获取法国节日列表
  List<Holiday> _getFranceHolidays() {
    return [
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
    ];
  }

  /// 获取德国节日列表
  List<Holiday> _getGermanyHolidays() {
    return [
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
        calculationType: DateCalculationType.variableRule,
        calculationRule: '09-3-6', // 9月第3个星期六
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
  }
}
