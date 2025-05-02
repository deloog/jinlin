import 'package:jinlin_app/models/unified/holiday.dart';

/// 法国节日数据
class FranceHolidays {
  /// 获取法国节日列表
  static List<Holiday> getHolidays() {
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
  }
}
