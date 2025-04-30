// 文件： lib/services/auto_sync_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 自动同步服务
///
/// 用于定期自动同步节日数据
class AutoSyncService {
  // 单例模式
  static final AutoSyncService _instance = AutoSyncService._internal();

  factory AutoSyncService() {
    return _instance;
  }

  AutoSyncService._internal();

  // 云同步服务
  final CloudSyncService _cloudSyncService = CloudSyncService();

  // 定时器
  Timer? _syncTimer;

  // 是否正在同步
  bool _isSyncing = false;

  // 同步状态监听器
  final List<Function(bool)> _syncStatusListeners = [];

  // 同步结果监听器
  final List<Function(SyncResult)> _syncResultListeners = [];

  /// 初始化自动同步服务
  Future<void> initialize() async {
    // 检查是否启用自动同步
    final isEnabled = await _cloudSyncService.isAutoSyncEnabled();

    if (isEnabled) {
      // 启动定时器
      await startAutoSync();
    }
  }

  /// 启动自动同步
  Future<void> startAutoSync() async {
    // 取消现有定时器
    _syncTimer?.cancel();

    // 获取同步频率（小时）
    final syncFrequency = await _cloudSyncService.getSyncFrequency();

    // 创建新定时器
    _syncTimer = Timer.periodic(
      Duration(hours: syncFrequency),
      (_) => _performAutoSync(),
    );

    debugPrint('自动同步已启动，频率: $syncFrequency 小时');
  }

  /// 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('自动同步已停止');
  }

  /// 执行自动同步
  Future<void> _performAutoSync() async {
    // 检查是否已登录
    if (!_cloudSyncService.isLoggedIn) {
      debugPrint('用户未登录，跳过自动同步');
      return;
    }

    // 检查是否正在同步
    if (_isSyncing) {
      debugPrint('正在进行同步，跳过本次自动同步');
      return;
    }

    // 检查上次同步时间
    final lastSyncTime = await _cloudSyncService.getLastSyncTime();
    if (lastSyncTime != null) {
      final now = DateTime.now();
      final lastSync = DateTime.parse(lastSyncTime);
      final syncFrequency = await _cloudSyncService.getSyncFrequency();

      // 如果距离上次同步时间不足同步频率的一半，则跳过本次同步
      if (now.difference(lastSync).inHours < syncFrequency ~/ 2) {
        debugPrint('距离上次同步时间不足，跳过本次自动同步');
        return;
      }
    }

    // 执行同步
    await performSync();
  }

  /// 执行同步
  Future<SyncResult> performSync() async {
    if (!_cloudSyncService.isLoggedIn) {
      return SyncResult(
        success: false,
        message: '用户未登录',
        uploadCount: 0,
        downloadCount: 0,
        conflictCount: 0,
      );
    }

    // 设置同步状态
    _isSyncing = true;
    _notifySyncStatusListeners(true);

    try {
      // 模拟同步过程
      await Future.delayed(const Duration(seconds: 2));

      // 保存最后同步时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastAutoSyncTime', DateTime.now().toIso8601String());

      final result = SyncResult(
        success: true,
        message: '同步成功',
        uploadCount: 3, // 模拟上传了3个节日
        downloadCount: 2, // 模拟下载了2个节日
        conflictCount: 0, // 模拟没有冲突
      );

      // 通知监听器
      _notifySyncResultListeners(result);

      return result;
    } catch (e) {
      debugPrint('同步失败: $e');

      final result = SyncResult(
        success: false,
        message: '同步失败: $e',
        uploadCount: 0,
        downloadCount: 0,
        conflictCount: 0,
      );

      // 通知监听器
      _notifySyncResultListeners(result);

      return result;
    } finally {
      // 重置同步状态
      _isSyncing = false;
      _notifySyncStatusListeners(false);
    }
  }

  /// 添加同步状态监听器
  void addSyncStatusListener(Function(bool) listener) {
    _syncStatusListeners.add(listener);
  }

  /// 移除同步状态监听器
  void removeSyncStatusListener(Function(bool) listener) {
    _syncStatusListeners.remove(listener);
  }

  /// 通知同步状态监听器
  void _notifySyncStatusListeners(bool isSyncing) {
    for (var listener in _syncStatusListeners) {
      listener(isSyncing);
    }
  }

  /// 添加同步结果监听器
  void addSyncResultListener(Function(SyncResult) listener) {
    _syncResultListeners.add(listener);
  }

  /// 移除同步结果监听器
  void removeSyncResultListener(Function(SyncResult) listener) {
    _syncResultListeners.remove(listener);
  }

  /// 通知同步结果监听器
  void _notifySyncResultListeners(SyncResult result) {
    for (var listener in _syncResultListeners) {
      listener(result);
    }
  }

  /// 获取上次自动同步时间
  Future<DateTime?> getLastAutoSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('lastAutoSyncTime');

    if (timeString == null) {
      return null;
    }

    try {
      return DateTime.parse(timeString);
    } catch (e) {
      debugPrint('解析上次自动同步时间失败: $e');
      return null;
    }
  }

  /// 是否正在同步
  bool get isSyncing => _isSyncing;
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final int uploadCount;
  final int downloadCount;
  final int conflictCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.uploadCount,
    required this.downloadCount,
    required this.conflictCount,
  });
}
