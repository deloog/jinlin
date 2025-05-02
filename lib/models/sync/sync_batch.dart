import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/models/sync/sync_status_enum.dart';

/// 同步批次状态
enum SyncBatchStatus {
  /// 待同步
  pending,

  /// 同步中
  syncing,

  /// 已同步
  synced,

  /// 同步失败
  failed,

  /// 部分同步
  partialSync,
}

/// 同步批次
///
/// 表示一批同步操作
class SyncBatch {
  /// 批次ID
  final String id;

  /// 批次状态
  final SyncBatchStatus status;

  /// 同步操作列表
  final List<SyncOperation> operations;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime? lastModified;

  /// 最后同步时间
  final DateTime? lastSynced;

  /// 错误消息
  final String? errorMessage;

  /// 重试次数
  final int retryCount;

  /// 构造函数
  SyncBatch({
    required this.id,
    this.status = SyncBatchStatus.pending,
    required this.operations,
    DateTime? createdAt,
    this.lastModified,
    this.lastSynced,
    this.errorMessage,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建
  factory SyncBatch.fromJson(Map<String, dynamic> json) {
    return SyncBatch(
      id: json['id'] as String,
      status: SyncBatchStatus.values[json['status'] as int],
      operations: (json['operations'] as List<dynamic>)
          .map((e) => SyncOperation.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.index,
      'operations': operations.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  /// 创建带有更新的副本
  SyncBatch copyWith({
    String? id,
    SyncBatchStatus? status,
    List<SyncOperation>? operations,
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? lastSynced,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncBatch(
      id: id ?? this.id,
      status: status ?? this.status,
      operations: operations ?? this.operations,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastSynced: lastSynced ?? this.lastSynced,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// 更新状态
  SyncBatch updateStatus(SyncBatchStatus newStatus, {
    DateTime? lastModified,
    DateTime? lastSynced,
    String? errorMessage,
    int? retryCount,
  }) {
    return copyWith(
      status: newStatus,
      lastModified: lastModified ?? DateTime.now(),
      lastSynced: lastSynced,
      errorMessage: errorMessage,
      retryCount: retryCount,
    );
  }

  /// 标记为同步中
  SyncBatch markAsSyncing() {
    return updateStatus(SyncBatchStatus.syncing);
  }

  /// 标记为已同步
  SyncBatch markAsSynced() {
    return updateStatus(
      SyncBatchStatus.synced,
      lastSynced: DateTime.now(),
    );
  }

  /// 标记为同步失败
  SyncBatch markAsFailed(String error) {
    return updateStatus(
      SyncBatchStatus.failed,
      errorMessage: error,
      retryCount: retryCount + 1,
    );
  }

  /// 标记为部分同步
  SyncBatch markAsPartialSync(String error) {
    return updateStatus(
      SyncBatchStatus.partialSync,
      errorMessage: error,
      lastSynced: DateTime.now(),
    );
  }

  /// 重置状态
  SyncBatch resetStatus() {
    return updateStatus(SyncBatchStatus.pending);
  }

  /// 更新操作
  SyncBatch updateOperation(SyncOperation operation) {
    final index = operations.indexWhere((op) => op.id == operation.id);
    if (index == -1) {
      return this;
    }

    final updatedOperations = List<SyncOperation>.from(operations);
    updatedOperations[index] = operation;

    return copyWith(
      operations: updatedOperations,
      lastModified: DateTime.now(),
    );
  }

  /// 添加操作
  SyncBatch addOperation(SyncOperation operation) {
    final updatedOperations = List<SyncOperation>.from(operations);
    updatedOperations.add(operation);

    return copyWith(
      operations: updatedOperations,
      lastModified: DateTime.now(),
    );
  }

  /// 移除操作
  SyncBatch removeOperation(String operationId) {
    final updatedOperations = operations.where((op) => op.id != operationId).toList();

    return copyWith(
      operations: updatedOperations,
      lastModified: DateTime.now(),
    );
  }

  /// 获取待同步操作
  List<SyncOperation> getPendingOperations() {
    return operations.where((op) => op.status == SyncStatus.pending).toList();
  }

  /// 获取同步中操作
  List<SyncOperation> getSyncingOperations() {
    return operations.where((op) => op.status == SyncStatus.syncing).toList();
  }

  /// 获取已同步操作
  List<SyncOperation> getSyncedOperations() {
    return operations.where((op) => op.status == SyncStatus.synced).toList();
  }

  /// 获取同步失败操作
  List<SyncOperation> getFailedOperations() {
    return operations.where((op) => op.status == SyncStatus.failed).toList();
  }

  /// 获取冲突操作
  List<SyncOperation> getConflictOperations() {
    return operations.where((op) => op.status == SyncStatus.conflict).toList();
  }

  /// 是否有待同步操作
  bool hasPendingOperations() {
    return getPendingOperations().isNotEmpty;
  }

  /// 是否有同步中操作
  bool hasSyncingOperations() {
    return getSyncingOperations().isNotEmpty;
  }

  /// 是否有同步失败操作
  bool hasFailedOperations() {
    return getFailedOperations().isNotEmpty;
  }

  /// 是否有冲突操作
  bool hasConflictOperations() {
    return getConflictOperations().isNotEmpty;
  }

  /// 是否所有操作都已同步
  bool isAllSynced() {
    return operations.every((op) => op.status == SyncStatus.synced);
  }

  /// 获取同步进度
  double getSyncProgress() {
    if (operations.isEmpty) {
      return 1.0;
    }

    final syncedCount = getSyncedOperations().length;
    return syncedCount / operations.length;
  }
}
