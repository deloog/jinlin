import 'package:jinlin_app/models/unified/reminder.dart';

/// 提醒事项存储库接口
///
/// 定义提醒事项存储库的方法
abstract class ReminderRepositoryInterface {
  /// 初始化提醒事项存储库
  Future<void> initialize();
  
  /// 获取所有提醒事项
  Future<List<Reminder>> getReminders({
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool includeDeleted = false,
    bool forceRefresh = false,
  });
  
  /// 获取单个提醒事项
  Future<Reminder?> getReminder(String id, {bool forceRefresh = false});
  
  /// 保存提醒事项
  Future<Reminder> saveReminder(Reminder reminder);
  
  /// 批量保存提醒事项
  Future<List<Reminder>> saveReminders(List<Reminder> reminders);
  
  /// 删除提醒事项
  Future<bool> deleteReminder(String id, {bool hardDelete = false});
  
  /// 批量删除提醒事项
  Future<bool> deleteReminders(List<String> ids, {bool hardDelete = false});
  
  /// 标记提醒事项为已完成
  Future<Reminder?> markReminderAsCompleted(String id);
  
  /// 标记提醒事项为未完成
  Future<Reminder?> markReminderAsIncomplete(String id);
  
  /// 获取提醒事项数量
  Future<int> getReminderCount();
  
  /// 获取已删除提醒事项数量
  Future<int> getDeletedReminderCount();
  
  /// 获取所有已删除的提醒事项
  Future<List<Reminder>> getDeletedReminders();
  
  /// 恢复已删除的提醒事项
  Future<Reminder?> restoreReminder(String id);
  
  /// 清空已删除的提醒事项
  Future<void> purgeDeletedReminders();
  
  /// 同步提醒事项数据
  Future<void> syncReminders();
  
  /// 获取提醒事项更新
  Future<List<Reminder>> getReminderUpdates(DateTime lastSyncTime);
  
  /// 导入提醒事项数据
  Future<int> importReminders(List<Reminder> reminders);
  
  /// 导出提醒事项数据
  Future<List<Reminder>> exportReminders();
  
  /// 获取提醒事项统计信息
  Future<Map<String, dynamic>> getReminderStats();
  
  /// 关闭提醒事项存储库
  Future<void> close();
}
