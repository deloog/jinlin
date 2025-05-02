import 'package:sqflite/sqflite.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 数据库错误类型
enum DatabaseErrorType {
  // 一般错误
  general,

  // 连接错误
  connection,

  // 查询错误
  query,

  // 事务错误
  transaction,

  // 数据错误
  data,

  // 初始化错误
  initialization,

  // 升级错误
  upgrade,

  // 权限错误
  permission,

  // 同步错误
  sync,

  // 未知错误
  unknown,
}

/// 数据库错误处理工具类
///
/// 提供统一的数据库错误处理接口，支持不同类型的数据库错误处理
class DatabaseErrorHandler {
  // 日志标签
  static const String _tag = 'DatabaseError';

  /// 处理数据库错误
  static void handleError(dynamic error, StackTrace? stackTrace, String operation, {String? context}) {
    // 确定错误类型
    final errorType = _determineErrorType(error);

    // 构建错误消息
    final message = _buildErrorMessage(errorType, operation, context);

    // 记录错误日志
    logger.e(_tag, message, error: error, stackTrace: stackTrace);

    // 根据错误类型执行特定处理
    _handleSpecificError(errorType, error, operation);
  }

  /// 确定错误类型
  static DatabaseErrorType _determineErrorType(dynamic error) {
    if (error is DatabaseException) {
      // SQLite错误
      final code = error.getResultCode();

      if (code == null) {
        return DatabaseErrorType.general;
      }

      switch (code) {
        case 1:  // SQL错误
          return DatabaseErrorType.query;
        case 5:  // 数据库繁忙
        case 6:  // 数据库锁定
          return DatabaseErrorType.connection;
        case 8:  // 只读数据库
        case 9:  // 中断
        case 10: // IO错误
        case 11: // 磁盘已满
          return DatabaseErrorType.permission;
        case 19: // 约束失败
        case 20: // 数据类型不匹配
          return DatabaseErrorType.data;
        default:
          return DatabaseErrorType.general;
      }
    } else if (error is Exception) {
      // 其他异常
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('connection') || errorString.contains('network')) {
        return DatabaseErrorType.connection;
      } else if (errorString.contains('permission') || errorString.contains('access')) {
        return DatabaseErrorType.permission;
      } else if (errorString.contains('transaction')) {
        return DatabaseErrorType.transaction;
      } else if (errorString.contains('init') || errorString.contains('open')) {
        return DatabaseErrorType.initialization;
      } else if (errorString.contains('upgrade') || errorString.contains('version')) {
        return DatabaseErrorType.upgrade;
      } else if (errorString.contains('sync')) {
        return DatabaseErrorType.sync;
      }
    }

    return DatabaseErrorType.unknown;
  }

  /// 构建错误消息
  static String _buildErrorMessage(DatabaseErrorType errorType, String operation, String? context) {
    final contextInfo = context != null ? ' ($context)' : '';
    final baseMessage = '数据库操作失败: $operation$contextInfo';

    switch (errorType) {
      case DatabaseErrorType.connection:
        return '$baseMessage - 连接错误';
      case DatabaseErrorType.query:
        return '$baseMessage - 查询错误';
      case DatabaseErrorType.transaction:
        return '$baseMessage - 事务错误';
      case DatabaseErrorType.data:
        return '$baseMessage - 数据错误';
      case DatabaseErrorType.initialization:
        return '$baseMessage - 初始化错误';
      case DatabaseErrorType.upgrade:
        return '$baseMessage - 升级错误';
      case DatabaseErrorType.permission:
        return '$baseMessage - 权限错误';
      case DatabaseErrorType.sync:
        return '$baseMessage - 同步错误';
      case DatabaseErrorType.general:
        return '$baseMessage - 一般错误';
      case DatabaseErrorType.unknown:
        return '$baseMessage - 未知错误';
    }
  }

  /// 处理特定类型的错误
  static void _handleSpecificError(DatabaseErrorType errorType, dynamic error, String operation) {
    switch (errorType) {
      case DatabaseErrorType.connection:
        // 可以在这里添加重试逻辑
        break;
      case DatabaseErrorType.permission:
        // 可以在这里添加权限请求逻辑
        break;
      case DatabaseErrorType.initialization:
        // 可以在这里添加数据库重置逻辑
        break;
      default:
        // 默认不做特殊处理
        break;
    }
  }

  /// 获取SQLite错误码
  static int? getResultCode(DatabaseException error) {
    // 尝试从错误消息中提取错误码
    final message = error.toString();
    final regex = RegExp(r'Error code (\d+)');
    final match = regex.firstMatch(message);

    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }
}

/// 扩展DatabaseException类，添加获取错误码的方法
extension DatabaseExceptionExtension on DatabaseException {
  int? getResultCode() {
    return DatabaseErrorHandler.getResultCode(this);
  }
}
