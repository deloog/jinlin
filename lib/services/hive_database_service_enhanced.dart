import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/holiday_cache_service_enhanced.dart';

/// 增强版Hive数据库服务
///
/// 提供对所有数据模型的CRUD操作和高级查询功能
class HiveDatabaseServiceEnhanced {
  // 单例模式
  static final HiveDatabaseServiceEnhanced _instance = HiveDatabaseServiceEnhanced._internal();
  factory HiveDatabaseServiceEnhanced() => _instance;
  HiveDatabaseServiceEnhanced._internal();

  // 数据库是否已初始化
  bool _isInitialized = false;

  // 获取数据库初始化状态
  bool get isInitialized => _isInitialized;

  // 数据库盒子
  Box<HolidayModelExtended>? _holidaysBox;
  Box<ContactModel>? _contactsBox;
  Box<UserSettingsModel>? _userSettingsBox;
  Box<ReminderEventModel>? _reminderEventsBox;

  /// 初始化数据库
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化Hive
      await Hive.initFlutter();

      // 注册适配器
      _registerAdapters();

      // 打开盒子
      _holidaysBox = await Hive.openBox<HolidayModelExtended>('holidays_extended');
      _contactsBox = await Hive.openBox<ContactModel>('contacts');
      _userSettingsBox = await Hive.openBox<UserSettingsModel>('user_settings');
      _reminderEventsBox = await Hive.openBox<ReminderEventModel>('reminder_events');

      _isInitialized = true;
      debugPrint('增强版Hive数据库服务初始化成功');
    } catch (e) {
      debugPrint('增强版Hive数据库服务初始化失败: $e');
      rethrow;
    }
  }

  /// 注册适配器
  void _registerAdapters() {
    // 注册HolidayModelExtended适配器
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(HolidayModelExtendedAdapter());
    }

    // 注册ContactModel适配器
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(RelationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(ContactModelAdapter());
    }

    // 注册UserSettingsModel适配器
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(AppThemeModeAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(ReminderAdvanceTimeAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(UserSettingsModelAdapter());
    }

    // 注册ReminderEventModel适配器
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(ReminderEventTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(ReminderStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(ReminderEventModelAdapter());
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    await _holidaysBox?.close();
    await _contactsBox?.close();
    await _userSettingsBox?.close();
    await _reminderEventsBox?.close();
    _isInitialized = false;
  }

  // ==================== 节日相关操作 ====================

  /// 保存节日
  Future<void> saveHoliday(HolidayModelExtended holiday) async {
    _checkInitialized();

    // 更新最后修改时间
    final updatedHoliday = holiday.copyWithLastModified();

    // 保存到数据库
    await _holidaysBox!.put(updatedHoliday.id, updatedHoliday);

    // 更新缓存
    HolidayCacheServiceEnhanced.updateHolidayInCache(updatedHoliday);

    debugPrint('保存节日并更新最后修改时间: ${updatedHoliday.id} (${updatedHoliday.name})');
  }

  /// 批量保存节日
  Future<void> saveHolidays(List<HolidayModelExtended> holidays) async {
    _checkInitialized();

    // 更新最后修改时间并创建映射
    final Map<String, HolidayModelExtended> holidayMap = {};
    for (final holiday in holidays) {
      final updatedHoliday = holiday.copyWithLastModified();
      holidayMap[updatedHoliday.id] = updatedHoliday;
    }

    // 批量保存到数据库
    await _holidaysBox!.putAll(holidayMap);

    // 更新缓存
    HolidayCacheServiceEnhanced.updateHolidaysInCache(holidayMap.values.toList());

    debugPrint('批量保存 ${holidays.length} 个节日后更新缓存');
  }

  /// 获取所有节日
  List<HolidayModelExtended> getAllHolidays() {
    _checkInitialized();

    // 尝试从缓存获取
    final cachedHolidays = HolidayCacheServiceEnhanced.getAllHolidaysFromCache();
    if (cachedHolidays.isNotEmpty) {
      debugPrint('从缓存中获取 ${cachedHolidays.length} 个节日记录');
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = _holidaysBox!.values.toList();

    // 更新缓存
    HolidayCacheServiceEnhanced.cacheHolidays(holidays);

    debugPrint('从数据库中获取 ${holidays.length} 个节日记录');
    return holidays;
  }

  /// 根据ID获取节日
  HolidayModelExtended? getHolidayById(String id) {
    _checkInitialized();

    // 尝试从缓存获取
    final cachedHoliday = HolidayCacheServiceEnhanced.getHolidayFromCache(id);
    if (cachedHoliday != null) {
      debugPrint('从缓存中获取节日: $id (${cachedHoliday.name})');
      return cachedHoliday;
    }

    // 从数据库获取
    final holiday = _holidaysBox!.get(id);

    // 更新缓存
    if (holiday != null) {
      HolidayCacheServiceEnhanced.cacheHoliday(holiday);
    }

    return holiday;
  }

  /// 根据地区获取节日
  List<HolidayModelExtended> getHolidaysByRegion(String region, {bool isChineseLocale = false}) {
    _checkInitialized();

    // 尝试从缓存获取
    final cachedHolidays = HolidayCacheServiceEnhanced.getHolidaysByRegionFromCache(region);
    if (cachedHolidays.isNotEmpty) {
      debugPrint('从缓存中获取 ${cachedHolidays.length} 个 $region 地区的节日');
      return cachedHolidays;
    }

    // 从数据库获取
    final allHolidays = getAllHolidays();

    // 筛选出指定地区的节日
    final List<HolidayModelExtended> regionHolidays = [];
    final List<HolidayModelExtended> internationalHolidays = [];

    for (final holiday in allHolidays) {
      // 检查是否包含指定地区
      if (holiday.regions.contains(region)) {
        debugPrint('添加/更新地区节日: ${holiday.id} (${holiday.name}) - ${holiday.calculationRule} - 匹配语言: $isChineseLocale');
        regionHolidays.add(holiday);
      }
      // 检查是否为国际节日
      else if (holiday.regions.contains('INTL') || holiday.regions.contains('ALL')) {
        // 检查是否已有同名地区节日
        final hasRegionalEquivalent = regionHolidays.any((h) =>
          h.name == holiday.name ||
          (h.nameEn != null && h.nameEn == holiday.nameEn)
        );

        if (!hasRegionalEquivalent) {
          if (regionHolidays.isNotEmpty) {
            debugPrint('添加/更新国际节日: ${holiday.id} (${holiday.name}) - ${holiday.calculationRule} - 匹配语言: $isChineseLocale');
          } else {
            debugPrint('跳过国际节日(已有地区节日): ${holiday.id} (${holiday.name}) - ${holiday.calculationRule}');
          }
          internationalHolidays.add(holiday);
        }
      }
    }

    // 合并地区节日和国际节日
    final result = [...regionHolidays, ...internationalHolidays];

    // 更新缓存
    HolidayCacheServiceEnhanced.cacheHolidaysByRegion(region, result);

    debugPrint('总共获取到 ${result.length} 个节日 (语言环境: ${isChineseLocale ? '中文' : '非中文'})');
    return result;
  }

  /// 根据类型获取节日
  List<HolidayModelExtended> getHolidaysByType(HolidayType type) {
    _checkInitialized();

    // 从数据库获取所有节日
    final allHolidays = getAllHolidays();

    // 筛选出指定类型的节日
    return allHolidays.where((holiday) => holiday.type == type).toList();
  }

  /// 根据日期范围获取节日
  List<HolidayModelExtended> getHolidaysByDateRange(DateTime startDate, DateTime endDate) {
    _checkInitialized();

    // 从数据库获取所有节日
    final allHolidays = getAllHolidays();

    // 筛选出在指定日期范围内的节日
    // 注意：这里需要计算每个节日的实际日期，可能需要额外的逻辑
    return allHolidays.where((holiday) {
      // 这里需要根据holiday.calculationType和holiday.calculationRule计算实际日期
      // 暂时返回所有节日，实际实现需要更复杂的逻辑
      return true;
    }).toList();
  }

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String holidayId, int importance) async {
    _checkInitialized();

    // 获取节日
    final holiday = getHolidayById(holidayId);
    if (holiday == null) return;

    // 更新重要性
    holiday.userImportance = importance;

    // 保存更新后的节日
    await saveHoliday(holiday);
  }

  /// 删除节日
  Future<void> deleteHoliday(String holidayId) async {
    _checkInitialized();

    // 从数据库删除
    await _holidaysBox!.delete(holidayId);

    // 从缓存删除
    HolidayCacheServiceEnhanced.removeHolidayFromCache(holidayId);

    debugPrint('删除节日: $holidayId');
  }

  /// 搜索节日
  List<HolidayModelExtended> searchHolidays(String query) {
    _checkInitialized();

    // 从数据库获取所有节日
    final allHolidays = getAllHolidays();

    // 转换查询字符串为小写
    final lowerQuery = query.toLowerCase();

    // 搜索节日
    return allHolidays.where((holiday) {
      // 搜索名称
      if (holiday.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索英文名称
      if (holiday.nameEn != null && holiday.nameEn!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言名称
      if (holiday.names != null) {
        for (final name in holiday.names!.values) {
          if (name.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索描述
      if (holiday.description != null && holiday.description!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索英文描述
      if (holiday.descriptionEn != null && holiday.descriptionEn!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言描述
      if (holiday.descriptions != null) {
        for (final description in holiday.descriptions!.values) {
          if (description.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  // ==================== 联系人相关操作 ====================

  /// 保存联系人
  Future<void> saveContact(ContactModel contact) async {
    _checkInitialized();

    // 更新最后修改时间
    final updatedContact = contact.copyWithLastModified();

    // 保存到数据库
    await _contactsBox!.put(updatedContact.id, updatedContact);

    debugPrint('保存联系人并更新最后修改时间: ${updatedContact.id} (${updatedContact.name})');
  }

  /// 批量保存联系人
  Future<void> saveContacts(List<ContactModel> contacts) async {
    _checkInitialized();

    // 更新最后修改时间并创建映射
    final Map<String, ContactModel> contactMap = {};
    for (final contact in contacts) {
      final updatedContact = contact.copyWithLastModified();
      contactMap[updatedContact.id] = updatedContact;
    }

    // 批量保存到数据库
    await _contactsBox!.putAll(contactMap);

    debugPrint('批量保存 ${contacts.length} 个联系人');
  }

  /// 获取所有联系人
  List<ContactModel> getAllContacts() {
    _checkInitialized();

    // 从数据库获取
    final contacts = _contactsBox!.values.toList();

    debugPrint('从数据库中获取 ${contacts.length} 个联系人记录');
    return contacts;
  }

  /// 根据ID获取联系人
  ContactModel? getContactById(String id) {
    _checkInitialized();

    // 从数据库获取
    return _contactsBox!.get(id);
  }

  /// 根据关系类型获取联系人
  List<ContactModel> getContactsByRelationType(RelationType relationType) {
    _checkInitialized();

    // 从数据库获取所有联系人
    final allContacts = getAllContacts();

    // 筛选出指定关系类型的联系人
    return allContacts.where((contact) => contact.relationType == relationType).toList();
  }

  /// 删除联系人
  Future<void> deleteContact(String contactId) async {
    _checkInitialized();

    // 从数据库删除
    await _contactsBox!.delete(contactId);

    debugPrint('删除联系人: $contactId');
  }

  /// 搜索联系人
  List<ContactModel> searchContacts(String query) {
    _checkInitialized();

    // 从数据库获取所有联系人
    final allContacts = getAllContacts();

    // 转换查询字符串为小写
    final lowerQuery = query.toLowerCase();

    // 搜索联系人
    return allContacts.where((contact) {
      // 搜索名称
      if (contact.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言名称
      if (contact.names != null) {
        for (final name in contact.names!.values) {
          if (name.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索具体关系
      if (contact.specificRelation != null && contact.specificRelation!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言具体关系
      if (contact.specificRelations != null) {
        for (final relation in contact.specificRelations!.values) {
          if (relation.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索电话号码
      if (contact.phoneNumber != null && contact.phoneNumber!.contains(query)) {
        return true;
      }

      // 搜索邮箱
      if (contact.email != null && contact.email!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  // ==================== 用户设置相关操作 ====================

  /// 获取用户设置
  UserSettingsModel? getUserSettings() {
    _checkInitialized();

    // 如果只有一个用户设置，直接返回
    if (_userSettingsBox!.length == 1) {
      return _userSettingsBox!.values.first;
    }

    // 如果有多个用户设置，返回第一个
    if (_userSettingsBox!.isNotEmpty) {
      return _userSettingsBox!.values.first;
    }

    return null;
  }

  /// 保存用户设置
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    _checkInitialized();

    // 更新最后修改时间
    final updatedSettings = settings.copyWithLastModified();

    // 保存到数据库
    await _userSettingsBox!.put(updatedSettings.userId, updatedSettings);

    debugPrint('保存用户设置并更新最后修改时间: ${updatedSettings.userId} (${updatedSettings.nickname})');
  }

  // ==================== 提醒事件相关操作 ====================

  /// 保存提醒事件
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    _checkInitialized();

    // 更新最后修改时间
    final updatedEvent = event.copyWithLastModified();

    // 保存到数据库
    await _reminderEventsBox!.put(updatedEvent.id, updatedEvent);

    debugPrint('保存提醒事件并更新最后修改时间: ${updatedEvent.id} (${updatedEvent.title})');
  }

  /// 批量保存提醒事件
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    _checkInitialized();

    // 更新最后修改时间并创建映射
    final Map<String, ReminderEventModel> eventMap = {};
    for (final event in events) {
      final updatedEvent = event.copyWithLastModified();
      eventMap[updatedEvent.id] = updatedEvent;
    }

    // 批量保存到数据库
    await _reminderEventsBox!.putAll(eventMap);

    debugPrint('批量保存 ${events.length} 个提醒事件');
  }

  /// 获取所有提醒事件
  List<ReminderEventModel> getAllReminderEvents() {
    _checkInitialized();

    // 从数据库获取
    final events = _reminderEventsBox!.values.toList();

    debugPrint('从数据库中获取 ${events.length} 个提醒事件记录');
    return events;
  }

  /// 根据ID获取提醒事件
  ReminderEventModel? getReminderEventById(String id) {
    _checkInitialized();

    // 从数据库获取
    return _reminderEventsBox!.get(id);
  }

  /// 根据类型获取提醒事件
  List<ReminderEventModel> getReminderEventsByType(ReminderEventType type) {
    _checkInitialized();

    // 从数据库获取所有提醒事件
    final allEvents = getAllReminderEvents();

    // 筛选出指定类型的提醒事件
    return allEvents.where((event) => event.type == type).toList();
  }

  /// 根据状态获取提醒事件
  List<ReminderEventModel> getReminderEventsByStatus(ReminderStatus status) {
    _checkInitialized();

    // 从数据库获取所有提醒事件
    final allEvents = getAllReminderEvents();

    // 筛选出指定状态的提醒事件
    return allEvents.where((event) => event.status == status).toList();
  }

  /// 根据日期范围获取提醒事件
  List<ReminderEventModel> getReminderEventsByDateRange(DateTime startDate, DateTime endDate) {
    _checkInitialized();

    // 从数据库获取所有提醒事件
    final allEvents = getAllReminderEvents();

    // 筛选出在指定日期范围内的提醒事件
    return allEvents.where((event) {
      if (event.dueDate == null) return false;

      final dueDate = DateTime(
        event.dueDate!.year,
        event.dueDate!.month,
        event.dueDate!.day,
      );

      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      return dueDate.isAtSameMomentAs(start) ||
             dueDate.isAtSameMomentAs(end) ||
             (dueDate.isAfter(start) && dueDate.isBefore(end));
    }).toList();
  }

  /// 获取今天的提醒事件
  List<ReminderEventModel> getTodayReminderEvents() {
    _checkInitialized();

    // 获取今天的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 获取今天的提醒事件
    return getReminderEventsByDateRange(today, tomorrow);
  }

  /// 获取未来的提醒事件
  List<ReminderEventModel> getFutureReminderEvents() {
    _checkInitialized();

    // 获取今天的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 从数据库获取所有提醒事件
    final allEvents = getAllReminderEvents();

    // 筛选出未来的提醒事件
    return allEvents.where((event) {
      if (event.dueDate == null) return false;

      final dueDate = DateTime(
        event.dueDate!.year,
        event.dueDate!.month,
        event.dueDate!.day,
      );

      return dueDate.isAfter(today);
    }).toList();
  }

  /// 更新提醒事件状态
  Future<void> updateReminderEventStatus(String eventId, ReminderStatus status) async {
    _checkInitialized();

    // 获取提醒事件
    final event = getReminderEventById(eventId);
    if (event == null) return;

    // 更新状态
    event.status = status;

    // 如果状态是已完成，更新完成时间
    if (status == ReminderStatus.completed) {
      event.isCompleted = true;
      event.completedAt = DateTime.now();
    } else {
      event.isCompleted = false;
      event.completedAt = null;
    }

    // 保存更新后的提醒事件
    await saveReminderEvent(event);
  }

  /// 删除提醒事件
  Future<void> deleteReminderEvent(String eventId) async {
    _checkInitialized();

    // 从数据库删除
    await _reminderEventsBox!.delete(eventId);

    debugPrint('删除提醒事件: $eventId');
  }

  /// 搜索提醒事件
  List<ReminderEventModel> searchReminderEvents(String query) {
    _checkInitialized();

    // 从数据库获取所有提醒事件
    final allEvents = getAllReminderEvents();

    // 转换查询字符串为小写
    final lowerQuery = query.toLowerCase();

    // 搜索提醒事件
    return allEvents.where((event) {
      // 搜索标题
      if (event.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言标题
      if (event.titles != null) {
        for (final title in event.titles!.values) {
          if (title.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索描述
      if (event.description != null && event.description!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索多语言描述
      if (event.descriptions != null) {
        for (final description in event.descriptions!.values) {
          if (description.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索位置
      if (event.location != null && event.location!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索标签
      if (event.tags != null) {
        for (final tag in event.tags!) {
          if (tag.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }

      // 搜索类别
      if (event.category != null && event.category!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  // ==================== 辅助方法 ====================

  /// 检查数据库是否已初始化
  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('增强版Hive数据库服务尚未初始化');
    }
  }
}
