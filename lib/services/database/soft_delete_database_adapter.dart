import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/database/soft_delete_manager.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 软删除数据库适配器
///
/// 包装另一个数据库适配器，添加软删除和恢复功能
class SoftDeleteDatabaseAdapter implements DatabaseInterfaceEnhanced {
  // 日志标签
  static const String _tag = 'SoftDeleteDB';

  // 被包装的数据库适配器
  final DatabaseInterfaceEnhanced _db;

  // 软删除管理器
  final SoftDeleteManager _softDeleteManager;

  // 是否包含已删除的数据
  bool _includeDeleted = false;

  // 已删除数据保留天数
  int _deletedDataRetentionDays = 30;

  /// 构造函数
  SoftDeleteDatabaseAdapter(this._db)
      : _softDeleteManager = SoftDeleteManager(_db);

  /// 获取软删除管理器
  SoftDeleteManager getSoftDeleteManager() {
    return _softDeleteManager;
  }

  /// 设置是否包含已删除的数据
  void setIncludeDeleted(bool includeDeleted) {
    _includeDeleted = includeDeleted;
    logger.i(_tag, '设置包含已删除的数据: $includeDeleted');
  }

  /// 获取是否包含已删除的数据
  bool getIncludeDeleted() {
    return _includeDeleted;
  }

  /// 设置已删除数据保留天数
  void setDeletedDataRetentionDays(int days) {
    _deletedDataRetentionDays = days;
    logger.i(_tag, '设置已删除数据保留天数: $days');
  }

  /// 获取已删除数据保留天数
  int getDeletedDataRetentionDays() {
    return _deletedDataRetentionDays;
  }

  /// 清理过期的已删除数据
  Future<void> cleanupExpiredDeletedData() async {
    await _softDeleteManager.cleanupExpiredDeletedData(_deletedDataRetentionDays);
  }

  @override
  Future<void> initialize() async {
    await _db.initialize();
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<void> clearAll() async {
    await _db.clearAll();
  }

  @override
  Future<bool> isInitialized() async {
    return _db.isInitialized();
  }

  @override
  Future<bool> isFirstLaunch() async {
    return _db.isFirstLaunch();
  }

  @override
  Future<void> setFirstLaunch(bool value) async {
    await _db.setFirstLaunch(value);
  }

  @override
  Future<int> getDatabaseVersion() async {
    return _db.getDatabaseVersion();
  }

  @override
  Future<void> setDatabaseVersion(int version) async {
    await _db.setDatabaseVersion(version);
  }

  // ==================== 节日相关操作 ====================

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _db.saveHoliday(holiday);
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _db.saveHolidays(holidays);
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    final holidays = await _db.getAllHolidays();

    if (!_includeDeleted) {
      // 过滤掉已删除的节日
      return holidays.where((holiday) => !holiday.isDeleted).toList();
    }

    return holidays;
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    final holiday = await _db.getHolidayById(id);

    if (holiday != null && holiday.isDeleted && !_includeDeleted) {
      // 如果节日已删除且不包含已删除的数据，则返回null
      return null;
    }

    return holiday;
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    final holidays = await _db.getHolidaysByRegion(region, languageCode: languageCode);

    if (!_includeDeleted) {
      // 过滤掉已删除的节日
      return holidays.where((holiday) => !holiday.isDeleted).toList();
    }

    return holidays;
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    final holidays = await _db.getHolidaysByType(type);

    if (!_includeDeleted) {
      // 过滤掉已删除的节日
      return holidays.where((holiday) => !holiday.isDeleted).toList();
    }

    return holidays;
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    final holidays = await _db.searchHolidays(query, languageCode: languageCode);

    if (!_includeDeleted) {
      // 过滤掉已删除的节日
      return holidays.where((holiday) => !holiday.isDeleted).toList();
    }

    return holidays;
  }

  @override
  Future<void> deleteHoliday(String id) async {
    // 软删除节日
    await _softDeleteManager.softDeleteHoliday(id);
  }

  /// 永久删除节日
  Future<void> permanentlyDeleteHoliday(String id) async {
    await _softDeleteManager.permanentlyDeleteHoliday(id);
  }

  /// 恢复节日
  Future<void> restoreHoliday(String id) async {
    await _softDeleteManager.restoreHoliday(id);
  }

  /// 获取已删除的节日
  Future<List<Holiday>> getDeletedHolidays() async {
    return _softDeleteManager.getDeletedHolidays();
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _db.updateHolidayImportance(id, importance);
  }

  // ==================== 联系人相关操作 ====================

  @override
  Future<void> saveContact(ContactModel contact) async {
    await _db.saveContact(contact);
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    await _db.saveContacts(contacts);
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    final contacts = await _db.getAllContacts();

    if (!_includeDeleted) {
      // 过滤掉已删除的联系人
      return contacts.where((contact) => !contact.isDeleted).toList();
    }

    return contacts;
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    final contact = await _db.getContactById(id);

    if (contact != null && contact.isDeleted && !_includeDeleted) {
      // 如果联系人已删除且不包含已删除的数据，则返回null
      return null;
    }

    return contact;
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    final contacts = await _db.getContactsByRelationType(relationType);

    if (!_includeDeleted) {
      // 过滤掉已删除的联系人
      return contacts.where((contact) => !contact.isDeleted).toList();
    }

    return contacts;
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    final contacts = await _db.searchContacts(query);

    if (!_includeDeleted) {
      // 过滤掉已删除的联系人
      return contacts.where((contact) => !contact.isDeleted).toList();
    }

    return contacts;
  }

  @override
  Future<void> deleteContact(String id) async {
    // 软删除联系人
    await _softDeleteManager.softDeleteContact(id);
  }

  /// 永久删除联系人
  Future<void> permanentlyDeleteContact(String id) async {
    await _softDeleteManager.permanentlyDeleteContact(id);
  }

  /// 恢复联系人
  Future<void> restoreContact(String id) async {
    await _softDeleteManager.restoreContact(id);
  }

  /// 获取已删除的联系人
  Future<List<ContactModel>> getDeletedContacts() async {
    return _softDeleteManager.getDeletedContacts();
  }

  // ==================== 提醒事件相关操作 ====================

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    await _db.saveReminderEvent(event);
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    await _db.saveReminderEvents(events);
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    final events = await _db.getAllReminderEvents();

    if (!_includeDeleted) {
      // 过滤掉已删除的提醒事件
      return events.where((event) => !event.isDeleted).toList();
    }

    return events;
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    final event = await _db.getReminderEventById(id);

    if (event != null && event.isDeleted && !_includeDeleted) {
      // 如果提醒事件已删除且不包含已删除的数据，则返回null
      return null;
    }

    return event;
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    final events = await _db.getUpcomingReminderEvents(days);

    if (!_includeDeleted) {
      // 过滤掉已删除的提醒事件
      return events.where((event) => !event.isDeleted).toList();
    }

    return events;
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    final events = await _db.getExpiredReminderEvents();

    if (!_includeDeleted) {
      // 过滤掉已删除的提醒事件
      return events.where((event) => !event.isDeleted).toList();
    }

    return events;
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    final events = await _db.getReminderEventsByType(type);

    if (!_includeDeleted) {
      // 过滤掉已删除的提醒事件
      return events.where((event) => !event.isDeleted).toList();
    }

    return events;
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    final events = await _db.searchReminderEvents(query);

    if (!_includeDeleted) {
      // 过滤掉已删除的提醒事件
      return events.where((event) => !event.isDeleted).toList();
    }

    return events;
  }

  @override
  Future<void> deleteReminderEvent(String id) async {
    // 软删除提醒事件
    await _softDeleteManager.softDeleteReminderEvent(id);
  }

  /// 永久删除提醒事件
  Future<void> permanentlyDeleteReminderEvent(String id) async {
    await _softDeleteManager.permanentlyDeleteReminderEvent(id);
  }

  /// 恢复提醒事件
  Future<void> restoreReminderEvent(String id) async {
    await _softDeleteManager.restoreReminderEvent(id);
  }

  /// 获取已删除的提醒事件
  Future<List<ReminderEventModel>> getDeletedReminderEvents() async {
    return _softDeleteManager.getDeletedReminderEvents();
  }

  @override
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _db.updateReminderEventStatus(id, status);
  }

  // ==================== 用户设置相关操作 ====================

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _db.saveUserSettings(settings);
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    return _db.getUserSettings();
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _db.updateUserSettings(updates);
  }

  // ==================== 同步相关操作 ====================

  @override
  Future<DateTime?> getLastSyncTime() async {
    return _db.getLastSyncTime();
  }

  @override
  Future<void> updateLastSyncTime(DateTime time) async {
    await _db.updateLastSyncTime(time);
  }

  @override
  Future<Map<String, dynamic>> getModifiedData(DateTime? since) async {
    final modifiedData = await _db.getModifiedData(since);

    if (!_includeDeleted) {
      // 过滤掉已删除的数据
      if (modifiedData.containsKey('holidays')) {
        final holidays = modifiedData['holidays'] as List<dynamic>;
        modifiedData['holidays'] = holidays.where((holiday) => !(holiday as Map<String, dynamic>)['isDeleted']).toList();
      }

      if (modifiedData.containsKey('contacts')) {
        final contacts = modifiedData['contacts'] as List<dynamic>;
        modifiedData['contacts'] = contacts.where((contact) => !(contact as Map<String, dynamic>)['isDeleted']).toList();
      }

      if (modifiedData.containsKey('reminderEvents')) {
        final events = modifiedData['reminderEvents'] as List<dynamic>;
        modifiedData['reminderEvents'] = events.where((event) => !(event as Map<String, dynamic>)['isDeleted']).toList();
      }
    }

    return modifiedData;
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _db.markSyncConflict(entityType, id, isConflict);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    final conflicts = await _db.getSyncConflicts();

    if (!_includeDeleted) {
      // 过滤掉已删除的数据
      return conflicts.where((conflict) => !(conflict['isDeleted'] as bool? ?? false)).toList();
    }

    return conflicts;
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    await _db.resolveSyncConflict(entityType, id, resolvedData);
  }

  // ==================== 其他操作 ====================

  @override
  Future<String> backup() async {
    return _db.backup();
  }

  @override
  Future<bool> restore(String backupPath) async {
    return _db.restore(backupPath);
  }

  @override
  Future<void> performMaintenance() async {
    await _db.performMaintenance();

    // 清理过期的已删除数据
    await cleanupExpiredDeletedData();
  }

  /// 清空回收站
  Future<void> emptyTrash() async {
    await _softDeleteManager.emptyTrash();
  }

  @override
  Future<String?> getAppSetting(String key) async {
    return _db.getAppSetting(key);
  }

  @override
  Future<void> setAppSetting(String key, String value) async {
    await _db.setAppSetting(key, value);
  }

  @override
  Future<List<SyncBatch>> getSyncBatches() async {
    return _db.getSyncBatches();
  }

  @override
  Future<SyncBatch?> getSyncBatch(String batchId) async {
    return _db.getSyncBatch(batchId);
  }

  @override
  Future<void> saveSyncBatch(SyncBatch batch) async {
    await _db.saveSyncBatch(batch);
  }

  @override
  Future<void> deleteSyncBatch(String batchId) async {
    await _db.deleteSyncBatch(batchId);
  }

  @override
  Future<List<SyncOperation>> getSyncOperations() async {
    return _db.getSyncOperations();
  }

  @override
  Future<SyncOperation?> getSyncOperation(String operationId) async {
    return _db.getSyncOperation(operationId);
  }

  @override
  Future<void> saveSyncOperation(SyncOperation operation) async {
    await _db.saveSyncOperation(operation);
  }

  @override
  Future<void> deleteSyncOperation(String operationId) async {
    await _db.deleteSyncOperation(operationId);
  }

  @override
  Future<Map<String, dynamic>?> getSyncConflict(String conflictId) async {
    return _db.getSyncConflict(conflictId);
  }

  @override
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    await _db.saveSyncConflict(conflict);
  }

  @override
  Future<void> deleteSyncConflict(String conflictId) async {
    await _db.deleteSyncConflict(conflictId);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflictsLegacy() async {
    return _db.getSyncConflictsLegacy();
  }
}
