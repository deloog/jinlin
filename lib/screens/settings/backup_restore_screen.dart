import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jinlin_app/generated/l10n.dart';
import 'package:jinlin_app/services/backup_restore_service.dart';
import 'package:jinlin_app/widgets/common/custom_app_bar.dart';
import 'package:jinlin_app/widgets/common/custom_card.dart';

/// 备份和恢复页面
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupRestoreService _backupService = BackupRestoreService();
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = true;
  DateTime? _lastBackupTime;
  final TextEditingController _passwordController = TextEditingController();
  bool _usePassword = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
    _loadLastBackupTime();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// 加载备份文件列表
  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _backupService.getBackupFiles();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载备份文件列表失败: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载备份文件列表失败: $e')),
        );
      }
    }
  }

  /// 加载最后备份时间
  Future<void> _loadLastBackupTime() async {
    try {
      final lastBackupTime = await _backupService.getLastBackupTime();
      setState(() {
        _lastBackupTime = lastBackupTime;
      });
    } catch (e) {
      debugPrint('加载最后备份时间失败: $e');
    }
  }

  /// 创建备份
  Future<void> _createBackup() async {
    try {
      final password = _usePassword ? _passwordController.text : null;

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在创建备份...'),
              ],
            ),
          ),
        );
      }

      // 创建备份
      final backupFilePath = await _backupService.createBackup(password: password);

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (backupFilePath != null) {
        // 刷新备份文件列表
        await _loadBackupFiles();
        await _loadLastBackupTime();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份创建成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份创建失败')),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('创建备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建备份失败: $e')),
        );
      }
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup(String backupFilePath) async {
    try {
      // 显示密码输入对话框
      final password = await _showPasswordInputDialog();
      if (password == null) {
        return;
      }

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在恢复备份...'),
              ],
            ),
          ),
        );
      }

      // 恢复备份
      final success = await _backupService.restoreBackup(
        backupFilePath,
        password: password.isNotEmpty ? password : null,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份恢复成功，请重启应用以应用更改')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份恢复失败，可能是密码错误或备份文件损坏')),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('恢复备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复备份失败: $e')),
        );
      }
    }
  }

  /// 删除备份
  Future<void> _deleteBackup(String backupFilePath) async {
    try {
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除此备份吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      // 删除备份
      final success = await _backupService.deleteBackupFile(backupFilePath);
      if (success) {
        // 刷新备份文件列表
        await _loadBackupFiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份已删除')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除备份失败')),
          );
        }
      }
    } catch (e) {
      debugPrint('删除备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除备份失败: $e')),
        );
      }
    }
  }

  /// 导出备份
  Future<void> _exportBackup() async {
    try {
      // 显示密码输入对话框
      final password = await _showPasswordInputDialog();
      if (password == null) {
        return;
      }

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导出备份...'),
              ],
            ),
          ),
        );
      }

      // 导出备份
      final exportPath = await _backupService.exportBackup(
        password: password.isNotEmpty ? password : null,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (exportPath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('备份已导出到: $exportPath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出备份失败')),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('导出备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出备份失败: $e')),
        );
      }
    }
  }

  /// 导入备份
  Future<void> _importBackup() async {
    try {
      // 显示密码输入对话框
      final password = await _showPasswordInputDialog();
      if (password == null) {
        return;
      }

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入备份...'),
              ],
            ),
          ),
        );
      }

      // 导入备份
      final success = await _backupService.importBackup(
        password: password.isNotEmpty ? password : null,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // 刷新备份文件列表
        await _loadBackupFiles();
        await _loadLastBackupTime();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备份导入成功，请重启应用以应用更改')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导入备份失败，可能是密码错误或备份文件损坏')),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('导入备份失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入备份失败: $e')),
        );
      }
    }
  }

  /// 显示密码输入对话框
  Future<String?> _showPasswordInputDialog() async {
    final controller = TextEditingController();
    bool usePassword = false;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('备份密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('如果备份已加密，请输入密码。如果未加密，请留空。'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('使用密码'),
                value: usePassword,
                onChanged: (value) {
                  setState(() {
                    usePassword = value ?? false;
                  });
                },
              ),
              if (usePassword)
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                usePassword ? controller.text : '',
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: s.backupAndRestore,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 备份操作卡片
          CustomCard(
            title: '备份操作',
            child: Column(
              children: [
                // 最后备份时间
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('最后备份时间'),
                  subtitle: Text(
                    _lastBackupTime != null
                        ? DateFormat.yMd().add_Hms().format(_lastBackupTime!)
                        : '从未备份',
                  ),
                ),
                // 创建备份
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('创建备份'),
                  subtitle: const Text('创建应用数据的备份'),
                  onTap: () => _showCreateBackupDialog(),
                ),
                // 导入备份
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('导入备份'),
                  subtitle: const Text('从外部导入备份文件'),
                  onTap: _importBackup,
                ),
                // 导出备份
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('导出备份'),
                  subtitle: const Text('将备份导出到外部存储'),
                  onTap: _exportBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 备份文件列表卡片
          CustomCard(
            title: '备份文件',
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _backupFiles.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('没有备份文件')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _backupFiles.length,
                        itemBuilder: (context, index) {
                          final file = _backupFiles[index];
                          final fileName = file.path.split('/').last;
                          final fileStats = FileStat.statSync(file.path);
                          final fileSize = _formatFileSize(fileStats.size);
                          final fileDate = DateFormat.yMd().add_Hms().format(fileStats.modified);

                          return ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(fileName),
                            subtitle: Text('$fileSize - $fileDate'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore),
                                  tooltip: '恢复',
                                  onPressed: () => _restoreBackup(file.path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: '删除',
                                  onPressed: () => _deleteBackup(file.path),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 显示创建备份对话框
  void _showCreateBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('创建应用数据的备份。您可以选择使用密码加密备份。'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('使用密码加密'),
                value: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value ?? false;
                  });
                },
              ),
              if (_usePassword)
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _passwordController.clear();
                _usePassword = false;
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createBackup();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化文件大小
  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
