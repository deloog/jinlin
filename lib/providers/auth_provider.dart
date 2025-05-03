import 'package:flutter/material.dart';
import 'package:jinlin_app/models/user/user.dart';
import 'package:jinlin_app/services/auth/auth_service.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 认证状态提供者
///
/// 管理应用程序的认证状态
class AuthProvider extends ChangeNotifier {
  // 认证服务
  final AuthService _authService;
  
  // 日志服务
  final LoggingService _logger = LoggingService();
  
  // 是否正在加载
  bool _isLoading = false;
  
  // 错误消息
  String? _errorMessage;
  
  /// 构造函数
  AuthProvider({
    required AuthService authService,
  }) : _authService = authService {
    _logger.debug('初始化认证状态提供者');
    
    // 添加认证状态变化监听器
    _authService.addAuthStateListener(_onAuthStateChanged);
  }
  
  /// 获取当前用户
  User? get currentUser => _authService.currentUser;
  
  /// 获取当前用户ID
  String? get currentUserId => _authService.currentUserId;
  
  /// 检查用户是否已登录
  bool get isLoggedIn => _authService.isLoggedIn;
  
  /// 检查用户是否是高级用户
  bool get isPremiumUser => _authService.isPremiumUser;
  
  /// 检查用户是否是管理员
  bool get isAdmin => _authService.isAdmin;
  
  /// 获取是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取错误消息
  String? get errorMessage => _errorMessage;
  
  /// 注册用户
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 登录
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.login(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 使用第三方服务登录
  Future<bool> loginWithProvider(String provider) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.loginWithProvider(provider);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 登出
  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.logout();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// 发送密码重置邮件
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 重置密码
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 更新用户信息
  Future<bool> updateUserInfo({
    String? displayName,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserInfo(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 更新密码
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 更新电子邮件
  Future<bool> updateEmail({
    required String password,
    required String newEmail,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateEmail(
        password: password,
        newEmail: newEmail,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 发送电子邮件验证
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendEmailVerification();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 验证电子邮件
  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.verifyEmail(token);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 删除账户
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.deleteAccount(password);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置错误消息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除错误消息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 认证状态变化回调
  void _onAuthStateChanged(User? user) {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _logger.debug('销毁认证状态提供者');
    
    // 移除认证状态变化监听器
    _authService.removeAuthStateListener(_onAuthStateChanged);
    
    super.dispose();
  }
}
