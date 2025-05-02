// 注意：这个文件原本使用了json_annotation库，但该库尚未添加到依赖中
// 暂时使用手动实现的JSON序列化方法

/// 同步状态
///
/// 表示同步的状态信息
class SyncStatus {
  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 是否正在同步
  final bool isSyncing;

  /// 同步进度（0-1）
  final double syncProgress;

  /// 待同步操作数
  final int pendingOperationsCount;

  /// 同步中操作数
  final int syncingOperationsCount;

  /// 已同步操作数
  final int syncedOperationsCount;

  /// 同步失败操作数
  final int failedOperationsCount;

  /// 冲突操作数
  final int conflictOperationsCount;

  /// 最后同步错误
  final String? lastSyncError;

  /// 构造函数
  SyncStatus({
    this.lastSyncTime,
    this.isSyncing = false,
    this.syncProgress = 0.0,
    this.pendingOperationsCount = 0,
    this.syncingOperationsCount = 0,
    this.syncedOperationsCount = 0,
    this.failedOperationsCount = 0,
    this.conflictOperationsCount = 0,
    this.lastSyncError,
  });

  /// 从JSON创建
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      isSyncing: json['isSyncing'] as bool? ?? false,
      syncProgress: (json['syncProgress'] as num?)?.toDouble() ?? 0.0,
      pendingOperationsCount: json['pendingOperationsCount'] as int? ?? 0,
      syncingOperationsCount: json['syncingOperationsCount'] as int? ?? 0,
      syncedOperationsCount: json['syncedOperationsCount'] as int? ?? 0,
      failedOperationsCount: json['failedOperationsCount'] as int? ?? 0,
      conflictOperationsCount: json['conflictOperationsCount'] as int? ?? 0,
      lastSyncError: json['lastSyncError'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'isSyncing': isSyncing,
      'syncProgress': syncProgress,
      'pendingOperationsCount': pendingOperationsCount,
      'syncingOperationsCount': syncingOperationsCount,
      'syncedOperationsCount': syncedOperationsCount,
      'failedOperationsCount': failedOperationsCount,
      'conflictOperationsCount': conflictOperationsCount,
      'lastSyncError': lastSyncError,
    };
  }

  /// 创建带有更新的副本
  SyncStatus copyWith({
    DateTime? lastSyncTime,
    bool? isSyncing,
    double? syncProgress,
    int? pendingOperationsCount,
    int? syncingOperationsCount,
    int? syncedOperationsCount,
    int? failedOperationsCount,
    int? conflictOperationsCount,
    String? lastSyncError,
  }) {
    return SyncStatus(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      syncProgress: syncProgress ?? this.syncProgress,
      pendingOperationsCount: pendingOperationsCount ?? this.pendingOperationsCount,
      syncingOperationsCount: syncingOperationsCount ?? this.syncingOperationsCount,
      syncedOperationsCount: syncedOperationsCount ?? this.syncedOperationsCount,
      failedOperationsCount: failedOperationsCount ?? this.failedOperationsCount,
      conflictOperationsCount: conflictOperationsCount ?? this.conflictOperationsCount,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }

  /// 标记为同步开始
  SyncStatus markAsSyncStarted() {
    return copyWith(
      isSyncing: true,
      syncProgress: 0.0,
    );
  }

  /// 标记为同步完成
  SyncStatus markAsSyncCompleted() {
    return copyWith(
      lastSyncTime: DateTime.now(),
      isSyncing: false,
      syncProgress: 1.0,
    );
  }

  /// 标记为同步失败
  SyncStatus markAsSyncFailed(String error) {
    return copyWith(
      isSyncing: false,
      lastSyncError: error,
    );
  }

  /// 更新同步进度
  SyncStatus updateSyncProgress(double progress) {
    return copyWith(
      syncProgress: progress,
    );
  }

  /// 更新操作计数
  SyncStatus updateOperationCounts({
    int? pendingOperationsCount,
    int? syncingOperationsCount,
    int? syncedOperationsCount,
    int? failedOperationsCount,
    int? conflictOperationsCount,
  }) {
    return copyWith(
      pendingOperationsCount: pendingOperationsCount,
      syncingOperationsCount: syncingOperationsCount,
      syncedOperationsCount: syncedOperationsCount,
      failedOperationsCount: failedOperationsCount,
      conflictOperationsCount: conflictOperationsCount,
    );
  }

  /// 是否有待处理的操作
  bool hasPendingOperations() {
    return pendingOperationsCount > 0;
  }

  /// 是否有同步失败的操作
  bool hasFailedOperations() {
    return failedOperationsCount > 0;
  }

  /// 是否有冲突的操作
  bool hasConflictOperations() {
    return conflictOperationsCount > 0;
  }

  /// 获取总操作数
  int getTotalOperationsCount() {
    return pendingOperationsCount +
        syncingOperationsCount +
        syncedOperationsCount +
        failedOperationsCount +
        conflictOperationsCount;
  }
}
