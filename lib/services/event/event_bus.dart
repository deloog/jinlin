import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 事件总线
///
/// 提供组件间通信的事件机制，基于发布-订阅模式
class EventBus {
  static final EventBus _instance = EventBus._internal();
  
  factory EventBus() {
    return _instance;
  }
  
  EventBus._internal() {
    _logger.debug('事件总线初始化');
  }
  
  final LoggingService _logger = LoggingService();
  final StreamController _streamController = StreamController.broadcast();
  
  /// 发布事件
  void fire(dynamic event) {
    _logger.debug('发布事件: ${event.runtimeType}');
    _streamController.add(event);
  }
  
  /// 订阅特定类型的事件
  Stream<T> on<T>() {
    _logger.debug('订阅事件: $T');
    return _streamController.stream
        .where((event) => event is T)
        .cast<T>();
  }
  
  /// 销毁事件总线
  void dispose() {
    _logger.debug('销毁事件总线');
    _streamController.close();
  }
}

/// 全局事件总线实例
final eventBus = EventBus();

// 以下是预定义的事件类型

/// 节日数据更新事件
class HolidayDataUpdatedEvent {
  final String regionCode;
  final int itemCount;
  
  HolidayDataUpdatedEvent(this.regionCode, this.itemCount);
  
  @override
  String toString() => 'HolidayDataUpdatedEvent(regionCode: $regionCode, itemCount: $itemCount)';
}

/// 提醒事项更新事件
class ReminderUpdatedEvent {
  final String? reminderId;
  
  ReminderUpdatedEvent({this.reminderId});
  
  @override
  String toString() => 'ReminderUpdatedEvent(reminderId: $reminderId)';
}

/// 设置更新事件
class SettingsUpdatedEvent {
  final String key;
  final dynamic value;
  
  SettingsUpdatedEvent(this.key, this.value);
  
  @override
  String toString() => 'SettingsUpdatedEvent(key: $key, value: $value)';
}

/// 同步完成事件
class SyncCompletedEvent {
  final bool success;
  final String message;
  
  SyncCompletedEvent(this.success, this.message);
  
  @override
  String toString() => 'SyncCompletedEvent(success: $success, message: $message)';
}

/// 主题变更事件
class ThemeChangedEvent {
  final ThemeMode themeMode;
  
  ThemeChangedEvent(this.themeMode);
  
  @override
  String toString() => 'ThemeChangedEvent(themeMode: $themeMode)';
}

/// 语言变更事件
class LanguageChangedEvent {
  final String languageCode;
  
  LanguageChangedEvent(this.languageCode);
  
  @override
  String toString() => 'LanguageChangedEvent(languageCode: $languageCode)';
}

/// 刷新时间线事件
class RefreshTimelineEvent {
  RefreshTimelineEvent();
  
  @override
  String toString() => 'RefreshTimelineEvent()';
}

/// 网络状态变更事件
class NetworkStatusChangedEvent {
  final bool isConnected;
  
  NetworkStatusChangedEvent(this.isConnected);
  
  @override
  String toString() => 'NetworkStatusChangedEvent(isConnected: $isConnected)';
}

/// 应用生命周期变更事件
class AppLifecycleChangedEvent {
  final AppLifecycleState state;
  
  AppLifecycleChangedEvent(this.state);
  
  @override
  String toString() => 'AppLifecycleChangedEvent(state: $state)';
}
