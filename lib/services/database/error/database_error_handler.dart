import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 数据库错误处理类
///
/// 用于处理数据库操作中的错误，记录错误日志，并提供错误恢复机制
class DatabaseErrorHandler {
  // 日志标签
  static const String _tag = 'DatabaseErrorHandler';

  // 日志记录器
  static final logger = Logger();

  // 错误计数器
  static final Map<String, int> _errorCounts = {};

  // 最近的错误记录（最多保存100条）
  static final List<Map<String, dynamic>> _recentErrors = [];

  // 最大记录数
  static const int _maxRecentErrors = 100;

  // 错误回调函数
  static Function(Object error, StackTrace stackTrace, String operation, String? context)? _errorCallback;

  /// 设置错误回调函数
  static void setErrorCallback(
      Function(Object error, StackTrace stackTrace, String operation, String? context) callback) {
    _errorCallback = callback;
  }

  /// 处理错误
  static void handleError(
    Object error,
    StackTrace stackTrace,
    String operation, {
    String? context,
    bool shouldRethrow = true,
  }) {
    // 记录错误计数
    _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;

    // 记录错误详情
    final errorInfo = {
      'error': error.toString(),
      'operation': operation,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'count': _errorCounts[operation],
    };

    // 添加到最近错误列表
    _recentErrors.add(errorInfo);

    // 如果超过最大记录数，移除最早的记录
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }

    // 记录错误日志
    logger.e(_tag, '数据库操作错误: $operation ${context != null ? "($context)" : ""}: $error');
    if (kDebugMode) {
      logger.e(_tag, '堆栈跟踪: $stackTrace');
    }

    // 调用错误回调函数
    _errorCallback?.call(error, stackTrace, operation, context);

    // 如果需要重新抛出错误，则重新抛出
    if (shouldRethrow) {
      throw error;
    }
  }

  /// 获取错误计数
  static Map<String, int> getErrorCounts() {
    return Map<String, int>.from(_errorCounts);
  }

  /// 获取最近的错误记录
  static List<Map<String, dynamic>> getRecentErrors() {
    return List<Map<String, dynamic>>.from(_recentErrors);
  }

  /// 清除错误记录
  static void clearErrors() {
    _errorCounts.clear();
    _recentErrors.clear();
    logger.i(_tag, '错误记录已清除');
  }

  /// 获取错误报告
  static String getErrorReport() {
    final buffer = StringBuffer();
    buffer.writeln('数据库错误报告');
    buffer.writeln('=================');

    // 错误计数统计
    buffer.writeln('\n错误计数统计:');
    final sortedOperations = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedOperations) {
      buffer.writeln('  ${entry.key}: ${entry.value}次');
    }

    // 最近的错误记录
    buffer.writeln('\n最近的错误记录:');
    final recentErrors = List<Map<String, dynamic>>.from(_recentErrors.reversed);
    for (int i = 0; i < recentErrors.length && i < 10; i++) {
      final error = recentErrors[i];
      buffer.writeln('  ${i + 1}. 操作: ${error['operation']}');
      buffer.writeln('     错误: ${error['error']}');
      if (error['context'] != null) {
        buffer.writeln('     上下文: ${error['context']}');
      }
      buffer.writeln('     时间: ${error['timestamp']}');
      buffer.writeln('     计数: ${error['count']}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// 尝试执行数据库操作，如果失败则重试
  static Future<T> tryWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
    String? context,
  }) async {
    int retries = 0;
    while (true) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        retries++;
        if (retries >= maxRetries) {
          // 达到最大重试次数，处理错误并重新抛出
          handleError(
            e,
            stackTrace,
            operationName,
            context: '${context ?? ''} (重试 $retries/$maxRetries)',
          );
        }

        // 记录重试日志
        logger.w(_tag, '数据库操作失败，准备重试: $operationName ($retries/$maxRetries): $e');

        // 等待一段时间后重试
        await Future.delayed(retryDelay * retries);
      }
    }
  }
}
