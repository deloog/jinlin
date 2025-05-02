import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';

/// 增强版数据库接口
///
/// 定义所有数据库操作的抽象接口，支持所有数据模型的CRUD操作
abstract class DatabaseInterfaceEnhanced {
  /// 初始化数据库
  Future<void> initialize();

  /// 关闭数据库
  Future<void> close();

  /// 清空数据库
  Future<void> clearAll();

  // ==================== 节日相关操作 ====================

  /// 保存节日
  Future<void> saveHoliday(Holiday holiday);

  /// 批量保存节日
  Future<void> saveHolidays(List<Holiday> holidays);

  /// 获取所有节日
  Future<List<Holiday>> getAllHolidays();

  /// 根据ID获取节日
  Future<Holiday?> getHolidayById(String id);

  /// 根据地区获取节日
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'});

  /// 根据类型获取节日
  Future<List<Holiday>> getHolidaysByType(HolidayType type);

  /// 搜索节日
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'});

  /// 删除节日
  Future<void> deleteHoliday(String id);

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String id, int importance);

  // ==================== 联系人相关操作 ====================

  /// 保存联系人
  Future<void> saveContact(ContactModel contact);

  /// 批量保存联系人
  Future<void> saveContacts(List<ContactModel> contacts);

  /// 获取所有联系人
  Future<List<ContactModel>> getAllContacts();

  /// 根据ID获取联系人
  Future<ContactModel?> getContactById(String id);

  /// 根据关系类型获取联系人
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType);

  /// 搜索联系人
  Future<List<ContactModel>> searchContacts(String query);

  /// 删除联系人
  Future<void> deleteContact(String id);

  // ==================== 提醒事件相关操作 ====================

  /// 保存提醒事件
  Future<void> saveReminderEvent(ReminderEventModel event);

  /// 批量保存提醒事件
  Future<void> saveReminderEvents(List<ReminderEventModel> events);

  /// 获取所有提醒事件
  Future<List<ReminderEventModel>> getAllReminderEvents();

  /// 根据ID获取提醒事件
  Future<ReminderEventModel?> getReminderEventById(String id);

  /// 获取即将到来的提醒事件
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days);

  /// 获取过期的提醒事件
  Future<List<ReminderEventModel>> getExpiredReminderEvents();

  /// 根据类型获取提醒事件
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type);

  /// 搜索提醒事件
  Future<List<ReminderEventModel>> searchReminderEvents(String query);

  /// 删除提醒事件
  Future<void> deleteReminderEvent(String id);

  /// 更新提醒事件状态
  Future<void> updateReminderEventStatus(String id, ReminderStatus status);

  // ==================== 用户设置相关操作 ====================

  /// 保存用户设置
  Future<void> saveUserSettings(UserSettingsModel settings);

  /// 获取用户设置
  Future<UserSettingsModel?> getUserSettings();

  /// 更新用户设置
  Future<void> updateUserSettings(Map<String, dynamic> updates);

  // ==================== 数据同步相关操作 ====================

  /// 获取上次同步时间
  Future<DateTime?> getLastSyncTime();

  /// 更新上次同步时间
  Future<void> updateLastSyncTime(DateTime time);

  /// 获取修改过的数据（用于增量同步）
  Future<Map<String, dynamic>> getModifiedData(DateTime? since);

  /// 标记同步冲突
  Future<void> markSyncConflict(String entityType, String id, bool isConflict);

  /// 获取同步冲突（旧版本）
  Future<List<Map<String, dynamic>>> getSyncConflictsLegacy();

  /// 解决同步冲突
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData);

  /// 获取应用设置
  Future<String?> getAppSetting(String key);

  /// 设置应用设置
  Future<void> setAppSetting(String key, String value);

  /// 获取同步批次
  Future<List<SyncBatch>> getSyncBatches();

  /// 获取同步批次
  Future<SyncBatch?> getSyncBatch(String batchId);

  /// 保存同步批次
  Future<void> saveSyncBatch(SyncBatch batch);

  /// 删除同步批次
  Future<void> deleteSyncBatch(String batchId);

  /// 获取同步操作
  Future<List<SyncOperation>> getSyncOperations();

  /// 获取同步操作
  Future<SyncOperation?> getSyncOperation(String operationId);

  /// 保存同步操作
  Future<void> saveSyncOperation(SyncOperation operation);

  /// 删除同步操作
  Future<void> deleteSyncOperation(String operationId);

  /// 获取同步冲突
  Future<List<Map<String, dynamic>>> getSyncConflicts();

  /// 获取同步冲突
  Future<Map<String, dynamic>?> getSyncConflict(String conflictId);

  /// 保存同步冲突
  Future<void> saveSyncConflict(SyncConflict conflict);

  /// 删除同步冲突
  Future<void> deleteSyncConflict(String conflictId);

  // ==================== 其他操作 ====================

  /// 检查数据库是否已初始化
  Future<bool> isInitialized();

  /// 检查是否是首次启动
  Future<bool> isFirstLaunch();

  /// 设置首次启动标志
  Future<void> setFirstLaunch(bool value);

  /// 获取数据库版本
  Future<int> getDatabaseVersion();

  /// 设置数据库版本
  Future<void> setDatabaseVersion(int version);

  /// 执行数据库备份
  Future<String> backup();

  /// 从备份恢复数据库
  Future<bool> restore(String backupPath);

  /// 执行数据库维护
  Future<void> performMaintenance();
}
