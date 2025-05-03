import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 错误处理服务
///
/// 提供统一的错误处理功能，捕获未处理的异常并记录日志
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  
  factory ErrorHandler() {
    return _instance;
  }
  
  ErrorHandler._internal();
  
  final LoggingService _loggingService = LoggingService();
  
  /// 初始化错误处理器
  void initialize() {
    // 捕获Flutter框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack, details.context.toString());
      // 在调试模式下重新抛出异常，以便在控制台显示完整的错误信息
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    
    // 捕获未处理的异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleError(error, stack, 'Async error');
      return true;
    };
  }
  
  /// 处理错误
  void _handleError(dynamic error, StackTrace? stackTrace, String context) {
    _loggingService.error('Unhandled error in $context', error, stackTrace);
    
    // 这里可以添加错误报告逻辑，如发送到Crashlytics或其他错误跟踪服务
  }
  
  /// 安全运行异步函数
  Future<T> runGuarded<T>(Future<T> Function() function, {
    String? context,
    Function(dynamic error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await function();
    } catch (e, stackTrace) {
      final errorContext = context ?? 'runGuarded';
      _handleError(e, stackTrace, errorContext);
      
      if (onError != null) {
        onError(e, stackTrace);
      }
      
      rethrow;
    }
  }
  
  /// 安全运行同步函数
  T runSyncGuarded<T>(T Function() function, {
    String? context,
    Function(dynamic error, StackTrace stackTrace)? onError,
  }) {
    try {
      return function();
    } catch (e, stackTrace) {
      final errorContext = context ?? 'runSyncGuarded';
      _handleError(e, stackTrace, errorContext);
      
      if (onError != null) {
        onError(e, stackTrace);
      }
      
      rethrow;
    }
  }
  
  /// 显示错误对话框
  void showErrorDialog(BuildContext context, String message, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 显示错误提示条
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
