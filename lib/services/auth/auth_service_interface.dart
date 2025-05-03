import 'package:jinlin_app/models/user/user.dart';

/// 认证服务接口
///
/// 定义认证服务的方法
abstract class AuthServiceInterface {
  /// 初始化认证服务
  Future<void> initialize();
  
  /// 获取当前用户
  User? get currentUser;
  
  /// 获取当前用户ID
  String? get currentUserId;
  
  /// 检查用户是否已登录
  bool get isLoggedIn;
  
  /// 检查用户是否是高级用户
  bool get isPremiumUser;
  
  /// 检查用户是否是管理员
  bool get isAdmin;
  
  /// 注册用户
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  });
  
  /// 登录
  Future<User> login({
    required String email,
    required String password,
  });
  
  /// 使用第三方服务登录
  Future<User> loginWithProvider(String provider);
  
  /// 登出
  Future<void> logout();
  
  /// 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email);
  
  /// 重置密码
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
  
  /// 更新用户信息
  Future<User> updateUserInfo({
    String? displayName,
    String? avatarUrl,
  });
  
  /// 更新密码
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// 更新电子邮件
  Future<void> updateEmail({
    required String password,
    required String newEmail,
  });
  
  /// 发送电子邮件验证
  Future<void> sendEmailVerification();
  
  /// 验证电子邮件
  Future<void> verifyEmail(String token);
  
  /// 删除账户
  Future<void> deleteAccount(String password);
  
  /// 获取访问令牌
  Future<String?> getAccessToken();
  
  /// 刷新访问令牌
  Future<String?> refreshAccessToken();
  
  /// 添加认证状态变化监听器
  void addAuthStateListener(void Function(User?) listener);
  
  /// 移除认证状态变化监听器
  void removeAuthStateListener(void Function(User?) listener);
  
  /// 关闭认证服务
  Future<void> close();
}
