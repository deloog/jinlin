import 'dart:convert';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/encryption/encryption_service.dart' hide logger;
import 'package:jinlin_app/utils/logger.dart';

/// 加密数据库适配器
///
/// 包装另一个数据库适配器，添加数据加密和解密功能
class EncryptedDatabaseAdapter implements DatabaseInterfaceEnhanced {
  // 日志标签
  static const String _tag = 'EncryptedDB';

  // 被包装的数据库适配器
  final DatabaseInterfaceEnhanced _db;

  // 加密服务
  final EncryptionService _encryptionService;

  // 是否启用加密
  bool _encryptionEnabled = true;

  // 需要加密的字段
  static const List<String> _sensitiveFields = [
    'phoneNumber',
    'email',
    'birthday',
    'additionalInfo',
    'location',
    'latitude',
    'longitude',
    'description',
    'aiGeneratedDescription',
    'aiGeneratedGreetings',
    'aiGeneratedGiftSuggestions',
  ];

  /// 构造函数
  EncryptedDatabaseAdapter(this._db, {EncryptionService? encryptionService})
      : _encryptionService = encryptionService ?? EncryptionService();

  /// 初始化
  @override
  Future<void> initialize() async {
    // 初始化加密服务
    await _encryptionService.initialize();

    // 初始化数据库
    await _db.initialize();
  }

  /// 启用加密
  void enableEncryption() {
    _encryptionEnabled = true;
    logger.i(_tag, '加密已启用');
  }

  /// 禁用加密
  void disableEncryption() {
    _encryptionEnabled = false;
    logger.i(_tag, '加密已禁用');
  }

  /// 获取是否启用加密
  bool isEncryptionEnabled() {
    return _encryptionEnabled;
  }

  /// 重置加密服务
  Future<void> resetEncryption() async {
    await _encryptionService.reset();
    logger.i(_tag, '加密服务已重置');
  }

  /// 加密敏感字段
  Map<String, dynamic> _encryptSensitiveFields(Map<String, dynamic> data) {
    if (!_encryptionEnabled) {
      return data;
    }

    final encryptedData = Map<String, dynamic>.from(data);

    for (final field in _sensitiveFields) {
      if (encryptedData.containsKey(field) && encryptedData[field] != null) {
        if (encryptedData[field] is String) {
          // 加密字符串
          encryptedData[field] = _encryptionService.encrypt(encryptedData[field] as String);
        } else if (encryptedData[field] is Map) {
          // 加密Map
          encryptedData[field] = _encryptionService.encryptMap(encryptedData[field] as Map<String, dynamic>);
        } else if (encryptedData[field] is List) {
          // 加密List
          encryptedData[field] = _encryptionService.encryptList(encryptedData[field] as List<dynamic>);
        }
      }
    }

    return encryptedData;
  }

  /// 解密敏感字段
  Map<String, dynamic> _decryptSensitiveFields(Map<String, dynamic> data) {
    if (!_encryptionEnabled) {
      return data;
    }

    final decryptedData = Map<String, dynamic>.from(data);

    for (final field in _sensitiveFields) {
      if (decryptedData.containsKey(field) && decryptedData[field] != null) {
        try {
          if (decryptedData[field] is String) {
            // 尝试解密字符串
            final decrypted = _encryptionService.decrypt(decryptedData[field] as String);

            // 尝试解析为JSON
            try {
              final json = jsonDecode(decrypted);
              if (json is Map) {
                decryptedData[field] = json;
              } else if (json is List) {
                decryptedData[field] = json;
              } else {
                decryptedData[field] = decrypted;
              }
            } catch (_) {
              // 不是JSON，保持为字符串
              decryptedData[field] = decrypted;
            }
          }
        } catch (e) {
          // 解密失败，保持原样
          logger.w(_tag, '解密字段失败: $field', error: e);
        }
      }
    }

    return decryptedData;
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
    // 转换为Map
    final holidayMap = holiday.toMap();

    // 加密敏感字段
    final encryptedMap = _encryptSensitiveFields(holidayMap);

    // 转换回Holiday
    final encryptedHoliday = Holiday.fromMap(encryptedMap);

    // 保存加密后的节日
    await _db.saveHoliday(encryptedHoliday);
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    // 加密每个节日
    final encryptedHolidays = <Holiday>[];

    for (final holiday in holidays) {
      // 转换为Map
      final holidayMap = holiday.toMap();

      // 加密敏感字段
      final encryptedMap = _encryptSensitiveFields(holidayMap);

      // 转换回Holiday
      final encryptedHoliday = Holiday.fromMap(encryptedMap);

      encryptedHolidays.add(encryptedHoliday);
    }

    // 保存加密后的节日
    await _db.saveHolidays(encryptedHolidays);
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    // 获取所有节日
    final holidays = await _db.getAllHolidays();

    // 解密每个节日
    final decryptedHolidays = <Holiday>[];

    for (final holiday in holidays) {
      // 转换为Map
      final holidayMap = holiday.toMap();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(holidayMap);

      // 转换回Holiday
      final decryptedHoliday = Holiday.fromMap(decryptedMap);

      decryptedHolidays.add(decryptedHoliday);
    }

    return decryptedHolidays;
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    // 获取节日
    final holiday = await _db.getHolidayById(id);

    if (holiday == null) {
      return null;
    }

    // 转换为Map
    final holidayMap = holiday.toMap();

    // 解密敏感字段
    final decryptedMap = _decryptSensitiveFields(holidayMap);

    // 转换回Holiday
    return Holiday.fromMap(decryptedMap);
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    // 获取节日
    final holidays = await _db.getHolidaysByRegion(region, languageCode: languageCode);

    // 解密每个节日
    final decryptedHolidays = <Holiday>[];

    for (final holiday in holidays) {
      // 转换为Map
      final holidayMap = holiday.toMap();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(holidayMap);

      // 转换回Holiday
      final decryptedHoliday = Holiday.fromMap(decryptedMap);

      decryptedHolidays.add(decryptedHoliday);
    }

    return decryptedHolidays;
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    // 获取节日
    final holidays = await _db.getHolidaysByType(type);

    // 解密每个节日
    final decryptedHolidays = <Holiday>[];

    for (final holiday in holidays) {
      // 转换为Map
      final holidayMap = holiday.toMap();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(holidayMap);

      // 转换回Holiday
      final decryptedHoliday = Holiday.fromMap(decryptedMap);

      decryptedHolidays.add(decryptedHoliday);
    }

    return decryptedHolidays;
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    // 获取节日
    final holidays = await _db.searchHolidays(query, languageCode: languageCode);

    // 解密每个节日
    final decryptedHolidays = <Holiday>[];

    for (final holiday in holidays) {
      // 转换为Map
      final holidayMap = holiday.toMap();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(holidayMap);

      // 转换回Holiday
      final decryptedHoliday = Holiday.fromMap(decryptedMap);

      decryptedHolidays.add(decryptedHoliday);
    }

    return decryptedHolidays;
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
    // 转换为Map
    final contactMap = contact.toJson();

    // 加密敏感字段
    final encryptedMap = _encryptSensitiveFields(contactMap);

    // 转换回ContactModel
    final encryptedContact = ContactModel.fromJson(encryptedMap);

    // 保存加密后的联系人
    await _db.saveContact(encryptedContact);
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    // 加密每个联系人
    final encryptedContacts = <ContactModel>[];

    for (final contact in contacts) {
      // 转换为Map
      final contactMap = contact.toJson();

      // 加密敏感字段
      final encryptedMap = _encryptSensitiveFields(contactMap);

      // 转换回ContactModel
      final encryptedContact = ContactModel.fromJson(encryptedMap);

      encryptedContacts.add(encryptedContact);
    }

    // 保存加密后的联系人
    await _db.saveContacts(encryptedContacts);
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    // 获取所有联系人
    final contacts = await _db.getAllContacts();

    // 解密每个联系人
    final decryptedContacts = <ContactModel>[];

    for (final contact in contacts) {
      // 转换为Map
      final contactMap = contact.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(contactMap);

      // 转换回ContactModel
      final decryptedContact = ContactModel.fromJson(decryptedMap);

      decryptedContacts.add(decryptedContact);
    }

    return decryptedContacts;
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    // 获取联系人
    final contact = await _db.getContactById(id);

    if (contact == null) {
      return null;
    }

    // 转换为Map
    final contactMap = contact.toJson();

    // 解密敏感字段
    final decryptedMap = _decryptSensitiveFields(contactMap);

    // 转换回ContactModel
    return ContactModel.fromJson(decryptedMap);
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    // 获取联系人
    final contacts = await _db.getContactsByRelationType(relationType);

    // 解密每个联系人
    final decryptedContacts = <ContactModel>[];

    for (final contact in contacts) {
      // 转换为Map
      final contactMap = contact.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(contactMap);

      // 转换回ContactModel
      final decryptedContact = ContactModel.fromJson(decryptedMap);

      decryptedContacts.add(decryptedContact);
    }

    return decryptedContacts;
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    // 获取联系人
    final contacts = await _db.searchContacts(query);

    // 解密每个联系人
    final decryptedContacts = <ContactModel>[];

    for (final contact in contacts) {
      // 转换为Map
      final contactMap = contact.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(contactMap);

      // 转换回ContactModel
      final decryptedContact = ContactModel.fromJson(decryptedMap);

      decryptedContacts.add(decryptedContact);
    }

    return decryptedContacts;
  }

  @override
  Future<void> deleteContact(String id) async {
    await _db.deleteContact(id);
  }

  // ==================== 提醒事件相关操作 ====================

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    // 转换为Map
    final eventMap = event.toJson();

    // 加密敏感字段
    final encryptedMap = _encryptSensitiveFields(eventMap);

    // 转换回ReminderEventModel
    final encryptedEvent = ReminderEventModel.fromJson(encryptedMap);

    // 保存加密后的提醒事件
    await _db.saveReminderEvent(encryptedEvent);
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    // 加密每个提醒事件
    final encryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 加密敏感字段
      final encryptedMap = _encryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final encryptedEvent = ReminderEventModel.fromJson(encryptedMap);

      encryptedEvents.add(encryptedEvent);
    }

    // 保存加密后的提醒事件
    await _db.saveReminderEvents(encryptedEvents);
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    // 获取所有提醒事件
    final events = await _db.getAllReminderEvents();

    // 解密每个提醒事件
    final decryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final decryptedEvent = ReminderEventModel.fromJson(decryptedMap);

      decryptedEvents.add(decryptedEvent);
    }

    return decryptedEvents;
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    // 获取提醒事件
    final event = await _db.getReminderEventById(id);

    if (event == null) {
      return null;
    }

    // 转换为Map
    final eventMap = event.toJson();

    // 解密敏感字段
    final decryptedMap = _decryptSensitiveFields(eventMap);

    // 转换回ReminderEventModel
    return ReminderEventModel.fromJson(decryptedMap);
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    // 获取提醒事件
    final events = await _db.getUpcomingReminderEvents(days);

    // 解密每个提醒事件
    final decryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final decryptedEvent = ReminderEventModel.fromJson(decryptedMap);

      decryptedEvents.add(decryptedEvent);
    }

    return decryptedEvents;
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    // 获取提醒事件
    final events = await _db.getExpiredReminderEvents();

    // 解密每个提醒事件
    final decryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final decryptedEvent = ReminderEventModel.fromJson(decryptedMap);

      decryptedEvents.add(decryptedEvent);
    }

    return decryptedEvents;
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    // 获取提醒事件
    final events = await _db.getReminderEventsByType(type);

    // 解密每个提醒事件
    final decryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final decryptedEvent = ReminderEventModel.fromJson(decryptedMap);

      decryptedEvents.add(decryptedEvent);
    }

    return decryptedEvents;
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    // 获取提醒事件
    final events = await _db.searchReminderEvents(query);

    // 解密每个提醒事件
    final decryptedEvents = <ReminderEventModel>[];

    for (final event in events) {
      // 转换为Map
      final eventMap = event.toJson();

      // 解密敏感字段
      final decryptedMap = _decryptSensitiveFields(eventMap);

      // 转换回ReminderEventModel
      final decryptedEvent = ReminderEventModel.fromJson(decryptedMap);

      decryptedEvents.add(decryptedEvent);
    }

    return decryptedEvents;
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
    // 转换为Map
    final settingsMap = settings.toJson();

    // 加密敏感字段
    final encryptedMap = _encryptSensitiveFields(settingsMap);

    // 转换回UserSettingsModel
    final encryptedSettings = UserSettingsModel.fromJson(encryptedMap);

    // 保存加密后的用户设置
    await _db.saveUserSettings(encryptedSettings);
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    // 获取用户设置
    final settings = await _db.getUserSettings();

    if (settings == null) {
      return null;
    }

    // 转换为Map
    final settingsMap = settings.toJson();

    // 解密敏感字段
    final decryptedMap = _decryptSensitiveFields(settingsMap);

    // 转换回UserSettingsModel
    return UserSettingsModel.fromJson(decryptedMap);
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    // 加密敏感字段
    final encryptedUpdates = _encryptSensitiveFields(updates);

    // 更新用户设置
    await _db.updateUserSettings(encryptedUpdates);
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
    // 获取修改的数据
    final modifiedData = await _db.getModifiedData(since);

    // 解密数据
    final decryptedData = <String, dynamic>{};

    // 解密节日
    if (modifiedData.containsKey('holidays')) {
      final holidays = modifiedData['holidays'] as List<dynamic>;
      final decryptedHolidays = <Map<String, dynamic>>[];

      for (final holiday in holidays) {
        final holidayMap = holiday as Map<String, dynamic>;
        final decryptedMap = _decryptSensitiveFields(holidayMap);
        decryptedHolidays.add(decryptedMap);
      }

      decryptedData['holidays'] = decryptedHolidays;
    }

    // 解密联系人
    if (modifiedData.containsKey('contacts')) {
      final contacts = modifiedData['contacts'] as List<dynamic>;
      final decryptedContacts = <Map<String, dynamic>>[];

      for (final contact in contacts) {
        final contactMap = contact as Map<String, dynamic>;
        final decryptedMap = _decryptSensitiveFields(contactMap);
        decryptedContacts.add(decryptedMap);
      }

      decryptedData['contacts'] = decryptedContacts;
    }

    // 解密提醒事件
    if (modifiedData.containsKey('reminderEvents')) {
      final events = modifiedData['reminderEvents'] as List<dynamic>;
      final decryptedEvents = <Map<String, dynamic>>[];

      for (final event in events) {
        final eventMap = event as Map<String, dynamic>;
        final decryptedMap = _decryptSensitiveFields(eventMap);
        decryptedEvents.add(decryptedMap);
      }

      decryptedData['reminderEvents'] = decryptedEvents;
    }

    // 解密用户设置
    if (modifiedData.containsKey('userSettings')) {
      final settings = modifiedData['userSettings'] as Map<String, dynamic>;
      final decryptedSettings = _decryptSensitiveFields(settings);
      decryptedData['userSettings'] = decryptedSettings;
    }

    // 复制其他数据
    for (final key in modifiedData.keys) {
      if (!decryptedData.containsKey(key)) {
        decryptedData[key] = modifiedData[key];
      }
    }

    return decryptedData;
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _db.markSyncConflict(entityType, id, isConflict);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    // 获取同步冲突
    final conflicts = await _db.getSyncConflicts();

    // 解密每个冲突
    final decryptedConflicts = <Map<String, dynamic>>[];

    for (final conflict in conflicts) {
      final decryptedConflict = _decryptSensitiveFields(conflict);
      decryptedConflicts.add(decryptedConflict);
    }

    return decryptedConflicts;
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    // 加密解决的数据
    dynamic encryptedData = resolvedData;

    if (resolvedData is Map<String, dynamic>) {
      encryptedData = _encryptSensitiveFields(resolvedData);
    } else if (resolvedData is Holiday) {
      final holidayMap = resolvedData.toMap();
      final encryptedMap = _encryptSensitiveFields(holidayMap);
      encryptedData = Holiday.fromMap(encryptedMap);
    } else if (resolvedData is ContactModel) {
      final contactMap = resolvedData.toJson();
      final encryptedMap = _encryptSensitiveFields(contactMap);
      encryptedData = ContactModel.fromJson(encryptedMap);
    } else if (resolvedData is ReminderEventModel) {
      final eventMap = resolvedData.toJson();
      final encryptedMap = _encryptSensitiveFields(eventMap);
      encryptedData = ReminderEventModel.fromJson(encryptedMap);
    } else if (resolvedData is UserSettingsModel) {
      final settingsMap = resolvedData.toJson();
      final encryptedMap = _encryptSensitiveFields(settingsMap);
      encryptedData = UserSettingsModel.fromJson(encryptedMap);
    }

    // 解决同步冲突
    await _db.resolveSyncConflict(entityType, id, encryptedData);
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
