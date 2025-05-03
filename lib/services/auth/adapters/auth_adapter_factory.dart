import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jinlin_app/services/auth/adapters/apple_auth_adapter.dart';
import 'package:jinlin_app/services/auth/adapters/auth_adapter_interface.dart';
import 'package:jinlin_app/services/auth/adapters/facebook_auth_adapter.dart';
import 'package:jinlin_app/services/auth/adapters/google_auth_adapter.dart';
import 'package:jinlin_app/services/auth/adapters/wechat_auth_adapter.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 认证适配器工厂
///
/// 用于创建和管理不同的认证适配器
class AuthAdapterFactory {
  // 单例实例
  static final AuthAdapterFactory _instance = AuthAdapterFactory._internal();

  // 工厂构造函数
  factory AuthAdapterFactory() => _instance;

  // 私有构造函数
  AuthAdapterFactory._internal();

  // 日志服务
  final LoggingService _logger = LoggingService();

  // 适配器缓存
  final Map<String, AuthAdapterInterface> _adapters = {};

  /// 获取适配器
  ///
  /// 根据提供者ID获取适配器
  Future<AuthAdapterInterface?> getAdapter(String providerId) async {
    // 检查缓存
    if (_adapters.containsKey(providerId)) {
      return _adapters[providerId];
    }

    // 创建适配器
    final adapter = await _createAdapter(providerId);

    if (adapter != null) {
      // 初始化适配器
      final initialized = await adapter.initialize();

      if (initialized) {
        // 缓存适配器
        _adapters[providerId] = adapter;
        return adapter;
      } else {
        _logger.warning('初始化适配器失败: $providerId');
        return null;
      }
    }

    return null;
  }

  /// 创建适配器
  ///
  /// 根据提供者ID创建适配器
  Future<AuthAdapterInterface?> _createAdapter(String providerId) async {
    switch (providerId.toLowerCase()) {
      case 'google':
      case 'google.com':
        return GoogleAuthAdapter();

      case 'facebook':
      case 'facebook.com':
        return FacebookAuthAdapter();

      case 'apple':
      case 'apple.com':
        return AppleAuthAdapter();

      case 'wechat':
      case 'wechat.com':
        // 获取微信应用ID和密钥
        final appId = dotenv.env['WECHAT_APP_ID'];
        final appSecret = dotenv.env['WECHAT_APP_SECRET'];

        if (appId == null || appSecret == null) {
          _logger.error('缺少微信应用ID或密钥');
          return null;
        }

        return WeChatAuthAdapter(
          appId: appId,
          appSecret: appSecret,
        );

      // 更多适配器将在未来添加

      default:
        _logger.warning('不支持的提供者ID: $providerId');
        return null;
    }
  }

  /// 获取可用的提供者
  ///
  /// 返回当前平台可用的提供者列表
  Future<List<String>> getAvailableProviders() async {
    final providers = <String>[];

    // 检查Google登录
    final googleAdapter = await getAdapter('google.com');
    if (googleAdapter != null && await googleAdapter.isAvailable()) {
      providers.add('google.com');
    }

    // 检查Facebook登录
    final facebookAdapter = await getAdapter('facebook.com');
    if (facebookAdapter != null && await facebookAdapter.isAvailable()) {
      providers.add('facebook.com');
    }

    // 检查Apple登录
    final appleAdapter = await getAdapter('apple.com');
    if (appleAdapter != null && await appleAdapter.isAvailable()) {
      providers.add('apple.com');
    }

    // 检查微信登录
    final wechatAdapter = await getAdapter('wechat.com');
    if (wechatAdapter != null && await wechatAdapter.isAvailable()) {
      providers.add('wechat.com');
    }

    // 更多提供者将在未来添加

    return providers;
  }

  /// 获取中国区可用的提供者
  ///
  /// 返回中国区可用的提供者列表
  Future<List<String>> getChineseProviders() async {
    final providers = <String>[];

    // 检查微信登录
    final wechatAdapter = await getAdapter('wechat.com');
    if (wechatAdapter != null && await wechatAdapter.isAvailable()) {
      providers.add('wechat.com');
    }

    // QQ登录将在未来添加

    // 微博登录将在未来添加

    // 抖音登录将在未来添加

    // 检查Apple登录（iOS平台）
    if (Platform.isIOS) {
      final appleAdapter = await getAdapter('apple.com');
      if (appleAdapter != null && await appleAdapter.isAvailable()) {
        providers.add('apple.com');
      }
    }

    return providers;
  }

  /// 获取国际区可用的提供者
  ///
  /// 返回国际区可用的提供者列表
  Future<List<String>> getInternationalProviders() async {
    final providers = <String>[];

    // 检查Google登录
    final googleAdapter = await getAdapter('google.com');
    if (googleAdapter != null && await googleAdapter.isAvailable()) {
      providers.add('google.com');
    }

    // 检查Facebook登录
    final facebookAdapter = await getAdapter('facebook.com');
    if (facebookAdapter != null && await facebookAdapter.isAvailable()) {
      providers.add('facebook.com');
    }

    // 检查Apple登录
    final appleAdapter = await getAdapter('apple.com');
    if (appleAdapter != null && await appleAdapter.isAvailable()) {
      providers.add('apple.com');
    }

    return providers;
  }

  /// 关闭所有适配器
  ///
  /// 释放资源
  Future<void> dispose() async {
    for (final adapter in _adapters.values) {
      await adapter.dispose();
    }

    _adapters.clear();
  }
}
