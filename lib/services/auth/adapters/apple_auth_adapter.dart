import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/models/auth/auth_result.dart';
import 'package:jinlin_app/models/user/user.dart' as app_user;
import 'package:jinlin_app/services/auth/adapters/auth_adapter_interface.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple认证适配器
///
/// 处理Apple登录逻辑
class AppleAuthAdapter implements AuthAdapterInterface {
  // 日志服务
  final LoggingService _logger = LoggingService();

  // Firebase认证实例
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Apple凭证
  AuthorizationCredentialAppleID? _appleCredential;

  // Firebase用户
  firebase_auth.User? _firebaseUser;

  @override
  String get providerId => 'apple.com';

  @override
  String get providerName => 'Apple';

  @override
  Future<bool> initialize() async {
    try {
      _logger.info('初始化Apple登录适配器');

      // 检查当前用户是否使用Apple登录
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        try {
          // 查找是否有Apple提供商
          currentUser.providerData
              .firstWhere(
                (element) => element.providerId == providerId,
              );

          // 如果找到了Apple提供商，设置当前用户
          _firebaseUser = currentUser;
        } catch (e) {
          // 没有找到Apple提供商，忽略
        }
      }

      return true;
    } catch (e, stack) {
      _logger.error('初始化Apple登录适配器失败', e, stack);
      return false;
    }
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      _logger.info('使用Apple登录');

      // 检查是否可用
      if (!await isAvailable()) {
        return AuthResult.failure(
          errorMessage: 'Apple登录在当前平台不可用',
          provider: providerId,
        );
      }

      // 登出当前用户
      await signOut();

      // 获取Apple登录凭证
      _appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 获取OAuthProvider
      final oauthProvider = firebase_auth.OAuthProvider('apple.com');

      // 获取Firebase凭证
      final credential = oauthProvider.credential(
        idToken: _appleCredential!.identityToken,
        accessToken: _appleCredential!.authorizationCode,
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

      // 更新用户信息（如果有）
      if (_appleCredential!.givenName != null || _appleCredential!.familyName != null) {
        final displayName = [
          _appleCredential!.givenName,
          _appleCredential!.familyName,
        ].where((name) => name != null).join(' ');

        if (displayName.isNotEmpty) {
          await _firebaseUser!.updateDisplayName(displayName);
        }
      }

      // 刷新用户信息
      await _firebaseUser!.reload();
      _firebaseUser = _firebaseAuth.currentUser;

      // 创建用户对象
      final user = app_user.User(
        id: _firebaseUser!.uid,
        username: _firebaseUser!.displayName ?? _firebaseUser!.email?.split('@').first ?? '',
        email: _firebaseUser!.email ?? '',
        displayName: _firebaseUser!.displayName,
        avatarUrl: _firebaseUser!.photoURL,
        isEmailVerified: _firebaseUser!.emailVerified,
      );

      return AuthResult.success(
        user: user,
        token: _appleCredential!.identityToken,
        provider: providerId,
      );
    } catch (e, stack) {
      _logger.error('Apple登录失败', e, stack);

      // 检查是否是用户取消
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled(provider: providerId);
      }

      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: providerId,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.info('Apple登出');

      await _firebaseAuth.signOut();

      _appleCredential = null;
      _firebaseUser = null;
    } catch (e, stack) {
      _logger.error('Apple登出失败', e, stack);
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return _appleCredential?.identityToken;
  }

  @override
  Future<String?> refreshAccessToken() async {
    // Apple不提供刷新令牌的方法，需要重新登录
    return _appleCredential?.identityToken;
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    if (_firebaseUser == null) {
      return null;
    }

    return {
      'id': _firebaseUser!.uid,
      'username': _firebaseUser!.displayName ?? _firebaseUser!.email?.split('@').first ?? '',
      'email': _firebaseUser!.email ?? '',
      'displayName': _firebaseUser!.displayName ?? '',
      'avatarUrl': _firebaseUser!.photoURL,
      'isEmailVerified': _firebaseUser!.emailVerified,
      'provider': providerId,
    };
  }

  @override
  Future<bool> isSignedIn() async {
    return _firebaseUser != null;
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false; // Web平台不支持Apple登录
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return true; // iOS和macOS平台支持Apple登录
    }

    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    // 无需特殊处理
  }
}
