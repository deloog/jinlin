import '../special_date.dart';
import 'package:flutter/material.dart';

// 国际节日和西方传统节日列表
List<SpecialDate> getInternationalHolidays(BuildContext context) {
  return [
    // --- 国际性节日 ---
    SpecialDate(
      id: 'INTL_NewYearDay',
      name: 'New Year\'s Day',
      type: SpecialDateType.statutory,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-01', // MM-DD
      description: 'The first day of the year in the Gregorian calendar',
    ),
    SpecialDate(
      id: 'INTL_ValentinesDay',
      name: 'Valentine\'s Day',
      type: SpecialDateType.traditional,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '02-14', // MM-DD
      description: 'A day celebrating love and affection',
    ),
    SpecialDate(
      id: 'INTL_EarthDay',
      name: 'Earth Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-22', // MM-DD
      description: 'A day to demonstrate support for environmental protection',
    ),
    SpecialDate(
      id: 'INTL_LabourDay',
      name: 'Labour Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-01', // MM-DD
      description: 'A celebration of laborers and the working classes',
    ),
    SpecialDate(
      id: 'INTL_ChildrensDay',
      name: 'Children\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-01', // MM-DD
      description: 'A day to honor children',
    ),
    SpecialDate(
      id: 'INTL_WorldEnvironmentDay',
      name: 'World Environment Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-05', // MM-DD
      description: 'A day for encouraging awareness and action for the environment',
    ),
    SpecialDate(
      id: 'INTL_UNDay',
      name: 'United Nations Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-24', // MM-DD
      description: 'Anniversary of the UN Charter coming into force',
    ),
    SpecialDate(
      id: 'INTL_HumanRightsDay',
      name: 'Human Rights Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-10', // MM-DD
      description: 'Anniversary of the Universal Declaration of Human Rights',
    ),

    // --- 西方传统节日 ---
    SpecialDate(
      id: 'WEST_Easter',
      name: 'Easter',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '4,1,0', // 复活节计算比较复杂，这里简化为4月第一个周日
      description: 'Christian festival celebrating the resurrection of Jesus',
    ),
    SpecialDate(
      id: 'WEST_GoodFriday',
      name: 'Good Friday',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.relativeTo,
      calculationRule: 'WEST_Easter,-2', // 复活节前两天
      description: 'Christian observance commemorating the crucifixion of Jesus',
    ),
    SpecialDate(
      id: 'WEST_StPatricksDay',
      name: 'St. Patrick\'s Day',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'IE', 'US'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-17', // MM-DD
      description: 'Cultural and religious celebration held on 17 March',
    ),
    SpecialDate(
      id: 'WEST_Halloween',
      name: 'Halloween',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-31', // MM-DD
      description: 'A celebration observed on the eve of the Western Christian feast of All Hallows\' Day',
    ),
    SpecialDate(
      id: 'WEST_Thanksgiving',
      name: 'Thanksgiving',
      type: SpecialDateType.traditional,
      regions: ['US', 'WEST'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '11,4,4', // 11月第4个周四
      description: 'A national holiday celebrated in the United States',
    ),
    SpecialDate(
      id: 'WEST_Christmas',
      name: 'Christmas',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-25', // MM-DD
      description: 'Christian festival celebrating the birth of Jesus',
    ),
    SpecialDate(
      id: 'WEST_NewYearsEve',
      name: 'New Year\'s Eve',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-31', // MM-DD
      description: 'The last day of the year in the Gregorian calendar',
    ),

    // --- 家庭相关节日 ---
    SpecialDate(
      id: 'INTL_MothersDay',
      name: 'Mother\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '5,2,0', // 5月第2个周日
      description: 'A celebration honoring mothers',
    ),
    SpecialDate(
      id: 'INTL_FathersDay',
      name: 'Father\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '6,3,0', // 6月第3个周日
      description: 'A celebration honoring fathers',
    ),

    // --- 国际纪念日 ---
    SpecialDate(
      id: 'INTL_WorldHealthDay',
      name: 'World Health Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-07', // MM-DD
      description: 'A global health awareness day celebrated every year on April 7',
    ),
    SpecialDate(
      id: 'INTL_WorldOceansDay',
      name: 'World Oceans Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-08', // MM-DD
      description: 'A day to celebrate the ocean and take action to protect it',
    ),
    SpecialDate(
      id: 'INTL_InternationalPeaceDay',
      name: 'International Day of Peace',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-21', // MM-DD
      description: 'A day devoted to strengthening the ideals of peace',
    ),
    SpecialDate(
      id: 'INTL_WorldTeachersDay',
      name: 'World Teachers\' Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-05', // MM-DD
      description: 'A day celebrating teachers around the world',
    ),
  ];
}

// 根据地区获取节日列表
List<SpecialDate> getHolidaysForRegion(BuildContext context, String regionCode) {
  final holidays = getInternationalHolidays(context);
  return holidays.where((h) =>
    h.regions.contains(regionCode) ||
    h.regions.contains('ALL') ||
    (regionCode == 'INTL' && h.regions.contains('WEST'))
  ).toList();
}
