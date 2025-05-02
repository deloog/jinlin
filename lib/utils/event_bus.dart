// 文件: lib/utils/event_bus.dart
import 'dart:async';

/// 事件总线
/// 
/// 用于在不同组件之间传递事件，实现解耦通信
class EventBus {
  // 单例模式
  static final EventBus _instance = EventBus._internal();
  static EventBus get instance => _instance;
  EventBus._internal();
  
  // 事件流控制器
  final StreamController _streamController = StreamController.broadcast();
  
  /// 发送事件
  void fire(event) {
    _streamController.add(event);
  }
  
  /// 监听事件
  Stream get on => _streamController.stream;
  
  /// 关闭事件总线
  void dispose() {
    _streamController.close();
  }
}

/// 刷新时间线事件
/// 
/// 用于通知首页刷新时间线
class RefreshTimelineEvent {
  final String? holidayId;
  
  RefreshTimelineEvent([this.holidayId]);
}
