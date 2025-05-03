import 'package:jinlin_app/models/auth/auth_result.dart';

/// 第三方登录服务接口
///
/// 定义第三方登录服务的接口
abstract class ThirdPartyAuthServiceInterface {
  /// 使用Google登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithGoogle();
  
  /// 使用Facebook登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithFacebook();
  
  /// 使用Twitter登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithTwitter();
  
  /// 使用Apple登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithApple();
  
  /// 使用微信登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithWeChat();
  
  /// 使用QQ登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithQQ();
  
  /// 使用微博登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithWeibo();
  
  /// 使用抖音登录
  ///
  /// 返回登录结果
  Future<AuthResult> signInWithTikTok();
  
  /// 获取当前登录的第三方平台
  ///
  /// 返回当前登录的第三方平台，如果未登录则返回null
  Future<String?> getCurrentProvider();
  
  /// 退出登录
  ///
  /// 退出当前登录的第三方平台
  Future<void> signOut();
  
  /// 获取第三方平台的用户信息
  ///
  /// 返回第三方平台的用户信息
  Future<Map<String, dynamic>?> getUserInfo();
  
  /// 获取第三方平台的访问令牌
  ///
  /// 返回第三方平台的访问令牌
  Future<String?> getAccessToken();
  
  /// 刷新第三方平台的访问令牌
  ///
  /// 返回刷新后的访问令牌
  Future<String?> refreshAccessToken();
  
  /// 检查第三方平台的访问令牌是否有效
  ///
  /// 返回访问令牌是否有效
  Future<bool> isAccessTokenValid();
  
  /// 获取第三方平台的用户ID
  ///
  /// 返回第三方平台的用户ID
  Future<String?> getUserId();
  
  /// 获取第三方平台的用户名
  ///
  /// 返回第三方平台的用户名
  Future<String?> getUsername();
  
  /// 获取第三方平台的用户头像
  ///
  /// 返回第三方平台的用户头像URL
  Future<String?> getAvatarUrl();
  
  /// 获取第三方平台的用户邮箱
  ///
  /// 返回第三方平台的用户邮箱
  Future<String?> getEmail();
  
  /// 初始化第三方登录服务
  ///
  /// 初始化第三方登录服务，返回是否初始化成功
  Future<bool> initialize();
  
  /// 关闭第三方登录服务
  ///
  /// 关闭第三方登录服务，释放资源
  Future<void> dispose();
  
  /// 检查第三方平台是否可用
  ///
  /// 检查指定的第三方平台是否可用
  Future<bool> isProviderAvailable(String provider);
  
  /// 获取所有可用的第三方平台
  ///
  /// 返回所有可用的第三方平台
  Future<List<String>> getAvailableProviders();
  
  /// 链接第三方平台账号
  ///
  /// 将当前账号与指定的第三方平台账号关联
  Future<AuthResult> linkProvider(String provider);
  
  /// 解除第三方平台账号关联
  ///
  /// 解除当前账号与指定的第三方平台账号的关联
  Future<AuthResult> unlinkProvider(String provider);
  
  /// 获取已关联的第三方平台账号
  ///
  /// 返回当前账号已关联的所有第三方平台账号
  Future<List<String>> getLinkedProviders();
}
