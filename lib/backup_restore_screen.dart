import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'data/data_manager.dart';
import 'data/file_manager.dart';

final Logger logger = Logger('BackupRestoreScreen');

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final DataManager _dataManager = DataManager();
  final FileManager _fileManager = FileManager();
  bool _isLoading = false;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadLastBackupInfo();
  }

  // 加载上次备份信息
  Future<void> _loadLastBackupInfo() async {
    // 这里可以从 SharedPreferences 加载上次备份的路径和时间
    // 暂时留空，后续可以实现
  }

  // 备份数据
  Future<void> _backupData() async {
    if (!mounted) return;

    // 获取本地化实例，在异步操作前
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // 导出数据到文件
      final filePath = await _dataManager.exportData();

      if (!mounted) return;

      // 分享文件
      final shared = await _fileManager.shareFile(
        filePath,
        subject: l10n.backupFileSubject,
      );

      if (shared) {
        // 更新上次备份信息
        setState(() {
          _lastBackupTime = DateTime.now();
        });

        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupSuccessMessage)),
          );
        }
      }
    } catch (e) {
      logger.warning('Backup failed: $e');
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupFailedMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 恢复数据
  Future<void> _restoreData() async {
    if (!mounted) return;

    // 获取本地化实例，在异步操作前
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // 选择文件
      final filePath = await _fileManager.pickFile(
        allowedExtensions: ['json'],
        dialogTitle: l10n.selectBackupFileTitle,
      );

      if (filePath == null || !mounted) {
        // 用户取消了选择或组件已卸载
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 显示确认对话框前检查组件是否仍然挂载
      if (!mounted) return;

      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.restoreButton),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        // 用户取消了恢复
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 导入数据
      final importedCount = await _dataManager.importData(filePath);

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreSuccessMessage(importedCount))),
        );
      }
    } catch (e) {
      logger.warning('Restore failed: $e');
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailedMessage)),
        );
      }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupRestoreTitle),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 备份卡片
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.backup, color: theme.colorScheme.primary),
                              const SizedBox(width: 8.0),
                              Text(
                                l10n.backupTitle,
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Text(l10n.backupDescription),
                          const SizedBox(height: 16.0),
                          if (_lastBackupTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                l10n.lastBackupTime(_lastBackupTime!.toString()),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _backupData,
                            icon: const Icon(Icons.save),
                            label: Text(l10n.createBackupButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 恢复卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restore, color: theme.colorScheme.primary),
                              const SizedBox(width: 8.0),
                              Text(
                                l10n.restoreTitle,
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Text(l10n.restoreDescription),
                          const SizedBox(height: 16.0),
                          ElevatedButton.icon(
                            onPressed: _restoreData,
                            icon: const Icon(Icons.file_upload),
                            label: Text(l10n.restoreFromBackupButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 警告信息
                  const SizedBox(height: 24.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: theme.colorScheme.error),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            l10n.backupRestoreWarning,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
