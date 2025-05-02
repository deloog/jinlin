// 文件: lib/models/sync/sync_status_enum.dart

/// 同步状态枚举
enum SyncStatus {
  /// 等待同步
  pending,
  
  /// 同步中
  syncing,
  
  /// 同步完成
  synced,
  
  /// 同步失败
  failed,
  
  /// 同步冲突
  conflict,
}
