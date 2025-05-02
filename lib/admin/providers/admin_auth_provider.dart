import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理后台认证提供者
///
/// 负责管理后台的登录状态和认证逻辑
class AdminAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  
  // 默认管理员账号和密码
  static const String _defaultUsername = 'admin';
  static const String _defaultPassword = 'admin123';
  
  // 登录状态存储键
  static const String _loginStateKey = 'admin_login_state';
  static const String _usernameKey = 'admin_username';
  
  /// 是否已登录
  bool get isLoggedIn => _isLoggedIn;
  
  /// 当前登录用户名
  String? get username => _username;
  
  /// 构造函数
  AdminAuthProvider() {
    _loadLoginState();
  }
  
  /// 加载登录状态
  Future<void> _loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_loginStateKey) ?? false;
      _username = prefs.getString(_usernameKey);
      notifyListeners();
    } catch (e) {
      debugPrint('加载登录状态失败: $e');
      _isLoggedIn = false;
      _username = null;
    }
  }
  
  /// 保存登录状态
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginStateKey, _isLoggedIn);
      if (_username != null) {
        await prefs.setString(_usernameKey, _username!);
      } else {
        await prefs.remove(_usernameKey);
      }
    } catch (e) {
      debugPrint('保存登录状态失败: $e');
    }
  }
  
  /// 登录
  ///
  /// 返回登录是否成功
  Future<bool> login(String username, String password) async {
    // 简单的认证逻辑，实际应用中应该使用更安全的方式
    if (username == _defaultUsername && password == _defaultPassword) {
      _isLoggedIn = true;
      _username = username;
      await _saveLoginState();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// 退出登录
  Future<void> logout() async {
    _isLoggedIn = false;
    _username = null;
    await _saveLoginState();
    notifyListeners();
  }
}
