import 'package:jinlin_app/models/sync/sync_operation.dart';

/// 冲突解决结果
enum ConflictResolutionResult {
  /// 使用本地数据
  useLocal,

  /// 使用服务器数据
  useServer,

  /// 使用合并数据
  useMerged,

  /// 跳过
  skip,
}

/// 同步冲突
///
/// 表示同步过程中的冲突
class SyncConflict {
  /// 冲突ID
  final String id;

  /// 同步操作
  final SyncOperation operation;

  /// 本地数据
  final Map<String, dynamic> localData;

  /// 服务器数据
  final Map<String, dynamic> serverData;

  /// 合并数据
  final Map<String, dynamic>? mergedData;

  /// 是否已解决
  final bool isResolved;

  /// 解决结果
  final ConflictResolutionResult? resolutionResult;

  /// 创建时间
  final DateTime createdAt;

  /// 解决时间
  final DateTime? resolvedAt;

  /// 构造函数
  SyncConflict({
    required this.id,
    required this.operation,
    required this.localData,
    required this.serverData,
    this.mergedData,
    this.isResolved = false,
    this.resolutionResult,
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建
  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      operation: SyncOperation.fromJson(json['operation'] as Map<String, dynamic>),
      localData: json['localData'] as Map<String, dynamic>,
      serverData: json['serverData'] as Map<String, dynamic>,
      mergedData: json['mergedData'] as Map<String, dynamic>?,
      isResolved: json['isResolved'] as bool? ?? false,
      resolutionResult: json['resolutionResult'] != null
          ? ConflictResolutionResult.values[json['resolutionResult'] as int]
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.toJson(),
      'localData': localData,
      'serverData': serverData,
      'mergedData': mergedData,
      'isResolved': isResolved,
      'resolutionResult': resolutionResult?.index,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  /// 创建带有更新的副本
  SyncConflict copyWith({
    String? id,
    SyncOperation? operation,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? serverData,
    Map<String, dynamic>? mergedData,
    bool? isResolved,
    ConflictResolutionResult? resolutionResult,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      localData: localData ?? this.localData,
      serverData: serverData ?? this.serverData,
      mergedData: mergedData ?? this.mergedData,
      isResolved: isResolved ?? this.isResolved,
      resolutionResult: resolutionResult ?? this.resolutionResult,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// 解决冲突，使用本地数据
  SyncConflict resolveUseLocal() {
    return copyWith(
      isResolved: true,
      resolutionResult: ConflictResolutionResult.useLocal,
      resolvedAt: DateTime.now(),
    );
  }

  /// 解决冲突，使用服务器数据
  SyncConflict resolveUseServer() {
    return copyWith(
      isResolved: true,
      resolutionResult: ConflictResolutionResult.useServer,
      resolvedAt: DateTime.now(),
    );
  }

  /// 解决冲突，使用合并数据
  SyncConflict resolveUseMerged(Map<String, dynamic> mergedData) {
    return copyWith(
      isResolved: true,
      resolutionResult: ConflictResolutionResult.useMerged,
      mergedData: mergedData,
      resolvedAt: DateTime.now(),
    );
  }

  /// 解决冲突，跳过
  SyncConflict resolveSkip() {
    return copyWith(
      isResolved: true,
      resolutionResult: ConflictResolutionResult.skip,
      resolvedAt: DateTime.now(),
    );
  }

  /// 获取解决后的数据
  Map<String, dynamic>? getResolvedData() {
    if (!isResolved) {
      return null;
    }

    switch (resolutionResult) {
      case ConflictResolutionResult.useLocal:
        return localData;
      case ConflictResolutionResult.useServer:
        return serverData;
      case ConflictResolutionResult.useMerged:
        return mergedData;
      case ConflictResolutionResult.skip:
        return null;
      default:
        return null;
    }
  }
}
