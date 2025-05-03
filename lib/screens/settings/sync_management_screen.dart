import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jinlin_app/models/sync/sync_config.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation_type.dart';
import 'package:jinlin_app/models/sync/sync_status_enum.dart';
import 'package:jinlin_app/providers/sync_provider.dart';
import 'package:jinlin_app/generated/l10n.dart';
import 'package:jinlin_app/widgets/common/custom_app_bar.dart';
import 'package:jinlin_app/widgets/common/custom_card.dart';

/// 同步管理页面
class SyncManagementScreen extends StatelessWidget {
  const SyncManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final syncProvider = SyncProvider.of(context);
    final s = S.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: s.syncManagement,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: syncProvider.isSyncing
                ? null
                : () => syncProvider.startSync(),
            tooltip: s.sync,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => syncProvider.startSync(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSyncStatusCard(context, syncProvider),
            const SizedBox(height: 16.0),
            _buildSyncConfigCard(context, syncProvider),
            const SizedBox(height: 16.0),
            _buildSyncOperationsCard(context, syncProvider),
            const SizedBox(height: 16.0),
            _buildSyncConflictsCard(context, syncProvider),
          ],
        ),
      ),
    );
  }

  /// 构建同步状态卡片
  Widget _buildSyncStatusCard(BuildContext context, SyncProvider syncProvider) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final lastSyncTime = syncProvider.lastSyncTime;
    final lastSyncTimeText = lastSyncTime != null
        ? DateFormat.yMd().add_Hms().format(lastSyncTime)
        : s.never;

    return CustomCard(
      title: s.syncStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (syncProvider.isSyncing) ...[
            LinearProgressIndicator(
              value: syncProvider.syncProgress,
            ),
            const SizedBox(height: 16.0),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.lastSyncTime, style: textTheme.bodyLarge),
              Text(lastSyncTimeText, style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.syncStatus, style: textTheme.bodyLarge),
              Text(
                syncProvider.isSyncing ? s.syncing : s.idle,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          if (syncProvider.lastSyncError != null) ...[
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.lastSyncError, style: textTheme.bodyLarge),
                Expanded(
                  child: Text(
                    syncProvider.lastSyncError!,
                    style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusCounter(
                context,
                s.pending,
                syncProvider.pendingOperationsCount,
                Colors.blue,
              ),
              _buildStatusCounter(
                context,
                s.syncing,
                syncProvider.syncingOperationsCount,
                Colors.orange,
              ),
              _buildStatusCounter(
                context,
                s.synced,
                syncProvider.syncedOperationsCount,
                Colors.green,
              ),
              _buildStatusCounter(
                context,
                s.failed,
                syncProvider.failedOperationsCount,
                Colors.red,
              ),
              _buildStatusCounter(
                context,
                s.conflicts,
                syncProvider.conflictOperationsCount,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: Text(s.sync),
                onPressed: syncProvider.isSyncing
                    ? null
                    : () => syncProvider.startSync(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: Text(s.retry),
                onPressed: syncProvider.isSyncing || !syncProvider.hasFailedOperations
                    ? null
                    : () => syncProvider.retryFailedOperations(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: Text(s.cancel),
                onPressed: !syncProvider.isSyncing
                    ? null
                    : () => syncProvider.cancelSync(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建状态计数器
  Widget _buildStatusCounter(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 构建同步配置卡片
  Widget _buildSyncConfigCard(BuildContext context, SyncProvider syncProvider) {
    final s = S.of(context);

    return CustomCard(
      title: s.syncSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(s.autoSync),
            subtitle: Text(s.autoSyncDescription),
            value: syncProvider.isAutoSyncEnabled,
            onChanged: (value) {
              if (value) {
                syncProvider.enableAutoSync();
              } else {
                syncProvider.disableAutoSync();
              }
            },
          ),
          ListTile(
            title: Text(s.syncInterval),
            subtitle: Text(
              s.syncIntervalMinutes(syncProvider.config.autoSyncIntervalMinutes),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () => _showSyncIntervalDialog(context, syncProvider),
          ),
          ListTile(
            title: Text(s.syncOnlyOnWifi),
            subtitle: Text(s.syncOnlyOnWifiDescription),
            trailing: Switch(
              value: syncProvider.config.syncOnlyOnWifi,
              onChanged: (value) {
                final newConfig = syncProvider.config.copyWith(
                  syncOnlyOnWifi: value,
                );
                syncProvider.updateSyncConfig(newConfig);
              },
            ),
          ),
          ListTile(
            title: Text(s.incrementalSync),
            subtitle: Text(s.incrementalSyncDescription),
            trailing: Switch(
              value: syncProvider.config.enableIncrementalSync,
              onChanged: (value) {
                final newConfig = syncProvider.config.copyWith(
                  enableIncrementalSync: value,
                );
                syncProvider.updateSyncConfig(newConfig);
              },
            ),
          ),
          ListTile(
            title: Text(s.conflictResolution),
            subtitle: Text(_getConflictResolutionText(context, syncProvider.config.conflictResolutionStrategy)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () => _showConflictResolutionDialog(context, syncProvider),
          ),
          ListTile(
            title: Text(s.syncDeletedData),
            subtitle: Text(s.syncDeletedDataDescription),
            trailing: Switch(
              value: syncProvider.config.syncDeletedData,
              onChanged: (value) {
                final newConfig = syncProvider.config.copyWith(
                  syncDeletedData: value,
                );
                syncProvider.updateSyncConfig(newConfig);
              },
            ),
          ),
          ListTile(
            title: Text(s.enableEncryption),
            subtitle: Text(s.enableEncryptionDescription),
            trailing: Switch(
              value: syncProvider.config.enableEncryption,
              onChanged: (value) {
                final newConfig = syncProvider.config.copyWith(
                  enableEncryption: value,
                );
                syncProvider.updateSyncConfig(newConfig);
              },
            ),
          ),
          ListTile(
            title: Text(s.enableCompression),
            subtitle: Text(s.enableCompressionDescription),
            trailing: Switch(
              value: syncProvider.config.enableCompression,
              onChanged: (value) {
                final newConfig = syncProvider.config.copyWith(
                  enableCompression: value,
                );
                syncProvider.updateSyncConfig(newConfig);
              },
            ),
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(s.clearSyncData),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _showClearSyncDataDialog(context, syncProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取冲突解决策略文本
  String _getConflictResolutionText(BuildContext context, ConflictResolutionStrategy strategy) {
    final s = S.of(context);

    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return s.useLocalData;
      case ConflictResolutionStrategy.useServer:
        return s.useServerData;
      case ConflictResolutionStrategy.merge:
        return s.mergeData;
      case ConflictResolutionStrategy.manual:
        return s.manualResolution;
    }
  }

  /// 显示同步间隔对话框
  Future<void> _showSyncIntervalDialog(BuildContext context, SyncProvider syncProvider) async {
    final s = S.of(context);

    final intervals = [15, 30, 60, 120, 240, 480, 720, 1440];
    int selectedInterval = syncProvider.config.autoSyncIntervalMinutes;

    if (!intervals.contains(selectedInterval)) {
      intervals.add(selectedInterval);
      intervals.sort();
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(s.syncInterval),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.selectSyncInterval),
                  const SizedBox(height: 16.0),
                  DropdownButton<int>(
                    value: selectedInterval,
                    isExpanded: true,
                    items: intervals.map((interval) {
                      return DropdownMenuItem<int>(
                        value: interval,
                        child: Text(_formatInterval(context, interval)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedInterval = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(s.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(s.save),
                  onPressed: () {
                    final newConfig = syncProvider.config.copyWith(
                      autoSyncIntervalMinutes: selectedInterval,
                    );
                    syncProvider.updateSyncConfig(newConfig);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 格式化间隔
  String _formatInterval(BuildContext context, int minutes) {
    final s = S.of(context);

    if (minutes < 60) {
      return s.minutesCount(minutes);
    } else if (minutes == 60) {
      return s.hour1;
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return s.hoursCount(hours);
    } else if (minutes == 1440) {
      return s.day1;
    } else {
      final days = minutes ~/ 1440;
      return s.daysCount(days);
    }
  }

  /// 显示冲突解决策略对话框
  Future<void> _showConflictResolutionDialog(BuildContext context, SyncProvider syncProvider) async {
    final s = S.of(context);

    ConflictResolutionStrategy selectedStrategy = syncProvider.config.conflictResolutionStrategy;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(s.conflictResolution),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.selectConflictResolution),
                  const SizedBox(height: 16.0),
                  RadioListTile<ConflictResolutionStrategy>(
                    title: Text(s.useLocalData),
                    subtitle: Text(s.useLocalDataDescription),
                    value: ConflictResolutionStrategy.useLocal,
                    groupValue: selectedStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStrategy = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionStrategy>(
                    title: Text(s.useServerData),
                    subtitle: Text(s.useServerDataDescription),
                    value: ConflictResolutionStrategy.useServer,
                    groupValue: selectedStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStrategy = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionStrategy>(
                    title: Text(s.mergeData),
                    subtitle: Text(s.mergeDataDescription),
                    value: ConflictResolutionStrategy.merge,
                    groupValue: selectedStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStrategy = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionStrategy>(
                    title: Text(s.manualResolution),
                    subtitle: Text(s.manualResolutionDescription),
                    value: ConflictResolutionStrategy.manual,
                    groupValue: selectedStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStrategy = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(s.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(s.save),
                  onPressed: () {
                    final newConfig = syncProvider.config.copyWith(
                      conflictResolutionStrategy: selectedStrategy,
                    );
                    syncProvider.updateSyncConfig(newConfig);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示清除同步数据对话框
  Future<void> _showClearSyncDataDialog(BuildContext context, SyncProvider syncProvider) async {
    final s = S.of(context);
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s.clearSyncData),
          content: Text(s.clearSyncDataConfirmation),
          actions: [
            TextButton(
              child: Text(s.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                s.clear,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () {
                syncProvider.clearAllSyncData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 构建同步操作卡片
  Widget _buildSyncOperationsCard(BuildContext context, SyncProvider syncProvider) {
    final s = S.of(context);

    final operations = syncProvider.operations;

    return CustomCard(
      title: s.syncOperations,
      child: operations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(s.noSyncOperations),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: operations.length > 5 ? 5 : operations.length,
                  itemBuilder: (context, index) {
                    final operation = operations[index];
                    return ListTile(
                      title: Text(
                        '${_getOperationTypeText(context, operation.operationType)} - ${operation.entityType}',
                      ),
                      subtitle: Text(
                        '${operation.entityId} - ${_getOperationStatusText(context, operation.status)}',
                      ),
                      trailing: _getOperationStatusIcon(context, operation.status),
                    );
                  },
                ),
                if (operations.length > 5) ...[
                  const Divider(),
                  Center(
                    child: TextButton(
                      child: Text(s.viewAll),
                      onPressed: () {
                        // TODO: 导航到同步操作列表页面
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// 获取操作类型文本
  String _getOperationTypeText(BuildContext context, SyncOperationType type) {
    final s = S.of(context);

    switch (type) {
      case SyncOperationType.create:
        return s.create;
      case SyncOperationType.update:
        return s.update;
      case SyncOperationType.delete:
        return s.delete;
      case SyncOperationType.softDelete:
        return s.softDelete;
      case SyncOperationType.restore:
        return s.restore;
    }
  }

  /// 获取操作状态文本
  String _getOperationStatusText(BuildContext context, SyncStatus status) {
    final s = S.of(context);

    switch (status) {
      case SyncStatus.pending:
        return s.pending;
      case SyncStatus.syncing:
        return s.syncing;
      case SyncStatus.synced:
        return s.synced;
      case SyncStatus.failed:
        return s.failed;
      case SyncStatus.conflict:
        return s.conflict;
    }
  }

  /// 获取操作状态图标
  Widget _getOperationStatusIcon(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return const Icon(Icons.schedule, color: Colors.blue);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case SyncStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case SyncStatus.conflict:
        return const Icon(Icons.warning, color: Colors.purple);
    }
  }

  /// 构建同步冲突卡片
  Widget _buildSyncConflictsCard(BuildContext context, SyncProvider syncProvider) {
    final s = S.of(context);

    final conflicts = syncProvider.conflicts;

    return CustomCard(
      title: s.syncConflicts,
      child: conflicts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(s.noSyncConflicts),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conflicts.length > 5 ? 5 : conflicts.length,
                  itemBuilder: (context, index) {
                    final conflict = conflicts[index];
                    return ListTile(
                      title: Text(
                        '${_getOperationTypeText(context, conflict.operation.operationType)} - ${conflict.operation.entityType}',
                      ),
                      subtitle: Text(conflict.operation.entityId),
                      trailing: conflict.isResolved
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.warning, color: Colors.orange),
                      onTap: () {
                        if (!conflict.isResolved) {
                          _showConflictResolutionDetailDialog(context, syncProvider, conflict);
                        }
                      },
                    );
                  },
                ),
                if (conflicts.length > 5) ...[
                  const Divider(),
                  Center(
                    child: TextButton(
                      child: Text(s.viewAll),
                      onPressed: () {
                        // TODO: 导航到同步冲突列表页面
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// 显示冲突解决对话框
  Future<void> _showConflictResolutionDetailDialog(
    BuildContext context,
    SyncProvider syncProvider,
    SyncConflict conflict,
  ) async {
    final s = S.of(context);
    final theme = Theme.of(context);

    ConflictResolutionResult selectedResult = ConflictResolutionResult.useLocal;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(s.resolveConflict),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getOperationTypeText(context, conflict.operation.operationType)} - ${conflict.operation.entityType} - ${conflict.operation.entityId}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16.0),
                  RadioListTile<ConflictResolutionResult>(
                    title: Text(s.useLocalData),
                    value: ConflictResolutionResult.useLocal,
                    groupValue: selectedResult,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedResult = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionResult>(
                    title: Text(s.useServerData),
                    value: ConflictResolutionResult.useServer,
                    groupValue: selectedResult,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedResult = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionResult>(
                    title: Text(s.mergeData),
                    value: ConflictResolutionResult.useMerged,
                    groupValue: selectedResult,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedResult = value;
                        });
                      }
                    },
                  ),
                  RadioListTile<ConflictResolutionResult>(
                    title: Text(s.skip),
                    value: ConflictResolutionResult.skip,
                    groupValue: selectedResult,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedResult = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(s.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(s.resolve),
                  onPressed: () {
                    syncProvider.resolveSyncConflict(
                      conflict.id,
                      selectedResult,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
