import '../special_date.dart';
import 'package:flutter/material.dart';

// 中国地区预设的特殊日期列表
List<SpecialDate> getChineseHolidays(BuildContext context) {
  return [
    // --- 法定节假日 ---
    SpecialDate(
      id: 'CN_NewYearDay',
      name: '元旦',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-01', // MM-DD
      description: '公历新年第一天',
    ),
    SpecialDate(
      id: 'CN_SpringFestival',
      name: '春节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '01-01L', // LMM-LDD (农历正月初一)
      description: '农历新年，最重要的传统节日',
    ),
    SpecialDate(
      id: 'CN_ChingMing',
      name: '清明节',
      type: SpecialDateType.statutory, // 也可算作 solarTerm
      regions: ['CN'],
      calculationType: DateCalculationType.solarTermBased, // 需要特殊计算
      calculationRule: 'QingMing', // 规则待定，可能需要查表或专用库
      description: '祭祖扫墓，踏青插柳',
    ),
    SpecialDate(
      id: 'CN_LabourDay',
      name: '劳动节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-01', // MM-DD
      description: '国际劳动节',
    ),
    SpecialDate(
      id: 'CN_DragonBoatFestival',
      name: '端午节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '05-05L', // LMM-LDD
      description: '纪念屈原，赛龙舟、吃粽子',
    ),
    SpecialDate(
      id: 'CN_MidAutumnFestival',
      name: '中秋节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '08-15L', // LMM-LDD
      description: '团圆赏月，吃月饼',
    ),
    SpecialDate(
      id: 'CN_NationalDay',
      name: '国庆节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-01', // MM-DD
      description: '庆祝中华人民共和国成立',
    ),

    // --- 传统节日 (示例) ---
    SpecialDate(
      id: 'CN_LanternFestival',
      name: '元宵节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '01-15L', // LMM-LDD
      description: '赏花灯、吃元宵/汤圆',
    ),
    SpecialDate(
      id: 'CN_DoubleSeventhFestival',
      name: '七夕节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '07-07L', // LMM-LDD
      description: '中国情人节，乞巧',
    ),
    SpecialDate(
      id: 'CN_DoubleNinthFestival',
      name: '重阳节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '09-09L', // LMM-LDD
      description: '登高赏秋，敬老',
    ),
    SpecialDate(
      id: 'CN_LabaFestival',
      name: '腊八节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '12-08L', // LMM-LDD (农历腊月初八)
      description: '喝腊八粥，佛教传统节日，也是春节前的重要节气',
    ),

    // --- 纪念日 (示例) ---
    SpecialDate(
      id: 'CN_TreePlantingDay',
      name: '植树节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-12', // MM-DD
      description: '鼓励植树造林',
    ),
    SpecialDate(
      id: 'CN_MothersDay',
      name: '母亲节',
      type: SpecialDateType.memorial, // 国际节日
      regions: ['CN', 'US', 'ALL'], // 可能适用多个地区
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '5,2,0', // 5月第2个周日 (0=周日)
      description: '感谢母亲',
    ),
    SpecialDate(
      id: 'CN_FathersDay',
      name: '父亲节',
      type: SpecialDateType.memorial, // 国际节日
      regions: ['CN', 'US', 'ALL'], // 可能适用多个地区
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '6,3,0', // 6月第3个周日 (0=周日)
      description: '感谢父亲',
    ),
  ];
}

// 根据地区获取节日列表
List<SpecialDate> getHolidaysForRegion(BuildContext context, String regionCode) {
  final holidays = getChineseHolidays(context);
  return holidays.where((h) => h.regions.contains(regionCode) || h.regions.contains('ALL')).toList();
}