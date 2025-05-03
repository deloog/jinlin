/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// 日志服务接口
///
/// 定义日志服务的方法
abstract class LoggingServiceInterface {
  /// 初始化日志服务
  Future<void> initialize();
  
  /// 记录调试级别日志
  void debug(String message);
  
  /// 记录信息级别日志
  void info(String message);
  
  /// 记录警告级别日志
  void warning(String message);
  
  /// 记录错误级别日志
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  
  /// 记录严重错误级别日志
  void critical(String message, [dynamic error, StackTrace? stackTrace]);
  
  /// 获取日志大小
  Future<int> getLogSize();
  
  /// 获取日志内容
  Future<String> getLogs();
  
  /// 清除日志
  Future<void> clearLogs();
  
  /// 设置日志级别
  void setLogLevel(LogLevel level);
  
  /// 获取日志级别
  LogLevel getLogLevel();
  
  /// 关闭日志服务
  Future<void> close();
}
