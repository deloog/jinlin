/// 软删除接口
///
/// 定义软删除相关的属性和方法
abstract class SoftDeletable {
  /// 是否已删除
  bool get isDeleted;
  
  /// 删除时间
  DateTime? get deletedAt;
  
  /// 删除原因
  String? get deletionReason;
}
