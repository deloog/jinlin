import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/services/database_manager_enhanced.dart';
import 'package:jinlin_app/services/database/database_factory.dart';
import 'package:jinlin_app/services/database/cached_database_adapter.dart';
import 'package:jinlin_app/services/database/validated_database_adapter.dart';
import 'package:jinlin_app/services/database/soft_delete_database_adapter.dart';
import 'package:jinlin_app/services/database/encrypted_database_adapter.dart';
import 'package:jinlin_app/services/database/monitoring/database_monitoring_adapter.dart';
import 'package:jinlin_app/services/database/soft_delete_manager.dart';

/// 增强版数据库提供者
///
/// 提供对数据库管理器的访问，并在应用启动时初始化数据库
class DatabaseProviderEnhanced {
  /// 创建数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> create() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.getDefaultEnhancedDatabase(),
      ),
    );
  }

  /// 创建缓存数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCached() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cached),
      ),
    );
  }

  /// 创建非缓存数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createNonCached() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.sqliteEnhanced),
      ),
    );
  }

  /// 创建验证数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createValidated() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.validated),
      ),
    );
  }

  /// 创建缓存+验证数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedValidated() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedValidated),
      ),
    );
  }

  /// 创建软删除数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createSoftDelete() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.softDelete),
      ),
    );
  }

  /// 创建缓存+软删除数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedSoftDelete() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedSoftDelete),
      ),
    );
  }

  /// 创建验证+软删除数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createValidatedSoftDelete() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.validatedSoftDelete),
      ),
    );
  }

  /// 创建缓存+验证+软删除数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedValidatedSoftDelete() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedValidatedSoftDelete),
      ),
    );
  }

  /// 创建加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.encrypted),
      ),
    );
  }

  /// 创建缓存+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedEncrypted),
      ),
    );
  }

  /// 创建验证+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createValidatedEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.validatedEncrypted),
      ),
    );
  }

  /// 创建软删除+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createSoftDeleteEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.softDeleteEncrypted),
      ),
    );
  }

  /// 创建缓存+验证+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedValidatedEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedValidatedEncrypted),
      ),
    );
  }

  /// 创建缓存+软删除+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedSoftDeleteEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedSoftDeleteEncrypted),
      ),
    );
  }

  /// 创建验证+软删除+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createValidatedSoftDeleteEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.validatedSoftDeleteEncrypted),
      ),
    );
  }

  /// 创建缓存+验证+软删除+加密数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedValidatedSoftDeleteEncrypted() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedValidatedSoftDeleteEncrypted),
      ),
    );
  }

  /// 创建监控数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createMonitored() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.monitored),
      ),
    );
  }

  /// 创建缓存+验证+软删除+监控数据库管理器提供者
  static ChangeNotifierProvider<DatabaseManagerEnhanced> createCachedValidatedSoftDeleteMonitored() {
    return ChangeNotifierProvider<DatabaseManagerEnhanced>(
      create: (_) => DatabaseManagerEnhanced(
        db: databaseFactory.createEnhancedDatabase(DatabaseType.cachedValidatedSoftDeleteMonitored),
      ),
    );
  }

  /// 初始化数据库
  static Future<void> initialize(BuildContext? context) async {
    if (context == null) {
      // 如果没有提供 BuildContext，则创建一个新的 DatabaseManagerEnhanced 实例
      final dbManager = DatabaseManagerEnhanced();
      await dbManager.initialize(null);
    } else {
      // 如果提供了 BuildContext，则从 Provider 中获取实例
      final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
      await dbManager.initialize(context);
    }
  }

  /// 获取数据库管理器实例
  static DatabaseManagerEnhanced of(BuildContext context, {bool listen = true}) {
    return Provider.of<DatabaseManagerEnhanced>(context, listen: listen);
  }

  /// 清除所有缓存
  static void clearAllCaches(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is CachedDatabaseAdapter) {
      db.clearAllCaches();
    }
  }

  /// 启用缓存
  static void enableCache(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is CachedDatabaseAdapter) {
      db.enableCache();
    }
  }

  /// 禁用缓存
  static void disableCache(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is CachedDatabaseAdapter) {
      db.disableCache();
    }
  }

  /// 启用验证
  static void enableValidation(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is ValidatedDatabaseAdapter) {
      db.enableValidation();
    }
  }

  /// 禁用验证
  static void disableValidation(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is ValidatedDatabaseAdapter) {
      db.disableValidation();
    }
  }

  /// 启用验证异常
  static void enableValidationExceptions(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is ValidatedDatabaseAdapter) {
      db.enableExceptions();
    }
  }

  /// 禁用验证异常
  static void disableValidationExceptions(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is ValidatedDatabaseAdapter) {
      db.disableExceptions();
    }
  }

  /// 设置是否包含已删除的数据
  static void setIncludeDeleted(BuildContext context, bool includeDeleted) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      db.setIncludeDeleted(includeDeleted);
    }
  }

  /// 获取是否包含已删除的数据
  static bool getIncludeDeleted(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      return db.getIncludeDeleted();
    }

    return false;
  }

  /// 设置已删除数据保留天数
  static void setDeletedDataRetentionDays(BuildContext context, int days) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      db.setDeletedDataRetentionDays(days);
    }
  }

  /// 获取已删除数据保留天数
  static int getDeletedDataRetentionDays(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      return db.getDeletedDataRetentionDays();
    }

    return 30; // 默认30天
  }

  /// 清理过期的已删除数据
  static Future<void> cleanupExpiredDeletedData(BuildContext context) async {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      await db.cleanupExpiredDeletedData();
    }
  }

  /// 清空回收站
  static Future<void> emptyTrash(BuildContext context) async {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      await db.emptyTrash();
    }
  }

  /// 获取软删除管理器
  static SoftDeleteManager? getSoftDeleteManager(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is SoftDeleteDatabaseAdapter) {
      return db.getSoftDeleteManager();
    }

    return null;
  }

  /// 启用加密
  static void enableEncryption(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is EncryptedDatabaseAdapter) {
      db.enableEncryption();
    }
  }

  /// 禁用加密
  static void disableEncryption(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is EncryptedDatabaseAdapter) {
      db.disableEncryption();
    }
  }

  /// 获取是否启用加密
  static bool isEncryptionEnabled(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is EncryptedDatabaseAdapter) {
      return db.isEncryptionEnabled();
    }

    return false;
  }

  /// 重置加密服务
  static Future<void> resetEncryption(BuildContext context) async {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is EncryptedDatabaseAdapter) {
      await db.resetEncryption();
    }
  }

  /// 启用数据库监控
  static void enableDatabaseMonitoring(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is DatabaseMonitoringAdapter) {
      db.enableMonitoring();
    }
  }

  /// 禁用数据库监控
  static void disableDatabaseMonitoring(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is DatabaseMonitoringAdapter) {
      db.disableMonitoring();
    }
  }

  /// 获取数据库性能报告
  static String getDatabasePerformanceReport(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is DatabaseMonitoringAdapter) {
      return db.getPerformanceReport();
    }

    return '数据库监控未启用';
  }

  /// 清除数据库监控数据
  static void clearDatabaseMonitoringData(BuildContext context) {
    final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
    final db = dbManager.getDatabase();

    if (db is DatabaseMonitoringAdapter) {
      db.clearMonitoringData();
    }
  }
}
