import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_config.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/models/sync/sync_operation_type.dart';
import 'package:jinlin_app/models/sync/sync_status.dart' as status_model;

/// 同步服务接口
///
/// 定义同步服务的基本接口
abstract class SyncServiceInterface {
  /// 初始化同步服务
  Future<void> initialize();

  /// 关闭同步服务
  Future<void> close();

  /// 获取同步配置
  Future<SyncConfig> getSyncConfig();

  /// 更新同步配置
  Future<void> updateSyncConfig(SyncConfig config);

  /// 获取同步状态
  Future<status_model.SyncStatus> getSyncStatus();

  /// 开始同步
  Future<void> startSync();

  /// 取消同步
  Future<void> cancelSync();

  /// 获取同步批次
  Future<List<SyncBatch>> getSyncBatches();

  /// 获取同步批次
  Future<SyncBatch?> getSyncBatch(String batchId);

  /// 创建同步批次
  Future<SyncBatch> createSyncBatch(List<SyncOperation> operations);

  /// 删除同步批次
  Future<void> deleteSyncBatch(String batchId);

  /// 获取同步操作
  Future<List<SyncOperation>> getSyncOperations();

  /// 获取同步操作
  Future<SyncOperation?> getSyncOperation(String operationId);

  /// 创建同步操作
  Future<SyncOperation> createSyncOperation(
    SyncOperationType operationType,
    String entityType,
    String entityId,
    Map<String, dynamic>? entityData,
  );

  /// 删除同步操作
  Future<void> deleteSyncOperation(String operationId);

  /// 获取同步冲突
  Future<List<SyncConflict>> getSyncConflicts();

  /// 获取同步冲突
  Future<SyncConflict?> getSyncConflict(String conflictId);

  /// 解决同步冲突
  Future<void> resolveSyncConflict(
    String conflictId,
    ConflictResolutionResult resolutionResult, {
    Map<String, dynamic>? mergedData,
  });

  /// 获取待同步操作数
  Future<int> getPendingOperationsCount();

  /// 获取同步失败操作数
  Future<int> getFailedOperationsCount();

  /// 获取冲突操作数
  Future<int> getConflictOperationsCount();

  /// 重试失败的同步操作
  Future<void> retryFailedOperations();

  /// 清除所有同步数据
  Future<void> clearAllSyncData();

  /// 启用自动同步
  Future<void> enableAutoSync();

  /// 禁用自动同步
  Future<void> disableAutoSync();

  /// 是否启用自动同步
  Future<bool> isAutoSyncEnabled();

  /// 获取最后同步时间
  Future<DateTime?> getLastSyncTime();

  /// 获取同步进度
  Future<double> getSyncProgress();

  /// 是否正在同步
  Future<bool> isSyncing();

  /// 添加同步监听器
  void addSyncListener(SyncListener listener);

  /// 移除同步监听器
  void removeSyncListener(SyncListener listener);
}

/// 同步监听器
///
/// 监听同步事件
abstract class SyncListener {
  /// 同步开始
  void onSyncStarted();

  /// 同步完成
  void onSyncCompleted();

  /// 同步失败
  void onSyncFailed(String error);

  /// 同步进度更新
  void onSyncProgressUpdated(double progress);

  /// 同步状态更新
  void onSyncStatusUpdated(status_model.SyncStatus status);

  /// 同步冲突
  void onSyncConflict(SyncConflict conflict);

  /// 同步操作更新
  void onSyncOperationUpdated(SyncOperation operation);

  /// 同步批次更新
  void onSyncBatchUpdated(SyncBatch batch);
}
