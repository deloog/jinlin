import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../reminder.dart';

final Logger logger = Logger('DataManager');

class DataManager {
  // 单例模式
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 缓存
  List<Reminder>? _cachedReminders;
  DateTime? _lastLoadTime;

  // 缓存过期时间（5分钟）
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // 获取提醒列表
  Future<List<Reminder>> getReminders({bool forceRefresh = false}) async {
    // 如果缓存有效且不强制刷新，则返回缓存
    if (!forceRefresh && _cachedReminders != null && _lastLoadTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastLoadTime!) < _cacheExpiration) {
        logger.info('Using cached reminders (${_cachedReminders!.length} items)');
        return _cachedReminders!;
      }
    }

    // 否则从 SharedPreferences 加载
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? remindersString = prefs.getString('reminders');
      
      if (remindersString != null) {
        final List<dynamic> reminderJson = jsonDecode(remindersString);
        final loadedReminders = reminderJson
            .map((json) => Reminder.fromJson(json))
            .whereType<Reminder>() // 确保转换成功
            .toList();
        
        // 更新缓存
        _cachedReminders = loadedReminders;
        _lastLoadTime = DateTime.now();
        
        logger.info('Loaded ${loadedReminders.length} reminders from SharedPreferences');
        return loadedReminders;
      } else {
        // 如果没有数据，返回空列表
        _cachedReminders = [];
        _lastLoadTime = DateTime.now();
        return [];
      }
    } catch (e) {
      logger.warning('Failed to load reminders: $e');
      // 如果加载失败但有缓存，返回缓存
      if (_cachedReminders != null) {
        logger.info('Returning cached reminders after load failure');
        return _cachedReminders!;
      }
      // 否则抛出异常
      rethrow;
    }
  }

  // 保存提醒列表
  Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String remindersString = jsonEncode(reminders.map((r) => r.toJson()).toList());
      await prefs.setString('reminders', remindersString);
      
      // 更新缓存
      _cachedReminders = List.from(reminders);
      _lastLoadTime = DateTime.now();
      
      logger.info('Saved ${reminders.length} reminders to SharedPreferences');
    } catch (e) {
      logger.warning('Failed to save reminders: $e');
      rethrow;
    }
  }

  // 添加提醒
  Future<void> addReminder(Reminder reminder) async {
    try {
      // 先获取当前列表
      final reminders = await getReminders();
      // 添加新提醒
      reminders.add(reminder);
      // 保存更新后的列表
      await saveReminders(reminders);
      logger.info('Added reminder: ${reminder.title}');
    } catch (e) {
      logger.warning('Failed to add reminder: $e');
      rethrow;
    }
  }

  // 更新提醒
  Future<void> updateReminder(Reminder updatedReminder) async {
    try {
      // 先获取当前列表
      final reminders = await getReminders();
      // 查找要更新的提醒
      final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
      if (index != -1) {
        // 更新提醒
        reminders[index] = updatedReminder;
        // 保存更新后的列表
        await saveReminders(reminders);
        logger.info('Updated reminder: ${updatedReminder.title}');
      } else {
        logger.warning('Reminder not found for update: ${updatedReminder.id}');
        throw Exception('Reminder not found');
      }
    } catch (e) {
      logger.warning('Failed to update reminder: $e');
      rethrow;
    }
  }

  // 删除提醒
  Future<void> deleteReminder(String id) async {
    try {
      // 先获取当前列表
      final reminders = await getReminders();
      // 删除提醒
      final initialLength = reminders.length;
      reminders.removeWhere((r) => r.id == id);
      
      // 检查是否真的删除了
      if (reminders.length < initialLength) {
        // 保存更新后的列表
        await saveReminders(reminders);
        logger.info('Deleted reminder: $id');
      } else {
        logger.warning('Reminder not found for deletion: $id');
        throw Exception('Reminder not found');
      }
    } catch (e) {
      logger.warning('Failed to delete reminder: $e');
      rethrow;
    }
  }

  // 切换提醒完成状态
  Future<void> toggleReminderComplete(String id) async {
    try {
      // 先获取当前列表
      final reminders = await getReminders();
      // 查找要更新的提醒
      final index = reminders.indexWhere((r) => r.id == id);
      if (index != -1) {
        // 切换完成状态
        reminders[index] = reminders[index].toggleComplete();
        // 保存更新后的列表
        await saveReminders(reminders);
        logger.info('Toggled reminder complete: ${reminders[index].title}');
      } else {
        logger.warning('Reminder not found for toggle: $id');
        throw Exception('Reminder not found');
      }
    } catch (e) {
      logger.warning('Failed to toggle reminder complete: $e');
      rethrow;
    }
  }

  // 清除缓存
  void clearCache() {
    _cachedReminders = null;
    _lastLoadTime = null;
    logger.info('Cache cleared');
  }

  // 导出数据到文件
  Future<String> exportData() async {
    try {
      // 获取所有提醒
      final reminders = await getReminders();
      
      // 创建导出数据
      final exportData = {
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      // 转换为 JSON 字符串
      final jsonString = jsonEncode(exportData);
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'jinlin_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      
      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      logger.info('Data exported to: $filePath');
      return filePath;
    } catch (e) {
      logger.warning('Failed to export data: $e');
      rethrow;
    }
  }

  // 从文件导入数据
  Future<int> importData(String filePath) async {
    try {
      // 读取文件
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // 解析 JSON
      final importData = jsonDecode(jsonString);
      
      // 验证数据格式
      if (!importData.containsKey('reminders') || !importData.containsKey('version')) {
        throw Exception('Invalid backup file format');
      }
      
      // 转换为 Reminder 对象
      final List<dynamic> reminderJsonList = importData['reminders'];
      final importedReminders = reminderJsonList
          .map((json) => Reminder.fromJson(json))
          .whereType<Reminder>()
          .toList();
      
      // 保存导入的提醒
      await saveReminders(importedReminders);
      
      // 清除缓存
      clearCache();
      
      logger.info('Imported ${importedReminders.length} reminders from: $filePath');
      return importedReminders.length;
    } catch (e) {
      logger.warning('Failed to import data: $e');
      rethrow;
    }
  }
}
