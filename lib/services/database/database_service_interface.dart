import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';

/// 数据库服务接口
///
/// 定义与本地数据库交互的方法
abstract class DatabaseServiceInterface {
  /// 初始化数据库
  Future<void> initialize();
  
  /// 关闭数据库
  Future<void> close();
  
  /// 清空数据库
  Future<void> clear();
  
  /// 获取数据库版本
  Future<int> getVersion();
  
  /// 设置数据库版本
  Future<void> setVersion(int version);
  
  /// 获取所有节日
  Future<List<Holiday>> getHolidays({
    String? languageCode,
    String? regionCode,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
  });
  
  /// 获取单个节日
  Future<Holiday?> getHoliday(String id);
  
  /// 保存节日
  Future<void> saveHoliday(Holiday holiday);
  
  /// 批量保存节日
  Future<void> saveHolidays(List<Holiday> holidays);
  
  /// 删除节日
  Future<void> deleteHoliday(String id, {bool hardDelete = false});
  
  /// 批量删除节日
  Future<void> deleteHolidays(List<String> ids, {bool hardDelete = false});
  
  /// 获取所有提醒事项
  Future<List<Reminder>> getReminders({
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool includeDeleted = false,
  });
  
  /// 获取单个提醒事项
  Future<Reminder?> getReminder(String id);
  
  /// 保存提醒事项
  Future<void> saveReminder(Reminder reminder);
  
  /// 批量保存提醒事项
  Future<void> saveReminders(List<Reminder> reminders);
  
  /// 删除提醒事项
  Future<void> deleteReminder(String id, {bool hardDelete = false});
  
  /// 批量删除提醒事项
  Future<void> deleteReminders(List<String> ids, {bool hardDelete = false});
  
  /// 获取最后同步时间
  Future<DateTime?> getLastSyncTime();
  
  /// 设置最后同步时间
  Future<void> setLastSyncTime(DateTime time);
  
  /// 获取用户设置
  Future<Map<String, dynamic>> getUserSettings();
  
  /// 保存用户设置
  Future<void> saveUserSettings(Map<String, dynamic> settings);
  
  /// 获取数据库大小
  Future<int> getDatabaseSize();
  
  /// 备份数据库
  Future<String> backup();
  
  /// 从备份恢复数据库
  Future<bool> restore(String backupPath);
  
  /// 获取所有已删除的节日
  Future<List<Holiday>> getDeletedHolidays();
  
  /// 获取所有已删除的提醒事项
  Future<List<Reminder>> getDeletedReminders();
  
  /// 恢复已删除的节日
  Future<void> restoreHoliday(String id);
  
  /// 恢复已删除的提醒事项
  Future<void> restoreReminder(String id);
  
  /// 清空已删除的节日
  Future<void> purgeDeletedHolidays();
  
  /// 清空已删除的提醒事项
  Future<void> purgeDeletedReminders();
  
  /// 获取节日数量
  Future<int> getHolidayCount();
  
  /// 获取提醒事项数量
  Future<int> getReminderCount();
  
  /// 获取已删除节日数量
  Future<int> getDeletedHolidayCount();
  
  /// 获取已删除提醒事项数量
  Future<int> getDeletedReminderCount();
  
  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats();
  
  /// 优化数据库
  Future<void> optimize();
  
  /// 验证数据库完整性
  Future<bool> validateIntegrity();
  
  /// 执行自定义SQL查询
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]);
  
  /// 执行自定义SQL更新
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]);
  
  /// 执行自定义SQL插入
  Future<int> rawInsert(String sql, [List<dynamic>? arguments]);
  
  /// 执行自定义SQL删除
  Future<int> rawDelete(String sql, [List<dynamic>? arguments]);
}
