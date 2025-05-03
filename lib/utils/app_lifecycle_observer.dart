import 'package:flutter/material.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 应用生命周期观察者
///
/// 监听应用生命周期变化，并通过事件总线通知其他组件
class AppLifecycleObserver extends WidgetsBindingObserver {
  final LoggingService _logger = LoggingService();
  
  // 上一个生命周期状态
  AppLifecycleState? _previousState;
  
  AppLifecycleObserver() {
    _logger.debug('初始化应用生命周期观察者');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.info('应用生命周期状态变化: $_previousState -> $state');
    
    // 发布生命周期变化事件
    eventBus.fire(AppLifecycleChangedEvent(state));
    
    // 根据状态变化执行特定操作
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.inactive:
        _onInactive();
        break;
      case AppLifecycleState.paused:
        _onPaused();
        break;
      case AppLifecycleState.detached:
        _onDetached();
        break;
      case AppLifecycleState.hidden:
        _onHidden();
        break;
    }
    
    _previousState = state;
  }
  
  /// 应用从后台恢复到前台时调用
  void _onResumed() {
    _logger.debug('应用恢复到前台');
    
    // 这里可以添加应用恢复到前台时需要执行的操作
    // 例如：刷新数据、恢复动画等
  }
  
  /// 应用处于非活动状态时调用（例如：接听电话）
  void _onInactive() {
    _logger.debug('应用进入非活动状态');
    
    // 这里可以添加应用进入非活动状态时需要执行的操作
    // 例如：暂停动画、暂停音频等
  }
  
  /// 应用进入后台时调用
  void _onPaused() {
    _logger.debug('应用进入后台');
    
    // 这里可以添加应用进入后台时需要执行的操作
    // 例如：保存状态、停止网络请求等
  }
  
  /// 应用被终止时调用
  void _onDetached() {
    _logger.debug('应用被终止');
    
    // 这里可以添加应用被终止时需要执行的操作
    // 例如：保存重要数据、清理资源等
  }
  
  /// 应用被隐藏时调用（例如：多窗口模式下被其他窗口覆盖）
  void _onHidden() {
    _logger.debug('应用被隐藏');
    
    // 这里可以添加应用被隐藏时需要执行的操作
    // 例如：暂停更新、减少资源使用等
  }
}
