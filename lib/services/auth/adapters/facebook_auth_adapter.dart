import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:jinlin_app/models/auth/auth_result.dart';
import 'package:jinlin_app/models/user/user.dart' as app_user;
import 'package:jinlin_app/services/auth/adapters/auth_adapter_interface.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// Facebook认证适配器
///
/// 处理Facebook登录逻辑
class FacebookAuthAdapter implements AuthAdapterInterface {
  // 日志服务
  final LoggingService _logger = LoggingService();
  
  // Facebook登录实例
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  
  // Firebase认证实例
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  // Facebook登录结果
  LoginResult? _loginResult;
  
  // Facebook用户数据
  Map<String, dynamic>? _userData;
  
  // Firebase用户
  firebase_auth.User? _firebaseUser;
  
  @override
  String get providerId => 'facebook.com';
  
  @override
  String get providerName => 'Facebook';
  
  @override
  Future<bool> initialize() async {
    try {
      _logger.info('初始化Facebook登录适配器');
      
      // 检查是否已登录
      final accessToken = await _facebookAuth.accessToken;
      
      if (accessToken != null) {
        // 获取用户数据
        final userData = await _facebookAuth.getUserData();
        _userData = userData;
        
        // 获取Firebase凭证
        final credential = firebase_auth.FacebookAuthProvider.credential(accessToken.token);
        
        // 登录Firebase
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        _firebaseUser = userCredential.user;
      }
      
      return true;
    } catch (e, stack) {
      _logger.error('初始化Facebook登录适配器失败', e, stack);
      return false;
    }
  }
  
  @override
  Future<AuthResult> signIn() async {
    try {
      _logger.info('使用Facebook登录');
      
      // 登出当前用户
      await signOut();
      
      // 显示Facebook登录界面
      _loginResult = await _facebookAuth.login();
      
      switch (_loginResult?.status) {
        case LoginStatus.success:
          // 获取用户数据
          _userData = await _facebookAuth.getUserData();
          
          // 获取Firebase凭证
          final credential = firebase_auth.FacebookAuthProvider.credential(
            _loginResult!.accessToken!.token,
          );
          
          // 登录Firebase
          final userCredential = await _firebaseAuth.signInWithCredential(credential);
          _firebaseUser = userCredential.user;
          
          if (_firebaseUser == null) {
            return AuthResult.failure(
              errorMessage: '无法获取用户信息',
              provider: providerId,
            );
          }
          
          // 创建用户对象
          final user = app_user.User(
            id: _firebaseUser!.uid,
            username: _userData?['name'] ?? '',
            email: _userData?['email'] ?? _firebaseUser!.email ?? '',
            displayName: _userData?['name'] ?? _firebaseUser!.displayName,
            avatarUrl: _userData?['picture']?['data']?['url'] ?? _firebaseUser!.photoURL,
            isEmailVerified: _firebaseUser!.emailVerified,
          );
          
          return AuthResult.success(
            user: user,
            token: _loginResult!.accessToken!.token,
            provider: providerId,
          );
          
        case LoginStatus.cancelled:
          return AuthResult.cancelled(provider: providerId);
          
        case LoginStatus.failed:
          return AuthResult.failure(
            errorMessage: _loginResult?.message ?? 'Facebook登录失败',
            provider: providerId,
          );
          
        case LoginStatus.operationInProgress:
          return AuthResult.failure(
            errorMessage: '登录操作正在进行中',
            provider: providerId,
          );
          
        default:
          return AuthResult.failure(
            errorMessage: '未知错误',
            provider: providerId,
          );
      }
    } catch (e, stack) {
      _logger.error('Facebook登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: providerId,
      );
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      _logger.info('Facebook登出');
      
      await _facebookAuth.logOut();
      await _firebaseAuth.signOut();
      
      _loginResult = null;
      _userData = null;
      _firebaseUser = null;
    } catch (e, stack) {
      _logger.error('Facebook登出失败', e, stack);
    }
  }
  
  @override
  Future<String?> getAccessToken() async {
    try {
      final accessToken = await _facebookAuth.accessToken;
      return accessToken?.token;
    } catch (e, stack) {
      _logger.error('获取Facebook访问令牌失败', e, stack);
      return null;
    }
  }
  
  @override
  Future<String?> refreshAccessToken() async {
    try {
      // Facebook SDK会自动刷新令牌
      final accessToken = await _facebookAuth.accessToken;
      return accessToken?.token;
    } catch (e, stack) {
      _logger.error('刷新Facebook访问令牌失败', e, stack);
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    if (_firebaseUser == null) {
      return null;
    }
    
    if (_userData == null) {
      try {
        _userData = await _facebookAuth.getUserData();
      } catch (e) {
        _logger.error('获取Facebook用户数据失败', e);
      }
    }
    
    return {
      'id': _firebaseUser!.uid,
      'username': _userData?['name'] ?? _firebaseUser!.displayName ?? '',
      'email': _userData?['email'] ?? _firebaseUser!.email ?? '',
      'displayName': _userData?['name'] ?? _firebaseUser!.displayName ?? '',
      'avatarUrl': _userData?['picture']?['data']?['url'] ?? _firebaseUser!.photoURL,
      'isEmailVerified': _firebaseUser!.emailVerified,
      'provider': providerId,
    };
  }
  
  @override
  Future<bool> isSignedIn() async {
    final accessToken = await _facebookAuth.accessToken;
    return accessToken != null && _firebaseUser != null;
  }
  
  @override
  Future<bool> isAvailable() async {
    return true; // Facebook登录在大多数平台上都可用
  }
  
  @override
  Future<void> dispose() async {
    // 无需特殊处理
  }
}
