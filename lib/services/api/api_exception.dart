/// API异常
///
/// 表示API请求过程中发生的异常
class ApiException implements Exception {
  /// HTTP状态码
  final int statusCode;
  
  /// 错误消息
  final String message;
  
  /// 响应体
  final String? body;
  
  /// 原始错误
  final dynamic error;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
    this.error,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message (状态码: $statusCode)');
    
    if (body != null && body!.isNotEmpty) {
      buffer.write('\n响应体: $body');
    }
    
    if (error != null) {
      buffer.write('\n原始错误: $error');
    }
    
    return buffer.toString();
  }
}
