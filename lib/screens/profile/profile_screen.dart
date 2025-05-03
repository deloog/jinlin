import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// 个人资料屏幕
///
/// 显示和编辑用户个人资料
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 是否处于编辑模式
  bool _isEditing = false;

  // 表单键
  final _formKey = GlobalKey<FormState>();

  // 显示名称控制器
  late TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _displayNameController = TextEditingController(
      text: authProvider.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  /// 处理编辑个人资料
  void _handleEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  /// 处理取消编辑
  void _handleCancel() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isEditing = false;
      _displayNameController.text = authProvider.currentUser?.displayName ?? '';
    });
  }

  /// 处理保存个人资料
  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updateUserInfo(
        displayName: _displayNameController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人资料已更新'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 处理修改密码
  void _handleChangePassword() {
    AppRouter.navigateToChangePassword(context);
  }

  /// 处理修改电子邮件
  void _handleChangeEmail() {
    AppRouter.navigateToChangeEmail(context);
  }

  /// 处理登出
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.logout();

    if (mounted) {
      AppRouter.navigateToLogin(context);
    }
  }

  /// 处理删除账户
  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户'),
        content: const Text('您确定要删除账户吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示删除账户确认对话框
  void _showDeleteAccountConfirmation() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除账户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入您的密码以确认删除账户'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                hintText: '请输入您的密码',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (passwordController.text.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                final success = await authProvider.deleteAccount(
                  passwordController.text,
                );

                if (success && mounted) {
                  AppRouter.navigateToLogin(context);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
        ),
        body: const Center(
          child: Text('请先登录'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: _handleEdit,
              icon: const Icon(Icons.edit),
              tooltip: '编辑',
            ),
          ] else ...[
            IconButton(
              onPressed: _handleCancel,
              icon: const Icon(Icons.cancel),
              tooltip: '取消',
            ),
            IconButton(
              onPressed: authProvider.isLoading ? null : _handleSave,
              icon: authProvider.isLoading
                  ? const LoadingIndicator(size: 24)
                  : const Icon(Icons.save),
              tooltip: '保存',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像和用户名
              Center(
                child: Column(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName![0].toUpperCase()
                            : user.username[0].toUpperCase(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 用户名
                    Text(
                      user.username,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 电子邮件
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // 电子邮件验证状态
                    if (!user.isEmailVerified) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            color: theme.colorScheme.error,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '未验证',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await authProvider.sendEmailVerification();
                              if (mounted) {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('验证邮件已发送'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            child: const Text('发送验证邮件'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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

              // 个人信息
              Text(
                '个人信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 显示名称
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '请输入您的显示名称',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: _isEditing && !authProvider.isLoading,
              ),
              const SizedBox(height: 32),

              // 账户安全
              Text(
                '账户安全',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 修改密码
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('修改密码'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleChangePassword,
              ),

              // 修改电子邮件
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('修改电子邮件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleChangeEmail,
              ),
              const SizedBox(height: 32),

              // 账户操作
              Text(
                '账户操作',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 登出
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('登出'),
                onTap: _handleLogout,
              ),

              // 删除账户
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  '删除账户',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: _handleDeleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
