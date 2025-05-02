import 'dart:async';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/database/monitoring/database_monitor.dart';

// 导入需要的类型
export 'package:jinlin_app/models/contact_model.dart' show RelationType;
export 'package:jinlin_app/models/reminder_event_model.dart' show ReminderEventType, ReminderStatus;

/// 数据库监控适配器
///
/// 包装数据库接口，添加性能监控功能
class DatabaseMonitoringAdapter implements DatabaseInterfaceEnhanced {
  // 被包装的数据库接口
  final DatabaseInterfaceEnhanced _db;

  // 数据库监控器
  final DatabaseMonitor _monitor;

  // 构造函数
  DatabaseMonitoringAdapter(this._db) : _monitor = DatabaseMonitor();

  /// 启用监控
  void enableMonitoring() {
    _monitor.enable();
  }

  /// 禁用监控
  void disableMonitoring() {
    _monitor.disable();
  }

  /// 获取性能报告
  String getPerformanceReport() {
    return _monitor.getPerformanceReport();
  }

  /// 清除监控数据
  void clearMonitoringData() {
    _monitor.clear();
  }

  /// 测量方法执行时间的辅助方法
  Future<T> _measureExecutionTime<T>(String methodName, Future<T> Function() method) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await method();
    } finally {
      stopwatch.stop();
      _monitor.recordQueryExecutionTime(methodName, stopwatch.elapsedMilliseconds);
    }
  }

  @override
  Future<void> initialize() async {
    await _measureExecutionTime('initialize', () => _db.initialize());
  }

  @override
  Future<void> close() async {
    await _measureExecutionTime('close', () => _db.close());
  }

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _measureExecutionTime('saveHoliday', () => _db.saveHoliday(holiday));
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _measureExecutionTime('saveHolidays', () => _db.saveHolidays(holidays));
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    return await _measureExecutionTime('getAllHolidays', () => _db.getAllHolidays());
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    return await _measureExecutionTime('getHolidayById', () => _db.getHolidayById(id));
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    return await _measureExecutionTime('getHolidaysByRegion',
      () => _db.getHolidaysByRegion(region, languageCode: languageCode));
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    return await _measureExecutionTime('getHolidaysByType', () => _db.getHolidaysByType(type));
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    return await _measureExecutionTime('searchHolidays',
      () => _db.searchHolidays(query, languageCode: languageCode));
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _measureExecutionTime('deleteHoliday', () => _db.deleteHoliday(id));
  }

  @override
  Future<void> saveContact(ContactModel contact) async {
    await _measureExecutionTime('saveContact', () => _db.saveContact(contact));
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    await _measureExecutionTime('saveContacts', () => _db.saveContacts(contacts));
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    return await _measureExecutionTime('getAllContacts', () => _db.getAllContacts());
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    return await _measureExecutionTime('getContactById', () => _db.getContactById(id));
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    return await _measureExecutionTime('searchContacts', () => _db.searchContacts(query));
  }

  @override
  Future<void> deleteContact(String id) async {
    await _measureExecutionTime('deleteContact', () => _db.deleteContact(id));
  }

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    await _measureExecutionTime('saveReminderEvent', () => _db.saveReminderEvent(event));
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    await _measureExecutionTime('saveReminderEvents', () => _db.saveReminderEvents(events));
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    return await _measureExecutionTime('getAllReminderEvents', () => _db.getAllReminderEvents());
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    return await _measureExecutionTime('getReminderEventById', () => _db.getReminderEventById(id));
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    return await _measureExecutionTime('getUpcomingReminderEvents',
      () => _db.getUpcomingReminderEvents(days));
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    return await _measureExecutionTime('getExpiredReminderEvents', () => _db.getExpiredReminderEvents());
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    return await _measureExecutionTime('getReminderEventsByType',
      () => _db.getReminderEventsByType(type));
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    return await _measureExecutionTime('searchReminderEvents', () => _db.searchReminderEvents(query));
  }

  @override
  Future<void> deleteReminderEvent(String id) async {
    await _measureExecutionTime('deleteReminderEvent', () => _db.deleteReminderEvent(id));
  }

  @override
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _measureExecutionTime('updateReminderEventStatus',
      () => _db.updateReminderEventStatus(id, status));
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _measureExecutionTime('saveUserSettings', () => _db.saveUserSettings(settings));
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    return await _measureExecutionTime('getUserSettings', () => _db.getUserSettings());
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _measureExecutionTime('updateUserSettings', () => _db.updateUserSettings(updates));
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _measureExecutionTime('markSyncConflict',
      () => _db.markSyncConflict(entityType, id, isConflict));
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    return await _measureExecutionTime('getSyncConflicts', () => _db.getSyncConflicts());
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflictsLegacy() async {
    return await _measureExecutionTime('getSyncConflictsLegacy', () => _db.getSyncConflictsLegacy());
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    await _measureExecutionTime('resolveSyncConflict',
      () => _db.resolveSyncConflict(entityType, id, resolvedData));
  }

  @override
  Future<String?> getAppSetting(String key) async {
    return await _measureExecutionTime('getAppSetting', () => _db.getAppSetting(key));
  }

  @override
  Future<void> setAppSetting(String key, String value) async {
    await _measureExecutionTime('setAppSetting', () => _db.setAppSetting(key, value));
  }

  @override
  Future<Map<String, dynamic>?> getSyncConflict(String conflictId) async {
    return await _measureExecutionTime('getSyncConflict', () => _db.getSyncConflict(conflictId));
  }

  @override
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    await _measureExecutionTime('saveSyncConflict', () => _db.saveSyncConflict(conflict));
  }

  @override
  Future<void> deleteSyncConflict(String conflictId) async {
    await _measureExecutionTime('deleteSyncConflict', () => _db.deleteSyncConflict(conflictId));
  }

  @override
  Future<List<SyncBatch>> getSyncBatches() async {
    return await _measureExecutionTime('getSyncBatches', () => _db.getSyncBatches());
  }

  @override
  Future<SyncBatch?> getSyncBatch(String batchId) async {
    return await _measureExecutionTime('getSyncBatch', () => _db.getSyncBatch(batchId));
  }

  @override
  Future<void> saveSyncBatch(SyncBatch batch) async {
    await _measureExecutionTime('saveSyncBatch', () => _db.saveSyncBatch(batch));
  }

  @override
  Future<void> deleteSyncBatch(String batchId) async {
    await _measureExecutionTime('deleteSyncBatch', () => _db.deleteSyncBatch(batchId));
  }

  @override
  Future<List<SyncOperation>> getSyncOperations() async {
    return await _measureExecutionTime('getSyncOperations', () => _db.getSyncOperations());
  }

  @override
  Future<SyncOperation?> getSyncOperation(String operationId) async {
    return await _measureExecutionTime('getSyncOperation', () => _db.getSyncOperation(operationId));
  }

  @override
  Future<void> saveSyncOperation(SyncOperation operation) async {
    await _measureExecutionTime('saveSyncOperation', () => _db.saveSyncOperation(operation));
  }

  @override
  Future<void> deleteSyncOperation(String operationId) async {
    await _measureExecutionTime('deleteSyncOperation', () => _db.deleteSyncOperation(operationId));
  }

  @override
  Future<String> backup() async {
    return await _measureExecutionTime('backup', () => _db.backup());
  }

  @override
  Future<void> clearAll() async {
    await _measureExecutionTime('clearAll', () => _db.clearAll());
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    return await _measureExecutionTime('getContactsByRelationType',
      () => _db.getContactsByRelationType(relationType));
  }

  @override
  Future<int> getDatabaseVersion() async {
    return await _measureExecutionTime('getDatabaseVersion', () => _db.getDatabaseVersion());
  }

  @override
  Future<bool> restore(String path) async {
    return await _measureExecutionTime('restore', () => _db.restore(path));
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _measureExecutionTime('updateHolidayImportance',
      () => _db.updateHolidayImportance(id, importance));
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return await _measureExecutionTime('getLastSyncTime', () => _db.getLastSyncTime());
  }

  @override
  Future<Map<String, dynamic>> getModifiedData(DateTime? since) async {
    return await _measureExecutionTime('getModifiedData', () => _db.getModifiedData(since));
  }

  @override
  Future<bool> isFirstLaunch() async {
    return await _measureExecutionTime('isFirstLaunch', () => _db.isFirstLaunch());
  }

  @override
  Future<bool> isInitialized() async {
    return await _db.isInitialized();
  }

  @override
  Future<void> setFirstLaunch(bool value) async {
    await _measureExecutionTime('setFirstLaunch', () => _db.setFirstLaunch(value));
  }

  @override
  Future<void> updateLastSyncTime(DateTime time) async {
    await _measureExecutionTime('updateLastSyncTime', () => _db.updateLastSyncTime(time));
  }

  @override
  Future<void> setDatabaseVersion(int version) async {
    await _measureExecutionTime('setDatabaseVersion', () => _db.setDatabaseVersion(version));
  }

  @override
  Future<void> performMaintenance() async {
    await _measureExecutionTime('performMaintenance', () => _db.performMaintenance());
  }
}
