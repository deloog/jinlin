import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static void log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {  // 在发布模式下可以禁用某些级别的日志
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = level.toString().split('.').last.toUpperCase();
      
      print('[$timestamp][$levelStr] $message');
      
      if (error != null) {
        print('Error details: $error');
      }
      
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }

  static void debug(String message) {
    log(LogLevel.debug, message);
  }

  static void info(String message) {
    log(LogLevel.info, message);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error, stackTrace);
  }
}
