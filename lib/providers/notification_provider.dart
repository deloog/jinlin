import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/notification/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通知提供者
///
/// 管理应用程序的通知设置和状态
class NotificationProvider extends ChangeNotifier {
  // 通知服务
  final NotificationService _notificationService;
  
  // 日志服务
  final LoggingService _logger = LoggingService();
  
  // 是否启用通知
  bool _enableNotifications = true;
  
  // 提醒事项通知提前时间（分钟）
  int _reminderNotificationAdvance = 30;
  
  // 节日通知提前时间（天）
  int _holidayNotificationAdvance = 1;
  
  // 是否启用振动
  bool _enableVibration = true;
  
  // 是否启用声音
  bool _enableSound = true;
  
  /// 构造函数
  NotificationProvider({
    required NotificationService notificationService,
  }) : _notificationService = notificationService {
    _logger.debug('初始化通知提供者');
    
    // 加载通知设置
    _loadNotificationSettings();
    
    // 初始化通知服务
    _initializeNotificationService();
  }
  
  /// 获取是否启用通知
  bool get enableNotifications => _enableNotifications;
  
  /// 获取提醒事项通知提前时间
  int get reminderNotificationAdvance => _reminderNotificationAdvance;
  
  /// 获取节日通知提前时间
  int get holidayNotificationAdvance => _holidayNotificationAdvance;
  
  /// 获取是否启用振动
  bool get enableVibration => _enableVibration;
  
  /// 获取是否启用声音
  bool get enableSound => _enableSound;
  
  /// 设置是否启用通知
  Future<void> setEnableNotifications(bool enable) async {
    if (_enableNotifications == enable) return;
    
    _enableNotifications = enable;
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
    
    // 如果禁用通知，取消所有通知
    if (!enable) {
      await _notificationService.cancelAllNotifications();
    }
  }
  
  /// 设置提醒事项通知提前时间
  Future<void> setReminderNotificationAdvance(int minutes) async {
    if (_reminderNotificationAdvance == minutes) return;
    
    _reminderNotificationAdvance = minutes;
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
  }
  
  /// 设置节日通知提前时间
  Future<void> setHolidayNotificationAdvance(int days) async {
    if (_holidayNotificationAdvance == days) return;
    
    _holidayNotificationAdvance = days;
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
  }
  
  /// 设置是否启用振动
  Future<void> setEnableVibration(bool enable) async {
    if (_enableVibration == enable) return;
    
    _enableVibration = enable;
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
  }
  
  /// 设置是否启用声音
  Future<void> setEnableSound(bool enable) async {
    if (_enableSound == enable) return;
    
    _enableSound = enable;
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
  }
  
  /// 检查通知权限
  Future<bool> checkNotificationPermission() async {
    return await _notificationService.checkPermission();
  }
  
  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    return await _notificationService.requestPermission();
  }
  
  /// 调度提醒事项通知
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_enableNotifications) return;
    
    await _notificationService.scheduleReminderNotification(reminder);
  }
  
  /// 调度节日通知
  Future<void> scheduleHolidayNotification(Holiday holiday, DateTime occurrenceDate) async {
    if (!_enableNotifications) return;
    
    await _notificationService.scheduleHolidayNotification(holiday, occurrenceDate);
  }
  
  /// 取消提醒事项通知
  Future<void> cancelReminderNotification(String reminderId) async {
    await _notificationService.cancelReminderNotification(reminderId);
  }
  
  /// 取消节日通知
  Future<void> cancelHolidayNotification(String holidayId) async {
    await _notificationService.cancelHolidayNotification(holidayId);
  }
  
  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
  
  /// 显示即时通知
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_enableNotifications) return;
    
    await _notificationService.showInstantNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
  
  /// 重置通知设置
  Future<void> resetNotificationSettings() async {
    _enableNotifications = true;
    _reminderNotificationAdvance = 30;
    _holidayNotificationAdvance = 1;
    _enableVibration = true;
    _enableSound = true;
    
    notifyListeners();
    
    // 保存通知设置
    await _saveNotificationSettings();
  }
  
  /// 初始化通知服务
  Future<void> _initializeNotificationService() async {
    try {
      await _notificationService.initialize();
      
      // 添加通知点击监听器
      _notificationService.addNotificationClickListener(_handleNotificationClick);
      
      _logger.debug('通知服务初始化完成');
    } catch (e, stack) {
      _logger.error('通知服务初始化失败', e, stack);
    }
  }
  
  /// 处理通知点击
  void _handleNotificationClick(String? payload) {
    _logger.debug('处理通知点击: $payload');
    
    // TODO: 处理通知点击
  }
  
  /// 加载通知设置
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载是否启用通知
      final enableNotifications = prefs.getBool('enable_notifications');
      if (enableNotifications != null) {
        _enableNotifications = enableNotifications;
      }
      
      // 加载提醒事项通知提前时间
      final reminderNotificationAdvance = prefs.getInt('reminder_notification_advance');
      if (reminderNotificationAdvance != null) {
        _reminderNotificationAdvance = reminderNotificationAdvance;
      }
      
      // 加载节日通知提前时间
      final holidayNotificationAdvance = prefs.getInt('holiday_notification_advance');
      if (holidayNotificationAdvance != null) {
        _holidayNotificationAdvance = holidayNotificationAdvance;
      }
      
      // 加载是否启用振动
      final enableVibration = prefs.getBool('enable_vibration');
      if (enableVibration != null) {
        _enableVibration = enableVibration;
      }
      
      // 加载是否启用声音
      final enableSound = prefs.getBool('enable_sound');
      if (enableSound != null) {
        _enableSound = enableSound;
      }
      
      _logger.debug('加载通知设置完成');
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载通知设置失败', e, stack);
    }
  }
  
  /// 保存通知设置
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存是否启用通知
      await prefs.setBool('enable_notifications', _enableNotifications);
      
      // 保存提醒事项通知提前时间
      await prefs.setInt('reminder_notification_advance', _reminderNotificationAdvance);
      
      // 保存节日通知提前时间
      await prefs.setInt('holiday_notification_advance', _holidayNotificationAdvance);
      
      // 保存是否启用振动
      await prefs.setBool('enable_vibration', _enableVibration);
      
      // 保存是否启用声音
      await prefs.setBool('enable_sound', _enableSound);
      
      _logger.debug('保存通知设置完成');
    } catch (e, stack) {
      _logger.error('保存通知设置失败', e, stack);
    }
  }
  
  @override
  void dispose() {
    _logger.debug('销毁通知提供者');
    
    // 移除通知点击监听器
    _notificationService.removeNotificationClickListener(_handleNotificationClick);
    
    super.dispose();
  }
}
