import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志工具类
///
/// 提供统一的日志记录接口，支持不同级别的日志记录
class Logger {
  // 单例模式
  static final Logger _instance = Logger._internal();

  factory Logger() {
    return _instance;
  }

  Logger._internal() {
    // 初始化日志文件
    _initLogFile();
  }

  // 当前日志级别
  LogLevel _currentLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  // 是否启用文件日志
  bool _enableFileLog = false;

  // 日志文件
  File? _logFile;

  // 日志监听器
  final List<void Function(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace})> _listeners = [];

  /// 初始化日志文件
  Future<void> _initLogFile() async {
    try {
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/logs';
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        _logFile = File('$path/app_log_$timestamp.log');
        _enableFileLog = true;
      }
    } catch (e) {
      debugPrint('初始化日志文件失败: $e');
      _enableFileLog = false;
    }
  }

  /// 设置日志级别
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 启用文件日志
  void enableFileLog() {
    _enableFileLog = true;
  }

  /// 禁用文件日志
  void disableFileLog() {
    _enableFileLog = false;
  }

  /// 添加日志监听器
  void addListener(void Function(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace}) listener) {
    _listeners.add(listener);
  }

  /// 移除日志监听器
  void removeListener(void Function(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace}) listener) {
    _listeners.remove(listener);
  }

  /// 记录调试日志
  void d(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, tag, message, error: error, stackTrace: stackTrace);
  }

  /// 记录信息日志
  void i(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, tag, message, error: error, stackTrace: stackTrace);
  }

  /// 记录警告日志
  void w(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, tag, message, error: error, stackTrace: stackTrace);
  }

  /// 记录错误日志
  void e(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  /// 记录致命错误日志
  void f(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, tag, message, error: error, stackTrace: stackTrace);
  }

  /// 记录日志
  void _log(LogLevel level, String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    // 检查日志级别
    if (level.index < _currentLevel.index) {
      return;
    }

    // 格式化日志消息
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] $levelStr/$tag: $message';

    // 控制台输出
    if (kDebugMode) {
      if (error != null) {
        print('$logMessage\nError: $error');
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      } else {
        print(logMessage);
      }
    }

    // 使用Flutter开发者日志
    developer.log(
      message,
      name: tag,
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );

    // 文件日志
    if (_enableFileLog && _logFile != null) {
      _writeToFile(logMessage, error, stackTrace);
    }

    // 通知监听器
    for (final listener in _listeners) {
      listener(level, tag, message, error: error, stackTrace: stackTrace);
    }
  }

  /// 获取日志级别对应的数值
  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  /// 写入日志文件
  Future<void> _writeToFile(String message, dynamic error, StackTrace? stackTrace) async {
    if (_logFile == null) return;

    try {
      String content = message;
      if (error != null) {
        content += '\nError: $error';
      }
      if (stackTrace != null) {
        content += '\nStackTrace: $stackTrace';
      }
      content += '\n';

      await _logFile!.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      debugPrint('写入日志文件失败: $e');
    }
  }

  // 兼容旧版API
  static void log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    final logger = Logger();
    logger._log(level, 'App', message, error: error, stackTrace: stackTrace);
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

/// 全局日志实例
final logger = Logger();
