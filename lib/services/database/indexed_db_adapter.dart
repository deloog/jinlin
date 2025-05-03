import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// IndexedDB适配器
///
/// 使用Hive实现的IndexedDB适配器，专为Web平台设计
class IndexedDBAdapter implements DatabaseInterface {
  static final IndexedDBAdapter _instance = IndexedDBAdapter._internal();

  factory IndexedDBAdapter() {
    return _instance;
  }

  IndexedDBAdapter._internal();

  final LoggingService _logger = LoggingService();
  bool _initialized = false;

  // 盒子名称
  static const String _holidaysBoxName = 'holidays';
  static const String _remindersBoxName = 'reminders';
  static const String _versionsBoxName = 'versions';
  static const String _settingsBoxName = 'settings';

  // 盒子
  Box<String>? _holidaysBox;
  Box<String>? _remindersBox;
  Box<String>? _versionsBox;
  Box<String>? _settingsBox;

  /// 获取是否已初始化
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.debug('初始化IndexedDB适配器');
      debugPrint('初始化IndexedDB适配器');

      // 初始化Hive
      await Hive.initFlutter();

      // 打开盒子
      _holidaysBox = await Hive.openBox<String>(_holidaysBoxName);
      _remindersBox = await Hive.openBox<String>(_remindersBoxName);
      _versionsBox = await Hive.openBox<String>(_versionsBoxName);
      _settingsBox = await Hive.openBox<String>(_settingsBoxName);

      _initialized = true;
      _logger.info('IndexedDB适配器初始化完成');
      debugPrint('IndexedDB适配器初始化完成');
    } catch (e, stack) {
      _logger.error('IndexedDB适配器初始化失败', e, stack);
      debugPrint('IndexedDB适配器初始化失败: $e');
      debugPrint('堆栈: $stack');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (!_initialized) return;

    try {
      await _holidaysBox?.close();
      await _remindersBox?.close();
      await _versionsBox?.close();
      await _settingsBox?.close();

      _initialized = false;
      _logger.debug('IndexedDB适配器已关闭');
    } catch (e, stack) {
      _logger.error('关闭IndexedDB适配器失败', e, stack);
      rethrow;
    }
  }

  // 节日相关方法

  @override
  Future<List<Holiday>> getHolidaysByRegion(String regionCode, String languageCode) async {
    _checkInitialized();

    try {
      final holidays = <Holiday>[];
      
      // 获取所有节日
      for (var i = 0; i < _holidaysBox!.length; i++) {
        final key = _holidaysBox!.keyAt(i);
        final value = _holidaysBox!.get(key);
        
        if (value != null) {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final holiday = Holiday.fromMap(map);
          
          // 检查地区
          if (holiday.regions.contains(regionCode) && !holiday.isDeleted) {
            holidays.add(holiday);
          }
        }
      }

      _logger.debug('从IndexedDB获取到 ${holidays.length} 个 $regionCode 地区的节日');
      return holidays;
    } catch (e, stack) {
      _logger.error('从IndexedDB获取节日数据失败', e, stack);
      return [];
    }
  }

  @override
  Future<void> saveHoliday(Holiday holiday, {bool needsSync = false}) async {
    _checkInitialized();

    try {
      final map = holiday.toMap();
      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await _holidaysBox!.put(holiday.id, jsonEncode(map));
      _logger.debug('保存节日到IndexedDB: ${holiday.id}');
    } catch (e, stack) {
      _logger.error('保存节日到IndexedDB失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    _checkInitialized();

    try {
      final batch = <String, String>{};

      for (final holiday in holidays) {
        batch[holiday.id] = jsonEncode(holiday.toMap());
      }

      await _holidaysBox!.putAll(batch);
      _logger.debug('保存 ${holidays.length} 个节日到IndexedDB');
    } catch (e, stack) {
      _logger.error('保存多个节日到IndexedDB失败', e, stack);
      rethrow;
    }
  }

  // 提醒事项相关方法

  @override
  Future<List<Reminder>> getReminders() async {
    _checkInitialized();

    try {
      final reminders = <Reminder>[];
      
      // 获取所有提醒事项
      for (var i = 0; i < _remindersBox!.length; i++) {
        final key = _remindersBox!.keyAt(i);
        final value = _remindersBox!.get(key);
        
        if (value != null) {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final reminder = Reminder.fromMap(map);
          
          // 检查是否已删除
          if (!reminder.isDeleted) {
            reminders.add(reminder);
          }
        }
      }

      _logger.debug('从IndexedDB获取到 ${reminders.length} 个提醒事项');
      return reminders;
    } catch (e, stack) {
      _logger.error('从IndexedDB获取提醒事项失败', e, stack);
      return [];
    }
  }

  @override
  Future<void> saveReminder(Reminder reminder, {bool needsSync = false}) async {
    _checkInitialized();

    try {
      final map = reminder.toMap();
      if (needsSync) {
        map['needs_sync'] = 1;
      }

      await _remindersBox!.put(reminder.id, jsonEncode(map));
      _logger.debug('保存提醒事项到IndexedDB: ${reminder.id}');
    } catch (e, stack) {
      _logger.error('保存提醒事项到IndexedDB失败', e, stack);
      rethrow;
    }
  }

  // 辅助方法

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_initialized) {
      throw Exception('IndexedDB适配器尚未初始化');
    }
  }
}
