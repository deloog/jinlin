// 文件： lib/services/database_init_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/holiday_migration_service.dart';
import 'package:jinlin_app/services/holiday_data_loader_service.dart';
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
  Future<bool> initialize([BuildContext? context]) async {
    // 如果已经初始化或正在初始化，则直接返回
    if (_isInitialized) return true;
    if (_isInitializing) return false;

    _isInitializing = true;

    try {
      // 1. 初始化Hive数据库
      try {
        await HiveDatabaseService.initialize();
        debugPrint('Hive数据库初始化成功');
      } catch (e) {
        debugPrint('Hive数据库初始化失败: $e');
        // 继续执行，不要因为Hive初始化失败而中断整个流程
      }

      // 2. 检查数据库迁移是否完成
      bool migrationComplete = false;
      try {
        migrationComplete = HiveDatabaseService.isMigrationComplete();
        debugPrint('数据库迁移状态检查成功: $migrationComplete');
      } catch (e) {
        debugPrint('数据库迁移状态检查失败: $e');
        // 继续执行，假设迁移未完成
      }

      // 3. 如果数据库迁移未完成，则执行迁移
      if (!migrationComplete) {
        try {
          // 执行迁移，不依赖于BuildContext
          await HolidayMigrationService.migrateHolidays();
          debugPrint('节日数据迁移成功');
        } catch (e) {
          debugPrint('节日数据迁移失败: $e');
          // 继续执行，不要因为迁移失败而中断整个流程
        }
      }

      // 4. 初始化全球节日数据
      try {
        final holidayDataLoader = HolidayDataLoaderService();
        await holidayDataLoader.initializeBasicData();
        debugPrint('全球节日数据初始化成功');
      } catch (e) {
        debugPrint('全球节日数据初始化失败: $e');
        // 继续执行，不要因为节日数据初始化失败而中断整个流程
      }

      // 5. 标记初始化完成
      _isInitialized = true;
      _isInitializing = false;

      // 6. 保存初始化状态
      try {
        await _saveInitializationState(true);
      } catch (e) {
        debugPrint('保存初始化状态失败: $e');
        // 继续执行，不要因为保存状态失败而中断整个流程
      }

      debugPrint('数据库和节日数据初始化成功');
      return true;
    } catch (e) {
      debugPrint('数据库和节日数据初始化失败: $e');
      _isInitializing = false;
      return false;
    }
  }

  /// 重置数据库和节日数据
  Future<bool> reset() async {
    try {
      _isInitialized = false;

      // 1. 重置数据库
      await HolidayMigrationService.resetDatabase();

      // 2. 重新初始化，不依赖于BuildContext
      final success = await initialize();

      // 3. 重新加载预设节日数据
      if (success) {
        try {
          final holidayDataLoader = HolidayDataLoaderService();
          // 强制重新加载预设节日数据
          await holidayDataLoader.initializeBasicData();
          debugPrint('预设节日数据重新加载成功');
        } catch (e) {
          debugPrint('预设节日数据重新加载失败: $e');
          // 继续执行，不要因为节日数据初始化失败而中断整个流程
        }
      }

      return success;
    } catch (e) {
      debugPrint('重置数据库和节日数据失败: $e');
      return false;
    }
  }

  /// 保存初始化状态
  Future<void> _saveInitializationState(bool state) async {
    try {
      // 在Web平台上，SharedPreferences可能会有问题
      if (kIsWeb) {
        debugPrint('在Web平台上，跳过保存初始化状态');
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('database_initialized', state);
        debugPrint('成功保存初始化状态: $state');
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('SharedPreferences插件未找到，可能是在不支持的平台上运行');
        } else {
          debugPrint('保存初始化状态失败: $e');
        }
      }
    } catch (e) {
      debugPrint('保存初始化状态过程中发生错误: $e');
    }
  }

  /// 检查是否已初始化
  Future<bool> checkInitializationState() async {
    try {
      // 在Web平台上，SharedPreferences可能会有问题
      if (kIsWeb) {
        debugPrint('在Web平台上，假设数据库未初始化');
        _isInitialized = false;
        return false;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final initialized = prefs.getBool('database_initialized') ?? false;
        _isInitialized = initialized;
        debugPrint('成功检查初始化状态: $initialized');
        return initialized;
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('SharedPreferences插件未找到，可能是在不支持的平台上运行');
        } else {
          debugPrint('检查初始化状态失败: $e');
        }
        _isInitialized = false;
        return false;
      }
    } catch (e) {
      debugPrint('检查初始化状态过程中发生错误: $e');
      _isInitialized = false;
      return false;
    }
  }
}
