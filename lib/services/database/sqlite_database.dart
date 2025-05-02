import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';

// 导入 FFI 支持
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// 导入 Web FFI 支持
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// SQLite数据库实现
class SQLiteDatabase implements DatabaseInterface {
  static final SQLiteDatabase _instance = SQLiteDatabase._internal();

  factory SQLiteDatabase() {
    return _instance;
  }

  SQLiteDatabase._internal() {
    _initPlatformSpecific();
  }

  // 数据库实例
  Database? _db;
  bool _initialized = false;

  // 数据库版本
  static const int _databaseVersion = 2;

  // 表名
  static const String _holidaysTable = 'holidays';
  static const String _prefsTable = 'preferences';

  // 初始化平台特定设置
  void _initPlatformSpecific() {
    if (kIsWeb) {
      // Web平台
      databaseFactory = databaseFactoryFfiWeb;
    } else if (!Platform.isAndroid && !Platform.isIOS) {
      // 桌面平台
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 获取数据库路径
      String path;

      if (kIsWeb) {
        // Web平台直接使用文件名
        path = 'jinlin_app.db';
      } else {
        // 非Web平台使用完整路径
        final dbPath = await getDatabasesPath();
        path = join(dbPath, 'jinlin_app.db');
      }

      // 打开数据库
      _db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      _initialized = true;
      debugPrint('SQLite数据库初始化成功');
    } catch (e) {
      debugPrint('SQLite数据库初始化失败: $e');
      rethrow;
    }
  }

  // 创建数据库表
  Future<void> _createDatabase(Database db, int version) async {
    // 创建节日表
    await db.execute('''
      CREATE TABLE $_holidaysTable (
        id TEXT PRIMARY KEY,
        is_system_holiday INTEGER NOT NULL DEFAULT 0,
        names TEXT NOT NULL,
        type_id INTEGER NOT NULL,
        regions TEXT NOT NULL,
        calculation_type_id INTEGER NOT NULL,
        calculation_rule TEXT NOT NULL,
        descriptions TEXT,
        importance_level INTEGER NOT NULL DEFAULT 0,
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
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT,
        deletion_reason TEXT
      )
    ''');

    // 创建偏好设置表
    await db.execute('''
      CREATE TABLE $_prefsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 初始化偏好设置
    await db.insert(_prefsTable, {
      'key': 'is_first_launch',
      'value': '1',
    });

    await db.insert(_prefsTable, {
      'key': 'data_version',
      'value': '1',
    });
  }

  // 升级数据库
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1 && newVersion == 2) {
      // 添加软删除相关字段
      await db.execute('ALTER TABLE $_holidaysTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $_holidaysTable ADD COLUMN deleted_at TEXT');
      await db.execute('ALTER TABLE $_holidaysTable ADD COLUMN deletion_reason TEXT');

      debugPrint('数据库从版本1升级到版本2：添加软删除字段');
    }
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _initialized = false;
    }
  }

  @override
  Future<void> clearAll() async {
    await _checkInitialized();

    // 清空节日表
    await _db!.delete(_holidaysTable);

    debugPrint('数据库已清空');
  }

  // 检查数据库是否已初始化
  Future<void> _checkInitialized() async {
    if (!_initialized || _db == null) {
      throw Exception('数据库未初始化');
    }
  }

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _checkInitialized();

    try {
      // 检查节日是否已存在
      final existing = await getHolidayById(holiday.id);

      if (existing != null) {
        // 更新现有节日
        await _db!.update(
          _holidaysTable,
          holiday.toMap(),
          where: 'id = ?',
          whereArgs: [holiday.id],
        );
        debugPrint('更新节日: ${holiday.id}');
      } else {
        // 插入新节日
        await _db!.insert(
          _holidaysTable,
          holiday.toMap(),
        );
        debugPrint('插入节日: ${holiday.id}');
      }
    } catch (e) {
      debugPrint('保存节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _checkInitialized();

    try {
      // 使用事务批量保存
      await _db!.transaction((txn) async {
        for (final holiday in holidays) {
          // 检查节日是否已存在
          final count = Sqflite.firstIntValue(await txn.query(
            _holidaysTable,
            columns: ['COUNT(*)'],
            where: 'id = ?',
            whereArgs: [holiday.id],
          )) ?? 0;

          if (count > 0) {
            // 更新现有节日
            await txn.update(
              _holidaysTable,
              holiday.toMap(),
              where: 'id = ?',
              whereArgs: [holiday.id],
            );
          } else {
            // 插入新节日
            await txn.insert(
              _holidaysTable,
              holiday.toMap(),
            );
          }
        }
      });

      debugPrint('批量保存 ${holidays.length} 个节日');
    } catch (e) {
      debugPrint('批量保存节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    await _checkInitialized();

    try {
      final maps = await _db!.query(_holidaysTable);
      return maps.map((map) => Holiday.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取所有节日失败: $e');
      return [];
    }
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    await _checkInitialized();

    try {
      final maps = await _db!.query(
        _holidaysTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Holiday.fromMap(maps.first);
    } catch (e) {
      debugPrint('根据ID获取节日失败: $e');
      return null;
    }
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      // 获取所有节日
      final allHolidays = await getAllHolidays();

      // 筛选出指定地区的节日
      return allHolidays.where((holiday) {
        return holiday.regions.contains(region) || holiday.regions.contains('ALL');
      }).toList();
    } catch (e) {
      debugPrint('根据地区获取节日失败: $e');
      return [];
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _checkInitialized();

    try {
      await _db!.delete(
        _holidaysTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('删除节日: $id');
    } catch (e) {
      debugPrint('删除节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _checkInitialized();

    try {
      await _db!.update(
        _holidaysTable,
        {'user_importance': importance},
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('更新节日重要性: $id -> $importance');
    } catch (e) {
      debugPrint('更新节日重要性失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isInitialized() async {
    return _initialized;
  }

  @override
  Future<bool> isFirstLaunch() async {
    await _checkInitialized();

    try {
      final result = await _db!.query(
        _prefsTable,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['is_first_launch'],
      );

      if (result.isEmpty) {
        return true;
      }

      return result.first['value'] == '1';
    } catch (e) {
      debugPrint('检查是否首次启动失败: $e');
      return true;
    }
  }

  @override
  Future<void> markFirstLaunchComplete() async {
    await _checkInitialized();

    try {
      await _db!.update(
        _prefsTable,
        {'value': '0'},
        where: 'key = ?',
        whereArgs: ['is_first_launch'],
      );

      debugPrint('标记首次启动完成');
    } catch (e) {
      debugPrint('标记首次启动完成失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> getDataVersion() async {
    await _checkInitialized();

    try {
      final result = await _db!.query(
        _prefsTable,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['data_version'],
      );

      if (result.isEmpty) {
        return 1;
      }

      return int.parse(result.first['value'] as String);
    } catch (e) {
      debugPrint('获取数据版本失败: $e');
      return 1;
    }
  }

  @override
  Future<void> updateDataVersion(int version) async {
    await _checkInitialized();

    try {
      await _db!.update(
        _prefsTable,
        {'value': version.toString()},
        where: 'key = ?',
        whereArgs: ['data_version'],
      );

      debugPrint('更新数据版本: $version');
    } catch (e) {
      debugPrint('更新数据版本失败: $e');
      rethrow;
    }
  }
}
