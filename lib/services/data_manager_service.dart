import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/hive_database_service_enhanced.dart';
import 'package:jinlin_app/services/database_init_service_enhanced.dart';
import 'package:jinlin_app/services/database_validator_service.dart';
import 'package:jinlin_app/services/backup_restore_service.dart';
import 'package:jinlin_app/services/cloud_sync_service_enhanced.dart';

/// 数据管理服务
///
/// 统一管理所有数据操作，是应用程序与数据库交互的唯一入口
class DataManagerService {
  // 单例模式
  static final DataManagerService _instance = DataManagerService._internal();
  factory DataManagerService() => _instance;
  DataManagerService._internal();

  // 数据库服务
  final _dbService = HiveDatabaseServiceEnhanced();

  // 数据库初始化服务
  final _initService = DatabaseInitServiceEnhanced();

  // 数据验证服务
  final _validatorService = DatabaseValidatorService();

  // 备份恢复服务
  final _backupService = BackupRestoreService();

  // 云同步服务
  final _cloudSyncService = CloudSyncServiceEnhanced();

  // 是否已初始化
  bool _isInitialized = false;

  // 获取初始化状态
  bool get isInitialized => _isInitialized;

  /// 初始化
  Future<bool> initialize(BuildContext context) async {
    if (_isInitialized) return true;

    try {
      // 检查数据库初始化状态
      final isDbInitialized = await _initService.checkInitializationState();
      if (!isDbInitialized) {
        // 初始化数据库
        if (!context.mounted) return false;
        final success = await _initService.initialize(context);
        if (!success) {
          return false;
        }
      } else {
        // 初始化数据库服务
        await _dbService.initialize();
      }

      // 检查登录状态
      await _cloudSyncService.checkLoginStatus();

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('数据管理服务初始化失败: $e');
      return false;
    }
  }

  /// 重置数据库
  Future<bool> resetDatabase(BuildContext context) async {
    try {
      if (!context.mounted) return false;
      return await _initService.reset(context);
    } catch (e) {
      debugPrint('重置数据库失败: $e');
      return false;
    }
  }

  // ==================== 节日相关操作 ====================

  /// 获取所有节日
  List<HolidayModelExtended> getAllHolidays() {
    _checkInitialized();
    return _dbService.getAllHolidays();
  }

  /// 根据ID获取节日
  HolidayModelExtended? getHolidayById(String id) {
    _checkInitialized();
    return _dbService.getHolidayById(id);
  }

  /// 根据地区获取节日
  List<HolidayModelExtended> getHolidaysByRegion(String region, {bool isChineseLocale = false}) {
    _checkInitialized();
    return _dbService.getHolidaysByRegion(region, isChineseLocale: isChineseLocale);
  }

  /// 根据类型获取节日
  List<HolidayModelExtended> getHolidaysByType(HolidayType type) {
    _checkInitialized();
    return _dbService.getHolidaysByType(type);
  }

  /// 根据日期范围获取节日
  List<HolidayModelExtended> getHolidaysByDateRange(DateTime startDate, DateTime endDate) {
    _checkInitialized();
    return _dbService.getHolidaysByDateRange(startDate, endDate);
  }

  /// 保存节日
  Future<void> saveHoliday(HolidayModelExtended holiday) async {
    _checkInitialized();
    await _dbService.saveHoliday(holiday);
  }

  /// 批量保存节日
  Future<void> saveHolidays(List<HolidayModelExtended> holidays) async {
    _checkInitialized();
    await _dbService.saveHolidays(holidays);
  }

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String holidayId, int importance) async {
    _checkInitialized();
    await _dbService.updateHolidayImportance(holidayId, importance);
  }

  /// 删除节日
  Future<void> deleteHoliday(String holidayId) async {
    _checkInitialized();
    await _dbService.deleteHoliday(holidayId);
  }

  /// 搜索节日
  List<HolidayModelExtended> searchHolidays(String query) {
    _checkInitialized();
    return _dbService.searchHolidays(query);
  }

  // ==================== 联系人相关操作 ====================

  /// 获取所有联系人
  List<ContactModel> getAllContacts() {
    _checkInitialized();
    return _dbService.getAllContacts();
  }

  /// 根据ID获取联系人
  ContactModel? getContactById(String id) {
    _checkInitialized();
    return _dbService.getContactById(id);
  }

  /// 根据关系类型获取联系人
  List<ContactModel> getContactsByRelationType(RelationType relationType) {
    _checkInitialized();
    return _dbService.getContactsByRelationType(relationType);
  }

  /// 保存联系人
  Future<void> saveContact(ContactModel contact) async {
    _checkInitialized();
    await _dbService.saveContact(contact);
  }

  /// 批量保存联系人
  Future<void> saveContacts(List<ContactModel> contacts) async {
    _checkInitialized();
    await _dbService.saveContacts(contacts);
  }

  /// 删除联系人
  Future<void> deleteContact(String contactId) async {
    _checkInitialized();
    await _dbService.deleteContact(contactId);
  }

  /// 搜索联系人
  List<ContactModel> searchContacts(String query) {
    _checkInitialized();
    return _dbService.searchContacts(query);
  }

  // ==================== 用户设置相关操作 ====================

  /// 获取用户设置
  UserSettingsModel? getUserSettings() {
    _checkInitialized();
    return _dbService.getUserSettings();
  }

  /// 保存用户设置
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    _checkInitialized();
    await _dbService.saveUserSettings(settings);
  }

  // ==================== 提醒事件相关操作 ====================

  /// 获取所有提醒事件
  List<ReminderEventModel> getAllReminderEvents() {
    _checkInitialized();
    return _dbService.getAllReminderEvents();
  }

  /// 根据ID获取提醒事件
  ReminderEventModel? getReminderEventById(String id) {
    _checkInitialized();
    return _dbService.getReminderEventById(id);
  }

  /// 根据类型获取提醒事件
  List<ReminderEventModel> getReminderEventsByType(ReminderEventType type) {
    _checkInitialized();
    return _dbService.getReminderEventsByType(type);
  }

  /// 根据状态获取提醒事件
  List<ReminderEventModel> getReminderEventsByStatus(ReminderStatus status) {
    _checkInitialized();
    return _dbService.getReminderEventsByStatus(status);
  }

  /// 根据日期范围获取提醒事件
  List<ReminderEventModel> getReminderEventsByDateRange(DateTime startDate, DateTime endDate) {
    _checkInitialized();
    return _dbService.getReminderEventsByDateRange(startDate, endDate);
  }

  /// 获取今天的提醒事件
  List<ReminderEventModel> getTodayReminderEvents() {
    _checkInitialized();
    return _dbService.getTodayReminderEvents();
  }

  /// 获取未来的提醒事件
  List<ReminderEventModel> getFutureReminderEvents() {
    _checkInitialized();
    return _dbService.getFutureReminderEvents();
  }

  /// 保存提醒事件
  Future<void> saveReminderEvent(ReminderEventModel event) async {
    _checkInitialized();
    await _dbService.saveReminderEvent(event);
  }

  /// 批量保存提醒事件
  Future<void> saveReminderEvents(List<ReminderEventModel> events) async {
    _checkInitialized();
    await _dbService.saveReminderEvents(events);
  }

  /// 更新提醒事件状态
  Future<void> updateReminderEventStatus(String eventId, ReminderStatus status) async {
    _checkInitialized();
    await _dbService.updateReminderEventStatus(eventId, status);
  }

  /// 删除提醒事件
  Future<void> deleteReminderEvent(String eventId) async {
    _checkInitialized();
    await _dbService.deleteReminderEvent(eventId);
  }

  /// 搜索提醒事件
  List<ReminderEventModel> searchReminderEvents(String query) {
    _checkInitialized();
    return _dbService.searchReminderEvents(query);
  }

  // ==================== 数据验证相关操作 ====================

  /// 验证所有数据
  Future<Map<String, Map<String, List<String>>>> validateAllData() async {
    _checkInitialized();
    return await _validatorService.validateAllData();
  }

  /// 修复所有数据问题
  Future<Map<String, int>> fixAllDataIssues() async {
    _checkInitialized();
    return await _validatorService.fixAllDataIssues();
  }

  // ==================== 备份恢复相关操作 ====================

  /// 创建备份
  Future<String?> createBackup({String? password}) async {
    _checkInitialized();
    return await _backupService.createBackup(password: password);
  }

  /// 恢复备份
  Future<bool> restoreBackup(String backupFilePath, {String? password}) async {
    _checkInitialized();
    return await _backupService.restoreBackup(backupFilePath, password: password);
  }

  /// 获取备份文件列表
  Future<List<FileSystemEntity>> getBackupFiles() async {
    _checkInitialized();
    return await _backupService.getBackupFiles();
  }

  /// 删除备份文件
  Future<bool> deleteBackupFile(String backupFilePath) async {
    _checkInitialized();
    return await _backupService.deleteBackupFile(backupFilePath);
  }

  /// 导出备份到自定义位置
  Future<String?> exportBackup({String? password}) async {
    _checkInitialized();
    return await _backupService.exportBackup(password: password);
  }

  /// 从自定义位置导入备份
  Future<bool> importBackup({String? password}) async {
    _checkInitialized();
    return await _backupService.importBackup(password: password);
  }

  /// 获取最后备份时间
  Future<DateTime?> getLastBackupTime() async {
    _checkInitialized();
    return await _backupService.getLastBackupTime();
  }

  /// 检查是否需要备份
  Future<bool> shouldBackup(int backupFrequencyDays) async {
    _checkInitialized();
    return await _backupService.shouldBackup(backupFrequencyDays);
  }

  // ==================== 云同步相关操作 ====================

  /// 登录
  Future<bool> login(String username, String password) async {
    _checkInitialized();
    return await _cloudSyncService.login(username, password);
  }

  /// 注册
  Future<bool> register(String username, String password, String email) async {
    _checkInitialized();
    return await _cloudSyncService.register(username, password, email);
  }

  /// 登出
  Future<bool> logout() async {
    _checkInitialized();
    return await _cloudSyncService.logout();
  }

  /// 检查登录状态
  Future<bool> checkLoginStatus() async {
    _checkInitialized();
    return await _cloudSyncService.checkLoginStatus();
  }

  /// 同步数据
  Future<Map<String, int>> syncData() async {
    _checkInitialized();
    return await _cloudSyncService.syncData();
  }

  // ==================== 辅助方法 ====================

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('数据管理服务尚未初始化');
    }
  }
}
