// 文件： lib/services/error_handling_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jinlin_app/utils/logger.dart';
import 'package:jinlin_app/utils/error_handler.dart';

/// 全局错误处理服务
///
/// 用于捕获和处理应用程序中的各种错误，包括：
/// 1. Flutter框架错误
/// 2. 未捕获的异步错误
/// 3. 区域错误
/// 4. 平台错误
class ErrorHandlingService {
  // 单例模式
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();

  factory ErrorHandlingService() {
    return _instance;
  }

  ErrorHandlingService._internal();

  // 全局导航键，用于在没有上下文的情况下显示错误消息
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // 初始化错误处理
  void initialize() {
    // 设置Flutter错误处理器
    FlutterError.onError = _handleFlutterError;

    // 设置未捕获的异步错误处理器
    PlatformDispatcher.instance.onError = _handlePlatformError;

    // 添加日志监听器
    logger.addListener(_logListener);

    // 捕获区域错误
    runZonedGuarded(
      () {
        // 应用程序已经在main.dart中启动
      },
      _handleZoneError,
    );

    Logger.info('错误处理服务已初始化');
  }

  // 处理Flutter框架错误
  void _handleFlutterError(FlutterErrorDetails details) {
    Logger.error(
      '捕获到Flutter框架错误',
      details.exception,
      details.stack,
    );

    // 在调试模式下重新抛出错误，以便在控制台显示完整的错误信息
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }

    // 显示错误消息
    _showErrorMessage('应用程序遇到了问题，请稍后重试');
  }

  // 处理平台错误
  bool _handlePlatformError(Object error, StackTrace stack) {
    Logger.error(
      '捕获到平台错误',
      error,
      stack,
    );

    // 显示错误消息
    _showErrorMessage('应用程序遇到了问题，请稍后重试');

    // 返回true表示错误已处理
    return true;
  }

  // 处理区域错误
  void _handleZoneError(Object error, StackTrace stack) {
    Logger.error(
      '捕获到区域错误',
      error,
      stack,
    );

    // 显示错误消息
    _showErrorMessage('应用程序遇到了问题，请稍后重试');
  }

  // 日志监听器
  void _logListener(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    // 只处理错误和致命错误
    if (level == LogLevel.error || level == LogLevel.fatal) {
      // 可以在这里添加额外的处理逻辑，例如发送错误报告到服务器
    }
  }

  // 显示错误消息
  void _showErrorMessage(String message) {
    // 获取当前上下文
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      // 使用ErrorHandler显示错误消息
      ErrorHandler.handleError(
        context,
        AppException(message),
        showSnackBar: true,
      );
    } else {
      // 如果没有上下文，只记录错误
      Logger.error('无法显示错误消息，上下文不可用: $message');
    }
  }

  // 处理特定错误
  void handleError(BuildContext context, dynamic error, {String? fallbackMessage}) {
    ErrorHandler.handleError(
      context,
      error,
      fallbackMessage: fallbackMessage,
      showSnackBar: true,
    );
  }
}

// 全局错误处理服务实例
final errorHandlingService = ErrorHandlingService();
