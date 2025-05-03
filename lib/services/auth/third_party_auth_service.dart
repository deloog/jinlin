import 'dart:async';
import 'dart:convert';
import 'package:jinlin_app/models/auth/auth_result.dart';
import 'package:jinlin_app/services/auth/adapters/auth_adapter_factory.dart';
import 'package:jinlin_app/services/auth/adapters/auth_adapter_interface.dart';
import 'package:jinlin_app/services/auth/third_party_auth_service_interface.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 第三方登录服务
///
/// 实现第三方登录服务接口
class ThirdPartyAuthService implements ThirdPartyAuthServiceInterface {
  // 单例实例
  static final ThirdPartyAuthService _instance = ThirdPartyAuthService._internal();

  // 工厂构造函数
  factory ThirdPartyAuthService() => _instance;

  // 私有构造函数
  ThirdPartyAuthService._internal();

  // 日志服务
  final LoggingService _logger = LoggingService();

  // 适配器工厂
  final AuthAdapterFactory _adapterFactory = AuthAdapterFactory();

  // 当前登录的第三方平台
  String? _currentProvider;

  // 当前适配器
  AuthAdapterInterface? _currentAdapter;

  // 用户信息
  Map<String, dynamic>? _userInfo;

  // 访问令牌
  String? _accessToken;

  // 是否已初始化
  bool _initialized = false;

  // 可用的第三方平台
  final List<String> _availableProviders = [];

  // 已关联的第三方平台
  final List<String> _linkedProviders = [];

  @override
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    try {
      _logger.info('初始化第三方登录服务');

      // 获取可用的第三方平台
      _availableProviders.clear();
      _availableProviders.addAll(await _adapterFactory.getAvailableProviders());

      // 加载保存的登录状态
      await _loadLoginState();

      // 如果有当前提供者，初始化适配器
      if (_currentProvider != null) {
        _currentAdapter = await _adapterFactory.getAdapter(_currentProvider!);

        if (_currentAdapter == null) {
          _logger.warning('无法获取适配器: $_currentProvider');
          await _clearLoginState();
        } else {
          // 检查是否已登录
          final isSignedIn = await _currentAdapter!.isSignedIn();

          if (!isSignedIn) {
            _logger.warning('用户未登录: $_currentProvider');
            await _clearLoginState();
          } else {
            // 获取用户信息
            _userInfo = await _currentAdapter!.getUserInfo();

            // 获取访问令牌
            _accessToken = await _currentAdapter!.getAccessToken();
          }
        }
      }

      _initialized = true;
      _logger.info('第三方登录服务初始化成功');
      return true;
    } catch (e, stack) {
      _logger.error('初始化第三方登录服务失败', e, stack);
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _logger.info('关闭第三方登录服务');

    // 关闭适配器工厂
    await _adapterFactory.dispose();

    // 如果有当前适配器，关闭它
    if (_currentAdapter != null) {
      await _currentAdapter!.dispose();
      _currentAdapter = null;
    }

    _initialized = false;
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      _logger.info('使用Google登录');

      // 获取Google适配器
      final adapter = await _adapterFactory.getAdapter('google.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: 'Google登录不可用',
          provider: 'google.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('Google登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'google.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    try {
      _logger.info('使用Facebook登录');

      // 获取Facebook适配器
      final adapter = await _adapterFactory.getAdapter('facebook.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: 'Facebook登录不可用',
          provider: 'facebook.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('Facebook登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'facebook.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithTwitter() async {
    try {
      _logger.info('使用Twitter登录');

      // 获取Twitter适配器
      final adapter = await _adapterFactory.getAdapter('twitter.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: 'Twitter登录不可用',
          provider: 'twitter.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('Twitter登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'twitter.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      _logger.info('使用Apple登录');

      // 获取Apple适配器
      final adapter = await _adapterFactory.getAdapter('apple.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: 'Apple登录不可用',
          provider: 'apple.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('Apple登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'apple.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithWeChat() async {
    try {
      _logger.info('使用微信登录');

      // 获取微信适配器
      final adapter = await _adapterFactory.getAdapter('wechat.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: '微信登录不可用',
          provider: 'wechat.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('微信登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'wechat.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithQQ() async {
    try {
      _logger.info('使用QQ登录');

      // 获取QQ适配器
      final adapter = await _adapterFactory.getAdapter('qq.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: 'QQ登录不可用',
          provider: 'qq.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('QQ登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'qq.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithWeibo() async {
    try {
      _logger.info('使用微博登录');

      // 获取微博适配器
      final adapter = await _adapterFactory.getAdapter('weibo.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: '微博登录不可用',
          provider: 'weibo.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('微博登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'weibo.com',
      );
    }
  }

  @override
  Future<AuthResult> signInWithTikTok() async {
    try {
      _logger.info('使用抖音登录');

      // 获取抖音适配器
      final adapter = await _adapterFactory.getAdapter('tiktok.com');

      if (adapter == null) {
        return AuthResult.failure(
          errorMessage: '抖音登录不可用',
          provider: 'tiktok.com',
        );
      }

      // 执行登录
      final result = await adapter.signIn();

      if (result.success) {
        // 更新当前状态
        _currentProvider = adapter.providerId;
        _currentAdapter = adapter;
        _userInfo = await adapter.getUserInfo();
        _accessToken = await adapter.getAccessToken();

        // 保存登录状态
        await _saveLoginState();
      }

      return result;
    } catch (e, stack) {
      _logger.error('抖音登录失败', e, stack);
      return AuthResult.failure(
        errorMessage: e.toString(),
        provider: 'tiktok.com',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _logger.info('退出登录');

    // 如果有当前适配器，调用其登出方法
    if (_currentAdapter != null) {
      await _currentAdapter!.signOut();
    }

    _currentProvider = null;
    _currentAdapter = null;
    _userInfo = null;
    _accessToken = null;

    // 清除保存的登录状态
    await _clearLoginState();
  }

  @override
  Future<String?> getCurrentProvider() async {
    return _currentProvider;
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo() async {
    return _userInfo;
  }

  @override
  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  @override
  Future<String?> refreshAccessToken() async {
    _logger.debug('刷新访问令牌');

    if (_currentAdapter == null) {
      _logger.warning('无法刷新访问令牌：未登录');
      return null;
    }

    try {
      // 刷新访问令牌
      _accessToken = await _currentAdapter!.refreshAccessToken();

      if (_accessToken != null) {
        // 保存登录状态
        await _saveLoginState();
      }

      return _accessToken;
    } catch (e, stack) {
      _logger.error('刷新访问令牌失败', e, stack);
      return null;
    }
  }

  @override
  Future<bool> isAccessTokenValid() async {
    if (_currentAdapter == null || _accessToken == null) {
      return false;
    }

    try {
      // 检查访问令牌是否有效
      return await _currentAdapter!.isSignedIn();
    } catch (e, stack) {
      _logger.error('检查访问令牌是否有效失败', e, stack);
      return false;
    }
  }

  @override
  Future<String?> getUserId() async {
    return _userInfo?['id'] as String?;
  }

  @override
  Future<String?> getUsername() async {
    return _userInfo?['username'] as String?;
  }

  @override
  Future<String?> getAvatarUrl() async {
    return _userInfo?['avatarUrl'] as String?;
  }

  @override
  Future<String?> getEmail() async {
    return _userInfo?['email'] as String?;
  }

  @override
  Future<bool> isProviderAvailable(String provider) async {
    // 获取适配器
    final adapter = await _adapterFactory.getAdapter(provider);

    if (adapter == null) {
      return false;
    }

    // 检查适配器是否可用
    return await adapter.isAvailable();
  }

  @override
  Future<List<String>> getAvailableProviders() async {
    // 刷新可用的提供者列表
    _availableProviders.clear();
    _availableProviders.addAll(await _adapterFactory.getAvailableProviders());

    return List.from(_availableProviders);
  }

  @override
  Future<AuthResult> linkProvider(String provider) async {
    try {
      _logger.info('关联第三方平台账号: $provider');

      if (!_availableProviders.contains(provider)) {
        return AuthResult(
          success: false,
          errorMessage: '不支持的第三方平台: $provider',
        );
      }

      if (_linkedProviders.contains(provider)) {
        return AuthResult(
          success: false,
          errorMessage: '已关联该第三方平台账号: $provider',
        );
      }

      // 模拟关联第三方平台账号
      _linkedProviders.add(provider);

      // 保存关联状态
      await _saveLinkedProviders();

      return AuthResult(
        success: true,
        provider: provider,
      );
    } catch (e, stack) {
      _logger.error('关联第三方平台账号失败', e, stack);
      return AuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<AuthResult> unlinkProvider(String provider) async {
    try {
      _logger.info('解除第三方平台账号关联: $provider');

      if (!_linkedProviders.contains(provider)) {
        return AuthResult(
          success: false,
          errorMessage: '未关联该第三方平台账号: $provider',
        );
      }

      // 模拟解除第三方平台账号关联
      _linkedProviders.remove(provider);

      // 保存关联状态
      await _saveLinkedProviders();

      return AuthResult(
        success: true,
        provider: provider,
      );
    } catch (e, stack) {
      _logger.error('解除第三方平台账号关联失败', e, stack);
      return AuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<List<String>> getLinkedProviders() async {
    return List.from(_linkedProviders);
  }

  /// 加载保存的登录状态
  Future<void> _loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载当前登录的第三方平台
      _currentProvider = prefs.getString('third_party_provider');

      // 加载用户信息
      final userInfoJson = prefs.getString('third_party_user_info');
      if (userInfoJson != null) {
        _userInfo = jsonDecode(userInfoJson) as Map<String, dynamic>;
      }

      // 加载访问令牌
      _accessToken = prefs.getString('third_party_access_token');

      // 加载已关联的第三方平台
      final linkedProvidersJson = prefs.getString('third_party_linked_providers');
      if (linkedProvidersJson != null) {
        final linkedProviders = jsonDecode(linkedProvidersJson) as List<dynamic>;
        _linkedProviders.clear();
        _linkedProviders.addAll(linkedProviders.cast<String>());
      }
    } catch (e, stack) {
      _logger.error('加载第三方登录状态失败', e, stack);
    }
  }

  /// 保存登录状态
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存当前登录的第三方平台
      if (_currentProvider != null) {
        await prefs.setString('third_party_provider', _currentProvider!);
      } else {
        await prefs.remove('third_party_provider');
      }

      // 保存用户信息
      if (_userInfo != null) {
        await prefs.setString('third_party_user_info', jsonEncode(_userInfo));
      } else {
        await prefs.remove('third_party_user_info');
      }

      // 保存访问令牌
      if (_accessToken != null) {
        await prefs.setString('third_party_access_token', _accessToken!);
      } else {
        await prefs.remove('third_party_access_token');
      }
    } catch (e, stack) {
      _logger.error('保存第三方登录状态失败', e, stack);
    }
  }

  /// 清除保存的登录状态
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('third_party_provider');
      await prefs.remove('third_party_user_info');
      await prefs.remove('third_party_access_token');
    } catch (e, stack) {
      _logger.error('清除第三方登录状态失败', e, stack);
    }
  }

  /// 保存已关联的第三方平台
  Future<void> _saveLinkedProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('third_party_linked_providers', jsonEncode(_linkedProviders));
    } catch (e, stack) {
      _logger.error('保存已关联的第三方平台失败', e, stack);
    }
  }
}
