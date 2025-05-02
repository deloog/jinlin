
import 'package:jinlin_app/models/sync/sync_operation_type.dart';
import 'package:jinlin_app/models/sync/sync_status_enum.dart';

/// 同步操作
///
/// 表示一个同步操作，包括操作类型、实体类型、实体ID等
class SyncOperation {
  /// 操作ID
  final String id;

  /// 操作类型
  final SyncOperationType operationType;

  /// 实体类型
  final String entityType;

  /// 实体ID
  final String entityId;

  /// 实体数据
  final Map<String, dynamic>? entityData;

  /// 版本号
  final int version;

  /// 同步状态
  final SyncStatus status;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime? lastModified;

  /// 最后同步时间
  final DateTime? lastSynced;

  /// 冲突数据
  final Map<String, dynamic>? conflictData;

  /// 错误消息
  final String? errorMessage;

  /// 重试次数
  final int retryCount;

  /// 构造函数
  SyncOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    this.entityData,
    required this.version,
    this.status = SyncStatus.pending,
    DateTime? createdAt,
    this.lastModified,
    this.lastSynced,
    this.conflictData,
    this.errorMessage,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      operationType: SyncOperationType.values[json['operationType'] as int],
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      entityData: json['entityData'] as Map<String, dynamic>?,
      version: json['version'] as int,
      status: SyncStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType.index,
      'entityType': entityType,
      'entityId': entityId,
      'entityData': entityData,
      'version': version,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'lastSynced': lastSynced?.toIso8601String(),
      'conflictData': conflictData,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  /// 创建带有更新的副本
  SyncOperation copyWith({
    String? id,
    SyncOperationType? operationType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? entityData,
    int? version,
    SyncStatus? status,
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? lastSynced,
    Map<String, dynamic>? conflictData,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityData: entityData ?? this.entityData,
      version: version ?? this.version,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastSynced: lastSynced ?? this.lastSynced,
      conflictData: conflictData ?? this.conflictData,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// 更新状态
  SyncOperation updateStatus(SyncStatus newStatus, {
    DateTime? lastModified,
    DateTime? lastSynced,
    Map<String, dynamic>? conflictData,
    String? errorMessage,
    int? retryCount,
  }) {
    return copyWith(
      status: newStatus,
      lastModified: lastModified ?? DateTime.now(),
      lastSynced: lastSynced,
      conflictData: conflictData,
      errorMessage: errorMessage,
      retryCount: retryCount,
    );
  }

  /// 标记为同步中
  SyncOperation markAsSyncing() {
    return updateStatus(SyncStatus.syncing);
  }

  /// 标记为已同步
  SyncOperation markAsSynced() {
    return updateStatus(
      SyncStatus.synced,
      lastSynced: DateTime.now(),
    );
  }

  /// 标记为同步失败
  SyncOperation markAsFailed(String error) {
    return updateStatus(
      SyncStatus.failed,
      errorMessage: error,
      retryCount: retryCount + 1,
    );
  }

  /// 标记为冲突
  SyncOperation markAsConflict(Map<String, dynamic> serverData) {
    return updateStatus(
      SyncStatus.conflict,
      conflictData: serverData,
    );
  }

  /// 重置状态
  SyncOperation resetStatus() {
    return updateStatus(SyncStatus.pending);
  }
}
