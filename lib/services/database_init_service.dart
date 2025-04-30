// 文件： lib/services/database_init_service.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/holiday_migration_service.dart';
import 'package:jinlin_app/services/holiday_init_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据库初始化服务
///
/// 统一管理数据库的初始化、迁移和全球节日数据的初始化
class DatabaseInitService {
  // 单例模式
  static final DatabaseInitService _instance = DatabaseInitService._internal();
  
  factory DatabaseInitService() {
    return _instance;
  }
  
  DatabaseInitService._internal();
  
  // 初始化状态
  bool _isInitializing = false;
  bool _isInitialized = false;
  
  // 获取初始化状态
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  
  /// 初始化数据库和节日数据
  /// 
  /// 统一管理数据库的初始化、迁移和全球节日数据的初始化
  /// 返回初始化是否成功
  Future<bool> initialize(BuildContext? context) async {
    // 如果已经初始化或正在初始化，则直接返回
    if (_isInitialized) return true;
    if (_isInitializing) return false;
    
    _isInitializing = true;
    
    try {
      // 1. 初始化Hive数据库
      await HiveDatabaseService.initialize();
      
      // 2. 检查数据库迁移是否完成
      final migrationComplete = HiveDatabaseService.isMigrationComplete();
      
      // 3. 如果数据库迁移未完成，则执行迁移
      if (!migrationComplete && context != null) {
        await HolidayMigrationService.migrateHolidays(context);
      }
      
      // 4. 初始化全球节日数据
      final holidayInitService = HolidayInitService();
      await holidayInitService.initializeGlobalHolidays();
      
      // 5. 标记初始化完成
      _isInitialized = true;
      _isInitializing = false;
      
      // 6. 保存初始化状态
      await _saveInitializationState(true);
      
      debugPrint('数据库和节日数据初始化成功');
      return true;
    } catch (e) {
      debugPrint('数据库和节日数据初始化失败: $e');
      _isInitializing = false;
      return false;
    }
  }
  
  /// 重置数据库和节日数据
  Future<bool> reset(BuildContext context) async {
    try {
      _isInitialized = false;
      
      // 1. 重置数据库
      await HolidayMigrationService.resetDatabase();
      
      // 2. 重新初始化
      final success = await initialize(context);
      
      return success;
    } catch (e) {
      debugPrint('重置数据库和节日数据失败: $e');
      return false;
    }
  }
  
  /// 保存初始化状态
  Future<void> _saveInitializationState(bool state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_initialized', state);
    } catch (e) {
      debugPrint('保存初始化状态失败: $e');
    }
  }
  
  /// 检查是否已初始化
  Future<bool> checkInitializationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final initialized = prefs.getBool('database_initialized') ?? false;
      _isInitialized = initialized;
      return initialized;
    } catch (e) {
      debugPrint('检查初始化状态失败: $e');
      return false;
    }
  }
}
