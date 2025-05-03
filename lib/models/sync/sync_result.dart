import 'package:jinlin_app/models/sync/sync_conflict.dart';

/// 同步结果
///
/// 表示同步操作的结果
class SyncResult {
  /// 是否成功
  final bool success;
  
  /// 错误消息
  final String? errorMessage;
  
  /// 上传的数据数量
  final int uploadedCount;
  
  /// 下载的数据数量
  final int downloadedCount;
  
  /// 冲突数量
  final int conflictCount;
  
  /// 冲突列表
  final List<SyncConflict>? conflicts;
  
  /// 同步时间
  final DateTime syncTime;
  
  /// 构造函数
  SyncResult({
    required this.success,
    this.errorMessage,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.conflictCount = 0,
    this.conflicts,
    DateTime? syncTime,
  }) : syncTime = syncTime ?? DateTime.now();
  
  /// 创建成功结果
  factory SyncResult.success({
    int uploadedCount = 0,
    int downloadedCount = 0,
    int conflictCount = 0,
    List<SyncConflict>? conflicts,
    DateTime? syncTime,
  }) {
    return SyncResult(
      success: true,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: conflictCount,
      conflicts: conflicts,
      syncTime: syncTime,
    );
  }
  
  /// 创建失败结果
  factory SyncResult.failure({
    required String errorMessage,
    int uploadedCount = 0,
    int downloadedCount = 0,
    int conflictCount = 0,
    List<SyncConflict>? conflicts,
    DateTime? syncTime,
  }) {
    return SyncResult(
      success: false,
      errorMessage: errorMessage,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: conflictCount,
      conflicts: conflicts,
      syncTime: syncTime,
    );
  }
  
  /// 创建冲突结果
  factory SyncResult.conflict({
    required List<SyncConflict> conflicts,
    int uploadedCount = 0,
    int downloadedCount = 0,
    DateTime? syncTime,
  }) {
    return SyncResult(
      success: false,
      errorMessage: '同步冲突',
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: conflicts.length,
      conflicts: conflicts,
      syncTime: syncTime,
    );
  }
  
  /// 合并结果
  SyncResult merge(SyncResult other) {
    return SyncResult(
      success: success && other.success,
      errorMessage: errorMessage ?? other.errorMessage,
      uploadedCount: uploadedCount + other.uploadedCount,
      downloadedCount: downloadedCount + other.downloadedCount,
      conflictCount: conflictCount + other.conflictCount,
      conflicts: [
        ...?conflicts,
        ...?other.conflicts,
      ],
      syncTime: other.syncTime.isAfter(syncTime) ? other.syncTime : syncTime,
    );
  }
  
  @override
  String toString() {
    return 'SyncResult{'
        'success: $success, '
        'errorMessage: $errorMessage, '
        'uploadedCount: $uploadedCount, '
        'downloadedCount: $downloadedCount, '
        'conflictCount: $conflictCount, '
        'syncTime: $syncTime'
        '}';
  }
}
