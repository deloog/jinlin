import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/widgets/auth/third_party_login_button.dart';
import 'package:provider/provider.dart';

/// 第三方登录面板
///
/// 用于显示第三方登录按钮面板
class ThirdPartyLoginPanel extends StatefulWidget {
  /// 是否显示文本
  final bool showText;

  /// 按钮大小
  final double buttonSize;

  /// 按钮间距
  final double spacing;

  /// 登录成功回调
  final VoidCallback? onLoginSuccess;

  /// 构造函数
  const ThirdPartyLoginPanel({
    super.key,
    this.showText = false,
    this.buttonSize = 40.0,
    this.spacing = 16.0,
    this.onLoginSuccess,
  });

  @override
  State<ThirdPartyLoginPanel> createState() => _ThirdPartyLoginPanelState();
}

class _ThirdPartyLoginPanelState extends State<ThirdPartyLoginPanel> {
  // 提供者列表
  List<String> _providers = [];

  // 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  /// 加载提供者
  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前语言
      final locale = View.of(context).platformDispatcher.locale;
      final languageCode = locale.languageCode;

      // 根据语言选择提供者
      _providers = await _getProvidersForLanguage(languageCode);
    } catch (e) {
      // 使用默认提供者
      _providers = ['google.com', 'facebook.com', 'apple.com'];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Expanded(child: Divider(color: theme.colorScheme.outline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '或使用以下方式登录',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else if (widget.showText)
          Column(
            children: _providers.map((provider) => Padding(
              padding: EdgeInsets.only(bottom: widget.spacing),
              child: ThirdPartyLoginButton(
                provider: provider,
                onPressed: () => _handleLogin(context, provider),
                size: widget.buttonSize,
                showText: true,
              ),
            )).toList(),
          )
        else
          Wrap(
            spacing: widget.spacing,
            runSpacing: widget.spacing,
            alignment: WrapAlignment.center,
            children: _providers.map((provider) => ThirdPartyLoginButton(
              provider: provider,
              onPressed: () => _handleLogin(context, provider),
              size: widget.buttonSize,
            )).toList(),
          ),
      ],
    );
  }

  /// 处理登录
  Future<void> _handleLogin(BuildContext context, String provider) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 登录
      await authProvider.loginWithProvider(provider);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 登录成功回调
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误对话框
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('登录失败'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 根据语言获取提供者
  Future<List<String>> _getProvidersForLanguage(String languageCode) async {
    // 中文使用中国区提供者
    if (languageCode == 'zh') {
      return await ThirdPartyLoginButton.getChineseProviders();
    }

    // 其他语言使用国际区提供者
    return await ThirdPartyLoginButton.getInternationalProviders();
  }
}
