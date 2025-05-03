import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/widgets/auth/third_party_login_panel.dart';
import 'package:jinlin_app/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// 登录屏幕
///
/// 用户登录界面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 表单键
  final _formKey = GlobalKey<FormState>();

  // 电子邮件控制器
  final _emailController = TextEditingController();

  // 密码控制器
  final _passwordController = TextEditingController();

  // 是否显示密码
  bool _obscurePassword = true;

  // 是否记住我
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 处理登录
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // 导航到主屏幕
        AppRouter.navigateToHome(context);
      }
    }
  }



  /// 处理忘记密码
  void _handleForgotPassword() {
    AppRouter.navigateToForgotPassword(context);
  }

  /// 处理注册
  void _handleRegister() {
    AppRouter.navigateToRegister(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 应用标志
                  Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // 应用名称
                  Text(
                    'CetaMind Reminder',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 应用描述
                  Text(
                    '智能提醒，轻松管理',
                    style: theme.textTheme.titleMedium?.copyWith(
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
                  const SizedBox(height: 16),

                  // 密码输入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入您的密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }

                      if (value.length < 6) {
                        return '密码长度不能少于6个字符';
                      }

                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),
                  const SizedBox(height: 8),

                  // 记住我和忘记密码
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 记住我
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: authProvider.isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                          ),
                          const Text('记住我'),
                        ],
                      ),

                      // 忘记密码
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleForgotPassword,
                        child: const Text('忘记密码？'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: authProvider.isLoading
                        ? const LoadingIndicator(size: 24)
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 16),

                  // 第三方登录面板
                  ThirdPartyLoginPanel(
                    buttonSize: 40.0,
                    spacing: 16.0,
                    onLoginSuccess: () {
                      if (mounted) {
                        AppRouter.navigateToHome(context);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // 注册链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('还没有账户？'),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleRegister,
                        child: const Text('立即注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
