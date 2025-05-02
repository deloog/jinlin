import 'package:flutter/material.dart';
import 'package:jinlin_app/database/database_helper.dart';
import 'package:jinlin_app/database/holiday_model.dart';
import 'package:jinlin_app/database/region_model.dart';
import 'package:jinlin_app/database/holiday_type_model.dart';
import 'package:jinlin_app/data/special_days.dart' as special_days;
import 'package:shared_preferences/shared_preferences.dart';

class HolidayMigrationService {
  static const String _migrationCompleteKey = 'holiday_migration_complete';

  // 检查是否已经完成迁移
  static Future<bool> isMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationCompleteKey) ?? false;
  }

  // 标记迁移已完成
  static Future<void> markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationCompleteKey, true);
  }

  // 执行迁移
  static Future<void> migrateHolidays([dynamic context]) async {
    // 获取硬编码的节日数据
    final specialDays = special_days.getDefaultSpecialDays();

    // 检查是否已经完成迁移
    final migrationComplete = await isMigrationComplete();
    if (migrationComplete) {
      debugPrint('节日数据迁移已完成，跳过迁移过程');
      return;
    }

    debugPrint('开始节日数据迁移...');

    // 获取数据库实例
    final dbHelper = DatabaseHelper.instance;

    // 1. 迁移地区数据
    await _migrateRegions(dbHelper);

    // 2. 迁移节日类型数据
    await _migrateHolidayTypes(dbHelper);

    // 3. 迁移节日数据
    await _migrateHolidayData(dbHelper, specialDays);

    // 标记迁移已完成
    await markMigrationComplete();

    debugPrint('节日数据迁移完成');
  }

  // 迁移地区数据
  static Future<void> _migrateRegions(DatabaseHelper dbHelper) async {
    debugPrint('迁移地区数据...');

    // 预定义的地区列表
    final regions = [
      Region(id: 'ALL', name: 'All Regions', nameZh: '所有地区', nameEn: 'All Regions'),
      Region(id: 'INTL', name: 'International', nameZh: '国际', nameEn: 'International'),
      Region(id: 'CN', name: 'China', nameZh: '中国', nameEn: 'China'),
      Region(id: 'US', name: 'United States', nameZh: '美国', nameEn: 'United States'),
      Region(id: 'UK', name: 'United Kingdom', nameZh: '英国', nameEn: 'United Kingdom'),
      Region(id: 'JP', name: 'Japan', nameZh: '日本', nameEn: 'Japan'),
      Region(id: 'KR', name: 'South Korea', nameZh: '韩国', nameEn: 'South Korea'),
      Region(id: 'IN', name: 'India', nameZh: '印度', nameEn: 'India'),
      Region(id: 'FR', name: 'France', nameZh: '法国', nameEn: 'France'),
      Region(id: 'DE', name: 'Germany', nameZh: '德国', nameEn: 'Germany'),
      Region(id: 'IT', name: 'Italy', nameZh: '意大利', nameEn: 'Italy'),
      Region(id: 'ES', name: 'Spain', nameZh: '西班牙', nameEn: 'Spain'),
      Region(id: 'CA', name: 'Canada', nameZh: '加拿大', nameEn: 'Canada'),
      Region(id: 'AU', name: 'Australia', nameZh: '澳大利亚', nameEn: 'Australia'),
      Region(id: 'NZ', name: 'New Zealand', nameZh: '新西兰', nameEn: 'New Zealand'),
    ];

    // 插入地区数据
    for (final region in regions) {
      await dbHelper.insertRegion(region);
    }

    debugPrint('地区数据迁移完成');
  }

  // 迁移节日类型数据
  static Future<void> _migrateHolidayTypes(DatabaseHelper dbHelper) async {
    debugPrint('迁移节日类型数据...');

    // 预定义的节日类型列表
    final holidayTypes = [
      HolidayType(
        id: 'statutory',
        name: 'Statutory Holiday',
        nameZh: '法定节日',
        nameEn: 'Statutory Holiday',
        iconCode: Icons.calendar_today.codePoint,
      ),
      HolidayType(
        id: 'traditional',
        name: 'Traditional Holiday',
        nameZh: '传统节日',
        nameEn: 'Traditional Holiday',
        iconCode: Icons.celebration.codePoint,
      ),
      HolidayType(
        id: 'memorial',
        name: 'Memorial Day',
        nameZh: '纪念日',
        nameEn: 'Memorial Day',
        iconCode: Icons.emoji_events.codePoint,
      ),
      HolidayType(
        id: 'solarTerm',
        name: 'Solar Term',
        nameZh: '节气',
        nameEn: 'Solar Term',
        iconCode: Icons.wb_sunny.codePoint,
      ),
    ];

    // 插入节日类型数据
    for (final type in holidayTypes) {
      await dbHelper.insertHolidayType(type);
    }

    debugPrint('节日类型数据迁移完成');
  }

  // 迁移节日数据
  static Future<void> _migrateHolidayData(DatabaseHelper dbHelper, List<dynamic> specialDays) async {
    debugPrint('迁移节日数据...');

    // 转换并插入节日数据
    for (final specialDay in specialDays) {
      final holiday = Holiday.fromSpecialDate(specialDay);
      await dbHelper.insertHoliday(holiday);
    }

    debugPrint('节日数据迁移完成');
  }
}
