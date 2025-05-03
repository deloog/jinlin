import 'package:flutter/material.dart';
// 暂时注释掉未安装的依赖
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';

/// 关于屏幕
///
/// 显示应用程序的相关信息
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  /// 加载应用信息
  Future<void> _loadAppInfo() async {
    try {
      // 暂时使用硬编码的版本信息
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });

      // 注释掉PackageInfo相关代码，等依赖安装后再启用
      // final packageInfo = await PackageInfo.fromPlatform();
      // setState(() {
      //   _appVersion = packageInfo.version;
      //   _buildNumber = packageInfo.buildNumber;
      // });
    } catch (e) {
      debugPrint('获取应用信息失败: $e');
    }
  }

  /// 打开网址
  Future<void> _launchUrl(String url) async {
    try {
      // 暂时使用简单的提示，等依赖安装后再启用真正的URL启动功能
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('尝试打开链接: $url')),
        );
      }

      // 注释掉URL启动相关代码，等依赖安装后再启用
      // final uri = Uri.parse(url);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri);
      // } else if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('无法打开链接: $url')),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // 应用图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 应用名称
            const Text(
              'CetaMind Reminder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 版本信息
            Text(
              '版本 $_appVersion ($_buildNumber)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 32),
            // 分隔线
            const Divider(),
            // 功能列表
            _buildListItem(
              icon: Icons.info_outline,
              title: '应用介绍',
              subtitle: '基于第一性原理的极简提醒应用',
              onTap: () => _showAppDescription(context),
            ),
            _buildListItem(
              icon: Icons.privacy_tip_outlined,
              title: '隐私政策',
              subtitle: '了解我们如何保护您的隐私',
              onTap: () => _launchUrl('https://example.com/privacy'),
            ),
            _buildListItem(
              icon: Icons.description_outlined,
              title: '用户协议',
              subtitle: '使用条款和条件',
              onTap: () => _launchUrl('https://example.com/terms'),
            ),
            _buildListItem(
              icon: Icons.email_outlined,
              title: '联系我们',
              subtitle: 'support@example.com',
              onTap: () => _launchUrl('mailto:support@example.com'),
            ),
            _buildListItem(
              icon: Icons.code,
              title: '开源许可',
              subtitle: '查看第三方库许可信息',
              onTap: () => _showLicenses(context),
            ),
            const SizedBox(height: 32),
            // 版权信息
            Text(
              '© ${DateTime.now().year} CetaMind. All rights reserved.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建列表项
  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// 显示应用描述
  void _showAppDescription(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用介绍'),
        content: const SingleChildScrollView(
          child: Text(
            'CetaMind Reminder 是一款基于第一性原理设计的极简提醒应用，'
            '旨在帮助用户以最简单的方式管理重要日期和提醒事项。\n\n'
            '我们的设计理念是：\n'
            '• 简洁至上，去除一切不必要的功能\n'
            '• 自动化，减少用户手动操作\n'
            '• 智能化，根据用户习惯提供个性化体验\n'
            '• 隐私保护，用户数据安全至上\n\n'
            '感谢您选择使用我们的应用！',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示许可证
  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'CetaMind Reminder',
      applicationVersion: _appVersion,
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.calendar_today,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
