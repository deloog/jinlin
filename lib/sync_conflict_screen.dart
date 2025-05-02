// 文件： lib/sync_conflict_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/cloud_sync_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/services/hive_database_service.dart';

class SyncConflictScreen extends StatefulWidget {
  const SyncConflictScreen({super.key});

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  final CloudSyncService _cloudSyncService = CloudSyncService();
  List<HolidayModel> _conflictedHolidays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConflictedHolidays();
  }

  Future<void> _loadConflictedHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final holidays = await _cloudSyncService.getConflictedHolidays();

      if (mounted) {
        setState(() {
          _conflictedHolidays = holidays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载冲突数据失败: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveConflict(HolidayModel holiday, bool keepLocal) async {
    try {
      if (keepLocal) {
        // 保留本地版本，上传到云端
        final updatedHoliday = holiday.copyWithLastModified();
        await HiveDatabaseService.saveHoliday(updatedHoliday);

        // 从冲突列表中移除
        setState(() {
          _conflictedHolidays.removeWhere((h) => h.id == holiday.id);
        });

        // 如果冲突全部解决，清除冲突记录
        if (_conflictedHolidays.isEmpty) {
          await _cloudSyncService.clearConflicts();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已保留本地版本: ${holiday.name}')),
          );
        }
      } else {
        // 使用云端版本，重新下载
        await _cloudSyncService.downloadHolidayData();

        // 从冲突列表中移除
        setState(() {
          _conflictedHolidays.removeWhere((h) => h.id == holiday.id);
        });

        // 如果冲突全部解决，清除冲突记录
        if (_conflictedHolidays.isEmpty) {
          await _cloudSyncService.clearConflicts();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已使用云端版本: ${holiday.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解决冲突失败: $e')),
        );
      }
    }
  }

  Future<void> _resolveAllConflicts(bool keepLocal) async {
    try {
      if (keepLocal) {
        // 保留所有本地版本
        for (var holiday in _conflictedHolidays) {
          final updatedHoliday = holiday.copyWithLastModified();
          await HiveDatabaseService.saveHoliday(updatedHoliday);
        }

        // 清除冲突记录
        await _cloudSyncService.clearConflicts();

        setState(() {
          _conflictedHolidays = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保留所有本地版本')),
          );
        }
      } else {
        // 使用所有云端版本
        await _cloudSyncService.downloadHolidayData();

        // 清除冲突记录
        await _cloudSyncService.clearConflicts();

        setState(() {
          _conflictedHolidays = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已使用所有云端版本')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解决所有冲突失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isChinese ? '同步冲突' : 'Sync Conflicts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conflictedHolidays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        isChinese ? '没有同步冲突' : 'No sync conflicts',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isChinese ? '所有数据已同步' : 'All data is in sync',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        isChinese
                            ? '发现 ${_conflictedHolidays.length} 个同步冲突，请选择要保留的版本'
                            : '${_conflictedHolidays.length} sync conflicts found, please choose which version to keep',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    // 批量操作按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolveAllConflicts(true),
                              icon: const Icon(Icons.phone_android),
                              label: Text(isChinese ? '保留所有本地版本' : 'Keep All Local'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolveAllConflicts(false),
                              icon: const Icon(Icons.cloud_download),
                              label: Text(isChinese ? '使用所有云端版本' : 'Use All Cloud'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 32),

                    // 冲突列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: _conflictedHolidays.length,
                        itemBuilder: (context, index) {
                          final holiday = _conflictedHolidays[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holiday.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${isChinese ? '类型' : 'Type'}: ${LocalizationService.getLocalizedHolidayType(context, holiday.type.toString().split('.').last)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${isChinese ? '最后修改' : 'Last Modified'}: ${holiday.lastModified?.toString() ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _resolveConflict(holiday, true),
                                          icon: const Icon(Icons.phone_android),
                                          label: Text(isChinese ? '保留本地版本' : 'Keep Local'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _resolveConflict(holiday, false),
                                          icon: const Icon(Icons.cloud_download),
                                          label: Text(isChinese ? '使用云端版本' : 'Use Cloud'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
