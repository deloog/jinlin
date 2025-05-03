import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// 日志服务
///
/// 提供统一的日志记录功能，支持控制台输出和文件记录
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  File? _logFile;
  bool _initialized = false;
  LogLevel _minLevel = LogLevel.debug;

  /// 初始化日志服务
  Future<void> initialize({LogLevel minLevel = LogLevel.debug}) async {
    if (_initialized) return;

    _minLevel = minLevel;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName = 'app_${DateFormat('yyyyMMdd').format(now)}.log';
      _logFile = File('${logDir.path}/$fileName');

      _initialized = true;

      info('日志服务初始化完成');
    } catch (e) {
      debugPrint('初始化日志服务失败: $e');
    }
  }

  /// 记录调试级别日志
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// 记录信息级别日志
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// 记录警告级别日志
  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// 记录错误级别日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final errorMessage = error != null ? '$message: $error' : message;
    _log(LogLevel.error, errorMessage);

    if (stackTrace != null) {
      _log(LogLevel.error, 'Stack trace: $stackTrace');
    }
  }

  /// 记录严重错误级别日志
  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    final errorMessage = error != null ? '$message: $error' : message;
    _log(LogLevel.critical, errorMessage);

    if (stackTrace != null) {
      _log(LogLevel.critical, 'Stack trace: $stackTrace');
    }
  }

  /// 内部日志记录方法
  void _log(LogLevel level, String message) {
    if (level.index < _minLevel.index) return;

    final now = DateTime.now();
    final formattedDate = _dateFormat.format(now);
    final logMessage = '[$formattedDate] ${_getLevelString(level)}: $message';

    // 打印到控制台
    debugPrint(logMessage);

    // 写入日志文件
    _writeToFile(logMessage);
  }

  /// 获取日志级别字符串
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  /// 写入日志文件
  Future<void> _writeToFile(String message) async {
    if (!_initialized || _logFile == null) return;

    try {
      await _logFile!.writeAsString('$message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('写入日志文件失败: $e');
    }
  }

  /// 获取日志文件列表
  Future<List<String>> getLogFiles() async {
    if (!_initialized) return [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().toList();
      return files
          .where((file) => file.path.endsWith('.log'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('获取日志文件列表失败: $e');
      return [];
    }
  }

  /// 读取日志文件内容
  Future<String?> readLogFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('读取日志文件失败: $e');
      return null;
    }
  }

  /// 清除所有日志
  Future<void> clearLogs() async {
    if (!_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await logDir.create();
      }

      info('日志已清除');
    } catch (e) {
      debugPrint('清除日志失败: $e');
    }
  }
}
