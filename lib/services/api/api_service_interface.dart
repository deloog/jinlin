import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';

/// API服务接口
///
/// 定义与后端API交互的方法
abstract class ApiServiceInterface {
  /// 初始化API服务
  Future<void> initialize();
  
  /// 获取健康状态
  Future<bool> getHealth();
  
  /// 获取API版本
  Future<String> getVersion();
  
  /// 获取所有节日
  Future<List<Holiday>> getHolidays({
    String? languageCode,
    String? regionCode,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// 获取单个节日
  Future<Holiday> getHoliday(String id);
  
  /// 创建节日
  Future<Holiday> createHoliday(Holiday holiday);
  
  /// 更新节日
  Future<Holiday> updateHoliday(Holiday holiday);
  
  /// 删除节日
  Future<bool> deleteHoliday(String id);
  
  /// 获取所有提醒事项
  Future<List<Reminder>> getReminders({
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  });
  
  /// 获取单个提醒事项
  Future<Reminder> getReminder(String id);
  
  /// 创建提醒事项
  Future<Reminder> createReminder(Reminder reminder);
  
  /// 更新提醒事项
  Future<Reminder> updateReminder(Reminder reminder);
  
  /// 删除提醒事项
  Future<bool> deleteReminder(String id);
  
  /// 标记提醒事项为已完成
  Future<Reminder> markReminderAsCompleted(String id);
  
  /// 标记提醒事项为未完成
  Future<Reminder> markReminderAsIncomplete(String id);
  
  /// 同步数据
  Future<Map<String, dynamic>> syncData(Map<String, dynamic> data);
  
  /// 获取用户设置
  Future<Map<String, dynamic>> getUserSettings();
  
  /// 更新用户设置
  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> settings);
  
  /// 获取节日数据更新
  Future<List<Holiday>> getHolidayUpdates(DateTime lastSyncTime);
  
  /// 获取提醒事项数据更新
  Future<List<Reminder>> getReminderUpdates(DateTime lastSyncTime);
  
  /// 批量创建节日
  Future<List<Holiday>> createHolidayBatch(List<Holiday> holidays);
  
  /// 批量更新节日
  Future<List<Holiday>> updateHolidayBatch(List<Holiday> holidays);
  
  /// 批量删除节日
  Future<bool> deleteHolidayBatch(List<String> ids);
  
  /// 批量创建提醒事项
  Future<List<Reminder>> createReminderBatch(List<Reminder> reminders);
  
  /// 批量更新提醒事项
  Future<List<Reminder>> updateReminderBatch(List<Reminder> reminders);
  
  /// 批量删除提醒事项
  Future<bool> deleteReminderBatch(List<String> ids);
  
  /// 关闭API服务
  Future<void> close();
}
