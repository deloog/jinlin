import 'package:flutter/material.dart';
import 'package:jinlin_app/admin/holiday_management_screen.dart';

/// 管理后台仪表盘
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理后台'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎信息
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '欢迎使用管理后台',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '在这里，您可以管理应用程序的各种数据和设置。',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 功能区域
            const Text(
              '数据管理',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 节日管理
            _buildFeatureCard(
              context,
              icon: Icons.calendar_today,
              title: '节日管理',
              description: '管理系统中的节日数据，包括添加、编辑和删除节日。',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HolidayManagementScreen(),
                  ),
                );
              },
            ),

            // 用户管理
            _buildFeatureCard(
              context,
              icon: Icons.people,
              title: '用户管理',
              description: '管理用户账户和权限设置。',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('用户管理功能尚未实现')),
                );
              },
            ),

            const SizedBox(height: 16),

            // 系统设置
            const Text(
              '系统设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 应用设置
            _buildFeatureCard(
              context,
              icon: Icons.settings,
              title: '应用设置',
              description: '配置应用程序的全局设置。',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('应用设置功能尚未实现')),
                );
              },
            ),

            // 数据备份
            _buildFeatureCard(
              context,
              icon: Icons.backup,
              title: '数据备份',
              description: '备份和恢复应用程序数据。',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据备份功能尚未实现')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
