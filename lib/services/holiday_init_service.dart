// 文件： lib/services/holiday_init_service.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/data/global_holidays.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 节日初始化服务
///
/// 用于初始化基础节日数据
class HolidayInitService {
  // 单例模式
  static final HolidayInitService _instance = HolidayInitService._internal();
  
  factory HolidayInitService() {
    return _instance;
  }
  
  HolidayInitService._internal();
  
  /// 检查是否已初始化基础节日数据
  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('global_holidays_initialized') ?? false;
  }
  
  /// 标记为已初始化
  Future<void> _markAsInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_holidays_initialized', true);
  }
  
  /// 初始化基础节日数据
  Future<void> initializeGlobalHolidays() async {
    try {
      // 检查是否已初始化
      final initialized = await isInitialized();
      if (initialized) {
        debugPrint('全球节日数据已初始化，跳过');
        return;
      }
      
      // 获取全球节日列表
      final globalHolidays = GlobalHolidays.getGlobalHolidays();
      
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();
      
      // 保存节日数据
      int count = 0;
      for (final holiday in globalHolidays) {
        // 检查节日是否已存在
        final existingHoliday = await HiveDatabaseService.getHolidayById(holiday.id);
        if (existingHoliday == null) {
          await HiveDatabaseService.saveHoliday(holiday);
          count++;
        }
      }
      
      // 标记为已初始化
      await _markAsInitialized();
      
      debugPrint('成功初始化 $count 个全球节日');
    } catch (e) {
      debugPrint('初始化全球节日数据失败: $e');
      rethrow;
    }
  }
  
  /// 重置基础节日数据
  Future<void> resetGlobalHolidays() async {
    try {
      // 获取全球节日列表
      final globalHolidays = GlobalHolidays.getGlobalHolidays();
      
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();
      
      // 删除现有的全球节日
      for (final holiday in globalHolidays) {
        await HiveDatabaseService.deleteHoliday(holiday.id);
      }
      
      // 重新保存节日数据
      for (final holiday in globalHolidays) {
        await HiveDatabaseService.saveHoliday(holiday);
      }
      
      // 标记为已初始化
      await _markAsInitialized();
      
      debugPrint('成功重置 ${globalHolidays.length} 个全球节日');
    } catch (e) {
      debugPrint('重置全球节日数据失败: $e');
      rethrow;
    }
  }
}
