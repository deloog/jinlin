import 'dart:async';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/database/holiday_model.dart';
import 'package:jinlin_app/database/region_model.dart';
import 'package:jinlin_app/database/holiday_type_model.dart';

// 导入 FFI 支持
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    // 初始化 SQLite
    if (kIsWeb) {
      // Web 平台
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // 桌面平台
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('holidays.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    if (kIsWeb) {
      // Web 平台直接使用文件名
      path = filePath;
    } else {
      // 非 Web 平台使用完整路径
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建地区表
    await db.execute('''
      CREATE TABLE regions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_zh TEXT NOT NULL,
        name_en TEXT NOT NULL
      )
    ''');

    // 创建节日类型表
    await db.execute('''
      CREATE TABLE holiday_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_zh TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');

    // 创建节日表
    await db.execute('''
      CREATE TABLE holidays (
        id TEXT PRIMARY KEY,
        name_zh TEXT NOT NULL,
        name_en TEXT NOT NULL,
        type_id TEXT NOT NULL,
        calculation_type TEXT NOT NULL,
        calculation_rule TEXT NOT NULL,
        description_zh TEXT,
        description_en TEXT,
        importance_level INTEGER DEFAULT 0,
        FOREIGN KEY (type_id) REFERENCES holiday_types (id)
      )
    ''');

    // 创建节日-地区关联表（多对多关系）
    await db.execute('''
      CREATE TABLE holiday_regions (
        holiday_id TEXT NOT NULL,
        region_id TEXT NOT NULL,
        PRIMARY KEY (holiday_id, region_id),
        FOREIGN KEY (holiday_id) REFERENCES holidays (id),
        FOREIGN KEY (region_id) REFERENCES regions (id)
      )
    ''');
  }

  // 地区相关操作
  Future<int> insertRegion(Region region) async {
    final db = await database;
    return await db.insert('regions', region.toMap());
  }

  Future<List<Region>> getAllRegions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('regions');
    return List.generate(maps.length, (i) => Region.fromMap(maps[i]));
  }

  // 节日类型相关操作
  Future<int> insertHolidayType(HolidayType type) async {
    final db = await database;
    return await db.insert('holiday_types', type.toMap());
  }

  Future<List<HolidayType>> getAllHolidayTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('holiday_types');
    return List.generate(maps.length, (i) => HolidayType.fromMap(maps[i]));
  }

  // 节日相关操作
  Future<int> insertHoliday(Holiday holiday) async {
    final db = await database;

    // 开始事务
    return await db.transaction((txn) async {
      // 插入节日
      final holidayId = await txn.insert('holidays', holiday.toMap());

      // 插入节日-地区关联
      for (final regionId in holiday.regionIds) {
        await txn.insert('holiday_regions', {
          'holiday_id': holiday.id,
          'region_id': regionId,
        });
      }

      return holidayId;
    });
  }

  Future<List<Holiday>> getAllHolidays() async {
    final db = await database;

    // 获取所有节日
    final List<Map<String, dynamic>> holidayMaps = await db.query('holidays');

    // 为每个节日获取关联的地区
    List<Holiday> holidays = [];
    for (var map in holidayMaps) {
      final holidayId = map['id'];

      // 获取节日关联的地区
      final List<Map<String, dynamic>> regionMaps = await db.rawQuery('''
        SELECT r.id FROM regions r
        JOIN holiday_regions hr ON r.id = hr.region_id
        WHERE hr.holiday_id = ?
      ''', [holidayId]);

      final List<String> regionIds = regionMaps.map((m) => m['id'] as String).toList();

      // 创建完整的节日对象
      holidays.add(Holiday.fromMap(map, regionIds));
    }

    return holidays;
  }

  // 根据地区获取节日
  Future<List<Holiday>> getHolidaysByRegion(String regionId) async {
    final db = await database;

    // 获取指定地区的节日
    final List<Map<String, dynamic>> holidayMaps = await db.rawQuery('''
      SELECT h.* FROM holidays h
      JOIN holiday_regions hr ON h.id = hr.holiday_id
      WHERE hr.region_id = ? OR hr.region_id = 'ALL'
    ''', [regionId]);

    // 为每个节日获取关联的地区
    List<Holiday> holidays = [];
    for (var map in holidayMaps) {
      final holidayId = map['id'];

      // 获取节日关联的地区
      final List<Map<String, dynamic>> regionMaps = await db.rawQuery('''
        SELECT r.id FROM regions r
        JOIN holiday_regions hr ON r.id = hr.region_id
        WHERE hr.holiday_id = ?
      ''', [holidayId]);

      final List<String> regionIds = regionMaps.map((m) => m['id'] as String).toList();

      // 创建完整的节日对象
      holidays.add(Holiday.fromMap(map, regionIds));
    }

    return holidays;
  }

  // 更新节日重要性
  Future<int> updateHolidayImportance(String holidayId, int importanceLevel) async {
    final db = await database;
    return await db.update(
      'holidays',
      {'importance_level': importanceLevel},
      where: 'id = ?',
      whereArgs: [holidayId],
    );
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
