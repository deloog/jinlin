// 文件: lib/models/sync/sync_operation_type.dart

/// 同步操作类型
enum SyncOperationType {
  /// 创建操作
  create,
  
  /// 更新操作
  update,
  
  /// 删除操作
  delete,
  
  /// 软删除操作
  softDelete,
  
  /// 恢复操作
  restore,
}
