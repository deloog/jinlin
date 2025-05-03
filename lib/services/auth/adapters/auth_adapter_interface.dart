import 'package:jinlin_app/models/auth/auth_result.dart';

/// 认证适配器接口
///
/// 定义认证适配器的通用接口，用于处理不同平台的登录逻辑
abstract class AuthAdapterInterface {
  /// 初始化适配器
  ///
  /// 返回是否初始化成功
  Future<bool> initialize();
  
  /// 登录
  ///
  /// 执行登录操作，返回登录结果
  Future<AuthResult> signIn();
  
  /// 登出
  ///
  /// 执行登出操作
  Future<void> signOut();
  
  /// 获取访问令牌
  ///
  /// 返回当前的访问令牌
  Future<String?> getAccessToken();
  
  /// 刷新访问令牌
  ///
  /// 刷新并返回新的访问令牌
  Future<String?> refreshAccessToken();
  
  /// 获取用户信息
  ///
  /// 返回用户信息
  Future<Map<String, dynamic>?> getUserInfo();
  
  /// 检查是否已登录
  ///
  /// 返回是否已登录
  Future<bool> isSignedIn();
  
  /// 获取提供者ID
  ///
  /// 返回提供者ID
  String get providerId;
  
  /// 获取提供者名称
  ///
  /// 返回提供者名称
  String get providerName;
  
  /// 检查是否可用
  ///
  /// 返回当前平台是否支持该提供者
  Future<bool> isAvailable();
  
  /// 关闭适配器
  ///
  /// 释放资源
  Future<void> dispose();
}
