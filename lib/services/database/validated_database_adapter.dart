import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/validation/validation_service.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 验证数据库适配器
///
/// 包装另一个数据库适配器，在数据库操作前验证数据
class ValidatedDatabaseAdapter implements DatabaseInterfaceEnhanced {
  // 日志标签
  static const String _tag = 'ValidatedDB';

  // 被包装的数据库适配器
  final DatabaseInterfaceEnhanced _db;

  // 验证服务
  final ValidationService _validationService;

  // 是否启用验证
  bool _validationEnabled = true;

  /// 构造函数
  ValidatedDatabaseAdapter(this._db, {ValidationService? validationService})
      : _validationService = validationService ?? ValidationService();

  /// 启用验证
  void enableValidation() {
    _validationEnabled = true;
    _validationService.enableValidation();
    logger.i(_tag, '验证已启用');
  }

  /// 禁用验证
  void disableValidation() {
    _validationEnabled = false;
    _validationService.disableValidation();
    logger.i(_tag, '验证已禁用');
  }

  /// 启用异常
  void enableExceptions() {
    _validationService.enableExceptions();
    logger.i(_tag, '验证异常已启用');
  }

  /// 禁用异常
  void disableExceptions() {
    _validationService.disableExceptions();
    logger.i(_tag, '验证异常已禁用');
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
    if (_validationEnabled) {
      // 验证节日
      _validationService.validateHoliday(holiday);
    }

    await _db.saveHoliday(holiday);
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    if (_validationEnabled) {
      // 验证所有节日
      for (final holiday in holidays) {
        _validationService.validateHoliday(holiday);
      }
    }

    await _db.saveHolidays(holidays);
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    return _db.getAllHolidays();
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    return _db.getHolidayById(id);
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    return _db.getHolidaysByRegion(region, languageCode: languageCode);
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    return _db.getHolidaysByType(type);
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    return _db.searchHolidays(query, languageCode: languageCode);
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _db.deleteHoliday(id);
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _db.updateHolidayImportance(id, importance);
  }

  // ==================== 联系人相关操作 ====================

  @override
  Future<void> saveContact(ContactModel contact) async {
    if (_validationEnabled) {
      // 验证联系人
      _validationService.validateContact(contact);
    }

    await _db.saveContact(contact);
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    if (_validationEnabled) {
      // 验证所有联系人
      for (final contact in contacts) {
        _validationService.validateContact(contact);
      }
    }

    await _db.saveContacts(contacts);
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    return _db.getAllContacts();
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    return _db.getContactById(id);
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    return _db.getContactsByRelationType(relationType);
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    return _db.searchContacts(query);
  }

  @override
  Future<void> deleteContact(String id) async {
    await _db.deleteContact(id);
  }

  // ==================== 提醒事件相关操作 ====================

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    if (_validationEnabled) {
      // 验证提醒事件
      _validationService.validateReminderEvent(event);
    }

    await _db.saveReminderEvent(event);
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    if (_validationEnabled) {
      // 验证所有提醒事件
      for (final event in events) {
        _validationService.validateReminderEvent(event);
      }
    }

    await _db.saveReminderEvents(events);
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    return _db.getAllReminderEvents();
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    return _db.getReminderEventById(id);
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    return _db.getUpcomingReminderEvents(days);
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    return _db.getExpiredReminderEvents();
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    return _db.getReminderEventsByType(type);
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    return _db.searchReminderEvents(query);
  }

  @override
  Future<void> deleteReminderEvent(String id) async {
    await _db.deleteReminderEvent(id);
  }

  @override
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _db.updateReminderEventStatus(id, status);
  }

  // ==================== 用户设置相关操作 ====================

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    if (_validationEnabled) {
      // 验证用户设置
      _validationService.validateUserSettings(settings);
    }

    await _db.saveUserSettings(settings);
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    return _db.getUserSettings();
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    // 这里无法验证部分更新，因为我们没有完整的用户设置对象
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
    return _db.getModifiedData(since);
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _db.markSyncConflict(entityType, id, isConflict);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    return _db.getSyncConflicts();
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    // 这里可以根据实体类型验证解决的数据
    if (_validationEnabled && resolvedData != null) {
      switch (entityType) {
        case 'holiday':
          if (resolvedData is Holiday) {
            _validationService.validateHoliday(resolvedData);
          }
          break;
        case 'contact':
          if (resolvedData is ContactModel) {
            _validationService.validateContact(resolvedData);
          }
          break;
        case 'reminder_event':
          if (resolvedData is ReminderEventModel) {
            _validationService.validateReminderEvent(resolvedData);
          }
          break;
      }
    }

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
