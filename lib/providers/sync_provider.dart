import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_config.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/models/sync/sync_operation_type.dart';
import 'package:jinlin_app/models/sync/sync_status.dart' as status_model;
import 'package:jinlin_app/services/sync/sync_service_interface.dart';

/// 同步提供者
///
/// 提供对同步服务的访问，并在应用启动时初始化同步服务
class SyncProvider extends ChangeNotifier implements SyncListener {
  // 同步服务
  final SyncServiceInterface _syncService;

  // 同步状态
  status_model.SyncStatus _status = status_model.SyncStatus();

  // 同步配置
  SyncConfig _config = SyncConfig();

  // 同步冲突
  final List<SyncConflict> _conflicts = [];

  // 同步批次
  final List<SyncBatch> _batches = [];

  // 同步操作
  final List<SyncOperation> _operations = [];

  /// 构造函数
  SyncProvider(this._syncService) {
    // 添加同步监听器
    _syncService.addSyncListener(this);

    // 初始化
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    try {
      // 初始化同步服务
      await _syncService.initialize();

      // 加载同步状态
      _status = await _syncService.getSyncStatus();

      // 加载同步配置
      _config = await _syncService.getSyncConfig();

      // 加载同步冲突
      _conflicts.clear();
      _conflicts.addAll(await _syncService.getSyncConflicts());

      // 加载同步批次
      _batches.clear();
      _batches.addAll(await _syncService.getSyncBatches());

      // 加载同步操作
      _operations.clear();
      _operations.addAll(await _syncService.getSyncOperations());

      // 通知监听器
      notifyListeners();
    } catch (e) {
      debugPrint('初始化同步提供者失败: $e');
    }
  }

  @override
  void dispose() {
    // 移除同步监听器
    _syncService.removeSyncListener(this);
    super.dispose();
  }

  /// 获取同步状态
  status_model.SyncStatus get status => _status;

  /// 获取同步配置
  SyncConfig get config => _config;

  /// 获取同步冲突
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);

  /// 获取同步批次
  List<SyncBatch> get batches => List.unmodifiable(_batches);

  /// 获取同步操作
  List<SyncOperation> get operations => List.unmodifiable(_operations);

  /// 是否正在同步
  bool get isSyncing => _status.isSyncing;

  /// 同步进度
  double get syncProgress => _status.syncProgress;

  /// 最后同步时间
  DateTime? get lastSyncTime => _status.lastSyncTime;

  /// 最后同步错误
  String? get lastSyncError => _status.lastSyncError;

  /// 待同步操作数
  int get pendingOperationsCount => _status.pendingOperationsCount;

  /// 同步中操作数
  int get syncingOperationsCount => _status.syncingOperationsCount;

  /// 已同步操作数
  int get syncedOperationsCount => _status.syncedOperationsCount;

  /// 同步失败操作数
  int get failedOperationsCount => _status.failedOperationsCount;

  /// 冲突操作数
  int get conflictOperationsCount => _status.conflictOperationsCount;

  /// 是否有待处理的操作
  bool get hasPendingOperations => _status.hasPendingOperations();

  /// 是否有同步失败的操作
  bool get hasFailedOperations => _status.hasFailedOperations();

  /// 是否有冲突的操作
  bool get hasConflictOperations => _status.hasConflictOperations();

  /// 是否启用自动同步
  bool get isAutoSyncEnabled => _config.enableAutoSync;

  /// 开始同步
  Future<void> startSync() async {
    try {
      await _syncService.startSync();
    } catch (e) {
      debugPrint('开始同步失败: $e');
      rethrow;
    }
  }

  /// 取消同步
  Future<void> cancelSync() async {
    try {
      await _syncService.cancelSync();
    } catch (e) {
      debugPrint('取消同步失败: $e');
      rethrow;
    }
  }

  /// 重试失败的同步操作
  Future<void> retryFailedOperations() async {
    try {
      await _syncService.retryFailedOperations();
    } catch (e) {
      debugPrint('重试失败的同步操作失败: $e');
      rethrow;
    }
  }

  /// 清除所有同步数据
  Future<void> clearAllSyncData() async {
    try {
      await _syncService.clearAllSyncData();
    } catch (e) {
      debugPrint('清除所有同步数据失败: $e');
      rethrow;
    }
  }

  /// 启用自动同步
  Future<void> enableAutoSync() async {
    try {
      await _syncService.enableAutoSync();
      _config = await _syncService.getSyncConfig();
      notifyListeners();
    } catch (e) {
      debugPrint('启用自动同步失败: $e');
      rethrow;
    }
  }

  /// 禁用自动同步
  Future<void> disableAutoSync() async {
    try {
      await _syncService.disableAutoSync();
      _config = await _syncService.getSyncConfig();
      notifyListeners();
    } catch (e) {
      debugPrint('禁用自动同步失败: $e');
      rethrow;
    }
  }

  /// 更新同步配置
  Future<void> updateSyncConfig(SyncConfig config) async {
    try {
      await _syncService.updateSyncConfig(config);
      _config = await _syncService.getSyncConfig();
      notifyListeners();
    } catch (e) {
      debugPrint('更新同步配置失败: $e');
      rethrow;
    }
  }

  /// 解决同步冲突
  Future<void> resolveSyncConflict(
    String conflictId,
    ConflictResolutionResult resolutionResult, {
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      await _syncService.resolveSyncConflict(
        conflictId,
        resolutionResult,
        mergedData: mergedData,
      );

      // 更新冲突列表
      _conflicts.clear();
      _conflicts.addAll(await _syncService.getSyncConflicts());

      // 通知监听器
      notifyListeners();
    } catch (e) {
      debugPrint('解决同步冲突失败: $e');
      rethrow;
    }
  }

  /// 创建同步操作
  Future<SyncOperation> createSyncOperation(
    SyncOperationType operationType,
    String entityType,
    String entityId,
    Map<String, dynamic>? entityData,
  ) async {
    try {
      final operation = await _syncService.createSyncOperation(
        operationType,
        entityType,
        entityId,
        entityData,
      );

      // 更新操作列表
      _operations.clear();
      _operations.addAll(await _syncService.getSyncOperations());

      // 通知监听器
      notifyListeners();

      return operation;
    } catch (e) {
      debugPrint('创建同步操作失败: $e');
      rethrow;
    }
  }

  /// 删除同步操作
  Future<void> deleteSyncOperation(String operationId) async {
    try {
      await _syncService.deleteSyncOperation(operationId);

      // 更新操作列表
      _operations.clear();
      _operations.addAll(await _syncService.getSyncOperations());

      // 通知监听器
      notifyListeners();
    } catch (e) {
      debugPrint('删除同步操作失败: $e');
      rethrow;
    }
  }

  // ==================== 同步监听器回调 ====================

  @override
  void onSyncStarted() {
    notifyListeners();
  }

  @override
  void onSyncCompleted() {
    notifyListeners();
  }

  @override
  void onSyncFailed(String error) {
    notifyListeners();
  }

  @override
  void onSyncProgressUpdated(double progress) {
    notifyListeners();
  }

  @override
  void onSyncStatusUpdated(status_model.SyncStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void onSyncConflict(SyncConflict conflict) {
    // 添加冲突
    final index = _conflicts.indexWhere((c) => c.id == conflict.id);
    if (index >= 0) {
      _conflicts[index] = conflict;
    } else {
      _conflicts.add(conflict);
    }

    notifyListeners();
  }

  @override
  void onSyncOperationUpdated(SyncOperation operation) {
    // 更新操作
    final index = _operations.indexWhere((op) => op.id == operation.id);
    if (index >= 0) {
      _operations[index] = operation;
    } else {
      _operations.add(operation);
    }

    notifyListeners();
  }

  @override
  void onSyncBatchUpdated(SyncBatch batch) {
    // 更新批次
    final index = _batches.indexWhere((b) => b.id == batch.id);
    if (index >= 0) {
      _batches[index] = batch;
    } else {
      _batches.add(batch);
    }

    notifyListeners();
  }

  /// 创建同步提供者
  static ChangeNotifierProvider<SyncProvider> create(SyncServiceInterface syncService) {
    return ChangeNotifierProvider<SyncProvider>(
      create: (_) => SyncProvider(syncService),
    );
  }

  /// 获取同步提供者
  static SyncProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<SyncProvider>(context, listen: listen);
  }
}
