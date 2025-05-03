import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// 忘记密码屏幕
///
/// 用户重置密码界面
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 表单键
  final _formKey = GlobalKey<FormState>();

  // 电子邮件控制器
  final _emailController = TextEditingController();

  // 是否已发送重置邮件
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// 处理发送重置邮件
  Future<void> _handleSendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    }
  }

  /// 处理返回登录
  void _handleBackToLogin() {
    AppRouter.navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('忘记密码'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _emailSent
                ? _buildSuccessView(theme)
                : _buildFormView(theme, authProvider),
          ),
        ),
      ),
    );
  }

  /// 构建表单视图
  Widget _buildFormView(ThemeData theme, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 应用标志
          Icon(
            Icons.lock_reset,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),

          // 标题
          Text(
            '重置密码',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 描述
          Text(
            '请输入您的电子邮件，我们将向您发送重置密码的链接',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 错误消息
          if (authProvider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                authProvider.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 电子邮件输入框
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '电子邮件',
              hintText: '请输入您的电子邮件',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入电子邮件';
              }

              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );

              if (!emailRegex.hasMatch(value.trim())) {
                return '请输入有效的电子邮件';
              }

              return null;
            },
            enabled: !authProvider.isLoading,
          ),
          const SizedBox(height: 24),

          // 发送重置邮件按钮
          ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : _handleSendResetEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: authProvider.isLoading
                ? const LoadingIndicator(size: 24)
                : const Text('发送重置邮件'),
          ),
          const SizedBox(height: 16),

          // 返回登录按钮
          TextButton(
            onPressed: authProvider.isLoading
                ? null
                : _handleBackToLogin,
            child: const Text('返回登录'),
          ),
        ],
      ),
    );
  }

  /// 构建成功视图
  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 成功图标
        Icon(
          Icons.check_circle,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),

        // 成功标题
        Text(
          '邮件已发送',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // 成功描述
        Text(
          '我们已向 ${_emailController.text.trim()} 发送了重置密码的链接，请查收邮件并按照指引重置密码',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // 返回登录按钮
        ElevatedButton(
          onPressed: _handleBackToLogin,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('返回登录'),
        ),
      ],
    );
  }
}
