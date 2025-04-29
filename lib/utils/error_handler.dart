import 'package:flutter/material.dart';
import 'package:jinlin_app/utils/logger.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message ${code ?? ''}'.trim();
}

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? fallbackMessage,
    bool showSnackBar = true,
    VoidCallback? onError,
  }) {
    String displayMessage;

    if (error is AppException) {
      displayMessage = error.message;
      Logger.error(error.message, error.originalError);
    } else {
      // 直接使用 fallbackMessage 或默认错误消息，不依赖于 l10n
      displayMessage = fallbackMessage ?? '操作失败，请稍后重试';
      Logger.error(displayMessage, error);
    }

    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    onError?.call();
  }
}