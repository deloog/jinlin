import 'package:jinlin_app/models/user/user.dart';

/// 认证结果
///
/// 表示认证操作的结果
class AuthResult {
  /// 是否成功
  final bool success;
  
  /// 用户
  final User? user;
  
  /// 令牌
  final String? token;
  
  /// 错误消息
  final String? errorMessage;
  
  /// 提供者
  final String? provider;
  
  /// 构造函数
  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.errorMessage,
    this.provider,
  });
  
  /// 创建成功结果
  factory AuthResult.success({
    required User user,
    String? token,
    String? provider,
  }) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
      provider: provider,
    );
  }
  
  /// 创建失败结果
  factory AuthResult.failure({
    required String errorMessage,
    String? provider,
  }) {
    return AuthResult(
      success: false,
      errorMessage: errorMessage,
      provider: provider,
    );
  }
  
  /// 创建取消结果
  factory AuthResult.cancelled({
    String? provider,
  }) {
    return AuthResult(
      success: false,
      errorMessage: '用户取消登录',
      provider: provider,
    );
  }
  
  @override
  String toString() {
    return 'AuthResult{'
        'success: $success, '
        'user: ${user?.id}, '
        'token: ${token != null ? '***' : 'null'}, '
        'errorMessage: $errorMessage, '
        'provider: $provider'
        '}';
  }
}
