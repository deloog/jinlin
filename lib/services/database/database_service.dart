import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:jinlin_app/services/database/indexed_db_adapter.dart';

/// 数据库服务
///
/// 提供统一的数据库访问接口，负责数据的存储和检索
class DatabaseService {
  static const String _databaseName = 'jinlin_app.db';
  static const int _databaseVersion = 1;

  final LoggingService _logger = LoggingService();
  Database? _database;
  bool _isInitialized = false;

  // Web平台使用IndexedDB适配器
  IndexedDBAdapter? _indexedDBAdapter;

  // 内存缓存
  final List<Holiday> _holidays = [];
  final List<Reminder> _reminders = [];

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// 获取是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化数据库
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.debug('初始化数据库服务');
      debugPrint('初始化数据库服务');

      if (kIsWeb) {
        // 在Web平台上使用IndexedDB
        _logger.debug('在Web平台上使用IndexedDB');
        debugPrint('在Web平台上使用IndexedDB');

        _indexedDBAdapter = IndexedDBAdapter();
        await _indexedDBAdapter!.initialize();

        // 预加载数据到内存缓存
        _holidays.clear();
        _holidays.addAll(await _indexedDBAdapter!.getHolidaysByRegion('GLOBAL', 'en'));

        _reminders.clear();
        _reminders.addAll(await _indexedDBAdapter!.getReminders());

        _isInitialized = true;
        _logger.info('IndexedDB初始化完成');
        debugPrint('IndexedDB初始化完成');
      } else {
        // 在非Web平台上使用SQLite
        debugPrint('开始获取SQLite数据库实例');
        await database;
        debugPrint('SQLite数据库实例获取成功');
        _isInitialized = true;
        _logger.info('SQLite数据库服务初始化完成');
        debugPrint('SQLite数据库服务初始化完成');
      }
    } catch (e, stack) {
      _logger.error('数据库服务初始化失败', e, stack);
      debugPrint('数据库服务初始化失败: $e');
      debugPrint('堆栈: $stack');
      rethrow;
    }
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    _logger.debug('创建数据库: $_databaseName');
    debugPrint('创建数据库: $_databaseName');

    try {
      // 在Web平台上使用内存数据库
      if (kIsWeb) {
        debugPrint('在Web平台上使用内存数据库');
        final db = await openDatabase(
          inMemoryDatabasePath,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        debugPrint('内存数据库打开成功');
        return db;
      } else {
        debugPrint('获取数据库路径');
        final databasePath = await getDatabasesPath();
        debugPrint('数据库路径: $databasePath');
        final path = join(databasePath, _databaseName);
        debugPrint('完整数据库路径: $path');

        debugPrint('打开数据库');
        final db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: onDatabaseDowngradeDelete,
        );
        debugPrint('数据库打开成功');
        return db;
      }
    } catch (e, stack) {
      debugPrint('初始化数据库失败: $e');
      debugPrint('堆栈: $stack');
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    _logger.debug('创建数据库表，版本: $version');
    debugPrint('创建数据库表，版本: $version');

    try {
      debugPrint('创建节日表');
      // 创建节日表
      await db.execute('''
        CREATE TABLE holidays (
          id TEXT PRIMARY KEY,
          is_system_holiday INTEGER NOT NULL DEFAULT 0,
          names TEXT NOT NULL,
          type_id INTEGER NOT NULL,
          regions TEXT NOT NULL,
          calculation_type_id INTEGER NOT NULL,
          calculation_rule TEXT NOT NULL,
          descriptions TEXT NOT NULL,
          importance_level INTEGER NOT NULL,
          customs TEXT,
          taboos TEXT,
          foods TEXT,
          greetings TEXT,
          activities TEXT,
          history TEXT,
          image_url TEXT,
          user_importance INTEGER NOT NULL DEFAULT 0,
          contact_id TEXT,
          created_at TEXT NOT NULL,
          last_modified TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
          deletion_reason TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      debugPrint('节日表创建成功');

      debugPrint('创建提醒表');
      // 创建提醒表
      await db.execute('''
        CREATE TABLE reminders (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          time TEXT,
          is_all_day INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          is_recurring INTEGER NOT NULL DEFAULT 0,
          recurrence_rule TEXT,
          importance INTEGER NOT NULL DEFAULT 0,
          color INTEGER,
          icon INTEGER,
          created_at TEXT NOT NULL,
          last_modified TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
          deletion_reason TEXT,
          needs_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      debugPrint('提醒表创建成功');

      debugPrint('创建版本表');
      // 创建版本表
      await db.execute('''
        CREATE TABLE versions (
          region_code TEXT PRIMARY KEY,
          version INTEGER NOT NULL,
          last_updated TEXT NOT NULL
        )
      ''');
      debugPrint('版本表创建成功');

      debugPrint('创建设置表');
      // 创建设置表
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          last_modified TEXT NOT NULL
        )
      ''');
      debugPrint('设置表创建成功');

      debugPrint('创建索引');
      // 创建索引
      await db.execute('CREATE INDEX idx_holidays_regions ON holidays (regions)');
      await db.execute('CREATE INDEX idx_holidays_needs_sync ON holidays (needs_sync)');
      await db.execute('CREATE INDEX idx_reminders_date ON reminders (date)');
      await db.execute('CREATE INDEX idx_reminders_needs_sync ON reminders (needs_sync)');
      debugPrint('索引创建成功');

      _logger.debug('数据库表创建完成');
      debugPrint('数据库表创建完成');
    } catch (e, stack) {
      debugPrint('创建数据库表失败: $e');
      debugPrint('堆栈: $stack');
      rethrow;
    }
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.debug('升级数据库，从版本 $oldVersion 到 $newVersion');

    if (oldVersion < 2) {
      // 版本1到版本2的升级
      // 这里添加升级逻辑
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    _logger.debug('关闭数据库');

    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  // 节日相关方法

  /// 获取特定地区和语言的节日
  Future<List<Holiday>> getHolidaysByRegion(String regionCode, String languageCode) async {
    try {
      if (kIsWeb) {
        // 先检查内存缓存
        if (_holidays.isNotEmpty) {
          _logger.debug('从内存缓存获取节日数据');
          return _holidays.where((holiday) =>
            holiday.regions.contains(regionCode) && !holiday.isDeleted).toList();
        }

        // 如果内存缓存为空，从IndexedDB获取
        _logger.debug('从IndexedDB获取节日数据');
        final holidays = await _indexedDBAdapter!.getHolidaysByRegion(regionCode, languageCode);

        // 更新内存缓存
        _holidays.clear();
        _holidays.addAll(holidays);

        return holidays;
      }

      final db = await database;

      // 使用SQL的LIKE操作符查找包含特定地区的节日
      final results = await db.query(
        'holidays',
        where: "regions LIKE ? AND is_deleted = 0",
        whereArgs: ["%$regionCode%"],
      );

      _logger.debug('获取到 ${results.length} 个 $regionCode 地区的节日');

      return results.map((map) => Holiday.fromMap(map)).toList();
    } catch (e, stack) {
      _logger.error('获取节日数据失败', e, stack);
      return [];
    }
  }

  /// 保存节日
  Future<void> saveHoliday(Holiday holiday, {bool needsSync = false}) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        final index = _holidays.indexWhere((h) => h.id == holiday.id);
        if (index >= 0) {
          _holidays[index] = holiday;
        } else {
          _holidays.add(holiday);
        }

        // 保存到IndexedDB
        _logger.debug('保存节日到IndexedDB: ${holiday.id}');
        await _indexedDBAdapter!.saveHoliday(holiday, needsSync: needsSync);
        return;
      }

      final db = await database;

      final map = holiday.toMap();
      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await db.insert(
        'holidays',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.debug('保存节日: ${holiday.id}');
    } catch (e, stack) {
      _logger.error('保存节日失败', e, stack);
      rethrow;
    }
  }

  /// 保存多个节日
  Future<void> saveHolidays(List<Holiday> holidays) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        for (final holiday in holidays) {
          final index = _holidays.indexWhere((h) => h.id == holiday.id);
          if (index >= 0) {
            _holidays[index] = holiday;
          } else {
            _holidays.add(holiday);
          }
        }

        // 保存到IndexedDB
        _logger.debug('保存 ${holidays.length} 个节日到IndexedDB');
        await _indexedDBAdapter!.saveHolidays(holidays);
        return;
      }

      final db = await database;

      final batch = db.batch();

      for (final holiday in holidays) {
        batch.insert(
          'holidays',
          holiday.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('保存 ${holidays.length} 个节日');
    } catch (e, stack) {
      _logger.error('保存多个节日失败', e, stack);
      rethrow;
    }
  }

  /// 更新节日
  Future<void> updateHolidays(List<Holiday> holidays) async {
    try {
      final db = await database;

      final batch = db.batch();

      for (final holiday in holidays) {
        batch.update(
          'holidays',
          holiday.toMap(),
          where: 'id = ?',
          whereArgs: [holiday.id],
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('更新 ${holidays.length} 个节日');
    } catch (e, stack) {
      _logger.error('更新节日失败', e, stack);
      rethrow;
    }
  }

  /// 删除节日
  Future<void> deleteHolidays(List<String> holidayIds) async {
    try {
      final db = await database;

      final batch = db.batch();

      for (final id in holidayIds) {
        batch.update(
          'holidays',
          {
            'is_deleted': 1,
            'deleted_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('删除 ${holidayIds.length} 个节日');
    } catch (e, stack) {
      _logger.error('删除节日失败', e, stack);
      rethrow;
    }
  }

  // 提醒事项相关方法

  /// 获取所有提醒事项
  Future<List<Reminder>> getReminders() async {
    try {
      if (kIsWeb) {
        // 先检查内存缓存
        if (_reminders.isNotEmpty) {
          _logger.debug('从内存缓存获取提醒事项');
          return _reminders.where((reminder) => !reminder.isDeleted).toList();
        }

        // 如果内存缓存为空，从IndexedDB获取
        _logger.debug('从IndexedDB获取提醒事项');
        final reminders = await _indexedDBAdapter!.getReminders();

        // 更新内存缓存
        _reminders.clear();
        _reminders.addAll(reminders);

        return reminders;
      }

      final db = await database;

      final results = await db.query(
        'reminders',
        where: "is_deleted = 0",
      );

      _logger.debug('获取到 ${results.length} 个提醒事项');

      return results.map((map) => Reminder.fromMap(map)).toList();
    } catch (e, stack) {
      _logger.error('获取提醒事项失败', e, stack);
      return [];
    }
  }

  /// 获取特定日期的提醒事项
  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    try {
      final db = await database;

      final dateString = date.toIso8601String().split('T')[0];

      final results = await db.query(
        'reminders',
        where: "date = ? AND is_deleted = 0",
        whereArgs: [dateString],
      );

      _logger.debug('获取到 ${results.length} 个 $dateString 的提醒事项');

      return results.map((map) => Reminder.fromMap(map)).toList();
    } catch (e, stack) {
      _logger.error('获取特定日期的提醒事项失败', e, stack);
      return [];
    }
  }

  /// 获取特定ID的提醒事项
  Future<Reminder?> getReminderById(String id) async {
    try {
      final db = await database;

      final results = await db.query(
        'reminders',
        where: "id = ? AND is_deleted = 0",
        whereArgs: [id],
      );

      if (results.isEmpty) {
        _logger.debug('未找到ID为 $id 的提醒事项');
        return null;
      }

      _logger.debug('获取到ID为 $id 的提醒事项');

      return Reminder.fromMap(results.first);
    } catch (e, stack) {
      _logger.error('获取特定ID的提醒事项失败', e, stack);
      return null;
    }
  }

  /// 保存提醒事项
  Future<void> saveReminder(Reminder reminder, {bool needsSync = false}) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) {
          _reminders[index] = reminder;
        } else {
          _reminders.add(reminder);
        }

        // 保存到IndexedDB
        _logger.debug('保存提醒事项到IndexedDB: ${reminder.id}');
        await _indexedDBAdapter!.saveReminder(reminder, needsSync: needsSync);
        return;
      }

      final db = await database;

      final map = reminder.toMap();
      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await db.insert(
        'reminders',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.debug('保存提醒事项: ${reminder.id}');
    } catch (e, stack) {
      _logger.error('保存提醒事项失败', e, stack);
      rethrow;
    }
  }

  /// 保存多个提醒事项
  Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        for (final reminder in reminders) {
          final index = _reminders.indexWhere((r) => r.id == reminder.id);
          if (index >= 0) {
            _reminders[index] = reminder;
          } else {
            _reminders.add(reminder);
          }
        }

        // 保存到IndexedDB
        _logger.debug('保存 ${reminders.length} 个提醒事项到IndexedDB');
        for (final reminder in reminders) {
          await _indexedDBAdapter!.saveReminder(reminder);
        }
        return;
      }

      final db = await database;

      final batch = db.batch();

      for (final reminder in reminders) {
        batch.insert(
          'reminders',
          reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('保存 ${reminders.length} 个提醒事项');
    } catch (e, stack) {
      _logger.error('保存多个提醒事项失败', e, stack);
      rethrow;
    }
  }

  /// 更新提醒事项
  Future<void> updateReminder(Reminder reminder, {bool needsSync = false}) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) {
          _reminders[index] = reminder;
        } else {
          _reminders.add(reminder);
        }

        // 保存到IndexedDB
        _logger.debug('更新提醒事项到IndexedDB: ${reminder.id}');
        await _indexedDBAdapter!.saveReminder(reminder, needsSync: needsSync);
        return;
      }

      final db = await database;

      final map = reminder.toMap();
      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await db.update(
        'reminders',
        map,
        where: 'id = ?',
        whereArgs: [reminder.id],
      );

      _logger.debug('更新提醒事项: ${reminder.id}');
    } catch (e, stack) {
      _logger.error('更新提醒事项失败', e, stack);
      rethrow;
    }
  }

  /// 删除提醒事项
  Future<void> deleteReminder(String id, {bool needsSync = false}) async {
    try {
      if (kIsWeb) {
        // 更新内存缓存
        final index = _reminders.indexWhere((r) => r.id == id);
        if (index >= 0) {
          _reminders[index] = _reminders[index].copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
          );

          // 保存到IndexedDB
          _logger.debug('在IndexedDB中标记提醒事项为已删除: $id');
          await _indexedDBAdapter!.saveReminder(_reminders[index], needsSync: needsSync);
        }
        return;
      }

      final db = await database;

      final map = {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      };

      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await db.update(
        'reminders',
        map,
        where: 'id = ?',
        whereArgs: [id],
      );

      _logger.debug('删除提醒事项: $id');
    } catch (e, stack) {
      _logger.error('删除提醒事项失败', e, stack);
      rethrow;
    }
  }

  /// 获取需要同步的提醒事项
  Future<List<Reminder>> getUnsyncedReminders() async {
    try {
      final db = await database;

      final results = await db.query(
        'reminders',
        where: "needs_sync = 1",
      );

      _logger.debug('获取到 ${results.length} 个需要同步的提醒事项');

      return results.map((map) => Reminder.fromMap(map)).toList();
    } catch (e, stack) {
      _logger.error('获取需要同步的提醒事项失败', e, stack);
      return [];
    }
  }

  /// 标记提醒事项已同步
  Future<void> markRemindersSynced(List<String> reminderIds) async {
    try {
      final db = await database;

      final batch = db.batch();

      for (final id in reminderIds) {
        batch.update(
          'reminders',
          {'needs_sync': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('标记 ${reminderIds.length} 个提醒事项已同步');
    } catch (e, stack) {
      _logger.error('标记提醒事项已同步失败', e, stack);
      rethrow;
    }
  }

  /// 应用提醒事项变更
  Future<void> applyReminderChanges(List<Reminder> reminders) async {
    try {
      final db = await database;

      final batch = db.batch();

      for (final reminder in reminders) {
        batch.insert(
          'reminders',
          reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      _logger.debug('应用 ${reminders.length} 个提醒事项变更');
    } catch (e, stack) {
      _logger.error('应用提醒事项变更失败', e, stack);
      rethrow;
    }
  }

  // 版本相关方法

  /// 获取数据版本
  Future<int?> getDataVersion(String regionCode) async {
    try {
      final db = await database;

      final results = await db.query(
        'versions',
        columns: ['version'],
        where: 'region_code = ?',
        whereArgs: [regionCode],
      );

      if (results.isEmpty) {
        _logger.debug('未找到 $regionCode 地区的数据版本');
        return 0;
      }

      final version = results.first['version'] as int;
      _logger.debug('获取到 $regionCode 地区的数据版本: $version');

      return version;
    } catch (e, stack) {
      _logger.error('获取数据版本失败', e, stack);
      return 0;
    }
  }

  /// 更新数据版本
  Future<void> updateDataVersion(String regionCode, int version) async {
    try {
      final db = await database;

      await db.insert(
        'versions',
        {
          'region_code': regionCode,
          'version': version,
          'last_updated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.debug('更新 $regionCode 地区的数据版本为 $version');
    } catch (e, stack) {
      _logger.error('更新数据版本失败', e, stack);
      rethrow;
    }
  }

  // 设置相关方法

  /// 获取应用设置
  Future<String?> getAppSetting(String key) async {
    try {
      final db = await database;

      final results = await db.query(
        'settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (results.isEmpty) {
        _logger.debug('未找到设置: $key');
        return null;
      }

      final value = results.first['value'] as String;
      _logger.debug('获取到设置: $key = $value');

      return value;
    } catch (e, stack) {
      _logger.error('获取应用设置失败', e, stack);
      return null;
    }
  }

  /// 设置应用设置
  Future<void> setAppSetting(String key, String value) async {
    try {
      final db = await database;

      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
          'last_modified': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.debug('设置应用设置: $key = $value');
    } catch (e, stack) {
      _logger.error('设置应用设置失败', e, stack);
      rethrow;
    }
  }
}
