import 'package:flutter/material.dart';
import 'package:jinlin_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';

/// 通知设置屏幕
///
/// 用于设置应用程序的通知
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    // 检查通知权限
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  /// 检查通知权限
  Future<void> _checkNotificationPermission() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final hasPermission = await notificationProvider.checkNotificationPermission();

    if (!hasPermission && mounted) {
      _showPermissionDialog();
    }
  }

  /// 显示权限对话框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知权限'),
        content: const Text('应用程序需要通知权限才能发送通知。请授予通知权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final notificationProvider = Provider.of<NotificationProvider>(
                context,
                listen: false,
              );

              await notificationProvider.requestNotificationPermission();
            },
            child: const Text('授权'),
          ),
        ],
      ),
    );
  }

  /// 显示提醒事项通知提前时间对话框
  void _showReminderNotificationAdvanceDialog() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final currentValue = notificationProvider.reminderNotificationAdvance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提醒事项通知提前时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择提醒事项通知提前时间'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: currentValue,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text('准时提醒'),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text('提前5分钟'),
                ),
                DropdownMenuItem(
                  value: 10,
                  child: Text('提前10分钟'),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text('提前15分钟'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('提前30分钟'),
                ),
                DropdownMenuItem(
                  value: 60,
                  child: Text('提前1小时'),
                ),
                DropdownMenuItem(
                  value: 120,
                  child: Text('提前2小时'),
                ),
                DropdownMenuItem(
                  value: 1440,
                  child: Text('提前1天'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notificationProvider.setReminderNotificationAdvance(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示节日通知提前时间对话框
  void _showHolidayNotificationAdvanceDialog() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final currentValue = notificationProvider.holidayNotificationAdvance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('节日通知提前时间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择节日通知提前时间'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: currentValue,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text('当天提醒'),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text('提前1天'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('提前2天'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('提前3天'),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text('提前5天'),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text('提前1周'),
                ),
                DropdownMenuItem(
                  value: 14,
                  child: Text('提前2周'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('提前1个月'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notificationProvider.setHolidayNotificationAdvance(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示测试通知对话框
  void _showTestNotificationDialog() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测试通知'),
        content: const Text('是否发送测试通知？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              notificationProvider.showInstantNotification(
                title: '测试通知',
                body: '这是一条测试通知',
                payload: 'test',
              );
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
      ),
      body: ListView(
        children: [
          // 启用通知
          SwitchListTile(
            title: const Text('启用通知'),
            subtitle: const Text('接收提醒事项和节日通知'),
            secondary: const Icon(Icons.notifications),
            value: notificationProvider.enableNotifications,
            onChanged: (value) => notificationProvider.setEnableNotifications(value),
          ),

          const Divider(),

          // 提醒事项通知设置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '提醒事项通知',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 提醒事项通知提前时间
          ListTile(
            title: const Text('提醒事项通知提前时间'),
            subtitle: Text(_getReminderNotificationAdvanceText(
              notificationProvider.reminderNotificationAdvance,
            )),
            leading: const Icon(Icons.access_time),
            enabled: notificationProvider.enableNotifications,
            onTap: notificationProvider.enableNotifications
                ? _showReminderNotificationAdvanceDialog
                : null,
          ),

          const Divider(),

          // 节日通知设置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '节日通知',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 节日通知提前时间
          ListTile(
            title: const Text('节日通知提前时间'),
            subtitle: Text(_getHolidayNotificationAdvanceText(
              notificationProvider.holidayNotificationAdvance,
            )),
            leading: const Icon(Icons.calendar_today),
            enabled: notificationProvider.enableNotifications,
            onTap: notificationProvider.enableNotifications
                ? _showHolidayNotificationAdvanceDialog
                : null,
          ),

          const Divider(),

          // 通知效果设置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '通知效果',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 启用振动
          SwitchListTile(
            title: const Text('启用振动'),
            subtitle: const Text('通知时振动'),
            secondary: const Icon(Icons.vibration),
            value: notificationProvider.enableVibration,
            onChanged: notificationProvider.enableNotifications
                ? (value) => notificationProvider.setEnableVibration(value)
                : null,
          ),

          // 启用声音
          SwitchListTile(
            title: const Text('启用声音'),
            subtitle: const Text('通知时播放声音'),
            secondary: const Icon(Icons.volume_up),
            value: notificationProvider.enableSound,
            onChanged: notificationProvider.enableNotifications
                ? (value) => notificationProvider.setEnableSound(value)
                : null,
          ),

          const Divider(),

          // 测试通知
          ListTile(
            title: const Text('测试通知'),
            subtitle: const Text('发送测试通知'),
            leading: const Icon(Icons.send),
            enabled: notificationProvider.enableNotifications,
            onTap: notificationProvider.enableNotifications
                ? _showTestNotificationDialog
                : null,
          ),

          // 重置通知设置
          ListTile(
            title: const Text('重置通知设置'),
            subtitle: const Text('恢复默认通知设置'),
            leading: const Icon(Icons.restore),
            onTap: () => _showResetNotificationSettingsDialog(context, notificationProvider),
          ),
        ],
      ),
    );
  }

  /// 获取提醒事项通知提前时间文本
  String _getReminderNotificationAdvanceText(int minutes) {
    if (minutes == 0) {
      return '准时提醒';
    } else if (minutes < 60) {
      return '提前$minutes分钟';
    } else if (minutes == 60) {
      return '提前1小时';
    } else if (minutes < 1440) {
      return '提前${minutes ~/ 60}小时';
    } else {
      return '提前${minutes ~/ 1440}天';
    }
  }

  /// 获取节日通知提前时间文本
  String _getHolidayNotificationAdvanceText(int days) {
    if (days == 0) {
      return '当天提醒';
    } else if (days == 1) {
      return '提前1天';
    } else if (days < 7) {
      return '提前$days天';
    } else if (days == 7) {
      return '提前1周';
    } else if (days == 14) {
      return '提前2周';
    } else if (days == 30) {
      return '提前1个月';
    } else {
      return '提前$days天';
    }
  }

  /// 显示重置通知设置对话框
  void _showResetNotificationSettingsDialog(
    BuildContext context,
    NotificationProvider notificationProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置通知设置'),
        content: const Text('确定要重置通知设置吗？这将恢复默认通知设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              notificationProvider.resetNotificationSettings();
              Navigator.pop(context);
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
