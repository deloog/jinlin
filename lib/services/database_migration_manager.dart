import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';

/// 数据库迁移管理器
///
/// 负责处理数据库版本升级和数据迁移
class DatabaseMigrationManager {
  static final DatabaseMigrationManager _instance = DatabaseMigrationManager._internal();
  factory DatabaseMigrationManager() => _instance;
  DatabaseMigrationManager._internal();

  // 当前数据库版本
  static const int currentVersion = 2;

  // 迁移函数映射
  final Map<int, Future<void> Function()> _migrations = {
    1: _migrateV1ToV2,
    // 未来版本的迁移函数
  };

  /// 执行迁移
  Future<bool> migrate() async {
    try {
      // 获取当前版本
      final currentDbVersion = await _getCurrentDatabaseVersion();

      debugPrint('当前数据库版本: $currentDbVersion, 目标版本: $currentVersion');

      // 如果当前版本低于最新版本，执行迁移
      if (currentDbVersion < currentVersion) {
        for (int version = currentDbVersion; version < currentVersion; version++) {
          debugPrint('执行从版本 $version 到 ${version + 1} 的迁移');
          if (_migrations.containsKey(version)) {
            await _migrations[version]!();
            await _saveCurrentDatabaseVersion(version + 1);
            debugPrint('迁移到版本 ${version + 1} 成功');
          } else {
            debugPrint('未找到从版本 $version 到 ${version + 1} 的迁移函数');
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('数据库迁移失败: $e');
      return false;
    }
  }

  /// 从V1迁移到V2
  static Future<void> _migrateV1ToV2() async {
    try {
      debugPrint('开始从V1迁移到V2...');

      // 1. 注册新的适配器
      _registerAdapters();

      // 2. 迁移节日数据
      await _migrateHolidayData();

      // 3. 创建新的数据表
      await _createNewTables();

      // 4. 初始化用户设置
      await _initializeUserSettings();

      debugPrint('从V1迁移到V2完成');
    } catch (e) {
      debugPrint('从V1迁移到V2失败: $e');
      rethrow;
    }
  }

  /// 注册新的适配器
  static void _registerAdapters() {
    try {
      // 注册新的适配器
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(HolidayModelExtendedAdapter());
      }

      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(RelationTypeAdapter());
      }

      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(ContactModelAdapter());
      }

      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(AppThemeModeAdapter());
      }

      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(ReminderAdvanceTimeAdapter());
      }

      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(UserSettingsModelAdapter());
      }

      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(ReminderEventTypeAdapter());
      }

      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(ReminderStatusAdapter());
      }

      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(ReminderEventModelAdapter());
      }

      debugPrint('注册新的适配器成功');
    } catch (e) {
      debugPrint('注册新的适配器失败: $e');
      rethrow;
    }
  }

  /// 迁移节日数据
  static Future<void> _migrateHolidayData() async {
    try {
      // 打开旧的节日数据表
      final oldBox = await Hive.openBox<HolidayModel>('holidays');

      // 打开新的节日数据表
      final newBox = await Hive.openBox<HolidayModelExtended>('holidays_extended');

      // 迁移数据
      final oldHolidays = oldBox.values.toList();
      debugPrint('找到 ${oldHolidays.length} 个旧节日数据');

      for (final oldHoliday in oldHolidays) {
        final newHoliday = HolidayModelExtended.fromHolidayModel(oldHoliday);
        await newBox.put(newHoliday.id, newHoliday);
      }

      debugPrint('迁移 ${oldHolidays.length} 个节日数据到新表成功');
    } catch (e) {
      debugPrint('迁移节日数据失败: $e');
      rethrow;
    }
  }

  /// 创建新的数据表
  static Future<void> _createNewTables() async {
    try {
      // 创建联系人表
      await Hive.openBox<ContactModel>('contacts');

      // 创建用户设置表
      await Hive.openBox<UserSettingsModel>('user_settings');

      // 创建提醒事件表
      await Hive.openBox<ReminderEventModel>('reminder_events');

      debugPrint('创建新的数据表成功');
    } catch (e) {
      debugPrint('创建新的数据表失败: $e');
      rethrow;
    }
  }

  /// 初始化用户设置
  static Future<void> _initializeUserSettings() async {
    try {
      final box = await Hive.openBox<UserSettingsModel>('user_settings');

      // 如果用户设置表为空，创建默认设置
      if (box.isEmpty) {
        final userId = DateTime.now().millisecondsSinceEpoch.toString();

        final settings = UserSettingsModel(
          userId: userId,
          nickname: 'User',
          languageCode: 'zh', // 默认中文
          countryCode: 'CN', // 默认中国
        );

        await box.put(userId, settings);
        debugPrint('创建默认用户设置成功');
      }
    } catch (e) {
      debugPrint('初始化用户设置失败: $e');
      rethrow;
    }
  }

  /// 获取当前数据库版本
  Future<int> _getCurrentDatabaseVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('database_version') ?? 1;
    } catch (e) {
      debugPrint('获取当前数据库版本失败: $e');
      return 1; // 默认为版本1
    }
  }

  /// 保存当前数据库版本
  Future<void> _saveCurrentDatabaseVersion(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('database_version', version);
      debugPrint('保存数据库版本 $version 成功');
    } catch (e) {
      debugPrint('保存数据库版本失败: $e');
      rethrow;
    }
  }
}
