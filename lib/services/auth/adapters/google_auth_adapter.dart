import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jinlin_app/models/auth/auth_result.dart';
import 'package:jinlin_app/models/user/user.dart' as app_user;
import 'package:jinlin_app/services/auth/adapters/auth_adapter_interface.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// Google认证适配器
///
/// 处理Google登录逻辑
class GoogleAuthAdapter implements AuthAdapterInterface {
  // 日志服务
  final LoggingService _logger = LoggingService();

  // Google登录实例
  late final GoogleSignIn _googleSignIn;

  // 构造函数
  GoogleAuthAdapter() {
    // 在Web平台上，需要提供clientId
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        // 在实际应用中，应该从环境变量或配置文件中获取clientId
        clientId: '123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com',
      );
    } else {
      _googleSignIn = GoogleSignIn();
    }
  }

  // Firebase认证实例
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Google用户
  GoogleSignInAccount? _googleUser;

  // Google认证
  GoogleSignInAuthentication? _googleAuth;

  // Firebase用户
  firebase_auth.User? _firebaseUser;

  @override
  String get providerId => 'google.com';

  @override
  String get providerName => 'Google';

  @override
  Future<bool> initialize() async {
    try {
      _logger.info('初始化Google登录适配器');

      // 在Web平台上，我们使用了一个假的clientId，所以不进行初始化
      if (kIsWeb) {
        _logger.info('在Web平台上跳过Google登录初始化');
        return true;
      }

      // 检查是否已登录
      _googleUser = await _googleSignIn.signInSilently();

      if (_googleUser != null) {
        _googleAuth = await _googleUser!.authentication;

        // 获取Firebase凭证
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: _googleAuth!.accessToken,
          idToken: _googleAuth!.idToken,
        );

        // 登录Firebase
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        _firebaseUser = userCredential.user;
      }

      return true;
    } catch (e, stack) {
      _logger.error('初始化Google登录适配器失败', e, stack);
      return false;
    }
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      _logger.info('使用Google登录');

      // 在Web平台上，我们使用了一个假的clientId，所以不进行登录
      if (kIsWeb) {
        _logger.info('在Web平台上不支持Google登录');
        return AuthResult.failure(
          errorMessage: '在Web平台上不支持Google登录',
          provider: providerId,
        );
      }

      // 登出当前用户
      await signOut();

      // 显示Google登录界面
      _googleUser = await _googleSignIn.signIn();

      if (_googleUser == null) {
        return AuthResult.cancelled(provider: providerId);
      }

      // 获取认证信息
      _googleAuth = await _googleUser!.authentication;

      // 获取Firebase凭证
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: _googleAuth!.accessToken,
        idToken: _googleAuth!.idToken,
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
        username: _firebaseUser!.displayName ?? _googleUser!.displayName ?? '',
        email: _firebaseUser!.email ?? _googleUser!.email,
        displayName: _firebaseUser!.displayName ?? _googleUser!.displayName,
        avatarUrl: _firebaseUser!.photoURL ?? _googleUser!.photoUrl,
        isEmailVerified: _firebaseUser!.emailVerified,
      );

      return AuthResult.success(
        user: user,
        token: _googleAuth!.accessToken,
        provider: providerId,
      );
    } catch (e, stack) {
      _logger.error('Google登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: providerId,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.info('Google登出');

      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      _googleUser = null;
      _googleAuth = null;
      _firebaseUser = null;
    } catch (e, stack) {
      _logger.error('Google登出失败', e, stack);
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      if (_googleAuth?.accessToken == null && _googleUser != null) {
        _googleAuth = await _googleUser!.authentication;
      }

      return _googleAuth?.accessToken;
    } catch (e, stack) {
      _logger.error('获取Google访问令牌失败', e, stack);
      return null;
    }
  }

  @override
  Future<String?> refreshAccessToken() async {
    try {
      if (_googleUser != null) {
        _googleAuth = await _googleUser!.authentication;
        return _googleAuth?.accessToken;
      }

      return null;
    } catch (e, stack) {
      _logger.error('刷新Google访问令牌失败', e, stack);
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    if (_firebaseUser == null) {
      return null;
    }

    return {
      'id': _firebaseUser!.uid,
      'username': _firebaseUser!.displayName ?? _googleUser?.displayName ?? '',
      'email': _firebaseUser!.email ?? _googleUser?.email ?? '',
      'displayName': _firebaseUser!.displayName ?? _googleUser?.displayName ?? '',
      'avatarUrl': _firebaseUser!.photoURL ?? _googleUser?.photoUrl,
      'isEmailVerified': _firebaseUser!.emailVerified,
      'provider': providerId,
    };
  }

  @override
  Future<bool> isSignedIn() async {
    return _googleUser != null && _firebaseUser != null;
  }

  @override
  Future<bool> isAvailable() async {
    // 在Web平台上，我们需要一个有效的clientId
    // 由于我们使用了一个假的clientId，所以在Web平台上不可用
    if (kIsWeb) {
      return false;
    }
    return true; // Google登录在大多数平台上都可用
  }

  @override
  Future<void> dispose() async {
    // 无需特殊处理
  }
}
