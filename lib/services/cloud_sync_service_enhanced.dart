import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/hive_database_service_enhanced.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// 增强版云同步服务
///
/// 提供数据的云同步功能，支持增量同步和冲突解决
class CloudSyncServiceEnhanced {
  // 单例模式
  static final CloudSyncServiceEnhanced _instance = CloudSyncServiceEnhanced._internal();
  factory CloudSyncServiceEnhanced() => _instance;
  CloudSyncServiceEnhanced._internal();

  // 数据库服务
  final _dbService = HiveDatabaseServiceEnhanced();

  // 模拟的API基础URL
  static const String _apiBaseUrl = 'https://api.example.com';

  // 用户认证令牌
  String? _authToken;

  // 用户ID
  String? _userId;

  // 是否已登录
  bool get isLoggedIn => _authToken != null && _userId != null;

  /// 登录
  Future<bool> login(String username, String password) async {
    try {
      // 模拟API调用
      // 实际应用中，这里应该调用真正的API
      await Future.delayed(const Duration(seconds: 1));

      // 模拟成功登录
      _authToken = _generateAuthToken(username, password);
      _userId = _generateUserId(username);

      // 保存认证信息
      await _saveAuthInfo();

      return true;
    } catch (e) {
      debugPrint('登录失败: $e');
      return false;
    }
  }

  /// 注册
  Future<bool> register(String username, String password, String email) async {
    try {
      // 模拟API调用
      // 实际应用中，这里应该调用真正的API
      await Future.delayed(const Duration(seconds: 1));

      // 模拟成功注册
      _authToken = _generateAuthToken(username, password);
      _userId = _generateUserId(username);

      // 保存认证信息
      await _saveAuthInfo();

      return true;
    } catch (e) {
      debugPrint('注册失败: $e');
      return false;
    }
  }

  /// 登出
  Future<bool> logout() async {
    try {
      // 清除认证信息
      _authToken = null;
      _userId = null;

      // 保存认证信息
      await _saveAuthInfo();

      return true;
    } catch (e) {
      debugPrint('登出失败: $e');
      return false;
    }
  }

  /// 检查登录状态
  Future<bool> checkLoginStatus() async {
    try {
      // 加载认证信息
      await _loadAuthInfo();

      return isLoggedIn;
    } catch (e) {
      debugPrint('检查登录状态失败: $e');
      return false;
    }
  }

  /// 同步数据
  Future<Map<String, int>> syncData() async {
    if (!isLoggedIn) {
      throw Exception('用户未登录');
    }

    try {
      // 获取最后同步时间
      final lastSyncTime = await _getLastSyncTime();

      // 上传数据
      final uploadResult = await _uploadData(lastSyncTime);

      // 下载数据
      final downloadResult = await _downloadData(lastSyncTime);

      // 更新最后同步时间
      await _updateLastSyncTime();

      return {
        'uploaded': uploadResult,
        'downloaded': downloadResult,
        'conflicts': 0, // 实际应用中，这里应该返回真正的冲突数量
      };
    } catch (e) {
      debugPrint('同步数据失败: $e');
      rethrow;
    }
  }

  /// 上传数据
  Future<int> _uploadData(DateTime? lastSyncTime) async {
    try {
      // 获取需要上传的数据
      final dataToUpload = await _getDataToUpload(lastSyncTime);

      // 模拟API调用
      // 实际应用中，这里应该调用真正的API
      await Future.delayed(const Duration(seconds: 1));

      return dataToUpload['total'] as int;
    } catch (e) {
      debugPrint('上传数据失败: $e');
      rethrow;
    }
  }

  /// 下载数据
  Future<int> _downloadData(DateTime? lastSyncTime) async {
    try {
      // 模拟API调用
      // 实际应用中，这里应该调用真正的API
      await Future.delayed(const Duration(seconds: 1));

      // 模拟下载的数据
      final downloadedData = {
        'holidays': <Map<String, dynamic>>[],
        'contacts': <Map<String, dynamic>>[],
        'settings': <Map<String, dynamic>>[],
        'events': <Map<String, dynamic>>[],
      };

      // 处理下载的数据
      await _processDownloadedData(downloadedData);

      return 0; // 实际应用中，这里应该返回真正的下载数量
    } catch (e) {
      debugPrint('下载数据失败: $e');
      rethrow;
    }
  }

  /// 获取需要上传的数据
  Future<Map<String, dynamic>> _getDataToUpload(DateTime? lastSyncTime) async {
    // 获取所有数据
    final holidays = _dbService.getAllHolidays();
    final contacts = _dbService.getAllContacts();
    final settings = _dbService.getUserSettings();
    final events = _dbService.getAllReminderEvents();

    // 筛选出需要上传的数据
    final holidaysToUpload = lastSyncTime != null
        ? holidays.where((holiday) =>
            holiday.lastModified != null &&
            holiday.lastModified!.isAfter(lastSyncTime))
        : holidays;

    final contactsToUpload = lastSyncTime != null
        ? contacts.where((contact) =>
            contact.lastModified != null &&
            contact.lastModified!.isAfter(lastSyncTime))
        : contacts;

    final eventsToUpload = lastSyncTime != null
        ? events.where((event) =>
            event.lastModified != null &&
            event.lastModified!.isAfter(lastSyncTime))
        : events;

    // 创建上传数据
    final dataToUpload = {
      'holidays': holidaysToUpload.map((holiday) => holiday.toJson()).toList(),
      'contacts': contactsToUpload.map((contact) => contact.toJson()).toList(),
      'settings': settings?.toJson(),
      'events': eventsToUpload.map((event) => event.toJson()).toList(),
      'total': holidaysToUpload.length +
          contactsToUpload.length +
          (settings != null ? 1 : 0) +
          eventsToUpload.length,
    };

    return dataToUpload;
  }

  /// 处理下载的数据
  Future<void> _processDownloadedData(Map<String, dynamic> downloadedData) async {
    // 处理节日数据
    if (downloadedData.containsKey('holidays') &&
        downloadedData['holidays'] is List) {
      final holidaysJson = downloadedData['holidays'] as List;
      final holidays = holidaysJson
          .map((json) => HolidayModelExtended.fromJson(json))
          .toList();
      await _processDownloadedHolidays(holidays);
    }

    // 处理联系人数据
    if (downloadedData.containsKey('contacts') &&
        downloadedData['contacts'] is List) {
      final contactsJson = downloadedData['contacts'] as List;
      final contacts = contactsJson
          .map((json) => ContactModel.fromJson(json))
          .toList();
      await _processDownloadedContacts(contacts);
    }

    // 处理用户设置
    if (downloadedData.containsKey('settings') &&
        downloadedData['settings'] is Map<String, dynamic>) {
      final settingsJson = downloadedData['settings'] as Map<String, dynamic>;
      final settings = UserSettingsModel.fromJson(settingsJson);
      await _processDownloadedSettings(settings);
    }

    // 处理提醒事件数据
    if (downloadedData.containsKey('events') &&
        downloadedData['events'] is List) {
      final eventsJson = downloadedData['events'] as List;
      final events = eventsJson
          .map((json) => ReminderEventModel.fromJson(json))
          .toList();
      await _processDownloadedEvents(events);
    }
  }

  /// 处理下载的节日数据
  Future<void> _processDownloadedHolidays(List<HolidayModelExtended> holidays) async {
    // 获取本地节日数据
    final localHolidays = _dbService.getAllHolidays();
    final localHolidaysMap = {
      for (var holiday in localHolidays) holiday.id: holiday
    };

    // 处理每个下载的节日
    for (final cloudHoliday in holidays) {
      // 检查是否存在本地版本
      if (localHolidaysMap.containsKey(cloudHoliday.id)) {
        final localHoliday = localHolidaysMap[cloudHoliday.id]!;

        // 检查最后修改时间
        if (cloudHoliday.lastModified != null &&
            localHoliday.lastModified != null) {
          if (cloudHoliday.lastModified!.isAfter(localHoliday.lastModified!)) {
            // 云端版本更新，使用云端版本
            await _dbService.saveHoliday(cloudHoliday);
          } else if (cloudHoliday.lastModified!
              .isAtSameMomentAs(localHoliday.lastModified!)) {
            // 时间相同，检查内容是否相同
            if (_holidayContentDiffers(cloudHoliday, localHoliday)) {
              // 内容不同，标记为冲突
              cloudHoliday.isSyncConflict = true;
              await _dbService.saveHoliday(cloudHoliday);
            }
          }
          // 如果本地版本更新，保留本地版本
        } else {
          // 如果没有时间戳，默认使用云端版本
          await _dbService.saveHoliday(cloudHoliday);
        }
      } else {
        // 本地不存在，直接导入
        await _dbService.saveHoliday(cloudHoliday);
      }
    }
  }

  /// 检查节日内容是否不同
  bool _holidayContentDiffers(
      HolidayModelExtended holiday1, HolidayModelExtended holiday2) {
    // 比较基本字段
    if (holiday1.name != holiday2.name ||
        holiday1.type != holiday2.type ||
        !_listsEqual(holiday1.regions, holiday2.regions) ||
        holiday1.calculationType != holiday2.calculationType ||
        holiday1.calculationRule != holiday2.calculationRule ||
        holiday1.description != holiday2.description ||
        holiday1.importanceLevel != holiday2.importanceLevel ||
        holiday1.customs != holiday2.customs ||
        holiday1.taboos != holiday2.taboos ||
        holiday1.foods != holiday2.foods ||
        holiday1.greetings != holiday2.greetings ||
        holiday1.activities != holiday2.activities ||
        holiday1.history != holiday2.history ||
        holiday1.imageUrl != holiday2.imageUrl ||
        holiday1.userImportance != holiday2.userImportance ||
        holiday1.nameEn != holiday2.nameEn ||
        holiday1.descriptionEn != holiday2.descriptionEn) {
      return true;
    }

    // 比较多语言字段
    if (!_mapsEqual(holiday1.names, holiday2.names) ||
        !_mapsEqual(holiday1.descriptions, holiday2.descriptions) ||
        !_mapsEqual(holiday1.customsMultilingual, holiday2.customsMultilingual) ||
        !_mapsEqual(holiday1.taboosMultilingual, holiday2.taboosMultilingual) ||
        !_mapsEqual(holiday1.foodsMultilingual, holiday2.foodsMultilingual) ||
        !_mapsEqual(holiday1.greetingsMultilingual, holiday2.greetingsMultilingual) ||
        !_mapsEqual(holiday1.activitiesMultilingual, holiday2.activitiesMultilingual) ||
        !_mapsEqual(holiday1.historyMultilingual, holiday2.historyMultilingual)) {
      return true;
    }

    return false;
  }

  /// 处理下载的联系人数据
  Future<void> _processDownloadedContacts(List<ContactModel> contacts) async {
    // 获取本地联系人数据
    final localContacts = _dbService.getAllContacts();
    final localContactsMap = {
      for (var contact in localContacts) contact.id: contact
    };

    // 处理每个下载的联系人
    for (final cloudContact in contacts) {
      // 检查是否存在本地版本
      if (localContactsMap.containsKey(cloudContact.id)) {
        final localContact = localContactsMap[cloudContact.id]!;

        // 检查最后修改时间
        if (cloudContact.lastModified != null &&
            localContact.lastModified != null) {
          if (cloudContact.lastModified!.isAfter(localContact.lastModified!)) {
            // 云端版本更新，使用云端版本
            await _dbService.saveContact(cloudContact);
          }
          // 如果本地版本更新，保留本地版本
        } else {
          // 如果没有时间戳，默认使用云端版本
          await _dbService.saveContact(cloudContact);
        }
      } else {
        // 本地不存在，直接导入
        await _dbService.saveContact(cloudContact);
      }
    }
  }

  /// 处理下载的用户设置
  Future<void> _processDownloadedSettings(UserSettingsModel settings) async {
    // 获取本地用户设置
    final localSettings = _dbService.getUserSettings();

    // 如果本地设置不存在，直接导入
    if (localSettings == null) {
      await _dbService.saveUserSettings(settings);
      return;
    }

    // 检查最后修改时间
    if (settings.lastModified.isAfter(localSettings.lastModified)) {
      // 云端版本更新，使用云端版本
      await _dbService.saveUserSettings(settings);
    }
    // 如果本地版本更新，保留本地版本
  }

  /// 处理下载的提醒事件数据
  Future<void> _processDownloadedEvents(List<ReminderEventModel> events) async {
    // 获取本地提醒事件数据
    final localEvents = _dbService.getAllReminderEvents();
    final localEventsMap = {
      for (var event in localEvents) event.id: event
    };

    // 处理每个下载的提醒事件
    for (final cloudEvent in events) {
      // 检查是否存在本地版本
      if (localEventsMap.containsKey(cloudEvent.id)) {
        final localEvent = localEventsMap[cloudEvent.id]!;

        // 检查最后修改时间
        if (cloudEvent.lastModified != null &&
            localEvent.lastModified != null) {
          if (cloudEvent.lastModified!.isAfter(localEvent.lastModified!)) {
            // 云端版本更新，使用云端版本
            await _dbService.saveReminderEvent(cloudEvent);
          }
          // 如果本地版本更新，保留本地版本
        } else {
          // 如果没有时间戳，默认使用云端版本
          await _dbService.saveReminderEvent(cloudEvent);
        }
      } else {
        // 本地不存在，直接导入
        await _dbService.saveReminderEvent(cloudEvent);
      }
    }
  }

  /// 生成认证令牌
  String _generateAuthToken(String username, String password) {
    // 使用用户名和密码生成令牌
    final bytes = utf8.encode('$username:$password:${DateTime.now().millisecondsSinceEpoch}');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 生成用户ID
  String _generateUserId(String username) {
    // 使用用户名生成用户ID
    final bytes = utf8.encode(username);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 保存认证信息
  Future<void> _saveAuthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null && _userId != null) {
        await prefs.setString('auth_token', _authToken!);
        await prefs.setString('user_id', _userId!);
      } else {
        await prefs.remove('auth_token');
        await prefs.remove('user_id');
      }
    } catch (e) {
      debugPrint('保存认证信息失败: $e');
    }
  }

  /// 加载认证信息
  Future<void> _loadAuthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      _userId = prefs.getString('user_id');
    } catch (e) {
      debugPrint('加载认证信息失败: $e');
    }
  }

  /// 获取最后同步时间
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_sync_time');
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('获取最后同步时间失败: $e');
      return null;
    }
  }

  /// 更新最后同步时间
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_sync_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('更新最后同步时间失败: $e');
    }
  }

  /// 比较两个列表是否相等
  bool _listsEqual<T>(List<T>? list1, List<T>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }

    return true;
  }

  /// 比较两个映射是否相等
  bool _mapsEqual<K, V>(Map<K, V>? map1, Map<K, V>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }

    return true;
  }
}
