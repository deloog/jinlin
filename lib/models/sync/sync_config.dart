// 注意：这个文件原本使用了json_annotation库，但该库尚未添加到依赖中
// 暂时使用手动实现的JSON序列化方法

/// 同步冲突解决策略
enum ConflictResolutionStrategy {
  /// 使用本地数据
  useLocal,

  /// 使用服务器数据
  useServer,

  /// 合并数据
  merge,

  /// 手动解决
  manual,
}

/// 同步配置
///
/// 表示同步的配置信息
class SyncConfig {
  /// 是否启用自动同步
  final bool enableAutoSync;

  /// 自动同步间隔（分钟）
  final int autoSyncIntervalMinutes;

  /// 是否仅在WiFi下同步
  final bool syncOnlyOnWifi;

  /// 是否仅在充电时同步
  final bool syncOnCharging;

  /// 最大同步批次大小
  final int maxSyncBatchSize;

  /// 是否启用增量同步
  final bool enableIncrementalSync;

  /// 冲突解决策略
  final ConflictResolutionStrategy conflictResolutionStrategy;

  /// 最大批次大小
  final int maxBatchSize;

  /// 最大重试次数
  final int maxRetryCount;

  /// 重试延迟（秒）
  final int retryDelaySeconds;

  /// 是否启用压缩
  final bool enableCompression;

  /// 是否启用加密
  final bool enableEncryption;

  /// 是否同步删除的数据
  final bool syncDeletedData;

  /// 构造函数
  SyncConfig({
    this.enableAutoSync = true,
    this.autoSyncIntervalMinutes = 60,
    this.syncOnlyOnWifi = true,
    this.syncOnCharging = false,
    this.maxSyncBatchSize = 50,
    this.enableIncrementalSync = true,
    this.conflictResolutionStrategy = ConflictResolutionStrategy.manual,
    this.maxBatchSize = 50,
    this.maxRetryCount = 3,
    this.retryDelaySeconds = 30,
    this.enableCompression = true,
    this.enableEncryption = true,
    this.syncDeletedData = true,
  });

  /// 从JSON创建
  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      enableAutoSync: json['enableAutoSync'] as bool? ?? true,
      autoSyncIntervalMinutes: json['autoSyncIntervalMinutes'] as int? ?? 60,
      syncOnlyOnWifi: json['syncOnlyOnWifi'] as bool? ?? true,
      syncOnCharging: json['syncOnCharging'] as bool? ?? false,
      maxSyncBatchSize: json['maxSyncBatchSize'] as int? ?? 50,
      enableIncrementalSync: json['enableIncrementalSync'] as bool? ?? true,
      conflictResolutionStrategy: ConflictResolutionStrategy.values.firstWhere(
        (e) => e.toString() == json['conflictResolutionStrategy'],
        orElse: () => ConflictResolutionStrategy.manual,
      ),
      maxBatchSize: json['maxBatchSize'] as int? ?? 50,
      maxRetryCount: json['maxRetryCount'] as int? ?? 3,
      retryDelaySeconds: json['retryDelaySeconds'] as int? ?? 30,
      enableCompression: json['enableCompression'] as bool? ?? true,
      enableEncryption: json['enableEncryption'] as bool? ?? true,
      syncDeletedData: json['syncDeletedData'] as bool? ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enableAutoSync': enableAutoSync,
      'autoSyncIntervalMinutes': autoSyncIntervalMinutes,
      'syncOnlyOnWifi': syncOnlyOnWifi,
      'syncOnCharging': syncOnCharging,
      'maxSyncBatchSize': maxSyncBatchSize,
      'enableIncrementalSync': enableIncrementalSync,
      'conflictResolutionStrategy': conflictResolutionStrategy.toString(),
      'maxBatchSize': maxBatchSize,
      'maxRetryCount': maxRetryCount,
      'retryDelaySeconds': retryDelaySeconds,
      'enableCompression': enableCompression,
      'enableEncryption': enableEncryption,
      'syncDeletedData': syncDeletedData,
    };
  }

  /// 创建带有更新的副本
  SyncConfig copyWith({
    bool? enableAutoSync,
    int? autoSyncIntervalMinutes,
    bool? syncOnlyOnWifi,
    bool? syncOnCharging,
    int? maxSyncBatchSize,
    bool? enableIncrementalSync,
    ConflictResolutionStrategy? conflictResolutionStrategy,
    int? maxBatchSize,
    int? maxRetryCount,
    int? retryDelaySeconds,
    bool? enableCompression,
    bool? enableEncryption,
    bool? syncDeletedData,
  }) {
    return SyncConfig(
      enableAutoSync: enableAutoSync ?? this.enableAutoSync,
      autoSyncIntervalMinutes: autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
      syncOnlyOnWifi: syncOnlyOnWifi ?? this.syncOnlyOnWifi,
      syncOnCharging: syncOnCharging ?? this.syncOnCharging,
      maxSyncBatchSize: maxSyncBatchSize ?? this.maxSyncBatchSize,
      enableIncrementalSync: enableIncrementalSync ?? this.enableIncrementalSync,
      conflictResolutionStrategy: conflictResolutionStrategy ?? this.conflictResolutionStrategy,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      retryDelaySeconds: retryDelaySeconds ?? this.retryDelaySeconds,
      enableCompression: enableCompression ?? this.enableCompression,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      syncDeletedData: syncDeletedData ?? this.syncDeletedData,
    );
  }
}
