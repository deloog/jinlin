import 'package:flutter/material.dart';
import 'package:jinlin_app/database/database_helper.dart';
import 'package:jinlin_app/database/holiday_model.dart';
import 'package:jinlin_app/special_date.dart';

class HolidayService {
  static final HolidayService instance = HolidayService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  HolidayService._init();

  // 获取所有节日
  Future<List<SpecialDate>> getAllHolidays(bool isChinese) async {
    final holidays = await _dbHelper.getAllHolidays();
    return holidays.map((holiday) => holiday.toSpecialDate(isChinese)).toList();
  }

  // 根据地区获取节日
  Future<List<SpecialDate>> getHolidaysByRegion(String regionId, bool isChinese) async {
    final holidays = await _dbHelper.getHolidaysByRegion(regionId);
    return holidays.map((holiday) => holiday.toSpecialDate(isChinese)).toList();
  }

  // 更新节日重要性
  Future<void> updateHolidayImportance(String holidayId, int importanceLevel) async {
    await _dbHelper.updateHolidayImportance(holidayId, importanceLevel);
  }

  // 根据语言环境获取用户所在地区的节日
  Future<List<SpecialDate>> getHolidaysForCurrentLocale(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    final isChinese = locale.languageCode == 'zh';
    
    // 根据语言环境确定用户所在地区
    String regionId;
    if (isChinese) {
      regionId = 'CN'; // 中文用户显示中国节日
    } else if (locale.languageCode == 'en') {
      regionId = 'US'; // 英文用户显示美国节日
    } else if (locale.languageCode == 'ja') {
      regionId = 'JP'; // 日语用户显示日本节日
    } else if (locale.languageCode == 'ko') {
      regionId = 'KR'; // 韩语用户显示韩国节日
    } else {
      regionId = 'INTL'; // 其他语言用户显示国际节日
    }
    
    // 获取用户所在地区和国际性的节日
    final holidays = await _dbHelper.getHolidaysByRegion(regionId);
    final internationalHolidays = await _dbHelper.getHolidaysByRegion('INTL');
    
    // 合并地区节日和国际节日
    final allHolidays = [...holidays, ...internationalHolidays];
    
    // 转换为 SpecialDate 对象
    return allHolidays.map((holiday) => holiday.toSpecialDate(isChinese)).toList();
  }
}
