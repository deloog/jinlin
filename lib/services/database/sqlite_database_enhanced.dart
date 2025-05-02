import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/models/sync/sync_status_enum.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/database/error/database_error_handler.dart';
import 'package:jinlin_app/services/database/schema/database_schema.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 增强版SQLite数据库适配器
///
/// 实现了增强版数据库接口，提供对SQLite数据库的访问
class SQLiteDatabaseEnhanced implements DatabaseInterfaceEnhanced {
  // 单例模式
  static final SQLiteDatabaseEnhanced _instance = SQLiteDatabaseEnhanced._internal();

  factory SQLiteDatabaseEnhanced() {
    return _instance;
  }

  SQLiteDatabaseEnhanced._internal() {
    // 初始化 SQLite
    if (kIsWeb) {
      // Web 平台
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // 数据库实例
  Database? _db;

  // 数据库是否已初始化
  bool _initialized = false;

  // 数据库文件名
  static const String _databaseName = 'jinlin_app_unified.db';

  // 数据库版本
  static const int _databaseVersion = DatabaseSchema.databaseVersion;

  // 日志标签
  static const String _tag = 'SQLiteDB';

  // 日志记录器
  final logger = Logger();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 获取数据库路径
      String path;

      if (kIsWeb) {
        // Web平台直接使用文件名
        path = _databaseName;
      } else {
        // 非Web平台使用完整路径
        final dbPath = await getDatabasesPath();
        path = join(dbPath, _databaseName);
      }

      logger.i(_tag, '正在初始化数据库: $path');

      // 打开数据库
      _db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      _initialized = true;
      logger.i(_tag, '数据库初始化成功');
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'initialize');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      try {
        await _db!.close();
        _db = null;
        _initialized = false;
        logger.i(_tag, '数据库已关闭');
      } catch (e, stackTrace) {
        DatabaseErrorHandler.handleError(e, stackTrace, 'close');
        rethrow;
      }
    }
  }

  @override
  Future<void> clearAll() async {
    await _checkInitialized();

    try {
      logger.w(_tag, '正在清空所有数据表');

      // 开始事务
      await _db!.transaction((txn) async {
        // 删除所有表中的数据
        await txn.delete(DatabaseSchema.holidaysTable);
        await txn.delete(DatabaseSchema.userSettingsTable);
        await txn.delete(DatabaseSchema.contactsTable);
        await txn.delete(DatabaseSchema.reminderEventsTable);
        await txn.delete(DatabaseSchema.syncStatusTable);
      });

      logger.i(_tag, '所有数据表已清空');
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'clearAll');
      rethrow;
    }
  }

  // 创建数据库表
  Future<void> _createDatabase(Database db, int version) async {
    try {
      logger.i(_tag, '正在创建数据库表 (版本: $version)');

      // 创建节日表
      await db.execute(DatabaseSchema.createHolidaysTable);
      logger.d(_tag, '节日表创建成功');

      // 创建用户设置表
      await db.execute(DatabaseSchema.createUserSettingsTable);
      logger.d(_tag, '用户设置表创建成功');

      // 创建联系人表
      await db.execute(DatabaseSchema.createContactsTable);
      logger.d(_tag, '联系人表创建成功');

      // 创建提醒事件表
      await db.execute(DatabaseSchema.createReminderEventsTable);
      logger.d(_tag, '提醒事件表创建成功');

      // 创建同步状态表
      await db.execute(DatabaseSchema.createSyncStatusTable);
      logger.d(_tag, '同步状态表创建成功');

      // 创建应用设置表
      await db.execute(DatabaseSchema.createAppSettingsTable);
      logger.d(_tag, '应用设置表创建成功');

      // 创建索引
      for (final indexSql in DatabaseSchema.createIndexes) {
        await db.execute(indexSql);
      }
      logger.d(_tag, '索引创建成功');

      logger.i(_tag, '所有数据库表创建成功');
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'createDatabase', context: 'version: $version');
      rethrow;
    }
  }

  // 升级数据库
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    try {
      logger.i(_tag, '正在升级数据库: $oldVersion -> $newVersion');

      // 获取升级脚本
      final upgradeScripts = DatabaseSchema.getUpgradeScripts(oldVersion, newVersion);

      if (upgradeScripts.isEmpty) {
        logger.i(_tag, '没有需要执行的升级脚本');
        return;
      }

      // 执行升级脚本
      for (int i = 0; i < upgradeScripts.length; i++) {
        final script = upgradeScripts[i];
        logger.d(_tag, '执行升级脚本 ${i + 1}/${upgradeScripts.length}');
        await db.execute(script);
      }

      logger.i(_tag, '数据库升级成功');
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        'upgradeDatabase',
        context: 'oldVersion: $oldVersion, newVersion: $newVersion'
      );
      rethrow;
    }
  }

  // 检查数据库是否已初始化
  Future<void> _checkInitialized() async {
    if (!_initialized || _db == null) {
      final error = Exception('数据库未初始化');
      final stackTrace = StackTrace.current;
      DatabaseErrorHandler.handleError(error, stackTrace, 'checkInitialized');
      throw error;
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
      // 检查用户设置表是否为空
      final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM ${DatabaseSchema.userSettingsTable}')
      ) ?? 0;

      final isFirst = count == 0;
      logger.d(_tag, '检查是否首次启动: $isFirst');
      return isFirst;
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'isFirstLaunch');
      rethrow;
    }
  }

  @override
  Future<void> setFirstLaunch(bool value) async {
    // 这个方法在SQLite中不需要实现，因为我们通过检查表是否为空来判断是否是首次启动
    logger.d(_tag, '设置首次启动状态: $value (在SQLite中不需要实现)');
    return;
  }

  @override
  Future<int> getDatabaseVersion() async {
    await _checkInitialized();

    try {
      final result = await _db!.rawQuery('PRAGMA user_version');
      final version = result.first['user_version'] as int;
      logger.d(_tag, '获取数据库版本: $version');
      return version;
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'getDatabaseVersion');
      rethrow;
    }
  }

  @override
  Future<void> setDatabaseVersion(int version) async {
    await _checkInitialized();

    try {
      logger.i(_tag, '设置数据库版本: $version');
      await _db!.execute('PRAGMA user_version = $version');
    } catch (e, stackTrace) {
      DatabaseErrorHandler.handleError(e, stackTrace, 'setDatabaseVersion', context: 'version: $version');
      rethrow;
    }
  }

  // ==================== 节日相关操作 ====================

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _checkInitialized();

    try {
      // 将Holiday对象转换为Map
      final Map<String, dynamic> holidayMap = holiday.toMap();

      // 检查节日是否已存在
      final existingHoliday = await getHolidayById(holiday.id);

      if (existingHoliday != null) {
        // 更新现有节日
        await _db!.update(
          DatabaseSchema.holidaysTable,
          holidayMap,
          where: 'id = ?',
          whereArgs: [holiday.id],
        );
        logger.i(_tag, '更新节日: ${holiday.id}');
      } else {
        // 插入新节日
        await _db!.insert(
          DatabaseSchema.holidaysTable,
          holidayMap,
        );
        logger.i(_tag, '插入节日: ${holiday.id}');
      }
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '保存节日',
        context: 'ID: ${holiday.id}, 名称: ${holiday.getLocalizedName("zh")}'
      );
      rethrow;
    }
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _checkInitialized();

    try {
      // 设置批量处理大小
      const int batchSize = 100;

      // 计算批次数量
      final int batchCount = (holidays.length / batchSize).ceil();

      // 分批处理
      for (int i = 0; i < batchCount; i++) {
        // 计算当前批次的起始和结束索引
        final int start = i * batchSize;
        final int end = (i + 1) * batchSize < holidays.length ? (i + 1) * batchSize : holidays.length;

        // 获取当前批次的节日
        final List<Holiday> batch = holidays.sublist(start, end);

        // 开始事务
        await _db!.transaction((txn) async {
          for (final holiday in batch) {
            // 将Holiday对象转换为Map
            final Map<String, dynamic> holidayMap = holiday.toMap();

            // 检查节日是否已存在
            final existingHoliday = await txn.query(
              DatabaseSchema.holidaysTable,
              where: 'id = ?',
              whereArgs: [holiday.id],
              limit: 1,
            );

            if (existingHoliday.isNotEmpty) {
              // 更新现有节日
              await txn.update(
                DatabaseSchema.holidaysTable,
                holidayMap,
                where: 'id = ?',
                whereArgs: [holiday.id],
              );
            } else {
              // 插入新节日
              await txn.insert(
                DatabaseSchema.holidaysTable,
                holidayMap,
              );
            }
          }
        });

        logger.i(_tag, '批量保存节日进度: $end/${holidays.length}');
      }

      logger.i(_tag, '批量保存 ${holidays.length} 个节日成功');
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '批量保存节日',
        context: '节日数量: ${holidays.length}'
      );
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    await _checkInitialized();

    try {
      // 查询所有节日
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.holidaysTable,
      );

      // 将查询结果转换为Holiday对象列表
      final List<Holiday> holidays = maps.map((map) => Holiday.fromMap(map)).toList();

      logger.i(_tag, '获取所有节日: ${holidays.length} 个');
      return holidays;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取所有节日'
      );
      rethrow;
    }
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    await _checkInitialized();

    try {
      // 查询指定ID的节日
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.holidaysTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      // 如果没有找到节日，返回null
      if (maps.isEmpty) {
        return null;
      }

      // 将查询结果转换为Holiday对象
      return Holiday.fromMap(maps.first);
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取节日',
        context: 'ID: $id'
      );
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      // 使用SQL的LIKE操作符查询包含指定地区的节日
      // 注意：这里假设regions字段存储的是JSON数组或逗号分隔的字符串
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.holidaysTable}
        WHERE regions LIKE ? OR regions LIKE ? OR regions = 'ALL'
      ''', ['%"$region"%', '%,$region,%']);

      // 将查询结果转换为Holiday对象列表
      final List<Holiday> holidays = maps.map((map) => Holiday.fromMap(map)).toList();

      logger.i(_tag, '获取地区 $region 的节日: ${holidays.length} 个');
      return holidays;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取地区节日',
        context: '地区: $region, 语言: $languageCode'
      );
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    await _checkInitialized();

    try {
      // 查询指定类型的节日
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.holidaysTable,
        where: 'type_id = ?',
        whereArgs: [type.index],
      );

      // 将查询结果转换为Holiday对象列表
      final List<Holiday> holidays = maps.map((map) => Holiday.fromMap(map)).toList();

      logger.i(_tag, '获取类型 ${type.toString()} 的节日: ${holidays.length} 个');
      return holidays;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取类型节日',
        context: '类型: ${type.toString()}'
      );
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      // 转换为小写以进行不区分大小写的搜索
      final String lowerQuery = query.toLowerCase();

      // 使用更精确的SQL查询，减少内存筛选的需要
      // 1. 对于JSON字段，使用JSON_EXTRACT函数提取特定语言的值
      // 2. 使用LOWER函数进行不区分大小写的比较
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.holidaysTable}
        WHERE
          LOWER(name) LIKE ? OR
          LOWER(description) LIKE ? OR
          LOWER(names) LIKE ? OR
          LOWER(descriptions) LIKE ? OR
          (names IS NOT NULL AND names LIKE ?) OR
          (descriptions IS NOT NULL AND descriptions LIKE ?)
        ORDER BY
          CASE
            WHEN LOWER(name) LIKE ? THEN 1
            WHEN names LIKE ? THEN 2
            ELSE 3
          END
      ''', [
        '%$lowerQuery%',                  // name LIKE
        '%$lowerQuery%',                  // description LIKE
        '%"$languageCode"%$lowerQuery%',  // names LIKE with languageCode
        '%"$languageCode"%$lowerQuery%',  // descriptions LIKE with languageCode
        '%"$languageCode":"$lowerQuery%', // names contains exact languageCode key
        '%"$languageCode":"$lowerQuery%', // descriptions contains exact languageCode key
        '%$lowerQuery%',                  // For ORDER BY: name LIKE
        '%"$languageCode"%$lowerQuery%'   // For ORDER BY: names LIKE with languageCode
      ]);

      // 将查询结果转换为Holiday对象列表
      final List<Holiday> holidays = maps.map((map) => Holiday.fromMap(map)).toList();

      logger.i(_tag, '搜索节日 "$query": ${holidays.length} 个');
      return holidays;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '搜索节日',
        context: '查询: $query, 语言: $languageCode'
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _checkInitialized();

    try {
      // 删除指定ID的节日
      await _db!.delete(
        DatabaseSchema.holidaysTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      logger.i(_tag, '删除节日: $id');
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '删除节日',
        context: 'ID: $id'
      );
      rethrow;
    }
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _checkInitialized();

    try {
      // 更新指定ID的节日重要性
      await _db!.update(
        DatabaseSchema.holidaysTable,
        {'user_importance': importance, 'last_modified': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      logger.i(_tag, '更新节日重要性: $id -> $importance');
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '更新节日重要性',
        context: 'ID: $id, 重要性: $importance'
      );
      rethrow;
    }
  }

  // ==================== 联系人相关操作 ====================

  @override
  Future<void> saveContact(ContactModel contact) async {
    await _checkInitialized();

    try {
      // 将联系人对象转换为Map
      final Map<String, dynamic> contactMap = {
        'id': contact.id,
        'name': contact.name,
        'relation_type': contact.relationType.index,
        'specific_relation': contact.specificRelation,
        'phone_number': contact.phoneNumber,
        'email': contact.email,
        'avatar_url': contact.avatarUrl,
        'birthday': contact.birthday?.toIso8601String(),
        'is_birthday_lunar': contact.isBirthdayLunar ? 1 : 0,
        'additional_info': contact.additionalInfo != null ? jsonEncode(contact.additionalInfo) : null,
        'associated_holiday_ids': contact.associatedHolidayIds != null ? jsonEncode(contact.associatedHolidayIds) : null,
        'names': contact.names != null ? jsonEncode(contact.names) : null,
        'specific_relations': contact.specificRelations != null ? jsonEncode(contact.specificRelations) : null,
        'created_at': contact.createdAt.toIso8601String(),
        'last_modified': contact.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      // 检查联系人是否已存在
      final existingContact = await getContactById(contact.id);

      if (existingContact != null) {
        // 更新现有联系人
        await _db!.update(
          DatabaseSchema.contactsTable,
          contactMap,
          where: 'id = ?',
          whereArgs: [contact.id],
        );
        debugPrint('更新联系人: ${contact.id}');
      } else {
        // 插入新联系人
        await _db!.insert(
          DatabaseSchema.contactsTable,
          contactMap,
        );
        debugPrint('插入联系人: ${contact.id}');
      }
    } catch (e) {
      debugPrint('保存联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    await _checkInitialized();

    try {
      // 设置批量处理大小
      const int batchSize = 50;

      // 计算批次数量
      final int batchCount = (contacts.length / batchSize).ceil();

      // 分批处理
      for (int i = 0; i < batchCount; i++) {
        // 计算当前批次的起始和结束索引
        final int start = i * batchSize;
        final int end = (i + 1) * batchSize < contacts.length ? (i + 1) * batchSize : contacts.length;

        // 获取当前批次的联系人
        final List<ContactModel> batch = contacts.sublist(start, end);

        // 开始事务
        await _db!.transaction((txn) async {
          for (final contact in batch) {
            // 将联系人对象转换为Map
            final Map<String, dynamic> contactMap = {
              'id': contact.id,
              'name': contact.name,
              'relation_type': contact.relationType.index,
              'specific_relation': contact.specificRelation,
              'phone_number': contact.phoneNumber,
              'email': contact.email,
              'avatar_url': contact.avatarUrl,
              'birthday': contact.birthday?.toIso8601String(),
              'is_birthday_lunar': contact.isBirthdayLunar ? 1 : 0,
              'additional_info': contact.additionalInfo != null ? jsonEncode(contact.additionalInfo) : null,
              'associated_holiday_ids': contact.associatedHolidayIds != null ? jsonEncode(contact.associatedHolidayIds) : null,
              'names': contact.names != null ? jsonEncode(contact.names) : null,
              'specific_relations': contact.specificRelations != null ? jsonEncode(contact.specificRelations) : null,
              'created_at': contact.createdAt.toIso8601String(),
              'last_modified': contact.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
            };

            // 检查联系人是否已存在
            final existingContact = await txn.query(
              DatabaseSchema.contactsTable,
              where: 'id = ?',
              whereArgs: [contact.id],
              limit: 1,
            );

            if (existingContact.isNotEmpty) {
              // 更新现有联系人
              await txn.update(
                DatabaseSchema.contactsTable,
                contactMap,
                where: 'id = ?',
                whereArgs: [contact.id],
              );
            } else {
              // 插入新联系人
              await txn.insert(
                DatabaseSchema.contactsTable,
                contactMap,
              );
            }
          }
        });

        debugPrint('批量保存联系人进度: $end/${contacts.length}');
      }

      debugPrint('批量保存 ${contacts.length} 个联系人成功');
    } catch (e) {
      debugPrint('批量保存联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    await _checkInitialized();

    try {
      // 查询所有联系人
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.contactsTable,
      );

      // 将查询结果转换为ContactModel对象列表
      final List<ContactModel> contacts = maps.map((map) => _mapToContact(map)).toList();

      debugPrint('获取所有联系人: ${contacts.length} 个');
      return contacts;
    } catch (e) {
      debugPrint('获取所有联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    await _checkInitialized();

    try {
      // 查询指定ID的联系人
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.contactsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      // 如果没有找到联系人，返回null
      if (maps.isEmpty) {
        return null;
      }

      // 将查询结果转换为ContactModel对象
      return _mapToContact(maps.first);
    } catch (e) {
      debugPrint('获取联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    await _checkInitialized();

    try {
      // 查询指定关系类型的联系人
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.contactsTable,
        where: 'relation_type = ?',
        whereArgs: [relationType.index],
      );

      // 将查询结果转换为ContactModel对象列表
      final List<ContactModel> contacts = maps.map((map) => _mapToContact(map)).toList();

      debugPrint('获取关系类型 ${relationType.toString()} 的联系人: ${contacts.length} 个');
      return contacts;
    } catch (e) {
      debugPrint('获取关系类型联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    await _checkInitialized();

    try {
      // 转换为小写以进行不区分大小写的搜索
      final String lowerQuery = query.toLowerCase();

      // 使用SQL的LIKE操作符进行搜索
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.contactsTable}
        WHERE
          name LIKE ? OR
          specific_relation LIKE ? OR
          phone_number LIKE ? OR
          email LIKE ? OR
          names LIKE ? OR
          specific_relations LIKE ?
      ''', [
        '%$lowerQuery%',
        '%$lowerQuery%',
        '%$lowerQuery%',
        '%$lowerQuery%',
        '%$lowerQuery%',
        '%$lowerQuery%'
      ]);

      // 将查询结果转换为ContactModel对象列表
      final List<ContactModel> contacts = maps.map((map) => _mapToContact(map)).toList();

      debugPrint('搜索联系人 "$query": ${contacts.length} 个');
      return contacts;
    } catch (e) {
      debugPrint('搜索联系人失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await _checkInitialized();

    try {
      // 删除指定ID的联系人
      await _db!.delete(
        DatabaseSchema.contactsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('删除联系人: $id');
    } catch (e) {
      debugPrint('删除联系人失败: $e');
      rethrow;
    }
  }

  // 将Map转换为ContactModel对象
  ContactModel _mapToContact(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as String,
      name: map['name'] as String,
      relationType: RelationType.values[map['relation_type'] as int],
      specificRelation: map['specific_relation'] as String?,
      phoneNumber: map['phone_number'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      birthday: map['birthday'] != null ? DateTime.parse(map['birthday'] as String) : null,
      isBirthdayLunar: map['is_birthday_lunar'] == 1,
      additionalInfo: map['additional_info'] != null
          ? Map<String, String>.from(jsonDecode(map['additional_info'] as String))
          : null,
      associatedHolidayIds: map['associated_holiday_ids'] != null
          ? List<String>.from(jsonDecode(map['associated_holiday_ids'] as String))
          : null,
      names: map['names'] != null
          ? Map<String, String>.from(jsonDecode(map['names'] as String))
          : null,
      specificRelations: map['specific_relations'] != null
          ? Map<String, String>.from(jsonDecode(map['specific_relations'] as String))
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
    );
  }

  // ==================== 提醒事件相关操作 ====================

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    await _checkInitialized();

    try {
      // 将提醒事件对象转换为Map
      final Map<String, dynamic> eventMap = {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'type': event.type.index,
        'due_date': event.dueDate?.toIso8601String(),
        'is_all_day': event.isAllDay ? 1 : 0,
        'is_lunar_date': event.isLunarDate ? 1 : 0,
        'status': event.status.index,
        'is_completed': event.isCompleted ? 1 : 0,
        'completed_at': event.completedAt?.toIso8601String(),
        'is_repeating': event.isRepeating ? 1 : 0,
        'repeat_rule': event.repeatRule,
        'repeat_until': event.repeatUntil?.toIso8601String(),
        'reminder_times': event.reminderTimes != null ? jsonEncode(event.reminderTimes) : null,
        'contact_id': event.contactId,
        'holiday_id': event.holidayId,
        'location': event.location,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'tags': event.tags != null ? jsonEncode(event.tags) : null,
        'category': event.category,
        'titles': event.titles != null ? jsonEncode(event.titles) : null,
        'descriptions': event.descriptions != null ? jsonEncode(event.descriptions) : null,
        'ai_generated_description': event.aiGeneratedDescription,
        'ai_generated_greetings': event.aiGeneratedGreetings,
        'ai_generated_gift_suggestions': event.aiGeneratedGiftSuggestions,
        'importance': event.importance,
        'custom_color': event.customColor,
        'custom_icon': event.customIcon,
        'is_shared': event.isShared ? 1 : 0,
        'shared_with': event.sharedWith != null ? jsonEncode(event.sharedWith) : null,
        'last_synced': event.lastSynced?.toIso8601String(),
        'is_sync_conflict': event.isSyncConflict ? 1 : 0,
        'created_at': event.createdAt.toIso8601String(),
        'last_modified': event.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      // 检查提醒事件是否已存在
      final existingEvent = await getReminderEventById(event.id);

      if (existingEvent != null) {
        // 更新现有提醒事件
        await _db!.update(
          DatabaseSchema.reminderEventsTable,
          eventMap,
          where: 'id = ?',
          whereArgs: [event.id],
        );
        debugPrint('更新提醒事件: ${event.id}');
      } else {
        // 插入新提醒事件
        await _db!.insert(
          DatabaseSchema.reminderEventsTable,
          eventMap,
        );
        debugPrint('插入提醒事件: ${event.id}');
      }
    } catch (e) {
      debugPrint('保存提醒事件失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    await _checkInitialized();

    try {
      // 设置批量处理大小
      const int batchSize = 50;

      // 计算批次数量
      final int batchCount = (events.length / batchSize).ceil();

      // 分批处理
      for (int i = 0; i < batchCount; i++) {
        // 计算当前批次的起始和结束索引
        final int start = i * batchSize;
        final int end = (i + 1) * batchSize < events.length ? (i + 1) * batchSize : events.length;

        // 获取当前批次的提醒事件
        final List<ReminderEventModel> batch = events.sublist(start, end);

        // 开始事务
        await _db!.transaction((txn) async {
          for (final event in batch) {
            // 将提醒事件对象转换为Map
            final Map<String, dynamic> eventMap = {
              'id': event.id,
              'title': event.title,
              'description': event.description,
              'type': event.type.index,
              'due_date': event.dueDate?.toIso8601String(),
              'is_all_day': event.isAllDay ? 1 : 0,
              'is_lunar_date': event.isLunarDate ? 1 : 0,
              'status': event.status.index,
              'is_completed': event.isCompleted ? 1 : 0,
              'completed_at': event.completedAt?.toIso8601String(),
              'is_repeating': event.isRepeating ? 1 : 0,
              'repeat_rule': event.repeatRule,
              'repeat_until': event.repeatUntil?.toIso8601String(),
              'reminder_times': event.reminderTimes != null ? jsonEncode(event.reminderTimes) : null,
              'contact_id': event.contactId,
              'holiday_id': event.holidayId,
              'location': event.location,
              'latitude': event.latitude,
              'longitude': event.longitude,
              'tags': event.tags != null ? jsonEncode(event.tags) : null,
              'category': event.category,
              'titles': event.titles != null ? jsonEncode(event.titles) : null,
              'descriptions': event.descriptions != null ? jsonEncode(event.descriptions) : null,
              'ai_generated_description': event.aiGeneratedDescription,
              'ai_generated_greetings': event.aiGeneratedGreetings != null ? jsonEncode(event.aiGeneratedGreetings) : null,
              'ai_generated_gift_suggestions': event.aiGeneratedGiftSuggestions != null ? jsonEncode(event.aiGeneratedGiftSuggestions) : null,
              'importance': event.importance,
              'custom_color': event.customColor,
              'custom_icon': event.customIcon,
              'is_shared': event.isShared ? 1 : 0,
              'shared_with': event.sharedWith != null ? jsonEncode(event.sharedWith) : null,
              'last_synced': event.lastSynced?.toIso8601String(),
              'is_sync_conflict': event.isSyncConflict ? 1 : 0,
              'created_at': event.createdAt.toIso8601String(),
              'last_modified': event.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
            };

            // 检查提醒事件是否已存在
            final existingEvent = await txn.query(
              DatabaseSchema.reminderEventsTable,
              where: 'id = ?',
              whereArgs: [event.id],
              limit: 1,
            );

            if (existingEvent.isNotEmpty) {
              // 更新现有提醒事件
              await txn.update(
                DatabaseSchema.reminderEventsTable,
                eventMap,
                where: 'id = ?',
                whereArgs: [event.id],
              );
            } else {
              // 插入新提醒事件
              await txn.insert(
                DatabaseSchema.reminderEventsTable,
                eventMap,
              );
            }
          }
        });

        debugPrint('批量保存提醒事件进度: $end/${events.length}');
      }

      debugPrint('批量保存 ${events.length} 个提醒事件成功');
    } catch (e) {
      debugPrint('批量保存提醒事件失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    await _checkInitialized();

    try {
      // 获取用户设置中的过期事件保留天数
      int retentionDays = 30; // 默认值
      try {
        final settings = await getUserSettings();
        if (settings != null && settings.expiredEventRetentionDays > 0) {
          retentionDays = settings.expiredEventRetentionDays;
        }
      } catch (e) {
        logger.w(_tag, '获取用户设置失败，使用默认过期事件保留天数: $e');
      }

      // 计算最早的过期日期
      final earliestDate = DateTime.now().subtract(Duration(days: retentionDays));

      // 使用优化的SQL查询，添加软删除条件和时间范围限制
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.reminderEventsTable,
        where: 'is_deleted = 0 AND (due_date IS NULL OR due_date > ?)',
        whereArgs: [earliestDate.toIso8601String()],
        orderBy: 'due_date ASC',
        limit: 1000, // 限制返回的记录数，避免内存问题
      );

      // 将查询结果转换为ReminderEventModel对象列表
      final List<ReminderEventModel> events = maps.map((map) => _mapToReminderEvent(map)).toList();

      logger.i(_tag, '获取所有提醒事件: ${events.length} 个');
      return events;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取所有提醒事件'
      );
      rethrow;
    }
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    await _checkInitialized();

    try {
      // 查询指定ID的提醒事件，不考虑软删除状态
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.reminderEventsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      // 如果没有找到提醒事件，返回null
      if (maps.isEmpty) {
        return null;
      }

      // 将查询结果转换为ReminderEventModel对象
      return _mapToReminderEvent(maps.first);
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取提醒事件',
        context: 'ID: $id'
      );
      rethrow;
    }
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    await _checkInitialized();

    try {
      // 获取当前日期
      final now = DateTime.now();

      // 计算截止日期
      final endDate = now.add(Duration(days: days));

      // 使用优化的SQL查询，利用复合索引和软删除条件
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.reminderEventsTable}
        WHERE
          due_date IS NOT NULL AND
          due_date > ? AND
          due_date < ? AND
          is_completed = 0 AND
          is_deleted = 0
        ORDER BY
          importance DESC,
          due_date ASC
        LIMIT 100
      ''', [now.toIso8601String(), endDate.toIso8601String()]);

      // 将查询结果转换为ReminderEventModel对象列表
      final List<ReminderEventModel> upcomingEvents = maps.map((map) => _mapToReminderEvent(map)).toList();

      logger.i(_tag, '获取即将到来的提醒事件: ${upcomingEvents.length} 个');
      return upcomingEvents;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取即将到来的提醒事件',
        context: '天数: $days'
      );
      rethrow;
    }
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    await _checkInitialized();

    try {
      // 获取当前日期
      final now = DateTime.now();

      // 获取用户设置中的过期事件保留天数
      int retentionDays = 30; // 默认值
      try {
        final settings = await getUserSettings();
        if (settings != null && settings.expiredEventRetentionDays > 0) {
          retentionDays = settings.expiredEventRetentionDays;
        }
      } catch (e) {
        logger.w(_tag, '获取用户设置失败，使用默认过期事件保留天数: $e');
      }

      // 计算最早的过期日期
      final earliestDate = now.subtract(Duration(days: retentionDays));

      // 使用优化的SQL查询，利用复合索引和软删除条件，并限制时间范围
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.reminderEventsTable}
        WHERE
          due_date IS NOT NULL AND
          due_date < ? AND
          due_date > ? AND
          is_completed = 0 AND
          is_deleted = 0
        ORDER BY
          importance DESC,
          due_date DESC
        LIMIT 100
      ''', [now.toIso8601String(), earliestDate.toIso8601String()]);

      // 将查询结果转换为ReminderEventModel对象列表
      final List<ReminderEventModel> expiredEvents = maps.map((map) => _mapToReminderEvent(map)).toList();

      logger.i(_tag, '获取已过期的提醒事件: ${expiredEvents.length} 个');
      return expiredEvents;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取已过期的提醒事件'
      );
      rethrow;
    }
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    await _checkInitialized();

    try {
      // 使用优化的SQL查询，添加软删除条件和结果排序
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.reminderEventsTable,
        where: 'type = ? AND is_deleted = 0',
        whereArgs: [type.index],
        orderBy: 'importance DESC, due_date ASC',
        limit: 100,
      );

      // 将查询结果转换为ReminderEventModel对象列表
      final List<ReminderEventModel> events = maps.map((map) => _mapToReminderEvent(map)).toList();

      logger.i(_tag, '获取类型 ${type.toString()} 的提醒事件: ${events.length} 个');
      return events;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '获取类型提醒事件',
        context: '类型: ${type.toString()}'
      );
      rethrow;
    }
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    await _checkInitialized();

    try {
      // 转换为小写以进行不区分大小写的搜索
      final String lowerQuery = query.toLowerCase();

      // 使用优化的SQL查询，添加软删除条件和结果限制
      final List<Map<String, dynamic>> maps = await _db!.rawQuery('''
        SELECT * FROM ${DatabaseSchema.reminderEventsTable}
        WHERE
          is_deleted = 0 AND
          (
            LOWER(title) LIKE ? OR
            LOWER(description) LIKE ? OR
            LOWER(location) LIKE ? OR
            LOWER(category) LIKE ? OR
            tags LIKE ? OR
            titles LIKE ? OR
            descriptions LIKE ? OR
            ai_generated_description LIKE ?
          )
        ORDER BY
          CASE
            WHEN LOWER(title) LIKE ? THEN 1
            WHEN LOWER(description) LIKE ? THEN 2
            ELSE 3
          END,
          importance DESC,
          due_date ASC
        LIMIT 50
      ''', [
        '%$lowerQuery%',  // title
        '%$lowerQuery%',  // description
        '%$lowerQuery%',  // location
        '%$lowerQuery%',  // category
        '%$lowerQuery%',  // tags
        '%$lowerQuery%',  // titles
        '%$lowerQuery%',  // descriptions
        '%$lowerQuery%',  // ai_generated_description
        '%$lowerQuery%',  // For ORDER BY: title
        '%$lowerQuery%'   // For ORDER BY: description
      ]);

      // 将查询结果转换为ReminderEventModel对象列表
      final List<ReminderEventModel> matchedEvents = maps.map((map) => _mapToReminderEvent(map)).toList();

      logger.i(_tag, '搜索提醒事件 "$query": ${matchedEvents.length} 个');
      return matchedEvents;
    } catch (e, stackTrace) {
      // 使用错误处理类处理错误
      DatabaseErrorHandler.handleError(
        e,
        stackTrace,
        '搜索提醒事件',
        context: '查询: $query'
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteReminderEvent(String id) async {
    await _checkInitialized();

    try {
      // 删除指定ID的提醒事件
      await _db!.delete(
        DatabaseSchema.reminderEventsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('删除提醒事件: $id');
    } catch (e) {
      debugPrint('删除提醒事件失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _checkInitialized();

    try {
      // 更新指定ID的提醒事件状态
      await _db!.update(
        DatabaseSchema.reminderEventsTable,
        {
          'status': status.index,
          'last_modified': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('更新提醒事件状态: $id -> ${status.toString()}');
    } catch (e) {
      debugPrint('更新提醒事件状态失败: $e');
      rethrow;
    }
  }

  // 将Map转换为ReminderEventModel对象
  ReminderEventModel _mapToReminderEvent(Map<String, dynamic> map) {
    return ReminderEventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: ReminderEventType.values[map['type'] as int],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isAllDay: map['is_all_day'] == 1,
      isLunarDate: map['is_lunar_date'] == 1,
      status: ReminderStatus.values[map['status'] as int],
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      isRepeating: map['is_repeating'] == 1,
      repeatRule: map['repeat_rule'] as String?,
      repeatUntil: map['repeat_until'] != null ? DateTime.parse(map['repeat_until'] as String) : null,
      reminderTimes: map['reminder_times'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['reminder_times'] as String))
          : null,
      contactId: map['contact_id'] as String?,
      holidayId: map['holiday_id'] as String?,
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : null,
      category: map['category'] as String?,
      titles: map['titles'] != null
          ? Map<String, String>.from(jsonDecode(map['titles'] as String))
          : null,
      descriptions: map['descriptions'] != null
          ? Map<String, String>.from(jsonDecode(map['descriptions'] as String))
          : null,
      aiGeneratedDescription: map['ai_generated_description'] as String?,
      aiGeneratedGreetings: map['ai_generated_greetings'] != null
          ? List<String>.from(jsonDecode(map['ai_generated_greetings'] as String))
          : null,
      aiGeneratedGiftSuggestions: map['ai_generated_gift_suggestions'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['ai_generated_gift_suggestions'] as String))
          : null,
      importance: map['importance'] as int? ?? 0,
      customColor: map['custom_color'] as String?,
      customIcon: map['custom_icon'] as String?,
      isShared: map['is_shared'] == 1,
      sharedWith: map['shared_with'] != null
          ? List<String>.from(jsonDecode(map['shared_with'] as String))
          : null,
      lastSynced: map['last_synced'] != null ? DateTime.parse(map['last_synced'] as String) : null,
      isSyncConflict: map['is_sync_conflict'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
    );
  }

  // ==================== 用户设置相关操作 ====================

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _checkInitialized();

    try {
      // 生成唯一ID
      final String settingsId = settings.key?.toString() ?? const Uuid().v4();

      // 将用户设置对象转换为Map
      final Map<String, dynamic> settingsMap = {
        'id': settingsId,
        'user_id': settings.userId,
        'nickname': settings.nickname,
        'avatar_url': settings.avatarUrl,
        'language_code': settings.languageCode,
        'country_code': settings.countryCode,
        'show_lunar_calendar': settings.showLunarCalendar ? 1 : 0,
        'theme_mode': settings.themeMode.index,
        'primary_color': settings.primaryColor,
        'background_image_url': settings.backgroundImageUrl,
        'enable_notifications': settings.enableNotifications ? 1 : 0,
        'default_reminder_times': jsonEncode(settings.defaultReminderTimes),
        'enable_sound': settings.enableSound ? 1 : 0,
        'enable_vibration': settings.enableVibration ? 1 : 0,
        'enable_cloud_sync': settings.enableCloudSync ? 1 : 0,
        'sync_frequency_hours': settings.syncFrequencyHours,
        'last_sync_time': settings.lastSyncTime?.toIso8601String(),
        'auto_backup': settings.autoBackup ? 1 : 0,
        'backup_frequency_days': settings.backupFrequencyDays,
        'last_backup_time': settings.lastBackupTime?.toIso8601String(),
        'show_expired_events': settings.showExpiredEvents ? 1 : 0,
        'expired_event_retention_days': settings.expiredEventRetentionDays,
        'enable_ai_features': settings.enableAIFeatures ? 1 : 0,
        'enabled_ai_features': jsonEncode(settings.enabledAIFeatures),
        'created_at': DateTime.now().toIso8601String(),
        'last_modified': settings.lastModified.toIso8601String(),
      };

      // 检查用户设置是否已存在
      final existingSettings = await getUserSettings();

      if (existingSettings != null) {
        // 更新现有用户设置
        await _db!.update(
          DatabaseSchema.userSettingsTable,
          settingsMap,
          where: 'id = ?',
          whereArgs: [settingsId],
        );
        debugPrint('更新用户设置: $settingsId');
      } else {
        // 插入新用户设置
        await _db!.insert(
          DatabaseSchema.userSettingsTable,
          settingsMap,
        );
        debugPrint('插入用户设置: $settingsId');
      }
    } catch (e) {
      debugPrint('保存用户设置失败: $e');
      rethrow;
    }
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    await _checkInitialized();

    try {
      // 查询用户设置
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.userSettingsTable,
        limit: 1,
      );

      // 如果没有找到用户设置，返回null
      if (maps.isEmpty) {
        return null;
      }

      // 将查询结果转换为UserSettingsModel对象
      return _mapToUserSettings(maps.first);
    } catch (e) {
      debugPrint('获取用户设置失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _checkInitialized();

    try {
      // 获取当前用户设置
      final currentSettings = await getUserSettings();

      if (currentSettings == null) {
        throw Exception('用户设置不存在');
      }

      // 添加最后修改时间
      updates['last_modified'] = DateTime.now().toIso8601String();

      // 获取设置ID
      final String settingsId = currentSettings.key?.toString() ??
          (await _db!.query(
            DatabaseSchema.userSettingsTable,
            columns: ['id'],
            limit: 1,
          )).first['id'] as String;

      // 更新用户设置
      await _db!.update(
        DatabaseSchema.userSettingsTable,
        updates,
        where: 'id = ?',
        whereArgs: [settingsId],
      );

      debugPrint('更新用户设置: $settingsId');
    } catch (e) {
      debugPrint('更新用户设置失败: $e');
      rethrow;
    }
  }

  // 将Map转换为UserSettingsModel对象
  UserSettingsModel _mapToUserSettings(Map<String, dynamic> map) {
    // 解析默认提醒时间
    Map<String, ReminderAdvanceTime> reminderTimes = {};
    if (map['default_reminder_times'] != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(map['default_reminder_times'] as String);
      jsonMap.forEach((key, value) {
        reminderTimes[key] = _parseReminderAdvanceTime(value);
      });
    }

    // 解析启用的AI功能
    Map<String, bool> aiFeatures = {};
    if (map['enabled_ai_features'] != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(map['enabled_ai_features'] as String);
      jsonMap.forEach((key, value) {
        aiFeatures[key] = value as bool;
      });
    }

    return UserSettingsModel(
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String,
      avatarUrl: map['avatar_url'] as String?,
      languageCode: map['language_code'] as String,
      countryCode: map['country_code'] as String?,
      showLunarCalendar: map['show_lunar_calendar'] == 1,
      themeMode: _parseAppThemeMode(map['theme_mode'] as int),
      primaryColor: map['primary_color'] as String?,
      backgroundImageUrl: map['background_image_url'] as String?,
      enableNotifications: map['enable_notifications'] == 1,
      defaultReminderTimes: reminderTimes,
      enableSound: map['enable_sound'] == 1,
      enableVibration: map['enable_vibration'] == 1,
      enableCloudSync: map['enable_cloud_sync'] == 1,
      syncFrequencyHours: map['sync_frequency_hours'] as int,
      lastSyncTime: map['last_sync_time'] != null ? DateTime.parse(map['last_sync_time'] as String) : null,
      autoBackup: map['auto_backup'] == 1,
      backupFrequencyDays: map['backup_frequency_days'] as int,
      lastBackupTime: map['last_backup_time'] != null ? DateTime.parse(map['last_backup_time'] as String) : null,
      showExpiredEvents: map['show_expired_events'] == 1,
      expiredEventRetentionDays: map['expired_event_retention_days'] as int,
      enableAIFeatures: map['enable_ai_features'] == 1,
      enabledAIFeatures: aiFeatures,
      lastModified: map['last_modified'] != null ? DateTime.parse(map['last_modified'] as String) : DateTime.now(),
    );
  }

  // 解析AppThemeMode
  AppThemeMode _parseAppThemeMode(int index) {
    if (index >= 0 && index < AppThemeMode.values.length) {
      return AppThemeMode.values[index];
    }
    return AppThemeMode.system;
  }

  // 解析ReminderAdvanceTime
  ReminderAdvanceTime _parseReminderAdvanceTime(dynamic value) {
    if (value is int && value >= 0 && value < ReminderAdvanceTime.values.length) {
      return ReminderAdvanceTime.values[value];
    } else if (value is String) {
      try {
        final index = ReminderAdvanceTime.values.indexWhere(
          (e) => e.toString().split('.').last == value,
        );
        if (index >= 0) {
          return ReminderAdvanceTime.values[index];
        }
      } catch (_) {}
    }
    return ReminderAdvanceTime.oneDay;
  }

  // ==================== 数据同步相关操作 ====================

  @override
  Future<DateTime?> getLastSyncTime() async {
    await _checkInitialized();

    try {
      // 查询用户设置
      final settings = await getUserSettings();

      // 返回最后同步时间
      return settings?.lastSyncTime;
    } catch (e) {
      debugPrint('获取最后同步时间失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastSyncTime(DateTime time) async {
    await _checkInitialized();

    try {
      // 更新用户设置
      await updateUserSettings({
        'last_sync_time': time.toIso8601String(),
      });

      debugPrint('更新最后同步时间: ${time.toIso8601String()}');
    } catch (e) {
      debugPrint('更新最后同步时间失败: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getModifiedData(DateTime? since) async {
    await _checkInitialized();

    try {
      final Map<String, dynamic> result = {
        'holidays': <Map<String, dynamic>>[],
        'contacts': <Map<String, dynamic>>[],
        'reminder_events': <Map<String, dynamic>>[],
        'user_settings': null,
      };

      // 如果没有指定时间，返回所有数据
      if (since == null) {
        // 获取所有节日
        final holidays = await getAllHolidays();
        result['holidays'] = holidays.map((h) => h.toMap()).toList();

        // 获取所有联系人
        final contacts = await getAllContacts();
        result['contacts'] = contacts.map((c) => {
          'id': c.id,
          'name': c.name,
          'relation_type': c.relationType.index,
          'specific_relation': c.specificRelation,
          'phone_number': c.phoneNumber,
          'email': c.email,
          'avatar_url': c.avatarUrl,
          'birthday': c.birthday?.toIso8601String(),
          'is_birthday_lunar': c.isBirthdayLunar,
          'additional_info': c.additionalInfo,
          'associated_holiday_ids': c.associatedHolidayIds,
          'names': c.names,
          'specific_relations': c.specificRelations,
          'created_at': c.createdAt.toIso8601String(),
          'last_modified': c.lastModified?.toIso8601String(),
        }).toList();

        // 获取所有提醒事件
        final reminderEvents = await getAllReminderEvents();
        result['reminder_events'] = reminderEvents.map((e) => {
          'id': e.id,
          'title': e.title,
          'description': e.description,
          'type': e.type.index,
          'due_date': e.dueDate?.toIso8601String(),
          'is_all_day': e.isAllDay,
          'is_lunar_date': e.isLunarDate,
          'status': e.status.index,
          'is_completed': e.isCompleted,
          'completed_at': e.completedAt?.toIso8601String(),
          'is_repeating': e.isRepeating,
          'repeat_rule': e.repeatRule,
          'repeat_until': e.repeatUntil?.toIso8601String(),
          'reminder_times': e.reminderTimes,
          'contact_id': e.contactId,
          'holiday_id': e.holidayId,
          'location': e.location,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'tags': e.tags,
          'category': e.category,
          'titles': e.titles,
          'descriptions': e.descriptions,
          'ai_generated_description': e.aiGeneratedDescription,
          'ai_generated_greetings': e.aiGeneratedGreetings,
          'ai_generated_gift_suggestions': e.aiGeneratedGiftSuggestions,
          'importance': e.importance,
          'custom_color': e.customColor,
          'custom_icon': e.customIcon,
          'is_shared': e.isShared,
          'shared_with': e.sharedWith,
          'last_synced': e.lastSynced?.toIso8601String(),
          'is_sync_conflict': e.isSyncConflict,
          'created_at': e.createdAt.toIso8601String(),
          'last_modified': e.lastModified?.toIso8601String(),
        }).toList();

        // 获取用户设置
        final userSettings = await getUserSettings();
        if (userSettings != null) {
          result['user_settings'] = {
            'user_id': userSettings.userId,
            'nickname': userSettings.nickname,
            'avatar_url': userSettings.avatarUrl,
            'language_code': userSettings.languageCode,
            'country_code': userSettings.countryCode,
            'show_lunar_calendar': userSettings.showLunarCalendar,
            'theme_mode': userSettings.themeMode.index,
            'primary_color': userSettings.primaryColor,
            'background_image_url': userSettings.backgroundImageUrl,
            'enable_notifications': userSettings.enableNotifications,
            'default_reminder_times': userSettings.defaultReminderTimes,
            'enable_sound': userSettings.enableSound,
            'enable_vibration': userSettings.enableVibration,
            'enable_cloud_sync': userSettings.enableCloudSync,
            'sync_frequency_hours': userSettings.syncFrequencyHours,
            'last_sync_time': userSettings.lastSyncTime?.toIso8601String(),
            'auto_backup': userSettings.autoBackup,
            'backup_frequency_days': userSettings.backupFrequencyDays,
            'last_backup_time': userSettings.lastBackupTime?.toIso8601String(),
            'show_expired_events': userSettings.showExpiredEvents,
            'expired_event_retention_days': userSettings.expiredEventRetentionDays,
            'enable_ai_features': userSettings.enableAIFeatures,
            'enabled_ai_features': userSettings.enabledAIFeatures,
            'last_modified': userSettings.lastModified.toIso8601String(),
          };
        }
      } else {
        // 获取自指定时间以来修改的数据
        final sinceStr = since.toIso8601String();

        // 获取修改过的节日
        final List<Map<String, dynamic>> holidayMaps = await _db!.query(
          DatabaseSchema.holidaysTable,
          where: 'last_modified > ?',
          whereArgs: [sinceStr],
        );
        result['holidays'] = holidayMaps.map((m) => Holiday.fromMap(m).toMap()).toList();

        // 获取修改过的联系人
        final List<Map<String, dynamic>> contactMaps = await _db!.query(
          DatabaseSchema.contactsTable,
          where: 'last_modified > ?',
          whereArgs: [sinceStr],
        );
        result['contacts'] = contactMaps.map((m) => _mapToContact(m)).map((c) => {
          'id': c.id,
          'name': c.name,
          'relation_type': c.relationType.index,
          'specific_relation': c.specificRelation,
          'phone_number': c.phoneNumber,
          'email': c.email,
          'avatar_url': c.avatarUrl,
          'birthday': c.birthday?.toIso8601String(),
          'is_birthday_lunar': c.isBirthdayLunar,
          'additional_info': c.additionalInfo,
          'associated_holiday_ids': c.associatedHolidayIds,
          'names': c.names,
          'specific_relations': c.specificRelations,
          'created_at': c.createdAt.toIso8601String(),
          'last_modified': c.lastModified?.toIso8601String(),
        }).toList();

        // 获取修改过的提醒事件
        final List<Map<String, dynamic>> eventMaps = await _db!.query(
          DatabaseSchema.reminderEventsTable,
          where: 'last_modified > ?',
          whereArgs: [sinceStr],
        );
        result['reminder_events'] = eventMaps.map((m) => _mapToReminderEvent(m)).map((e) => {
          'id': e.id,
          'title': e.title,
          'description': e.description,
          'type': e.type.index,
          'due_date': e.dueDate?.toIso8601String(),
          'is_all_day': e.isAllDay,
          'is_lunar_date': e.isLunarDate,
          'status': e.status.index,
          'is_completed': e.isCompleted,
          'completed_at': e.completedAt?.toIso8601String(),
          'is_repeating': e.isRepeating,
          'repeat_rule': e.repeatRule,
          'repeat_until': e.repeatUntil?.toIso8601String(),
          'reminder_times': e.reminderTimes,
          'contact_id': e.contactId,
          'holiday_id': e.holidayId,
          'location': e.location,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'tags': e.tags,
          'category': e.category,
          'titles': e.titles,
          'descriptions': e.descriptions,
          'ai_generated_description': e.aiGeneratedDescription,
          'ai_generated_greetings': e.aiGeneratedGreetings,
          'ai_generated_gift_suggestions': e.aiGeneratedGiftSuggestions,
          'importance': e.importance,
          'custom_color': e.customColor,
          'custom_icon': e.customIcon,
          'is_shared': e.isShared,
          'shared_with': e.sharedWith,
          'last_synced': e.lastSynced?.toIso8601String(),
          'is_sync_conflict': e.isSyncConflict,
          'created_at': e.createdAt.toIso8601String(),
          'last_modified': e.lastModified?.toIso8601String(),
        }).toList();

        // 获取修改过的用户设置
        final List<Map<String, dynamic>> settingsMaps = await _db!.query(
          DatabaseSchema.userSettingsTable,
          where: 'last_modified > ?',
          whereArgs: [sinceStr],
          limit: 1,
        );
        if (settingsMaps.isNotEmpty) {
          final userSettings = _mapToUserSettings(settingsMaps.first);
          result['user_settings'] = {
            'user_id': userSettings.userId,
            'nickname': userSettings.nickname,
            'avatar_url': userSettings.avatarUrl,
            'language_code': userSettings.languageCode,
            'country_code': userSettings.countryCode,
            'show_lunar_calendar': userSettings.showLunarCalendar,
            'theme_mode': userSettings.themeMode.index,
            'primary_color': userSettings.primaryColor,
            'background_image_url': userSettings.backgroundImageUrl,
            'enable_notifications': userSettings.enableNotifications,
            'default_reminder_times': userSettings.defaultReminderTimes,
            'enable_sound': userSettings.enableSound,
            'enable_vibration': userSettings.enableVibration,
            'enable_cloud_sync': userSettings.enableCloudSync,
            'sync_frequency_hours': userSettings.syncFrequencyHours,
            'last_sync_time': userSettings.lastSyncTime?.toIso8601String(),
            'auto_backup': userSettings.autoBackup,
            'backup_frequency_days': userSettings.backupFrequencyDays,
            'last_backup_time': userSettings.lastBackupTime?.toIso8601String(),
            'show_expired_events': userSettings.showExpiredEvents,
            'expired_event_retention_days': userSettings.expiredEventRetentionDays,
            'enable_ai_features': userSettings.enableAIFeatures,
            'enabled_ai_features': userSettings.enabledAIFeatures,
            'last_modified': userSettings.lastModified.toIso8601String(),
          };
        }
      }

      debugPrint('获取修改数据成功: ${result['holidays'].length} 个节日, ${result['contacts'].length} 个联系人, ${result['reminder_events'].length} 个提醒事件');
      return result;
    } catch (e) {
      debugPrint('获取修改数据失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _checkInitialized();

    try {
      // 获取表名
      String tableName;
      switch (entityType) {
        case 'holiday':
          tableName = DatabaseSchema.holidaysTable;
          break;
        case 'contact':
          tableName = DatabaseSchema.contactsTable;
          break;
        case 'reminder_event':
          tableName = DatabaseSchema.reminderEventsTable;
          break;
        default:
          throw Exception('未知实体类型: $entityType');
      }

      // 更新同步冲突标志
      await _db!.update(
        tableName,
        {'is_sync_conflict': isConflict ? 1 : 0, 'last_modified': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      // 记录同步冲突
      if (isConflict) {
        await _db!.insert(
          DatabaseSchema.syncStatusTable,
          {
            'id': const Uuid().v4(),
            'entity_type': entityType,
            'entity_id': id,
            'sync_status': 2, // 2表示冲突
            'is_conflict': 1,
            'server_version': null,
            'local_version': DateTime.now().toIso8601String(),
            'last_sync_time': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'last_modified': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // 删除同步冲突记录
        await _db!.delete(
          DatabaseSchema.syncStatusTable,
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: [entityType, id],
        );
      }

      debugPrint('标记同步冲突: $entityType $id -> $isConflict');
    } catch (e) {
      debugPrint('标记同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    await _checkInitialized();

    try {
      // 查询同步冲突
      final List<Map<String, dynamic>> conflicts = await _db!.query(
        DatabaseSchema.syncStatusTable,
        where: 'is_conflict = 1',
      );

      // 获取冲突实体的详细信息
      final List<Map<String, dynamic>> result = [];

      for (final conflict in conflicts) {
        final entityType = conflict['entity_type'] as String;
        final entityId = conflict['entity_id'] as String;
        final conflictId = conflict['id'] as String;
        final createdAt = DateTime.parse(conflict['created_at'] as String);

        // 获取实体数据
        Map<String, dynamic>? localData;
        Map<String, dynamic> serverData = {}; // 在实际应用中，这应该从服务器获取

        switch (entityType) {
          case 'holiday':
            final holiday = await getHolidayById(entityId);
            if (holiday != null) {
              localData = holiday.toMap();
            }
            break;
          case 'contact':
            final contact = await getContactById(entityId);
            if (contact != null) {
              localData = {
                'id': contact.id,
                'name': contact.name,
                'relation_type': contact.relationType.index,
                'specific_relation': contact.specificRelation,
                'phone_number': contact.phoneNumber,
                'email': contact.email,
                'avatar_url': contact.avatarUrl,
                'birthday': contact.birthday?.toIso8601String(),
                'is_birthday_lunar': contact.isBirthdayLunar,
                'additional_info': contact.additionalInfo,
                'associated_holiday_ids': contact.associatedHolidayIds,
                'names': contact.names,
                'specific_relations': contact.specificRelations,
                'created_at': contact.createdAt.toIso8601String(),
                'last_modified': contact.lastModified?.toIso8601String(),
              };
            }
            break;
          case 'reminder_event':
            final event = await getReminderEventById(entityId);
            if (event != null) {
              localData = {
                'id': event.id,
                'title': event.title,
                'description': event.description,
                'type': event.type.index,
                'due_date': event.dueDate?.toIso8601String(),
                'is_all_day': event.isAllDay,
                'is_lunar_date': event.isLunarDate,
                'status': event.status.index,
                'is_completed': event.isCompleted,
                'completed_at': event.completedAt?.toIso8601String(),
                'is_repeating': event.isRepeating,
                'repeat_rule': event.repeatRule,
                'repeat_until': event.repeatUntil?.toIso8601String(),
                'reminder_times': event.reminderTimes,
                'contact_id': event.contactId,
                'holiday_id': event.holidayId,
                'location': event.location,
                'latitude': event.latitude,
                'longitude': event.longitude,
                'tags': event.tags,
                'category': event.category,
                'titles': event.titles,
                'descriptions': event.descriptions,
                'ai_generated_description': event.aiGeneratedDescription,
                'ai_generated_greetings': event.aiGeneratedGreetings,
                'ai_generated_gift_suggestions': event.aiGeneratedGiftSuggestions,
                'importance': event.importance,
                'custom_color': event.customColor,
                'custom_icon': event.customIcon,
                'is_shared': event.isShared,
                'shared_with': event.sharedWith,
                'last_synced': event.lastSynced?.toIso8601String(),
                'is_sync_conflict': event.isSyncConflict,
                'created_at': event.createdAt.toIso8601String(),
                'last_modified': event.lastModified?.toIso8601String(),
              };
            }
            break;
        }

        if (localData != null) {
          // 创建冲突数据
          final Map<String, dynamic> conflictData = {
            'id': conflictId,
            'entity_type': entityType,
            'entity_id': entityId,
            'local_data': localData,
            'server_data': serverData,
            'created_at': createdAt.toIso8601String(),
          };

          result.add(conflictData);
        }
      }

      debugPrint('获取同步冲突: ${result.length} 个');
      return result;
    } catch (e) {
      debugPrint('获取同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    await _checkInitialized();

    try {
      // 获取表名
      String tableName;
      switch (entityType) {
        case 'holiday':
          tableName = DatabaseSchema.holidaysTable;
          break;
        case 'contact':
          tableName = DatabaseSchema.contactsTable;
          break;
        case 'reminder_event':
          tableName = DatabaseSchema.reminderEventsTable;
          break;
        default:
          throw Exception('未知实体类型: $entityType');
      }

      // 更新实体数据
      if (resolvedData != null) {
        // 确保数据是Map类型
        final Map<String, dynamic> data = resolvedData is Map<String, dynamic>
            ? resolvedData
            : jsonDecode(jsonEncode(resolvedData));

        // 添加最后修改时间
        data['last_modified'] = DateTime.now().toIso8601String();
        data['is_sync_conflict'] = 0;

        // 更新数据
        await _db!.update(
          tableName,
          data,
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 删除同步冲突记录
      await _db!.delete(
        DatabaseSchema.syncStatusTable,
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, id],
      );

      debugPrint('解决同步冲突: $entityType $id');
    } catch (e) {
      debugPrint('解决同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getAppSetting(String key) async {
    await _checkInitialized();

    try {
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.appSettingsTable,
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('获取应用设置失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflictsLegacy() async {
    await _checkInitialized();

    try {
      // 查询同步冲突
      final List<Map<String, dynamic>> conflicts = await _db!.query(
        DatabaseSchema.syncStatusTable,
        where: 'is_conflict = 1',
      );

      // 获取冲突实体的详细信息
      final List<Map<String, dynamic>> result = [];

      for (final conflict in conflicts) {
        final entityType = conflict['entity_type'] as String;
        final entityId = conflict['entity_id'] as String;

        // 获取实体数据
        Map<String, dynamic>? entityData;

        switch (entityType) {
          case 'holiday':
            final holiday = await getHolidayById(entityId);
            if (holiday != null) {
              entityData = holiday.toMap();
            }
            break;
          case 'contact':
            final contact = await getContactById(entityId);
            if (contact != null) {
              entityData = {
                'id': contact.id,
                'name': contact.name,
                'relation_type': contact.relationType.index,
                'specific_relation': contact.specificRelation,
                'phone_number': contact.phoneNumber,
                'email': contact.email,
                'avatar_url': contact.avatarUrl,
                'birthday': contact.birthday?.toIso8601String(),
                'is_birthday_lunar': contact.isBirthdayLunar,
                'additional_info': contact.additionalInfo,
                'associated_holiday_ids': contact.associatedHolidayIds,
                'names': contact.names,
                'specific_relations': contact.specificRelations,
                'created_at': contact.createdAt.toIso8601String(),
                'last_modified': contact.lastModified?.toIso8601String(),
              };
            }
            break;
          case 'reminder_event':
            final event = await getReminderEventById(entityId);
            if (event != null) {
              entityData = {
                'id': event.id,
                'title': event.title,
                'description': event.description,
                'type': event.type.index,
                'due_date': event.dueDate?.toIso8601String(),
                'is_all_day': event.isAllDay,
                'is_lunar_date': event.isLunarDate,
                'status': event.status.index,
                'is_completed': event.isCompleted,
                'completed_at': event.completedAt?.toIso8601String(),
                'is_repeating': event.isRepeating,
                'repeat_rule': event.repeatRule,
                'repeat_until': event.repeatUntil?.toIso8601String(),
                'reminder_times': event.reminderTimes,
                'contact_id': event.contactId,
                'holiday_id': event.holidayId,
                'location': event.location,
                'latitude': event.latitude,
                'longitude': event.longitude,
                'tags': event.tags,
                'category': event.category,
                'titles': event.titles,
                'descriptions': event.descriptions,
                'ai_generated_description': event.aiGeneratedDescription,
                'ai_generated_greetings': event.aiGeneratedGreetings,
                'ai_generated_gift_suggestions': event.aiGeneratedGiftSuggestions,
                'importance': event.importance,
                'custom_color': event.customColor,
                'custom_icon': event.customIcon,
                'is_shared': event.isShared,
                'shared_with': event.sharedWith,
                'last_synced': event.lastSynced?.toIso8601String(),
                'is_sync_conflict': event.isSyncConflict,
                'created_at': event.createdAt.toIso8601String(),
                'last_modified': event.lastModified?.toIso8601String(),
              };
            }
            break;
        }

        if (entityData != null) {
          result.add({
            'conflict': conflict,
            'entity': entityData,
          });
        }
      }

      debugPrint('获取同步冲突(旧版): ${result.length} 个');
      return result;
    } catch (e) {
      debugPrint('获取同步冲突(旧版)失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> setAppSetting(String key, String value) async {
    await _checkInitialized();

    try {
      // 检查设置是否已存在
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.appSettingsTable,
        columns: ['id'],
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        // 更新现有设置
        await _db!.update(
          DatabaseSchema.appSettingsTable,
          {
            'value': value,
            'last_modified': DateTime.now().toIso8601String(),
          },
          where: 'key = ?',
          whereArgs: [key],
        );
      } else {
        // 插入新设置
        await _db!.insert(
          DatabaseSchema.appSettingsTable,
          {
            'id': const Uuid().v4(),
            'key': key,
            'value': value,
            'created_at': DateTime.now().toIso8601String(),
            'last_modified': DateTime.now().toIso8601String(),
          },
        );
      }

      debugPrint('设置应用设置成功: $key');
    } catch (e) {
      debugPrint('设置应用设置失败: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getSyncConflict(String conflictId) async {
    await _checkInitialized();

    try {
      // 查询指定ID的同步冲突
      final List<Map<String, dynamic>> maps = await _db!.query(
        DatabaseSchema.syncStatusTable,
        where: 'id = ? AND is_conflict = 1',
        whereArgs: [conflictId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      final conflict = maps.first;
      final entityType = conflict['entity_type'] as String;
      final entityId = conflict['entity_id'] as String;
      final createdAt = DateTime.parse(conflict['created_at'] as String);

      // 获取实体数据
      Map<String, dynamic>? localData;
      Map<String, dynamic> serverData = {}; // 在实际应用中，这应该从服务器获取

      switch (entityType) {
        case 'holiday':
          final holiday = await getHolidayById(entityId);
          if (holiday != null) {
            localData = holiday.toMap();
          }
          break;
        case 'contact':
          final contact = await getContactById(entityId);
          if (contact != null) {
            localData = {
              'id': contact.id,
              'name': contact.name,
              'relation_type': contact.relationType.index,
              'specific_relation': contact.specificRelation,
              'phone_number': contact.phoneNumber,
              'email': contact.email,
              'avatar_url': contact.avatarUrl,
              'birthday': contact.birthday?.toIso8601String(),
              'is_birthday_lunar': contact.isBirthdayLunar,
              'additional_info': contact.additionalInfo,
              'associated_holiday_ids': contact.associatedHolidayIds,
              'names': contact.names,
              'specific_relations': contact.specificRelations,
              'created_at': contact.createdAt.toIso8601String(),
              'last_modified': contact.lastModified?.toIso8601String(),
            };
          }
          break;
        case 'reminder_event':
          final event = await getReminderEventById(entityId);
          if (event != null) {
            localData = {
              'id': event.id,
              'title': event.title,
              'description': event.description,
              'type': event.type.index,
              'due_date': event.dueDate?.toIso8601String(),
              'is_all_day': event.isAllDay,
              'is_lunar_date': event.isLunarDate,
              'status': event.status.index,
              'is_completed': event.isCompleted,
              'completed_at': event.completedAt?.toIso8601String(),
              'is_repeating': event.isRepeating,
              'repeat_rule': event.repeatRule,
              'repeat_until': event.repeatUntil?.toIso8601String(),
              'reminder_times': event.reminderTimes,
              'contact_id': event.contactId,
              'holiday_id': event.holidayId,
              'location': event.location,
              'latitude': event.latitude,
              'longitude': event.longitude,
              'tags': event.tags,
              'category': event.category,
              'titles': event.titles,
              'descriptions': event.descriptions,
              'ai_generated_description': event.aiGeneratedDescription,
              'ai_generated_greetings': event.aiGeneratedGreetings,
              'ai_generated_gift_suggestions': event.aiGeneratedGiftSuggestions,
              'importance': event.importance,
              'custom_color': event.customColor,
              'custom_icon': event.customIcon,
              'is_shared': event.isShared,
              'shared_with': event.sharedWith,
              'last_synced': event.lastSynced?.toIso8601String(),
              'is_sync_conflict': event.isSyncConflict,
              'created_at': event.createdAt.toIso8601String(),
              'last_modified': event.lastModified?.toIso8601String(),
            };
          }
          break;
      }

      if (localData == null) {
        return null;
      }

      // 创建冲突数据
      final Map<String, dynamic> conflictData = {
        'id': conflictId,
        'entity_type': entityType,
        'entity_id': entityId,
        'local_data': localData,
        'server_data': serverData,
        'created_at': createdAt.toIso8601String(),
      };

      return conflictData;
    } catch (e) {
      debugPrint('获取同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    await _checkInitialized();

    try {
      final operation = conflict.operation;

      // 保存同步冲突记录
      await _db!.insert(
        DatabaseSchema.syncStatusTable,
        {
          'id': conflict.id,
          'entity_type': operation.entityType,
          'entity_id': operation.entityId,
          'sync_status': SyncStatus.conflict.index,
          'is_conflict': 1,
          'server_version': null,
          'local_version': DateTime.now().toIso8601String(),
          'last_sync_time': DateTime.now().toIso8601String(),
          'created_at': conflict.createdAt.toIso8601String(),
          'last_modified': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 标记实体为冲突状态
      await markSyncConflict(
        operation.entityType,
        operation.entityId,
        true,
      );

      debugPrint('保存同步冲突: ${conflict.id}');
    } catch (e) {
      debugPrint('保存同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSyncConflict(String conflictId) async {
    await _checkInitialized();

    try {
      // 获取冲突记录
      final conflict = await getSyncConflict(conflictId);

      if (conflict != null) {
        // 删除冲突记录
        await _db!.delete(
          DatabaseSchema.syncStatusTable,
          where: 'id = ?',
          whereArgs: [conflictId],
        );

        // 清除实体的冲突标记
        final entityType = conflict['entity_type'] as String;
        final entityId = conflict['entity_id'] as String;

        await markSyncConflict(
          entityType,
          entityId,
          false,
        );
      }

      debugPrint('删除同步冲突: $conflictId');
    } catch (e) {
      debugPrint('删除同步冲突失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<SyncBatch>> getSyncBatches() async {
    // 暂时返回空列表，后续实现
    return [];
  }

  @override
  Future<SyncBatch?> getSyncBatch(String batchId) async {
    // 暂时返回null，后续实现
    return null;
  }

  @override
  Future<void> saveSyncBatch(SyncBatch batch) async {
    // 暂时不实现，后续实现
  }

  @override
  Future<void> deleteSyncBatch(String batchId) async {
    // 暂时不实现，后续实现
  }

  @override
  Future<List<SyncOperation>> getSyncOperations() async {
    // 暂时返回空列表，后续实现
    return [];
  }

  @override
  Future<SyncOperation?> getSyncOperation(String operationId) async {
    // 暂时返回null，后续实现
    return null;
  }

  @override
  Future<void> saveSyncOperation(SyncOperation operation) async {
    // 暂时不实现，后续实现
  }

  @override
  Future<void> deleteSyncOperation(String operationId) async {
    // 暂时不实现，后续实现
  }

  // ==================== 其他操作 ====================

  @override
  Future<String> backup() async {
    await _checkInitialized();

    try {
      // 关闭数据库
      await close();

      // 获取数据库文件路径
      String dbPath;
      if (kIsWeb) {
        throw Exception('Web平台不支持备份');
      } else {
        final databasesPath = await getDatabasesPath();
        dbPath = join(databasesPath, _databaseName);
      }

      // 创建备份文件路径
      final backupPath = '${dbPath}_backup_${DateTime.now().millisecondsSinceEpoch}.db';

      // 复制数据库文件
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      // 重新打开数据库
      await initialize();

      // 更新最后备份时间
      final settings = await getUserSettings();
      if (settings != null) {
        await updateUserSettings({
          'last_backup_time': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('备份数据库成功: $backupPath');
      return backupPath;
    } catch (e) {
      // 确保数据库重新打开
      try {
        await initialize();
      } catch (_) {}

      debugPrint('备份数据库失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> restore(String backupPath) async {
    await _checkInitialized();

    try {
      // 关闭数据库
      await close();

      // 获取数据库文件路径
      String dbPath;
      if (kIsWeb) {
        throw Exception('Web平台不支持恢复');
      } else {
        final databasesPath = await getDatabasesPath();
        dbPath = join(databasesPath, _databaseName);
      }

      // 检查备份文件是否存在
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在');
      }

      // 删除当前数据库文件
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // 复制备份文件
      await backupFile.copy(dbPath);

      // 重新打开数据库
      await initialize();

      debugPrint('恢复数据库成功: $backupPath');
      return true;
    } catch (e) {
      // 确保数据库重新打开
      try {
        await initialize();
      } catch (_) {}

      debugPrint('恢复数据库失败: $e');
      return false;
    }
  }

  @override
  Future<void> performMaintenance() async {
    await _checkInitialized();

    try {
      // 执行VACUUM操作
      await _db!.execute('VACUUM');

      // 执行ANALYZE操作
      await _db!.execute('ANALYZE');

      // 执行PRAGMA integrity_check
      final integrityResult = await _db!.rawQuery('PRAGMA integrity_check');
      final integrityOk = integrityResult.first.values.first == 'ok';

      if (!integrityOk) {
        debugPrint('数据库完整性检查失败: ${integrityResult.first.values.first}');
        throw Exception('数据库完整性检查失败');
      }

      debugPrint('数据库维护成功');
    } catch (e) {
      debugPrint('数据库维护失败: $e');
      rethrow;
    }
  }
}
