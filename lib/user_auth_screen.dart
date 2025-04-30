// 文件： lib/user_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/cloud_sync_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      await _cloudSyncService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示登录成功
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '没有找到该电子邮件对应的用户',
            textEn: 'No user found for that email',
            textFr: 'Aucun utilisateur trouvé pour cet e-mail',
            textDe: 'Kein Benutzer für diese E-Mail gefunden',
          );
          break;
        case 'wrong-password':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '密码错误',
            textEn: 'Wrong password',
            textFr: 'Mot de passe incorrect',
            textDe: 'Falsches Passwort',
          );
          break;
        case 'invalid-email':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '电子邮件格式无效',
            textEn: 'Invalid email format',
            textFr: 'Format d\'e-mail invalide',
            textDe: 'Ungültiges E-Mail-Format',
          );
          break;
        default:
          message = e.message ?? 'An unknown error occurred';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
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
      await _cloudSyncService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示注册成功
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'weak-password':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '密码太弱',
            textEn: 'The password is too weak',
            textFr: 'Le mot de passe est trop faible',
            textDe: 'Das Passwort ist zu schwach',
          );
          break;
        case 'email-already-in-use':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '该电子邮件已被使用',
            textEn: 'The email is already in use',
            textFr: 'Cet e-mail est déjà utilisé',
            textDe: 'Diese E-Mail wird bereits verwendet',
          );
          break;
        case 'invalid-email':
          message = LocalizationService.getLocalizedText(
            context: context,
            textZh: '电子邮件格式无效',
            textEn: 'Invalid email format',
            textFr: 'Format d\'e-mail invalide',
            textDe: 'Ungültiges E-Mail-Format',
          );
          break;
        default:
          message = e.message ?? 'An unknown error occurred';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
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
      await _cloudSyncService.signInWithGoogle();

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示登录成功
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
    final l10n = AppLocalizations.of(context);
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
