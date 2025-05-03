import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/widgets/auth/third_party_login_panel.dart';
import 'package:jinlin_app/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// 注册屏幕
///
/// 用户注册界面
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 表单键
  final _formKey = GlobalKey<FormState>();

  // 用户名控制器
  final _usernameController = TextEditingController();

  // 电子邮件控制器
  final _emailController = TextEditingController();

  // 密码控制器
  final _passwordController = TextEditingController();

  // 确认密码控制器
  final _confirmPasswordController = TextEditingController();

  // 是否显示密码
  bool _obscurePassword = true;

  // 是否显示确认密码
  bool _obscureConfirmPassword = true;

  // 是否同意条款
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 处理注册
  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请同意用户协议和隐私政策'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // 导航到主屏幕
        AppRouter.navigateToHome(context);
      }
    }
  }

  /// 处理登录
  void _handleLogin() {
    AppRouter.navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册'),
      ),
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
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // 应用名称
                  Text(
                    'CetaMind Reminder',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 应用描述
                  Text(
                    '创建您的账户',
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

                  // 用户名输入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入您的用户名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }

                      if (value.trim().length < 3) {
                        return '用户名长度不能少于3个字符';
                      }

                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  // 确认密码输入框
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      hintText: '请再次输入您的密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }

                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }

                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 同意条款
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: authProvider.isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: '我已阅读并同意',
                            children: [
                              TextSpan(
                                text: '用户协议',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                                // TODO: 添加点击事件
                              ),
                              const TextSpan(text: '和'),
                              TextSpan(
                                text: '隐私政策',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                                // TODO: 添加点击事件
                              ),
                            ],
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 注册按钮
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: authProvider.isLoading
                        ? const LoadingIndicator(size: 24)
                        : const Text('注册'),
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 16),

                  // 登录链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已有账户？'),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleLogin,
                        child: const Text('立即登录'),
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
