import 'package:flutter/foundation.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/database/sqlite_database.dart';
import 'package:jinlin_app/services/database/sqlite_database_enhanced.dart';
import 'package:jinlin_app/services/database/cached_database_adapter.dart';
import 'package:jinlin_app/services/database/validated_database_adapter.dart';
import 'package:jinlin_app/services/database/soft_delete_database_adapter.dart';
import 'package:jinlin_app/services/database/encrypted_database_adapter.dart';
import 'package:jinlin_app/services/database/hive_database.dart';
import 'package:jinlin_app/services/database/monitoring/database_monitoring_adapter.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 数据库类型
enum DatabaseType {
  /// 旧版SQLite数据库
  sqlite,

  /// 旧版Hive数据库
  hive,

  /// 增强版SQLite数据库
  sqliteEnhanced,

  /// 缓存数据库
  cached,

  /// 验证数据库
  validated,

  /// 缓存+验证数据库
  cachedValidated,

  /// 软删除数据库
  softDelete,

  /// 缓存+软删除数据库
  cachedSoftDelete,

  /// 验证+软删除数据库
  validatedSoftDelete,

  /// 缓存+验证+软删除数据库
  cachedValidatedSoftDelete,

  /// 加密数据库
  encrypted,

  /// 缓存+加密数据库
  cachedEncrypted,

  /// 验证+加密数据库
  validatedEncrypted,

  /// 软删除+加密数据库
  softDeleteEncrypted,

  /// 缓存+验证+加密数据库
  cachedValidatedEncrypted,

  /// 缓存+软删除+加密数据库
  cachedSoftDeleteEncrypted,

  /// 验证+软删除+加密数据库
  validatedSoftDeleteEncrypted,

  /// 缓存+验证+软删除+加密数据库
  cachedValidatedSoftDeleteEncrypted,

  /// 监控数据库
  monitored,

  /// 缓存+监控数据库
  cachedMonitored,

  /// 验证+监控数据库
  validatedMonitored,

  /// 软删除+监控数据库
  softDeleteMonitored,

  /// 缓存+验证+监控数据库
  cachedValidatedMonitored,

  /// 缓存+软删除+监控数据库
  cachedSoftDeleteMonitored,

  /// 验证+软删除+监控数据库
  validatedSoftDeleteMonitored,

  /// 缓存+验证+软删除+监控数据库
  cachedValidatedSoftDeleteMonitored,
}

/// 数据库工厂
///
/// 根据配置创建适当的数据库适配器
class DatabaseFactory {
  // 单例模式
  static final DatabaseFactory _instance = DatabaseFactory._internal();

  factory DatabaseFactory() {
    return _instance;
  }

  DatabaseFactory._internal();

  // 日志标签
  static const String _tag = 'DatabaseFactory';

  // 缓存的数据库实例
  final Map<DatabaseType, dynamic> _instances = {};

  /// 创建旧版数据库适配器
  DatabaseInterface createLegacyDatabase(DatabaseType type) {
    // 如果已经创建过，直接返回缓存的实例
    if (_instances.containsKey(type) && _instances[type] is DatabaseInterface) {
      logger.d(_tag, '返回缓存的旧版数据库实例: $type');
      return _instances[type] as DatabaseInterface;
    }

    // 在Web平台上使用Hive数据库
    if (kIsWeb && type == DatabaseType.sqlite) {
      logger.i(_tag, '在Web平台上使用Hive数据库');
      final db = HiveDatabase();
      _instances[DatabaseType.hive] = db;
      return db;
    }

    // 创建新的数据库实例
    DatabaseInterface db;

    switch (type) {
      case DatabaseType.sqlite:
        db = SQLiteDatabase();
        logger.i(_tag, '创建旧版SQLite数据库实例');
        break;

      case DatabaseType.hive:
        db = HiveDatabase();
        logger.i(_tag, '创建旧版Hive数据库实例');
        break;

      default:
        logger.w(_tag, '不支持的旧版数据库类型: $type，使用默认的SQLite数据库');
        db = SQLiteDatabase();
    }

    // 缓存实例
    _instances[type] = db;

    return db;
  }

  /// 创建增强版数据库适配器
  DatabaseInterfaceEnhanced createEnhancedDatabase(DatabaseType type) {
    // 如果已经创建过，直接返回缓存的实例
    if (_instances.containsKey(type) && _instances[type] is DatabaseInterfaceEnhanced) {
      logger.d(_tag, '返回缓存的增强版数据库实例: $type');
      return _instances[type] as DatabaseInterfaceEnhanced;
    }

    // 创建新的数据库实例
    DatabaseInterfaceEnhanced db;

    switch (type) {
      case DatabaseType.sqliteEnhanced:
        db = SQLiteDatabaseEnhanced();
        logger.i(_tag, '创建增强版SQLite数据库实例');
        break;

      case DatabaseType.cached:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        db = CachedDatabaseAdapter(sqliteDb);
        logger.i(_tag, '创建缓存数据库实例');
        break;

      case DatabaseType.validated:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        db = ValidatedDatabaseAdapter(sqliteDb);
        logger.i(_tag, '创建验证数据库实例');
        break;

      case DatabaseType.cachedValidated:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        db = ValidatedDatabaseAdapter(cachedDb);
        logger.i(_tag, '创建缓存+验证数据库实例');
        break;

      case DatabaseType.softDelete:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为软删除数据库适配器
        db = SoftDeleteDatabaseAdapter(sqliteDb);
        logger.i(_tag, '创建软删除数据库实例');
        break;

      case DatabaseType.cachedSoftDelete:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        db = SoftDeleteDatabaseAdapter(cachedDb);
        logger.i(_tag, '创建缓存+软删除数据库实例');
        break;

      case DatabaseType.validatedSoftDelete:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        db = SoftDeleteDatabaseAdapter(validatedDb);
        logger.i(_tag, '创建验证+软删除数据库实例');
        break;

      case DatabaseType.cachedValidatedSoftDelete:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(cachedDb);
        // 再包装为软删除数据库适配器
        db = SoftDeleteDatabaseAdapter(validatedDb);
        logger.i(_tag, '创建缓存+验证+软删除数据库实例');
        break;

      case DatabaseType.encrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(sqliteDb);
        logger.i(_tag, '创建加密数据库实例');
        break;

      case DatabaseType.cachedEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(cachedDb);
        logger.i(_tag, '创建缓存+加密数据库实例');
        break;

      case DatabaseType.validatedEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(sqliteDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(validatedDb);
        logger.i(_tag, '创建验证+加密数据库实例');
        break;

      case DatabaseType.softDeleteEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(sqliteDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(softDeleteDb);
        logger.i(_tag, '创建软删除+加密数据库实例');
        break;

      case DatabaseType.cachedValidatedEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(cachedDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(validatedDb);
        logger.i(_tag, '创建缓存+验证+加密数据库实例');
        break;

      case DatabaseType.cachedSoftDeleteEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(cachedDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(softDeleteDb);
        logger.i(_tag, '创建缓存+软删除+加密数据库实例');
        break;

      case DatabaseType.validatedSoftDeleteEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(validatedDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(softDeleteDb);
        logger.i(_tag, '创建验证+软删除+加密数据库实例');
        break;

      case DatabaseType.cachedValidatedSoftDeleteEncrypted:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(cachedDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(validatedDb);
        // 再包装为加密数据库适配器
        db = EncryptedDatabaseAdapter(softDeleteDb);
        logger.i(_tag, '创建缓存+验证+软删除+加密数据库实例');
        break;

      case DatabaseType.monitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(sqliteDb);
        logger.i(_tag, '创建监控数据库实例');
        break;

      case DatabaseType.cachedMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(cachedDb);
        logger.i(_tag, '创建缓存+监控数据库实例');
        break;

      case DatabaseType.validatedMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(sqliteDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(validatedDb);
        logger.i(_tag, '创建验证+监控数据库实例');
        break;

      case DatabaseType.softDeleteMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(sqliteDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(softDeleteDb);
        logger.i(_tag, '创建软删除+监控数据库实例');
        break;

      case DatabaseType.cachedValidatedMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(cachedDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(validatedDb);
        logger.i(_tag, '创建缓存+验证+监控数据库实例');
        break;

      case DatabaseType.cachedSoftDeleteMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(cachedDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(softDeleteDb);
        logger.i(_tag, '创建缓存+软删除+监控数据库实例');
        break;

      case DatabaseType.validatedSoftDeleteMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(sqliteDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(validatedDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(softDeleteDb);
        logger.i(_tag, '创建验证+软删除+监控数据库实例');
        break;

      case DatabaseType.cachedValidatedSoftDeleteMonitored:
        // 创建SQLite数据库实例
        final sqliteDb = SQLiteDatabaseEnhanced();
        // 包装为缓存数据库适配器
        final cachedDb = CachedDatabaseAdapter(sqliteDb);
        // 再包装为验证数据库适配器
        final validatedDb = ValidatedDatabaseAdapter(cachedDb);
        // 再包装为软删除数据库适配器
        final softDeleteDb = SoftDeleteDatabaseAdapter(validatedDb);
        // 再包装为监控数据库适配器
        db = DatabaseMonitoringAdapter(softDeleteDb);
        logger.i(_tag, '创建缓存+验证+软删除+监控数据库实例');
        break;

      default:
        logger.w(_tag, '不支持的增强版数据库类型: $type，使用默认的增强版SQLite数据库');
        db = SQLiteDatabaseEnhanced();
    }

    // 缓存实例
    _instances[type] = db;

    return db;
  }

  /// 获取默认数据库适配器（旧版）
  DatabaseInterface getDefaultLegacyDatabase() {
    return createLegacyDatabase(DatabaseType.sqlite);
  }

  /// 获取默认数据库适配器（增强版）
  DatabaseInterfaceEnhanced getDefaultEnhancedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedSoftDelete);
  }

  /// 获取验证数据库适配器
  ValidatedDatabaseAdapter getValidatedDatabase() {
    return createEnhancedDatabase(DatabaseType.validated) as ValidatedDatabaseAdapter;
  }

  /// 获取缓存+验证数据库适配器
  ValidatedDatabaseAdapter getCachedValidatedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidated) as ValidatedDatabaseAdapter;
  }

  /// 获取软删除数据库适配器
  SoftDeleteDatabaseAdapter getSoftDeleteDatabase() {
    return createEnhancedDatabase(DatabaseType.softDelete) as SoftDeleteDatabaseAdapter;
  }

  /// 获取缓存+软删除数据库适配器
  SoftDeleteDatabaseAdapter getCachedSoftDeleteDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedSoftDelete) as SoftDeleteDatabaseAdapter;
  }

  /// 获取验证+软删除数据库适配器
  SoftDeleteDatabaseAdapter getValidatedSoftDeleteDatabase() {
    return createEnhancedDatabase(DatabaseType.validatedSoftDelete) as SoftDeleteDatabaseAdapter;
  }

  /// 获取缓存+验证+软删除数据库适配器
  SoftDeleteDatabaseAdapter getCachedValidatedSoftDeleteDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedSoftDelete) as SoftDeleteDatabaseAdapter;
  }

  /// 获取加密数据库适配器
  EncryptedDatabaseAdapter getEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.encrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取缓存+加密数据库适配器
  EncryptedDatabaseAdapter getCachedEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取验证+加密数据库适配器
  EncryptedDatabaseAdapter getValidatedEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.validatedEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取软删除+加密数据库适配器
  EncryptedDatabaseAdapter getSoftDeleteEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.softDeleteEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取缓存+验证+加密数据库适配器
  EncryptedDatabaseAdapter getCachedValidatedEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取缓存+软删除+加密数据库适配器
  EncryptedDatabaseAdapter getCachedSoftDeleteEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedSoftDeleteEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取验证+软删除+加密数据库适配器
  EncryptedDatabaseAdapter getValidatedSoftDeleteEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.validatedSoftDeleteEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取缓存+验证+软删除+加密数据库适配器
  EncryptedDatabaseAdapter getCachedValidatedSoftDeleteEncryptedDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedSoftDeleteEncrypted) as EncryptedDatabaseAdapter;
  }

  /// 获取监控数据库适配器
  DatabaseMonitoringAdapter getMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.monitored) as DatabaseMonitoringAdapter;
  }

  /// 获取缓存+监控数据库适配器
  DatabaseMonitoringAdapter getCachedMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取验证+监控数据库适配器
  DatabaseMonitoringAdapter getValidatedMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.validatedMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取软删除+监控数据库适配器
  DatabaseMonitoringAdapter getSoftDeleteMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.softDeleteMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取缓存+验证+监控数据库适配器
  DatabaseMonitoringAdapter getCachedValidatedMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取缓存+软删除+监控数据库适配器
  DatabaseMonitoringAdapter getCachedSoftDeleteMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedSoftDeleteMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取验证+软删除+监控数据库适配器
  DatabaseMonitoringAdapter getValidatedSoftDeleteMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.validatedSoftDeleteMonitored) as DatabaseMonitoringAdapter;
  }

  /// 获取缓存+验证+软删除+监控数据库适配器
  DatabaseMonitoringAdapter getCachedValidatedSoftDeleteMonitoredDatabase() {
    return createEnhancedDatabase(DatabaseType.cachedValidatedSoftDeleteMonitored) as DatabaseMonitoringAdapter;
  }

  /// 关闭所有数据库
  Future<void> closeAll() async {
    for (final db in _instances.values) {
      if (db is DatabaseInterface) {
        await db.close();
      } else if (db is DatabaseInterfaceEnhanced) {
        await db.close();
      }
    }

    _instances.clear();
    logger.i(_tag, '关闭所有数据库');
  }

  /// 兼容旧版API
  static DatabaseInterface create(DatabaseType type) {
    return DatabaseFactory().createLegacyDatabase(type);
  }
}

/// 全局数据库工厂实例
final databaseFactory = DatabaseFactory();
