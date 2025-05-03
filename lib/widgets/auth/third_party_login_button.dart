import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/auth/adapters/auth_adapter_factory.dart';

/// 第三方登录按钮
///
/// 用于显示第三方登录按钮
class ThirdPartyLoginButton extends StatelessWidget {
  /// 提供者
  final String provider;

  /// 点击回调
  final VoidCallback onPressed;

  /// 按钮大小
  final double size;

  /// 按钮颜色
  final Color? color;

  /// 按钮文本
  final String? text;

  /// 是否显示文本
  final bool showText;

  /// 构造函数
  const ThirdPartyLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.size = 40.0,
    this.color,
    this.text,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 获取图标和颜色
    final IconData icon = _getProviderIcon();
    final Color buttonColor = color ?? _getProviderColor();
    final String buttonText = text ?? _getProviderText();

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: showText
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: size * 0.6,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    buttonText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: size * 0.6,
                ),
              ),
            ),
    );
  }

  /// 获取提供者图标
  IconData _getProviderIcon() {
    final providerName = provider.toLowerCase().replaceAll('.com', '');
    switch (providerName) {
      case 'google':
        return Icons.g_mobiledata;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.flutter_dash;
      case 'apple':
        return Icons.apple;
      case 'wechat':
        return Icons.wechat;
      case 'qq':
        return Icons.question_answer;
      case 'weibo':
        return Icons.web;
      case 'tiktok':
        return Icons.tiktok;
      default:
        return Icons.login;
    }
  }

  /// 获取提供者颜色
  Color _getProviderColor() {
    final providerName = provider.toLowerCase().replaceAll('.com', '');
    switch (providerName) {
      case 'google':
        return Colors.red;
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'apple':
        return Colors.black;
      case 'wechat':
        return const Color(0xFF07C160);
      case 'qq':
        return const Color(0xFF12B7F5);
      case 'weibo':
        return const Color(0xFFE6162D);
      case 'tiktok':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  /// 获取提供者文本
  String _getProviderText() {
    final providerName = provider.toLowerCase().replaceAll('.com', '');
    switch (providerName) {
      case 'google':
        return '使用Google登录';
      case 'facebook':
        return '使用Facebook登录';
      case 'twitter':
        return '使用Twitter登录';
      case 'apple':
        return '使用Apple登录';
      case 'wechat':
        return '使用微信登录';
      case 'qq':
        return '使用QQ登录';
      case 'weibo':
        return '使用微博登录';
      case 'tiktok':
        return '使用抖音登录';
      default:
        return '第三方登录';
    }
  }

  /// 获取当前平台可用的提供者
  static Future<List<String>> getAvailableProviders() async {
    try {
      // 使用适配器工厂获取可用的提供者
      final factory = AuthAdapterFactory();
      return await factory.getAvailableProviders();
    } catch (e) {
      // 如果出错，返回默认值
      if (kIsWeb) {
        // Web平台支持的第三方登录
        return ['google.com', 'facebook.com', 'twitter.com', 'apple.com'];
      } else if (Platform.isAndroid) {
        // Android平台支持的第三方登录
        return ['google.com', 'facebook.com', 'twitter.com', 'wechat.com', 'qq.com', 'weibo.com', 'tiktok.com'];
      } else if (Platform.isIOS) {
        // iOS平台支持的第三方登录
        return ['google.com', 'facebook.com', 'twitter.com', 'apple.com', 'wechat.com', 'qq.com', 'weibo.com', 'tiktok.com'];
      } else {
        // 其他平台
        return ['google.com', 'facebook.com', 'twitter.com'];
      }
    }
  }

  /// 获取中国区可用的提供者
  static Future<List<String>> getChineseProviders() async {
    try {
      // 使用适配器工厂获取中国区可用的提供者
      final factory = AuthAdapterFactory();
      return await factory.getChineseProviders();
    } catch (e) {
      // 如果出错，返回默认值
      if (kIsWeb) {
        // Web平台支持的中国区第三方登录
        return ['wechat.com', 'qq.com', 'weibo.com', 'tiktok.com'];
      } else if (Platform.isAndroid) {
        // Android平台支持的中国区第三方登录
        return ['wechat.com', 'qq.com', 'weibo.com', 'tiktok.com'];
      } else if (Platform.isIOS) {
        // iOS平台支持的中国区第三方登录
        return ['wechat.com', 'qq.com', 'weibo.com', 'tiktok.com', 'apple.com'];
      } else {
        // 其他平台
        return ['wechat.com', 'qq.com', 'weibo.com'];
      }
    }
  }

  /// 获取国际区可用的提供者
  static Future<List<String>> getInternationalProviders() async {
    try {
      // 使用适配器工厂获取国际区可用的提供者
      final factory = AuthAdapterFactory();
      return await factory.getInternationalProviders();
    } catch (e) {
      // 如果出错，返回默认值
      if (kIsWeb) {
        // Web平台支持的国际区第三方登录
        return ['google.com', 'facebook.com', 'twitter.com', 'apple.com'];
      } else if (Platform.isAndroid) {
        // Android平台支持的国际区第三方登录
        return ['google.com', 'facebook.com', 'twitter.com'];
      } else if (Platform.isIOS) {
        // iOS平台支持的国际区第三方登录
        return ['google.com', 'facebook.com', 'twitter.com', 'apple.com'];
      } else {
        // 其他平台
        return ['google.com', 'facebook.com', 'twitter.com'];
      }
    }
  }
}
