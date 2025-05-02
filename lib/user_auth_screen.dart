// 文件： lib/user_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/cloud_sync_service.dart';
import 'package:jinlin_app/services/localization_service.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CloudSyncService _cloudSyncService = CloudSyncService();

  bool _isLoading = false;
  bool _isLogin = true; // true表示登录，false表示注册
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 使用电子邮件和密码登录
  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 验证输入
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = LocalizationService.getLocalizedText(
            context: context,
            textZh: '请输入电子邮件和密码',
            textEn: 'Please enter email and password',
            textFr: 'Veuillez saisir l\'e-mail et le mot de passe',
            textDe: 'Bitte E-Mail und Passwort eingeben',
          );
          _isLoading = false;
        });
        return;
      }

      // 调用Firebase登录
      await _cloudSyncService.signInWithEmailAndPassword(email, password);

      // 登录成功后，尝试同步数据
      final isLoggedIn = await _cloudSyncService.isLoggedIn();
      if (isLoggedIn) {
        try {
          // 显示同步中的提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.getLocalizedText(
                  context: context,
                  textZh: '正在同步数据...',
                  textEn: 'Syncing data...',
                  textFr: 'Synchronisation des données...',
                  textDe: 'Daten werden synchronisiert...',
                )),
              ),
            );
          }

          // 下载云端数据
          await _cloudSyncService.downloadHolidayData();
        } catch (syncError) {
          debugPrint('同步数据失败: $syncError');
          // 同步失败不影响登录流程
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示登录成功
      }
    } catch (e) {
      if (mounted) {
        // 处理错误信息
        final errorMessage = LocalizationService.getLocalizedText(
          context: context,
          textZh: '登录失败: ${e.toString()}',
          textEn: 'Login failed: ${e.toString()}',
          textFr: 'Échec de la connexion: ${e.toString()}',
          textDe: 'Anmeldung fehlgeschlagen: ${e.toString()}',
        );

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  // 使用电子邮件和密码注册
  Future<void> _registerWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 验证输入
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = LocalizationService.getLocalizedText(
            context: context,
            textZh: '请输入电子邮件和密码',
            textEn: 'Please enter email and password',
            textFr: 'Veuillez saisir l\'e-mail et le mot de passe',
            textDe: 'Bitte E-Mail und Passwort eingeben',
          );
          _isLoading = false;
        });
        return;
      }

      // 验证密码强度
      if (password.length < 6) {
        setState(() {
          _errorMessage = LocalizationService.getLocalizedText(
            context: context,
            textZh: '密码至少需要6个字符',
            textEn: 'Password must be at least 6 characters',
            textFr: 'Le mot de passe doit comporter au moins 6 caractères',
            textDe: 'Das Passwort muss mindestens 6 Zeichen lang sein',
          );
          _isLoading = false;
        });
        return;
      }

      // 调用Firebase注册
      await _cloudSyncService.registerWithEmailAndPassword(email, password);

      // 注册成功后，尝试上传本地数据
      if (await _cloudSyncService.isLoggedIn()) {
        try {
          // 显示同步中的提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.getLocalizedText(
                  context: context,
                  textZh: '正在同步数据...',
                  textEn: 'Syncing data...',
                  textFr: 'Synchronisation des données...',
                  textDe: 'Daten werden synchronisiert...',
                )),
              ),
            );
          }

          // 上传本地数据
          await _cloudSyncService.uploadHolidayData();
        } catch (syncError) {
          debugPrint('同步数据失败: $syncError');
          // 同步失败不影响注册流程
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示注册成功
      }
    } catch (e) {
      if (mounted) {
        // 处理错误信息
        final errorMessage = LocalizationService.getLocalizedText(
          context: context,
          textZh: '注册失败: ${e.toString()}',
          textEn: 'Registration failed: ${e.toString()}',
          textFr: 'Échec de l\'inscription: ${e.toString()}',
          textDe: 'Registrierung fehlgeschlagen: ${e.toString()}',
        );

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  // 使用Google登录
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用Firebase Google登录
      await _cloudSyncService.signInWithGoogle();

      // 登录成功后，尝试同步数据
      final isLoggedIn = await _cloudSyncService.isLoggedIn();
      if (isLoggedIn) {
        try {
          // 显示同步中的提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.getLocalizedText(
                  context: context,
                  textZh: '正在同步数据...',
                  textEn: 'Syncing data...',
                  textFr: 'Synchronisation des données...',
                  textDe: 'Daten werden synchronisiert...',
                )),
              ),
            );
          }

          // 先尝试下载云端数据
          final downloadCount = await _cloudSyncService.downloadHolidayData();

          // 如果云端没有数据，则上传本地数据
          if (downloadCount == 0) {
            await _cloudSyncService.uploadHolidayData();
          }
        } catch (syncError) {
          debugPrint('同步数据失败: $syncError');
          // 同步失败不影响登录流程
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示登录成功
      }
    } catch (e) {
      if (mounted) {
        // 处理错误信息
        final errorMessage = LocalizationService.getLocalizedText(
          context: context,
          textZh: 'Google登录失败: ${e.toString()}',
          textEn: 'Google login failed: ${e.toString()}',
          textFr: 'Échec de la connexion Google: ${e.toString()}',
          textDe: 'Google-Anmeldung fehlgeschlagen: ${e.toString()}',
        );

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用LocalizationService检查是否为中文环境
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin
          ? (isChinese ? '登录' : 'Login')
          : (isChinese ? '注册' : 'Register')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题
                  Text(
                    _isLogin
                        ? (isChinese ? '登录您的账户' : 'Login to Your Account')
                        : (isChinese ? '创建新账户' : 'Create New Account'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // 错误消息
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 电子邮件输入框
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: isChinese ? '电子邮件' : 'Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: isChinese ? '密码' : 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),

                  // 登录/注册按钮
                  ElevatedButton(
                    onPressed: _isLogin
                        ? _signInWithEmailAndPassword
                        : _registerWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      _isLogin
                          ? (isChinese ? '登录' : 'Login')
                          : (isChinese ? '注册' : 'Register'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切换登录/注册
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? (isChinese ? '没有账户？创建一个' : 'No account? Create one')
                          : (isChinese ? '已有账户？登录' : 'Have an account? Login'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 分隔线
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(isChinese ? '或' : 'OR'),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google登录按钮
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.blue,
                    ),
                    label: Text(
                      isChinese ? '使用Google登录' : 'Sign in with Google',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
