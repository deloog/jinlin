// 文件： lib/cloud_sync_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/cloud_sync_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/services/auto_sync_service.dart';
import 'package:jinlin_app/user_auth_screen.dart';
import 'package:jinlin_app/sync_conflict_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final AutoSyncService _autoSyncService = AutoSyncService();
  bool _isLoading = false;
  String? _lastSyncTime;
  bool _autoSyncEnabled = false;
  int _syncFrequency = 24;
  dynamic _currentUser;
  bool _isSyncing = false;
  int _conflictCount = 0;
  DateTime? _lastAutoSyncTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoSyncService.addSyncStatusListener(_onSyncStatusChanged);
    _autoSyncService.addSyncResultListener(_onSyncResultReceived);
  }

  @override
  void dispose() {
    _autoSyncService.removeSyncStatusListener(_onSyncStatusChanged);
    _autoSyncService.removeSyncResultListener(_onSyncResultReceived);
    super.dispose();
  }

  void _onSyncStatusChanged(bool isSyncing) {
    if (mounted) {
      setState(() {
        _isSyncing = isSyncing;
      });
    }
  }

  void _onSyncResultReceived(SyncResult result) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      // 刷新数据
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _lastSyncTime = await _cloudSyncService.getLastSyncTime();
      _autoSyncEnabled = await _cloudSyncService.isAutoSyncEnabled();
      _syncFrequency = await _cloudSyncService.getSyncFrequency();
      // 获取Firebase当前用户
      _currentUser = FirebaseAuth.instance.currentUser;
      _conflictCount = await _cloudSyncService.getConflictCount();
      // 获取最后自动同步时间
      final lastAutoSyncTime = await _autoSyncService.getLastAutoSyncTime();
      if (lastAutoSyncTime != null && mounted) {
        setState(() {
          // 显示最后自动同步时间
          _lastSyncTime = '${_lastSyncTime ?? ''} (自动: ${lastAutoSyncTime.toLocal().toString().substring(0, 16)})';
        });
      }
    } catch (e) {
      debugPrint('加载数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  // 导航到登录界面
  Future<void> _navigateToAuthScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserAuthScreen(),
      ),
    );

    if (result == true) {
      // 登录成功，重新加载数据
      await _loadData();

      // 显示欢迎消息
      if (mounted && _currentUser != null) {
        final user = _currentUser as User;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.getLocalizedText(
                context: context,
                textZh: '欢迎回来，${user.displayName ?? user.email ?? "用户"}',
                textEn: 'Welcome back, ${user.displayName ?? user.email ?? "User"}',
                textFr: 'Bienvenue, ${user.displayName ?? user.email ?? "Utilisateur"}',
                textDe: 'Willkommen zurück, ${user.displayName ?? user.email ?? "Benutzer"}',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 退出登录
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cloudSyncService.signOut();

      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出登录失败: $e')),
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

  // 上传数据
  Future<void> _uploadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cloudSyncService.uploadHolidayData();

      // 重新加载数据
      _lastSyncTime = await _cloudSyncService.getLastSyncTime();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.getLocalizedText(
            context: context,
            textZh: '数据上传成功',
            textEn: 'Data uploaded successfully',
            textFr: 'Données téléchargées avec succès',
            textDe: 'Daten erfolgreich hochgeladen',
          ))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传数据失败: $e')),
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

  // 下载数据
  Future<void> _downloadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _cloudSyncService.downloadHolidayData();

      // 重新加载数据
      _lastSyncTime = await _cloudSyncService.getLastSyncTime();
      _conflictCount = await _cloudSyncService.getConflictCount();

      if (mounted) {
        // 如果有冲突，显示冲突提示
        if (_conflictCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.getLocalizedText(
                context: context,
                textZh: '成功下载 $count 个节日，发现 $_conflictCount 个冲突',
                textEn: 'Successfully downloaded $count holidays, found $_conflictCount conflicts',
                textFr: '$count jours fériés téléchargés avec succès, $_conflictCount conflits trouvés',
                textDe: '$count Feiertage erfolgreich heruntergeladen, $_conflictCount Konflikte gefunden',
              )),
              action: SnackBarAction(
                label: LocalizationService.isChineseLocale(context) ? '解决冲突' : 'Resolve',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SyncConflictScreen(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.getLocalizedText(
              context: context,
              textZh: '成功下载 $count 个节日',
              textEn: 'Successfully downloaded $count holidays',
              textFr: '$count jours fériés téléchargés avec succès',
              textDe: '$count Feiertage erfolgreich heruntergeladen',
            ))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载数据失败: $e')),
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

  // 切换自动同步
  Future<void> _toggleAutoSync(bool value) async {
    setState(() {
      _autoSyncEnabled = value;
    });

    try {
      await _cloudSyncService.enableAutoSync(value);

      // 启动或停止自动同步
      if (value) {
        await _autoSyncService.startAutoSync();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.getLocalizedText(
              context: context,
              textZh: '自动同步已启用',
              textEn: 'Auto sync enabled',
              textFr: 'Synchronisation automatique activée',
              textDe: 'Automatische Synchronisierung aktiviert',
            ))),
          );
        }
      } else {
        _autoSyncService.stopAutoSync();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.getLocalizedText(
              context: context,
              textZh: '自动同步已禁用',
              textEn: 'Auto sync disabled',
              textFr: 'Synchronisation automatique désactivée',
              textDe: 'Automatische Synchronisierung deaktiviert',
            ))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置自动同步失败: $e')),
        );

        // 恢复原值
        setState(() {
          _autoSyncEnabled = !value;
        });
      }
    }
  }

  // 设置同步频率
  Future<void> _setSyncFrequency(int hours) async {
    setState(() {
      _syncFrequency = hours;
    });

    try {
      await _cloudSyncService.setSyncFrequency(hours);

      // 如果自动同步已启用，重新启动自动同步
      if (_autoSyncEnabled) {
        await _autoSyncService.startAutoSync();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.getLocalizedText(
              context: context,
              textZh: '同步频率已更新为 $hours 小时',
              textEn: 'Sync frequency updated to $hours hours',
              textFr: 'Fréquence de synchronisation mise à jour à $hours heures',
              textDe: 'Synchronisierungsfrequenz auf $hours Stunden aktualisiert',
            ))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置同步频率失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isChinese ? '云同步' : 'Cloud Sync'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_conflictCount > 0)
            Badge(
              label: Text('$_conflictCount'),
              child: IconButton(
                icon: const Icon(Icons.warning_amber),
                tooltip: isChinese ? '解决冲突' : 'Resolve Conflicts',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SyncConflictScreen(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 账户状态卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isChinese ? '账户状态' : 'Account Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (_currentUser != null) ...[
                            // 已登录
                            Row(
                              children: [
                                const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (_currentUser as User).displayName ?? (_currentUser as User).email ?? 'User',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      if ((_currentUser as User).email != null)
                                        Text(
                                          (_currentUser as User).email!,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _signOut,
                                child: Text(isChinese ? '退出登录' : 'Sign Out'),
                              ),
                            ),
                          ] else ...[
                            // 未登录
                            Text(
                              isChinese
                                  ? '您尚未登录，请登录以使用云同步功能'
                                  : 'You are not logged in. Please login to use cloud sync features.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _navigateToAuthScreen,
                                child: Text(isChinese ? '登录/注册' : 'Login/Register'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 同步操作卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isChinese ? '同步操作' : 'Sync Operations',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isChinese
                                ? '手动同步您的节日数据'
                                : 'Manually sync your holiday data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_lastSyncTime != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              isChinese
                                  ? '上次同步: $_lastSyncTime'
                                  : 'Last sync: $_lastSyncTime',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _currentUser == null ? null : _uploadData,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: Text(isChinese ? '上传' : 'Upload'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _currentUser == null ? null : _downloadData,
                                  icon: const Icon(Icons.cloud_download),
                                  label: Text(isChinese ? '下载' : 'Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 自动同步设置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isChinese ? '自动同步设置' : 'Auto Sync Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(isChinese ? '启用自动同步' : 'Enable Auto Sync'),
                            subtitle: Text(
                              isChinese
                                  ? '定期自动同步您的节日数据'
                                  : 'Automatically sync your holiday data periodically',
                            ),
                            value: _autoSyncEnabled,
                            onChanged: _currentUser == null ? null : _toggleAutoSync,
                          ),
                          const Divider(),
                          ListTile(
                            title: Text(isChinese ? '同步频率' : 'Sync Frequency'),
                            subtitle: Text(
                              isChinese
                                  ? '每 $_syncFrequency 小时同步一次'
                                  : 'Sync every $_syncFrequency hours',
                            ),
                            trailing: DropdownButton<int>(
                              value: _syncFrequency,
                              onChanged: _currentUser == null || !_autoSyncEnabled
                                  ? null
                                  : (int? value) {
                                      if (value != null) {
                                        _setSyncFrequency(value);
                                      }
                                    },
                              items: [1, 6, 12, 24, 48, 72].map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value ${isChinese ? '小时' : 'hours'}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 注意事项
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(51), // 0.2 * 255 = 51
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.amber),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            isChinese
                                ? '云同步功能需要网络连接。上传将覆盖云端数据，下载将覆盖本地数据。请谨慎操作。'
                                : 'Cloud sync requires internet connection. Upload will overwrite cloud data, download will overwrite local data. Please proceed with caution.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 显示同步状态
          if (_isSyncing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      isChinese ? '正在同步...' : 'Syncing...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
