import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 网络服务
///
/// 监控网络连接状态，并通过事件总线通知其他组件
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final LoggingService _logger = LoggingService();

  // 网络连接状态
  bool _isConnected = false;

  // 网络连接类型
  ConnectivityResult _connectionType = ConnectivityResult.none;

  // 状态监听器
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// 获取是否已连接网络
  bool get isConnected => _isConnected;

  /// 获取网络连接类型
  ConnectivityResult get connectionType => _connectionType;

  /// 初始化网络服务
  Future<void> initialize() async {
    _logger.debug('初始化网络服务');

    // 获取初始网络状态
    await _checkConnectivity();

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _logger.debug('网络服务初始化完成，当前状态: $_connectionType');
  }

  /// 检查网络连接
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e, stack) {
      _logger.error('检查网络连接失败', e, stack);
      _isConnected = false;
      _connectionType = ConnectivityResult.none;
    }
  }

  /// 更新连接状态
  void _updateConnectionStatus(ConnectivityResult result) {
    final bool wasConnected = _isConnected;

    // 更新连接类型
    _connectionType = result;

    // 更新连接状态
    _isConnected = result != ConnectivityResult.none;

    // 记录状态变化
    _logger.debug('网络连接状态变化: $result, 已连接: $_isConnected');

    // 如果连接状态发生变化，发送事件
    if (wasConnected != _isConnected) {
      eventBus.fire(NetworkStatusChangedEvent(_isConnected));

      if (_isConnected) {
        _logger.info('网络已连接: $result');
      } else {
        _logger.warning('网络已断开');
      }
    }
  }

  /// 获取连接类型描述
  String getConnectionTypeDescription() {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return '移动数据';
      case ConnectivityResult.ethernet:
        return '以太网';
      case ConnectivityResult.bluetooth:
        return '蓝牙';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return '其他';
      case ConnectivityResult.none:
        return '无网络';
    }
  }

  /// 销毁网络服务
  void dispose() {
    _logger.debug('销毁网络服务');
    _connectivitySubscription?.cancel();
  }
}
