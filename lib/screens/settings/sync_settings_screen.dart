import 'package:flutter/material.dart';
import 'package:jinlin_app/models/sync/sync_config.dart';
import 'package:jinlin_app/models/sync/sync_status.dart' as status_model;
import 'package:jinlin_app/models/sync/sync_status.dart' show SyncStatusEnum;
import 'package:jinlin_app/providers/sync_provider.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:provider/provider.dart';

/// 同步设置屏幕
///
/// 用于设置应用程序的同步
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  // 日志服务
  final LoggingService _logger = LoggingService();

  // 同步配置
  SyncConfig? _syncConfig;

  // 同步状态
  status_model.SyncStatus? _syncStatus;

  // 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 加载同步配置和状态
    _loadSyncConfigAndStatus();
  }

  /// 加载同步配置和状态
  Future<void> _loadSyncConfigAndStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 加载同步配置
      final syncConfig = await syncProvider.getSyncConfig();

      // 加载同步状态
      final syncStatus = await syncProvider.getSyncStatus();

      setState(() {
        _syncConfig = syncConfig;
        _syncStatus = syncStatus;
        _isLoading = false;
      });
    } catch (e, stack) {
      _logger.error('加载同步配置和状态失败', e, stack);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载同步配置和状态失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 更新同步配置
  Future<void> _updateSyncConfig(SyncConfig config) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 更新同步配置
      await syncProvider.updateSyncConfig(config);

      // 重新加载同步配置和状态
      await _loadSyncConfigAndStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('同步配置已更新'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      _logger.error('更新同步配置失败', e, stack);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新同步配置失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 开始同步
  Future<void> _startSync() async {
    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 开始同步
      await syncProvider.startSync();

      // 重新加载同步状态
      await _loadSyncConfigAndStatus();
    } catch (e, stack) {
      _logger.error('开始同步失败', e, stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 取消同步
  Future<void> _cancelSync() async {
    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      // 取消同步
      await syncProvider.cancelSync();

      // 重新加载同步状态
      await _loadSyncConfigAndStatus();
    } catch (e, stack) {
      _logger.error('取消同步失败', e, stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示同步间隔对话框
  void _showSyncIntervalDialog() {
    if (_syncConfig == null) return;

    final currentValue = _syncConfig!.autoSyncIntervalMinutes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择自动同步间隔'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: currentValue,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 15,
                  child: Text('15分钟'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('30分钟'),
                ),
                DropdownMenuItem(
                  value: 60,
                  child: Text('1小时'),
                ),
                DropdownMenuItem(
                  value: 120,
                  child: Text('2小时'),
                ),
                DropdownMenuItem(
                  value: 360,
                  child: Text('6小时'),
                ),
                DropdownMenuItem(
                  value: 720,
                  child: Text('12小时'),
                ),
                DropdownMenuItem(
                  value: 1440,
                  child: Text('1天'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);

                  // 更新同步配置
                  final updatedConfig = _syncConfig!.copyWith(
                    autoSyncIntervalMinutes: value,
                  );

                  _updateSyncConfig(updatedConfig);
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

  /// 显示最大同步批次大小对话框
  void _showMaxSyncBatchSizeDialog() {
    if (_syncConfig == null) return;

    final currentValue = _syncConfig!.maxSyncBatchSize;
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最大同步批次大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('设置最大同步批次大小'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '最大同步批次大小',
                hintText: '请输入最大同步批次大小',
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
            onPressed: () {
              Navigator.pop(context);

              // 解析输入
              final value = int.tryParse(controller.text);

              if (value != null && value > 0) {
                // 更新同步配置
                final updatedConfig = _syncConfig!.copyWith(
                  maxSyncBatchSize: value,
                );

                _updateSyncConfig(updatedConfig);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入有效的最大同步批次大小'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示重置同步设置对话框
  void _showResetSyncSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置同步设置'),
        content: const Text('确定要重置同步设置吗？这将恢复默认同步设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // 重置同步配置
              final defaultConfig = SyncConfig();
              _updateSyncConfig(defaultConfig);
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _syncConfig == null
              ? const Center(child: Text('加载同步配置失败'))
              : ListView(
                  children: [
                    // 同步状态
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '同步状态',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),

                              // 同步状态
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('状态:'),
                                  Text(_getSyncStatusText(_syncStatus?.status)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 最后同步时间
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('最后同步时间:'),
                                  Text(_syncStatus?.lastSyncTime != null
                                      ? _formatDateTime(_syncStatus!.lastSyncTime!)
                                      : '从未同步'),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 同步进度
                              if (_syncStatus?.isSyncing == true) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _syncStatus?.syncProgress,
                                ),
                                const SizedBox(height: 8),
                                Text('同步进度: ${(_syncStatus?.syncProgress ?? 0) * 100}%'),
                              ],

                              const SizedBox(height: 16),

                              // 同步按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_syncStatus?.isSyncing == true) ...[
                                    ElevatedButton(
                                      onPressed: _cancelSync,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('取消同步'),
                                    ),
                                  ] else ...[
                                    ElevatedButton(
                                      onPressed: _startSync,
                                      child: const Text('立即同步'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(),

                    // 自动同步
                    SwitchListTile(
                      title: const Text('自动同步'),
                      subtitle: const Text('定期自动同步数据'),
                      secondary: const Icon(Icons.sync),
                      value: _syncConfig!.enableAutoSync,
                      onChanged: (value) {
                        // 更新同步配置
                        final updatedConfig = _syncConfig!.copyWith(
                          enableAutoSync: value,
                        );

                        _updateSyncConfig(updatedConfig);
                      },
                    ),

                    // 同步间隔
                    if (_syncConfig!.enableAutoSync) ...[
                      ListTile(
                        title: const Text('同步间隔'),
                        subtitle: Text(_getSyncIntervalText(_syncConfig!.autoSyncIntervalMinutes)),
                        leading: const Icon(Icons.timer),
                        onTap: _showSyncIntervalDialog,
                      ),
                    ],

                    const Divider(),

                    // 同步条件
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '同步条件',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 仅在WiFi下同步
                    SwitchListTile(
                      title: const Text('仅在WiFi下同步'),
                      subtitle: const Text('仅在连接WiFi时自动同步'),
                      secondary: const Icon(Icons.wifi),
                      value: _syncConfig!.syncOnlyOnWifi,
                      onChanged: (value) {
                        // 更新同步配置
                        final updatedConfig = _syncConfig!.copyWith(
                          syncOnlyOnWifi: value,
                        );

                        _updateSyncConfig(updatedConfig);
                      },
                    ),

                    // 仅在充电时同步
                    SwitchListTile(
                      title: const Text('仅在充电时同步'),
                      subtitle: const Text('仅在设备充电时自动同步'),
                      secondary: const Icon(Icons.battery_charging_full),
                      value: _syncConfig!.syncOnCharging,
                      onChanged: (value) {
                        // 更新同步配置
                        final updatedConfig = _syncConfig!.copyWith(
                          syncOnCharging: value,
                        );

                        _updateSyncConfig(updatedConfig);
                      },
                    ),

                    const Divider(),

                    // 高级设置
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '高级设置',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 最大同步批次大小
                    ListTile(
                      title: const Text('最大同步批次大小'),
                      subtitle: Text('${_syncConfig!.maxSyncBatchSize}条记录'),
                      leading: const Icon(Icons.storage),
                      onTap: _showMaxSyncBatchSizeDialog,
                    ),

                    const Divider(),

                    // 重置同步设置
                    ListTile(
                      title: const Text('重置同步设置'),
                      subtitle: const Text('恢复默认同步设置'),
                      leading: const Icon(Icons.restore),
                      onTap: _showResetSyncSettingsDialog,
                    ),
                  ],
                ),
    );
  }

  /// 获取同步状态文本
  String _getSyncStatusText(SyncStatusEnum? status) {
    switch (status) {
      case SyncStatusEnum.idle:
        return '空闲';
      case SyncStatusEnum.syncing:
        return '同步中';
      case SyncStatusEnum.error:
        return '错误';
      case SyncStatusEnum.conflict:
        return '冲突';
      default:
        return '未知';
    }
  }

  /// 获取同步间隔文本
  String _getSyncIntervalText(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟';
    } else if (minutes == 60) {
      return '1小时';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60}小时';
    } else {
      return '${minutes ~/ 1440}天';
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
