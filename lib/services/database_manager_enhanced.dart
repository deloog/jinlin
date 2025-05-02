import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/services/database/sqlite_database_enhanced.dart';

/// 增强版数据库管理器
///
/// 提供对数据库的统一访问接口，封装具体的数据库实现
class DatabaseManagerEnhanced extends ChangeNotifier {
  // 数据库接口
  final DatabaseInterfaceEnhanced _db;

  // 是否已初始化
  bool _isInitialized = false;

  /// 构造函数
  ///
  /// 可以指定使用的数据库实现，默认使用SQLite
  DatabaseManagerEnhanced({DatabaseInterfaceEnhanced? db}) : _db = db ?? SQLiteDatabaseEnhanced();

  /// 初始化数据库
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized) return;

    try {
      await _db.initialize();
      _isInitialized = true;
      notifyListeners();
      debugPrint('增强版数据库管理器初始化成功');
    } catch (e) {
      debugPrint('增强版数据库管理器初始化失败: $e');
      rethrow;
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await _db.close();
      _isInitialized = false;
      notifyListeners();
      debugPrint('增强版数据库管理器已关闭');
    } catch (e) {
      debugPrint('增强版数据库管理器关闭失败: $e');
      rethrow;
    }
  }

  /// 清空数据库
  Future<void> clearAll() async {
    await _checkInitialized();

    try {
      await _db.clearAll();
      notifyListeners();
      debugPrint('增强版数据库管理器已清空数据库');
    } catch (e) {
      debugPrint('增强版数据库管理器清空数据库失败: $e');
      rethrow;
    }
  }

  /// 检查数据库是否已初始化
  Future<void> _checkInitialized() async {
    if (!_isInitialized) {
      throw Exception('增强版数据库管理器未初始化');
    }
  }

  /// 检查是否是首次启动
  Future<bool> isFirstLaunch() async {
    await _checkInitialized();
    return _db.isFirstLaunch();
  }

  /// 获取数据库实例
  DatabaseInterfaceEnhanced getDatabase() {
    return _db;
  }

  // ==================== 节日相关操作 ====================

  /// 保存节日
  Future<void> saveHoliday(Holiday holiday) async {
    await _checkInitialized();

    try {
      await _db.saveHoliday(holiday);
      notifyListeners();
    } catch (e) {
      debugPrint('保存节日失败: $e');
      rethrow;
    }
  }

  /// 批量保存节日
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _checkInitialized();

    try {
      await _db.saveHolidays(holidays);
      notifyListeners();
    } catch (e) {
      debugPrint('批量保存节日失败: $e');
      rethrow;
    }
  }

  /// 获取所有节日
  Future<List<Holiday>> getAllHolidays() async {
    await _checkInitialized();

    try {
      return await _db.getAllHolidays();
    } catch (e) {
      debugPrint('获取所有节日失败: $e');
      rethrow;
    }
  }

  /// 根据ID获取节日
  Future<Holiday?> getHolidayById(String id) async {
    await _checkInitialized();

    try {
      return await _db.getHolidayById(id);
    } catch (e) {
      debugPrint('获取节日失败: $e');
      rethrow;
    }
  }

  /// 根据地区获取节日
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      return await _db.getHolidaysByRegion(region, languageCode: languageCode);
    } catch (e) {
      debugPrint('获取地区节日失败: $e');
      rethrow;
    }
  }

  /// 根据类型获取节日
  Future<List<Holiday>> getHolidaysByType(HolidayType type) async {
    await _checkInitialized();

    try {
      return await _db.getHolidaysByType(type);
    } catch (e) {
      debugPrint('获取类型节日失败: $e');
      rethrow;
    }
  }

  /// 搜索节日
  Future<List<Holiday>> searchHolidays(String query, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      return await _db.searchHolidays(query, languageCode: languageCode);
    } catch (e) {
      debugPrint('搜索节日失败: $e');
      rethrow;
    }
  }

  /// 删除节日
  Future<void> deleteHoliday(String id) async {
    await _checkInitialized();

    try {
      await _db.deleteHoliday(id);
      notifyListeners();
    } catch (e) {
      debugPrint('删除节日失败: $e');
      rethrow;
    }
  }

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _checkInitialized();

    try {
      await _db.updateHolidayImportance(id, importance);
      notifyListeners();
    } catch (e) {
      debugPrint('更新节日重要性失败: $e');
      rethrow;
    }
  }

  // ==================== 联系人相关操作 ====================

  /// 保存联系人
  Future<void> saveContact(ContactModel contact) async {
    await _checkInitialized();

    try {
      await _db.saveContact(contact);
      notifyListeners();
    } catch (e) {
      debugPrint('保存联系人失败: $e');
      rethrow;
    }
  }

  /// 批量保存联系人
  Future<void> saveContacts(List<ContactModel> contacts) async {
    await _checkInitialized();

    try {
      await _db.saveContacts(contacts);
      notifyListeners();
    } catch (e) {
      debugPrint('批量保存联系人失败: $e');
      rethrow;
    }
  }

  /// 获取所有联系人
  Future<List<ContactModel>> getAllContacts() async {
    await _checkInitialized();

    try {
      return await _db.getAllContacts();
    } catch (e) {
      debugPrint('获取所有联系人失败: $e');
      rethrow;
    }
  }

  /// 根据ID获取联系人
  Future<ContactModel?> getContactById(String id) async {
    await _checkInitialized();

    try {
      return await _db.getContactById(id);
    } catch (e) {
      debugPrint('获取联系人失败: $e');
      rethrow;
    }
  }

  /// 根据关系类型获取联系人
  Future<List<ContactModel>> getContactsByRelationType(RelationType relationType) async {
    await _checkInitialized();

    try {
      return await _db.getContactsByRelationType(relationType);
    } catch (e) {
      debugPrint('获取关系类型联系人失败: $e');
      rethrow;
    }
  }

  /// 搜索联系人
  Future<List<ContactModel>> searchContacts(String query) async {
    await _checkInitialized();

    try {
      return await _db.searchContacts(query);
    } catch (e) {
      debugPrint('搜索联系人失败: $e');
      rethrow;
    }
  }

  /// 删除联系人
  Future<void> deleteContact(String id) async {
    await _checkInitialized();

    try {
      await _db.deleteContact(id);
      notifyListeners();
    } catch (e) {
      debugPrint('删除联系人失败: $e');
      rethrow;
    }
  }

  // ==================== 提醒事件相关操作 ====================

  /// 保存提醒事件
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    await _checkInitialized();

    try {
      await _db.saveReminderEvent(event);
      notifyListeners();
    } catch (e) {
      debugPrint('保存提醒事件失败: $e');
      rethrow;
    }
  }

  /// 批量保存提醒事件
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    await _checkInitialized();

    try {
      await _db.saveReminderEvents(events);
      notifyListeners();
    } catch (e) {
      debugPrint('批量保存提醒事件失败: $e');
      rethrow;
    }
  }

  /// 获取所有提醒事件
  Future<List<ReminderEventModel>> getAllReminderEvents() async {
    await _checkInitialized();

    try {
      return await _db.getAllReminderEvents();
    } catch (e) {
      debugPrint('获取所有提醒事件失败: $e');
      rethrow;
    }
  }

  /// 根据ID获取提醒事件
  Future<ReminderEventModel?> getReminderEventById(String id) async {
    await _checkInitialized();

    try {
      return await _db.getReminderEventById(id);
    } catch (e) {
      debugPrint('获取提醒事件失败: $e');
      rethrow;
    }
  }

  /// 获取即将到来的提醒事件
  Future<List<ReminderEventModel>> getUpcomingReminderEvents(int days) async {
    await _checkInitialized();

    try {
      return await _db.getUpcomingReminderEvents(days);
    } catch (e) {
      debugPrint('获取即将到来的提醒事件失败: $e');
      rethrow;
    }
  }

  /// 获取过期的提醒事件
  Future<List<ReminderEventModel>> getExpiredReminderEvents() async {
    await _checkInitialized();

    try {
      return await _db.getExpiredReminderEvents();
    } catch (e) {
      debugPrint('获取过期的提醒事件失败: $e');
      rethrow;
    }
  }

  /// 根据类型获取提醒事件
  Future<List<ReminderEventModel>> getReminderEventsByType(ReminderEventType type) async {
    await _checkInitialized();

    try {
      return await _db.getReminderEventsByType(type);
    } catch (e) {
      debugPrint('获取类型提醒事件失败: $e');
      rethrow;
    }
  }

  /// 搜索提醒事件
  Future<List<ReminderEventModel>> searchReminderEvents(String query) async {
    await _checkInitialized();

    try {
      return await _db.searchReminderEvents(query);
    } catch (e) {
      debugPrint('搜索提醒事件失败: $e');
      rethrow;
    }
  }

  /// 删除提醒事件
  Future<void> deleteReminderEvent(String id) async {
    await _checkInitialized();

    try {
      await _db.deleteReminderEvent(id);
      notifyListeners();
    } catch (e) {
      debugPrint('删除提醒事件失败: $e');
      rethrow;
    }
  }

  /// 更新提醒事件状态
  Future<void> updateReminderEventStatus(String id, ReminderStatus status) async {
    await _checkInitialized();

    try {
      await _db.updateReminderEventStatus(id, status);
      notifyListeners();
    } catch (e) {
      debugPrint('更新提醒事件状态失败: $e');
      rethrow;
    }
  }

  // ==================== 用户设置相关操作 ====================

  /// 保存用户设置
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _checkInitialized();

    try {
      await _db.saveUserSettings(settings);
      notifyListeners();
    } catch (e) {
      debugPrint('保存用户设置失败: $e');
      rethrow;
    }
  }

  /// 获取用户设置
  Future<UserSettingsModel?> getUserSettings() async {
    await _checkInitialized();

    try {
      return await _db.getUserSettings();
    } catch (e) {
      debugPrint('获取用户设置失败: $e');
      rethrow;
    }
  }

  /// 更新用户设置
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _checkInitialized();

    try {
      await _db.updateUserSettings(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('更新用户设置失败: $e');
      rethrow;
    }
  }

  // ==================== 数据同步相关操作 ====================

  /// 获取上次同步时间
  Future<DateTime?> getLastSyncTime() async {
    await _checkInitialized();

    try {
      return await _db.getLastSyncTime();
    } catch (e) {
      debugPrint('获取上次同步时间失败: $e');
      rethrow;
    }
  }

  /// 更新上次同步时间
  Future<void> updateLastSyncTime(DateTime time) async {
    await _checkInitialized();

    try {
      await _db.updateLastSyncTime(time);
      notifyListeners();
    } catch (e) {
      debugPrint('更新上次同步时间失败: $e');
      rethrow;
    }
  }

  /// 获取修改过的数据
  Future<Map<String, dynamic>> getModifiedData(DateTime? since) async {
    await _checkInitialized();

    try {
      return await _db.getModifiedData(since);
    } catch (e) {
      debugPrint('获取修改过的数据失败: $e');
      rethrow;
    }
  }

  /// 标记同步冲突
  Future<void> markSyncConflict(String entityType, String id, bool isConflict) async {
    await _checkInitialized();

    try {
      await _db.markSyncConflict(entityType, id, isConflict);
      notifyListeners();
    } catch (e) {
      debugPrint('标记同步冲突失败: $e');
      rethrow;
    }
  }

  /// 获取同步冲突
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    await _checkInitialized();

    try {
      return await _db.getSyncConflicts();
    } catch (e) {
      debugPrint('获取同步冲突失败: $e');
      rethrow;
    }
  }

  /// 解决同步冲突
  Future<void> resolveSyncConflict(String entityType, String id, dynamic resolvedData) async {
    await _checkInitialized();

    try {
      await _db.resolveSyncConflict(entityType, id, resolvedData);
      notifyListeners();
    } catch (e) {
      debugPrint('解决同步冲突失败: $e');
      rethrow;
    }
  }

  // ==================== 其他操作 ====================

  /// 执行数据库备份
  Future<String> backup() async {
    await _checkInitialized();

    try {
      return await _db.backup();
    } catch (e) {
      debugPrint('执行数据库备份失败: $e');
      rethrow;
    }
  }

  /// 从备份恢复数据库
  Future<bool> restore(String backupPath) async {
    await _checkInitialized();

    try {
      final result = await _db.restore(backupPath);
      if (result) {
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('从备份恢复数据库失败: $e');
      rethrow;
    }
  }

  /// 执行数据库维护
  Future<void> performMaintenance() async {
    await _checkInitialized();

    try {
      await _db.performMaintenance();
    } catch (e) {
      debugPrint('执行数据库维护失败: $e');
      rethrow;
    }
  }
}
