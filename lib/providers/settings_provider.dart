import 'package:flutter/material.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置提供者
///
/// 管理应用程序的设置
class SettingsProvider extends ChangeNotifier {
  // 日志服务
  final LoggingService _logger = LoggingService();
  
  // 是否显示农历
  bool _showLunar = true;
  
  // 是否显示节气
  bool _showSolarTerms = true;
  
  // 是否显示节日倒计时
  bool _showHolidayCountdown = true;
  
  // 是否显示提醒事项倒计时
  bool _showReminderCountdown = true;
  
  // 是否自动同步
  bool _autoSync = true;
  
  // 同步频率（小时）
  int _syncInterval = 24;
  
  // 是否显示已完成的提醒事项
  bool _showCompletedReminders = true;
  
  // 是否显示已过期的提醒事项
  bool _showExpiredReminders = true;
  
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
  
  // 是否在启动时检查更新
  bool _checkUpdateOnStartup = true;
  
  // 是否自动备份
  bool _autoBackup = true;
  
  // 备份频率（天）
  int _backupInterval = 7;
  
  // 最大备份数量
  int _maxBackupCount = 5;
  
  /// 构造函数
  SettingsProvider() {
    _logger.debug('初始化设置提供者');
    
    // 加载设置
    _loadSettings();
  }
  
  /// 获取是否显示农历
  bool get showLunar => _showLunar;
  
  /// 获取是否显示节气
  bool get showSolarTerms => _showSolarTerms;
  
  /// 获取是否显示节日倒计时
  bool get showHolidayCountdown => _showHolidayCountdown;
  
  /// 获取是否显示提醒事项倒计时
  bool get showReminderCountdown => _showReminderCountdown;
  
  /// 获取是否自动同步
  bool get autoSync => _autoSync;
  
  /// 获取同步频率（小时）
  int get syncInterval => _syncInterval;
  
  /// 获取是否显示已完成的提醒事项
  bool get showCompletedReminders => _showCompletedReminders;
  
  /// 获取是否显示已过期的提醒事项
  bool get showExpiredReminders => _showExpiredReminders;
  
  /// 获取是否启用通知
  bool get enableNotifications => _enableNotifications;
  
  /// 获取提醒事项通知提前时间（分钟）
  int get reminderNotificationAdvance => _reminderNotificationAdvance;
  
  /// 获取节日通知提前时间（天）
  int get holidayNotificationAdvance => _holidayNotificationAdvance;
  
  /// 获取是否启用振动
  bool get enableVibration => _enableVibration;
  
  /// 获取是否启用声音
  bool get enableSound => _enableSound;
  
  /// 获取是否在启动时检查更新
  bool get checkUpdateOnStartup => _checkUpdateOnStartup;
  
  /// 获取是否自动备份
  bool get autoBackup => _autoBackup;
  
  /// 获取备份频率（天）
  int get backupInterval => _backupInterval;
  
  /// 获取最大备份数量
  int get maxBackupCount => _maxBackupCount;
  
  /// 设置是否显示农历
  Future<void> setShowLunar(bool showLunar) async {
    if (_showLunar == showLunar) return;
    
    _showLunar = showLunar;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否显示节气
  Future<void> setShowSolarTerms(bool showSolarTerms) async {
    if (_showSolarTerms == showSolarTerms) return;
    
    _showSolarTerms = showSolarTerms;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否显示节日倒计时
  Future<void> setShowHolidayCountdown(bool showHolidayCountdown) async {
    if (_showHolidayCountdown == showHolidayCountdown) return;
    
    _showHolidayCountdown = showHolidayCountdown;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否显示提醒事项倒计时
  Future<void> setShowReminderCountdown(bool showReminderCountdown) async {
    if (_showReminderCountdown == showReminderCountdown) return;
    
    _showReminderCountdown = showReminderCountdown;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否自动同步
  Future<void> setAutoSync(bool autoSync) async {
    if (_autoSync == autoSync) return;
    
    _autoSync = autoSync;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置同步频率（小时）
  Future<void> setSyncInterval(int syncInterval) async {
    if (_syncInterval == syncInterval) return;
    
    _syncInterval = syncInterval;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否显示已完成的提醒事项
  Future<void> setShowCompletedReminders(bool showCompletedReminders) async {
    if (_showCompletedReminders == showCompletedReminders) return;
    
    _showCompletedReminders = showCompletedReminders;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否显示已过期的提醒事项
  Future<void> setShowExpiredReminders(bool showExpiredReminders) async {
    if (_showExpiredReminders == showExpiredReminders) return;
    
    _showExpiredReminders = showExpiredReminders;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否启用通知
  Future<void> setEnableNotifications(bool enableNotifications) async {
    if (_enableNotifications == enableNotifications) return;
    
    _enableNotifications = enableNotifications;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置提醒事项通知提前时间（分钟）
  Future<void> setReminderNotificationAdvance(int reminderNotificationAdvance) async {
    if (_reminderNotificationAdvance == reminderNotificationAdvance) return;
    
    _reminderNotificationAdvance = reminderNotificationAdvance;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置节日通知提前时间（天）
  Future<void> setHolidayNotificationAdvance(int holidayNotificationAdvance) async {
    if (_holidayNotificationAdvance == holidayNotificationAdvance) return;
    
    _holidayNotificationAdvance = holidayNotificationAdvance;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否启用振动
  Future<void> setEnableVibration(bool enableVibration) async {
    if (_enableVibration == enableVibration) return;
    
    _enableVibration = enableVibration;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否启用声音
  Future<void> setEnableSound(bool enableSound) async {
    if (_enableSound == enableSound) return;
    
    _enableSound = enableSound;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否在启动时检查更新
  Future<void> setCheckUpdateOnStartup(bool checkUpdateOnStartup) async {
    if (_checkUpdateOnStartup == checkUpdateOnStartup) return;
    
    _checkUpdateOnStartup = checkUpdateOnStartup;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置是否自动备份
  Future<void> setAutoBackup(bool autoBackup) async {
    if (_autoBackup == autoBackup) return;
    
    _autoBackup = autoBackup;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置备份频率（天）
  Future<void> setBackupInterval(int backupInterval) async {
    if (_backupInterval == backupInterval) return;
    
    _backupInterval = backupInterval;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 设置最大备份数量
  Future<void> setMaxBackupCount(int maxBackupCount) async {
    if (_maxBackupCount == maxBackupCount) return;
    
    _maxBackupCount = maxBackupCount;
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
  
  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载设置
      _showLunar = prefs.getBool('show_lunar') ?? true;
      _showSolarTerms = prefs.getBool('show_solar_terms') ?? true;
      _showHolidayCountdown = prefs.getBool('show_holiday_countdown') ?? true;
      _showReminderCountdown = prefs.getBool('show_reminder_countdown') ?? true;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _syncInterval = prefs.getInt('sync_interval') ?? 24;
      _showCompletedReminders = prefs.getBool('show_completed_reminders') ?? true;
      _showExpiredReminders = prefs.getBool('show_expired_reminders') ?? true;
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _reminderNotificationAdvance = prefs.getInt('reminder_notification_advance') ?? 30;
      _holidayNotificationAdvance = prefs.getInt('holiday_notification_advance') ?? 1;
      _enableVibration = prefs.getBool('enable_vibration') ?? true;
      _enableSound = prefs.getBool('enable_sound') ?? true;
      _checkUpdateOnStartup = prefs.getBool('check_update_on_startup') ?? true;
      _autoBackup = prefs.getBool('auto_backup') ?? true;
      _backupInterval = prefs.getInt('backup_interval') ?? 7;
      _maxBackupCount = prefs.getInt('max_backup_count') ?? 5;
      
      _logger.debug('加载设置完成');
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载设置失败', e, stack);
    }
  }
  
  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存设置
      await prefs.setBool('show_lunar', _showLunar);
      await prefs.setBool('show_solar_terms', _showSolarTerms);
      await prefs.setBool('show_holiday_countdown', _showHolidayCountdown);
      await prefs.setBool('show_reminder_countdown', _showReminderCountdown);
      await prefs.setBool('auto_sync', _autoSync);
      await prefs.setInt('sync_interval', _syncInterval);
      await prefs.setBool('show_completed_reminders', _showCompletedReminders);
      await prefs.setBool('show_expired_reminders', _showExpiredReminders);
      await prefs.setBool('enable_notifications', _enableNotifications);
      await prefs.setInt('reminder_notification_advance', _reminderNotificationAdvance);
      await prefs.setInt('holiday_notification_advance', _holidayNotificationAdvance);
      await prefs.setBool('enable_vibration', _enableVibration);
      await prefs.setBool('enable_sound', _enableSound);
      await prefs.setBool('check_update_on_startup', _checkUpdateOnStartup);
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setInt('backup_interval', _backupInterval);
      await prefs.setInt('max_backup_count', _maxBackupCount);
      
      _logger.debug('保存设置完成');
    } catch (e, stack) {
      _logger.error('保存设置失败', e, stack);
    }
  }
  
  /// 重置设置
  Future<void> resetSettings() async {
    _showLunar = true;
    _showSolarTerms = true;
    _showHolidayCountdown = true;
    _showReminderCountdown = true;
    _autoSync = true;
    _syncInterval = 24;
    _showCompletedReminders = true;
    _showExpiredReminders = true;
    _enableNotifications = true;
    _reminderNotificationAdvance = 30;
    _holidayNotificationAdvance = 1;
    _enableVibration = true;
    _enableSound = true;
    _checkUpdateOnStartup = true;
    _autoBackup = true;
    _backupInterval = 7;
    _maxBackupCount = 5;
    
    notifyListeners();
    
    // 保存设置
    await _saveSettings();
  }
}
