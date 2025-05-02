import 'dart:async';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/models/sync/sync_batch.dart';
import 'package:jinlin_app/models/sync/sync_conflict.dart';
import 'package:jinlin_app/models/sync/sync_operation.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/cache/cache_manager.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 缓存数据库适配器
///
/// 包装另一个数据库适配器，添加缓存功能以减少数据库访问
class CachedDatabaseAdapter implements DatabaseInterfaceEnhanced {
  // 日志标签
  static const String _tag = 'CachedDB';

  // 被包装的数据库适配器
  final DatabaseInterfaceEnhanced _db;

  // 缓存名称
  static const String _holidayCache = 'holidays';
  static const String _contactCache = 'contacts';
  static const String _reminderEventCache = 'reminderEvents';
  static const String _userSettingsCache = 'userSettings';
  static const String _syncCache = 'sync';

  // 缓存过期时间（毫秒）
  static const int _shortCacheTime = 1 * 60 * 1000; // 1分钟
  static const int _mediumCacheTime = 5 * 60 * 1000; // 5分钟
  // 长缓存时间（暂未使用，但保留以备将来使用）
  // static const int _longCacheTime = 30 * 60 * 1000; // 30分钟

  // 是否启用缓存
  bool _cacheEnabled = true;

  /// 构造函数
  CachedDatabaseAdapter(this._db) {
    _initializeCaches();
  }

  /// 初始化缓存
  void _initializeCaches() {
    // 创建节日缓存
    cacheManager.createCache(
      _holidayCache,
      capacity: 500,
      strategy: CacheStrategy.leastRecentlyUsed,
    );

    // 创建联系人缓存
    cacheManager.createCache(
      _contactCache,
      capacity: 200,
      strategy: CacheStrategy.leastRecentlyUsed,
    );

    // 创建提醒事件缓存
    cacheManager.createCache(
      _reminderEventCache,
      capacity: 300,
      strategy: CacheStrategy.leastRecentlyUsed,
    );

    // 创建用户设置缓存
    cacheManager.createCache(
      _userSettingsCache,
      capacity: 10,
      strategy: CacheStrategy.leastRecentlyUsed,
    );

    // 创建同步缓存
    cacheManager.createCache(
      _syncCache,
      capacity: 50,
      strategy: CacheStrategy.leastRecentlyUsed,
    );

    logger.i(_tag, '缓存初始化完成');
  }

  /// 启用缓存
  void enableCache() {
    _cacheEnabled = true;
    logger.i(_tag, '缓存已启用');
  }

  /// 禁用缓存
  void disableCache() {
    _cacheEnabled = false;
    logger.i(_tag, '缓存已禁用');
  }

  /// 清除所有缓存
  void clearAllCaches() {
    cacheManager.clearAllCaches();
    logger.i(_tag, '所有缓存已清除');
  }

  /// 清除特定缓存
  void clearCache(String cacheName) {
    cacheManager.clearCache(cacheName);
    logger.i(_tag, '缓存 $cacheName 已清除');
  }

  /// 清除节日缓存
  void clearHolidayCache() {
    clearCache(_holidayCache);
  }

  /// 清除联系人缓存
  void clearContactCache() {
    clearCache(_contactCache);
  }

  /// 清除提醒事件缓存
  void clearReminderEventCache() {
    clearCache(_reminderEventCache);
  }

  /// 清除用户设置缓存
  void clearUserSettingsCache() {
    clearCache(_userSettingsCache);
  }

  /// 清除同步缓存
  void clearSyncCache() {
    clearCache(_syncCache);
  }

  /// 生成缓存键
  String _generateCacheKey(String method, [List<dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return method;
    }

    return '$method:${params.map((p) => p.toString()).join(':')}';
  }

  @override
  Future<void> initialize() async {
    await _db.initialize();
  }

  @override
  Future<void> close() async {
    await _db.close();
    clearAllCaches();
  }

  @override
  Future<void> clearAll() async {
    await _db.clearAll();
    clearAllCaches();
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

  @override
  Future<String> backup() async {
    return _db.backup();
  }

  @override
  Future<bool> restore(String path) async {
    final result = await _db.restore(path);
    if (result) {
      clearAllCaches();
    }
    return result;
  }

  @override
  Future<void> performMaintenance() async {
    await _db.performMaintenance();
  }

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
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    return _db.getSyncConflicts();
  }

  @override
  Future<Map<String, dynamic>?> getSyncConflict(String conflictId) async {
    return _db.getSyncConflict(conflictId);
  }

  @override
  Future<void> saveSyncConflict(SyncConflict conflict) async {
    await _db.saveSyncConflict(conflict);
    clearSyncCache();
  }

  @override
  Future<void> deleteSyncConflict(String conflictId) async {
    await _db.deleteSyncConflict(conflictId);
    clearSyncCache();
  }

  @override
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    await _db.resolveSyncConflict(entityType, id, resolvedData);
    clearSyncCache();

    // 清除相关实体缓存
    switch (entityType) {
      case 'holiday':
        clearHolidayCache();
        break;
      case 'contact':
        clearContactCache();
        break;
      case 'reminder_event':
        clearReminderEventCache();
        break;
    }
  }

  @override
  Future<String?> getAppSetting(String key) async {
    if (!_cacheEnabled) {
      return _db.getAppSetting(key);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getAppSetting', [key]);

    // 尝试从缓存获取
    final cachedValue = cacheManager.get<String>(_userSettingsCache, cacheKey);
    if (cachedValue != null) {
      logger.d(_tag, '从缓存获取应用设置: $key');
      return cachedValue;
    }

    // 从数据库获取
    final value = await _db.getAppSetting(key);

    // 更新缓存
    if (value != null) {
      cacheManager.set<String>(
        _userSettingsCache,
        cacheKey,
        value,
        expireTimeMs: _mediumCacheTime,
      );
    }

    logger.d(_tag, '从数据库获取应用设置: $key');
    return value;
  }

  @override
  Future<void> setAppSetting(String key, String value) async {
    await _db.setAppSetting(key, value);

    // 更新缓存
    if (_cacheEnabled) {
      final cacheKey = _generateCacheKey('getAppSetting', [key]);
      cacheManager.set<String>(
        _userSettingsCache,
        cacheKey,
        value,
        expireTimeMs: _mediumCacheTime,
      );
    }
  }

  // ==================== 同步批次相关操作 ====================

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
    clearSyncCache();
  }

  @override
  Future<void> deleteSyncBatch(String batchId) async {
    await _db.deleteSyncBatch(batchId);
    clearSyncCache();
  }

  // ==================== 同步操作相关操作 ====================

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
    clearSyncCache();
  }

  @override
  Future<void> deleteSyncOperation(String operationId) async {
    await _db.deleteSyncOperation(operationId);
    clearSyncCache();
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncConflictsLegacy() async {
    return _db.getSyncConflictsLegacy();
  }

  // ==================== 节日相关操作 ====================

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _db.saveHoliday(holiday);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearHolidayCache();
    }
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _db.saveHolidays(holidays);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearHolidayCache();
    }
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    if (!_cacheEnabled) {
      return _db.getAllHolidays();
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getAllHolidays');

    // 尝试从缓存获取
    final cachedHolidays = cacheManager.get<List<Holiday>>(_holidayCache, cacheKey);
    if (cachedHolidays != null) {
      logger.d(_tag, '从缓存获取所有节日: ${cachedHolidays.length} 个');
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = await _db.getAllHolidays();

    // 更新缓存
    cacheManager.set<List<Holiday>>(
      _holidayCache,
      cacheKey,
      holidays,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取所有节日: ${holidays.length} 个');
    return holidays;
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    if (!_cacheEnabled) {
      return _db.getHolidayById(id);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getHolidayById', [id]);

    // 尝试从缓存获取
    final cachedHoliday = cacheManager.get<Holiday>(_holidayCache, cacheKey);
    if (cachedHoliday != null) {
      logger.d(_tag, '从缓存获取节日: $id');
      return cachedHoliday;
    }

    // 从数据库获取
    final holiday = await _db.getHolidayById(id);

    // 更新缓存
    if (holiday != null) {
      cacheManager.set<Holiday>(
        _holidayCache,
        cacheKey,
        holiday,
        expireTimeMs: _mediumCacheTime,
      );
    }

    logger.d(_tag, '从数据库获取节日: $id');
    return holiday;
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    if (!_cacheEnabled) {
      return _db.getHolidaysByRegion(region, languageCode: languageCode);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getHolidaysByRegion', [region, languageCode]);

    // 尝试从缓存获取
    final cachedHolidays = cacheManager.get<List<Holiday>>(_holidayCache, cacheKey);
    if (cachedHolidays != null) {
      logger.d(_tag, '从缓存获取地区节日: $region, $languageCode, ${cachedHolidays.length} 个');
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = await _db.getHolidaysByRegion(region, languageCode: languageCode);

    // 更新缓存
    cacheManager.set<List<Holiday>>(
      _holidayCache,
      cacheKey,
      holidays,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取地区节日: $region, $languageCode, ${holidays.length} 个');
    return holidays;
  }

  @override
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    if (!_cacheEnabled) {
      return _db.getHolidaysByType(type);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getHolidaysByType', [type.index]);

    // 尝试从缓存获取
    final cachedHolidays = cacheManager.get<List<Holiday>>(_holidayCache, cacheKey);
    if (cachedHolidays != null) {
      logger.d(_tag, '从缓存获取类型节日: ${type.toString()}, ${cachedHolidays.length} 个');
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = await _db.getHolidaysByType(type);

    // 更新缓存
    cacheManager.set<List<Holiday>>(
      _holidayCache,
      cacheKey,
      holidays,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取类型节日: ${type.toString()}, ${holidays.length} 个');
    return holidays;
  }

  @override
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    if (!_cacheEnabled) {
      return _db.searchHolidays(query, languageCode: languageCode);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('searchHolidays', [query, languageCode]);

    // 尝试从缓存获取
    final cachedHolidays = cacheManager.get<List<Holiday>>(_holidayCache, cacheKey);
    if (cachedHolidays != null) {
      logger.d(_tag, '从缓存获取搜索节日: $query, $languageCode, ${cachedHolidays.length} 个');
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = await _db.searchHolidays(query, languageCode: languageCode);

    // 更新缓存
    cacheManager.set<List<Holiday>>(
      _holidayCache,
      cacheKey,
      holidays,
      expireTimeMs: _shortCacheTime, // 搜索结果缓存时间较短
    );

    logger.d(_tag, '从数据库获取搜索节日: $query, $languageCode, ${holidays.length} 个');
    return holidays;
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _db.deleteHoliday(id);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearHolidayCache();
    }
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _db.updateHolidayImportance(id, importance);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除特定节日缓存
      final cacheKey = _generateCacheKey('getHolidayById', [id]);
      cacheManager.remove(_holidayCache, cacheKey);

      // 清除可能包含该节日的列表缓存
      clearHolidayCache();
    }
  }

  // ==================== 联系人相关操作 ====================

  @override
  Future<void> saveContact(ContactModel contact) async {
    await _db.saveContact(contact);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearContactCache();
    }
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    await _db.saveContacts(contacts);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearContactCache();
    }
  }

  @override
  Future<List<ContactModel>> getAllContacts() async {
    if (!_cacheEnabled) {
      return _db.getAllContacts();
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getAllContacts');

    // 尝试从缓存获取
    final cachedContacts = cacheManager.get<List<ContactModel>>(_contactCache, cacheKey);
    if (cachedContacts != null) {
      logger.d(_tag, '从缓存获取所有联系人: ${cachedContacts.length} 个');
      return cachedContacts;
    }

    // 从数据库获取
    final contacts = await _db.getAllContacts();

    // 更新缓存
    cacheManager.set<List<ContactModel>>(
      _contactCache,
      cacheKey,
      contacts,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取所有联系人: ${contacts.length} 个');
    return contacts;
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    if (!_cacheEnabled) {
      return _db.getContactById(id);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getContactById', [id]);

    // 尝试从缓存获取
    final cachedContact = cacheManager.get<ContactModel>(_contactCache, cacheKey);
    if (cachedContact != null) {
      logger.d(_tag, '从缓存获取联系人: $id');
      return cachedContact;
    }

    // 从数据库获取
    final contact = await _db.getContactById(id);

    // 更新缓存
    if (contact != null) {
      cacheManager.set<ContactModel>(
        _contactCache,
        cacheKey,
        contact,
        expireTimeMs: _mediumCacheTime,
      );
    }

    logger.d(_tag, '从数据库获取联系人: $id');
    return contact;
  }

  @override
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    if (!_cacheEnabled) {
      return _db.getContactsByRelationType(relationType);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getContactsByRelationType', [relationType.index]);

    // 尝试从缓存获取
    final cachedContacts = cacheManager.get<List<ContactModel>>(_contactCache, cacheKey);
    if (cachedContacts != null) {
      logger.d(_tag, '从缓存获取关系类型联系人: ${relationType.toString()}, ${cachedContacts.length} 个');
      return cachedContacts;
    }

    // 从数据库获取
    final contacts = await _db.getContactsByRelationType(relationType);

    // 更新缓存
    cacheManager.set<List<ContactModel>>(
      _contactCache,
      cacheKey,
      contacts,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取关系类型联系人: ${relationType.toString()}, ${contacts.length} 个');
    return contacts;
  }

  @override
  Future<List<ContactModel>> searchContacts(String query) async {
    if (!_cacheEnabled) {
      return _db.searchContacts(query);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('searchContacts', [query]);

    // 尝试从缓存获取
    final cachedContacts = cacheManager.get<List<ContactModel>>(_contactCache, cacheKey);
    if (cachedContacts != null) {
      logger.d(_tag, '从缓存获取搜索联系人: $query, ${cachedContacts.length} 个');
      return cachedContacts;
    }

    // 从数据库获取
    final contacts = await _db.searchContacts(query);

    // 更新缓存
    cacheManager.set<List<ContactModel>>(
      _contactCache,
      cacheKey,
      contacts,
      expireTimeMs: _shortCacheTime, // 搜索结果缓存时间较短
    );

    logger.d(_tag, '从数据库获取搜索联系人: $query, ${contacts.length} 个');
    return contacts;
  }

  @override
  Future<void> deleteContact(String id) async {
    await _db.deleteContact(id);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearContactCache();
    }
  }

  // ==================== 提醒事件相关操作 ====================

  @override
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    await _db.saveReminderEvent(event);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearReminderEventCache();
    }
  }

  @override
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    await _db.saveReminderEvents(events);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearReminderEventCache();
    }
  }

  @override
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    if (!_cacheEnabled) {
      return _db.getAllReminderEvents();
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getAllReminderEvents');

    // 尝试从缓存获取
    final cachedEvents = cacheManager.get<List<ReminderEventModel>>(_reminderEventCache, cacheKey);
    if (cachedEvents != null) {
      logger.d(_tag, '从缓存获取所有提醒事件: ${cachedEvents.length} 个');
      return cachedEvents;
    }

    // 从数据库获取
    final events = await _db.getAllReminderEvents();

    // 更新缓存
    cacheManager.set<List<ReminderEventModel>>(
      _reminderEventCache,
      cacheKey,
      events,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取所有提醒事件: ${events.length} 个');
    return events;
  }

  @override
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    if (!_cacheEnabled) {
      return _db.getReminderEventById(id);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getReminderEventById', [id]);

    // 尝试从缓存获取
    final cachedEvent = cacheManager.get<ReminderEventModel>(_reminderEventCache, cacheKey);
    if (cachedEvent != null) {
      logger.d(_tag, '从缓存获取提醒事件: $id');
      return cachedEvent;
    }

    // 从数据库获取
    final event = await _db.getReminderEventById(id);

    // 更新缓存
    if (event != null) {
      cacheManager.set<ReminderEventModel>(
        _reminderEventCache,
        cacheKey,
        event,
        expireTimeMs: _mediumCacheTime,
      );
    }

    logger.d(_tag, '从数据库获取提醒事件: $id');
    return event;
  }

  @override
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    if (!_cacheEnabled) {
      return _db.getUpcomingReminderEvents(days);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getUpcomingReminderEvents', [days]);

    // 尝试从缓存获取
    final cachedEvents = cacheManager.get<List<ReminderEventModel>>(_reminderEventCache, cacheKey);
    if (cachedEvents != null) {
      logger.d(_tag, '从缓存获取即将到来的提醒事件: $days 天内, ${cachedEvents.length} 个');
      return cachedEvents;
    }

    // 从数据库获取
    final events = await _db.getUpcomingReminderEvents(days);

    // 更新缓存
    cacheManager.set<List<ReminderEventModel>>(
      _reminderEventCache,
      cacheKey,
      events,
      expireTimeMs: _shortCacheTime, // 即将到来的事件可能会变化，缓存时间较短
    );

    logger.d(_tag, '从数据库获取即将到来的提醒事件: $days 天内, ${events.length} 个');
    return events;
  }

  @override
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    if (!_cacheEnabled) {
      return _db.getExpiredReminderEvents();
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getExpiredReminderEvents');

    // 尝试从缓存获取
    final cachedEvents = cacheManager.get<List<ReminderEventModel>>(_reminderEventCache, cacheKey);
    if (cachedEvents != null) {
      logger.d(_tag, '从缓存获取已过期的提醒事件: ${cachedEvents.length} 个');
      return cachedEvents;
    }

    // 从数据库获取
    final events = await _db.getExpiredReminderEvents();

    // 更新缓存
    cacheManager.set<List<ReminderEventModel>>(
      _reminderEventCache,
      cacheKey,
      events,
      expireTimeMs: _shortCacheTime, // 过期事件可能会变化，缓存时间较短
    );

    logger.d(_tag, '从数据库获取已过期的提醒事件: ${events.length} 个');
    return events;
  }

  @override
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    if (!_cacheEnabled) {
      return _db.getReminderEventsByType(type);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getReminderEventsByType', [type.index]);

    // 尝试从缓存获取
    final cachedEvents = cacheManager.get<List<ReminderEventModel>>(_reminderEventCache, cacheKey);
    if (cachedEvents != null) {
      logger.d(_tag, '从缓存获取类型提醒事件: ${type.toString()}, ${cachedEvents.length} 个');
      return cachedEvents;
    }

    // 从数据库获取
    final events = await _db.getReminderEventsByType(type);

    // 更新缓存
    cacheManager.set<List<ReminderEventModel>>(
      _reminderEventCache,
      cacheKey,
      events,
      expireTimeMs: _mediumCacheTime,
    );

    logger.d(_tag, '从数据库获取类型提醒事件: ${type.toString()}, ${events.length} 个');
    return events;
  }

  @override
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    if (!_cacheEnabled) {
      return _db.searchReminderEvents(query);
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('searchReminderEvents', [query]);

    // 尝试从缓存获取
    final cachedEvents = cacheManager.get<List<ReminderEventModel>>(_reminderEventCache, cacheKey);
    if (cachedEvents != null) {
      logger.d(_tag, '从缓存获取搜索提醒事件: $query, ${cachedEvents.length} 个');
      return cachedEvents;
    }

    // 从数据库获取
    final events = await _db.searchReminderEvents(query);

    // 更新缓存
    cacheManager.set<List<ReminderEventModel>>(
      _reminderEventCache,
      cacheKey,
      events,
      expireTimeMs: _shortCacheTime, // 搜索结果缓存时间较短
    );

    logger.d(_tag, '从数据库获取搜索提醒事件: $query, ${events.length} 个');
    return events;
  }

  @override
  Future<void> deleteReminderEvent(String id) async {
    await _db.deleteReminderEvent(id);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearReminderEventCache();
    }
  }

  @override
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _db.updateReminderEventStatus(id, status);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除特定提醒事件缓存
      final cacheKey = _generateCacheKey('getReminderEventById', [id]);
      cacheManager.remove(_reminderEventCache, cacheKey);

      // 清除可能包含该提醒事件的列表缓存
      clearReminderEventCache();
    }
  }

  // ==================== 用户设置相关操作 ====================

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _db.saveUserSettings(settings);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearUserSettingsCache();
    }
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    if (!_cacheEnabled) {
      return _db.getUserSettings();
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey('getUserSettings');

    // 尝试从缓存获取
    final cachedSettings = cacheManager.get<UserSettingsModel>(_userSettingsCache, cacheKey);
    if (cachedSettings != null) {
      logger.d(_tag, '从缓存获取用户设置');
      return cachedSettings;
    }

    // 从数据库获取
    final settings = await _db.getUserSettings();

    // 更新缓存
    if (settings != null) {
      cacheManager.set<UserSettingsModel>(
        _userSettingsCache,
        cacheKey,
        settings,
        expireTimeMs: _mediumCacheTime,
      );
    }

    logger.d(_tag, '从数据库获取用户设置');
    return settings;
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _db.updateUserSettings(updates);

    // 更新缓存
    if (_cacheEnabled) {
      // 清除可能受影响的缓存
      clearUserSettingsCache();
    }
  }

  @override
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _db.markSyncConflict(entityType, id, isConflict);

    // 更新缓存
    if (_cacheEnabled) {
      // 根据实体类型清除相应的缓存
      switch (entityType) {
        case 'holiday':
          clearHolidayCache();
          break;
        case 'contact':
          clearContactCache();
          break;
        case 'reminder_event':
          clearReminderEventCache();
          break;
      }

      // 清除同步缓存
      clearSyncCache();
    }
  }


}
