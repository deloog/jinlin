import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/hive_database_service_enhanced.dart';

/// 数据验证和修复服务
///
/// 负责验证数据的完整性和一致性，并提供修复功能
class DatabaseValidatorService {
  // 单例模式
  static final DatabaseValidatorService _instance = DatabaseValidatorService._internal();
  factory DatabaseValidatorService() => _instance;
  DatabaseValidatorService._internal();

  // 数据库服务
  final _dbService = HiveDatabaseServiceEnhanced();

  /// 验证所有数据
  Future<Map<String, Map<String, List<String>>>> validateAllData() async {
    final result = <String, Map<String, List<String>>>{};
    
    // 验证节日数据
    final holidayIssues = await validateHolidays();
    if (holidayIssues.isNotEmpty) {
      result['holidays'] = holidayIssues;
    }
    
    // 验证联系人数据
    final contactIssues = await validateContacts();
    if (contactIssues.isNotEmpty) {
      result['contacts'] = contactIssues;
    }
    
    // 验证用户设置数据
    final settingsIssues = await validateUserSettings();
    if (settingsIssues.isNotEmpty) {
      result['settings'] = settingsIssues;
    }
    
    // 验证提醒事件数据
    final eventIssues = await validateReminderEvents();
    if (eventIssues.isNotEmpty) {
      result['events'] = eventIssues;
    }
    
    return result;
  }

  /// 验证节日数据
  Future<Map<String, List<String>>> validateHolidays() async {
    final issues = <String, List<String>>{};
    
    // 获取所有节日
    final holidays = _dbService.getAllHolidays();
    
    for (final holiday in holidays) {
      final holidayIssues = _validateHoliday(holiday);
      if (holidayIssues.isNotEmpty) {
        issues[holiday.id] = holidayIssues;
      }
    }
    
    return issues;
  }

  /// 验证单个节日
  List<String> _validateHoliday(HolidayModelExtended holiday) {
    final issues = <String>[];
    
    // 验证基本字段
    if (holiday.id.isEmpty) {
      issues.add('ID为空');
    }
    
    if (holiday.name.isEmpty) {
      issues.add('名称为空');
    }
    
    if (holiday.regions.isEmpty) {
      issues.add('地区列表为空');
    }
    
    if (holiday.calculationRule.isEmpty) {
      issues.add('计算规则为空');
    }
    
    // 验证计算规则格式
    if (!_isValidCalculationRule(holiday.calculationType, holiday.calculationRule)) {
      issues.add('计算规则格式无效: ${holiday.calculationRule}');
    }
    
    return issues;
  }

  /// 验证计算规则格式
  bool _isValidCalculationRule(DateCalculationType type, String rule) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        // 检查格式：MM-DD
        return RegExp(r'^\d{2}-\d{2}$').hasMatch(rule);
      case DateCalculationType.fixedLunar:
        // 检查格式：MM-DDL
        return RegExp(r'^\d{2}-\d{2}L$').hasMatch(rule);
      case DateCalculationType.nthWeekdayOfMonth:
        // 检查格式：MM,N,W
        return RegExp(r'^\d{1,2},\d{1},\d{1}$').hasMatch(rule);
      case DateCalculationType.lastWeekdayOfMonth:
        // 检查格式：MM,W
        return RegExp(r'^\d{1,2},\d{1}$').hasMatch(rule);
      case DateCalculationType.solarTermBased:
        // 检查是否为有效的节气名称
        final validSolarTerms = [
          'LiChun', 'YuShui', 'JingZhe', 'ChunFen', 'QingMing', 'GuYu',
          'LiXia', 'XiaoMan', 'MangZhong', 'XiaZhi', 'XiaoShu', 'DaShu',
          'LiQiu', 'ChuShu', 'BaiLu', 'QiuFen', 'HanLu', 'ShuangJiang',
          'LiDong', 'XiaoXue', 'DaXue', 'DongZhi', 'XiaoHan', 'DaHan'
        ];
        return validSolarTerms.contains(rule);
      case DateCalculationType.easterBased:
        // 检查格式：Easter,+/-N
        return RegExp(r'^Easter,[+-]\d+$').hasMatch(rule);
      case DateCalculationType.relativeTo:
        // 检查格式：HOLIDAY_ID,+/-N
        return RegExp(r'^[a-zA-Z0-9_]+,[+-]\d+$').hasMatch(rule);
      default:
        return true;
    }
  }

  /// 验证联系人数据
  Future<Map<String, List<String>>> validateContacts() async {
    final issues = <String, List<String>>{};
    
    // 获取所有联系人
    final contacts = _dbService.getAllContacts();
    
    for (final contact in contacts) {
      final contactIssues = _validateContact(contact);
      if (contactIssues.isNotEmpty) {
        issues[contact.id] = contactIssues;
      }
    }
    
    return issues;
  }

  /// 验证单个联系人
  List<String> _validateContact(ContactModel contact) {
    final issues = <String>[];
    
    // 验证基本字段
    if (contact.id.isEmpty) {
      issues.add('ID为空');
    }
    
    if (contact.name.isEmpty) {
      issues.add('名称为空');
    }
    
    // 验证电话号码格式
    if (contact.phoneNumber != null && contact.phoneNumber!.isNotEmpty) {
      if (!_isValidPhoneNumber(contact.phoneNumber!)) {
        issues.add('电话号码格式无效: ${contact.phoneNumber}');
      }
    }
    
    // 验证邮箱格式
    if (contact.email != null && contact.email!.isNotEmpty) {
      if (!_isValidEmail(contact.email!)) {
        issues.add('邮箱格式无效: ${contact.email}');
      }
    }
    
    return issues;
  }

  /// 验证电话号码格式
  bool _isValidPhoneNumber(String phoneNumber) {
    // 简单的电话号码验证，可以根据需要调整
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phoneNumber);
  }

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    // 简单的邮箱验证，可以根据需要调整
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// 验证用户设置数据
  Future<Map<String, List<String>>> validateUserSettings() async {
    final issues = <String, List<String>>{};
    
    // 获取用户设置
    final settings = _dbService.getUserSettings();
    if (settings == null) {
      issues['settings'] = ['用户设置不存在'];
      return issues;
    }
    
    final settingsIssues = _validateUserSettings(settings);
    if (settingsIssues.isNotEmpty) {
      issues[settings.userId] = settingsIssues;
    }
    
    return issues;
  }

  /// 验证用户设置
  List<String> _validateUserSettings(UserSettingsModel settings) {
    final issues = <String>[];
    
    // 验证基本字段
    if (settings.userId.isEmpty) {
      issues.add('用户ID为空');
    }
    
    if (settings.nickname.isEmpty) {
      issues.add('昵称为空');
    }
    
    if (settings.languageCode.isEmpty) {
      issues.add('语言代码为空');
    }
    
    return issues;
  }

  /// 验证提醒事件数据
  Future<Map<String, List<String>>> validateReminderEvents() async {
    final issues = <String, List<String>>{};
    
    // 获取所有提醒事件
    final events = _dbService.getAllReminderEvents();
    
    for (final event in events) {
      final eventIssues = _validateReminderEvent(event);
      if (eventIssues.isNotEmpty) {
        issues[event.id] = eventIssues;
      }
    }
    
    return issues;
  }

  /// 验证单个提醒事件
  List<String> _validateReminderEvent(ReminderEventModel event) {
    final issues = <String>[];
    
    // 验证基本字段
    if (event.id.isEmpty) {
      issues.add('ID为空');
    }
    
    if (event.title.isEmpty) {
      issues.add('标题为空');
    }
    
    // 验证重复规则
    if (event.isRepeating && (event.repeatRule == null || event.repeatRule!.isEmpty)) {
      issues.add('重复事件缺少重复规则');
    }
    
    // 验证完成状态
    if (event.isCompleted && event.status != ReminderStatus.completed) {
      issues.add('完成状态与状态不一致');
    }
    
    return issues;
  }

  /// 修复所有数据问题
  Future<Map<String, int>> fixAllDataIssues() async {
    final result = <String, int>{};
    
    // 验证并修复节日数据
    final holidayIssues = await validateHolidays();
    if (holidayIssues.isNotEmpty) {
      final fixedCount = await _fixHolidayIssues(holidayIssues);
      result['holidays'] = fixedCount;
    }
    
    // 验证并修复联系人数据
    final contactIssues = await validateContacts();
    if (contactIssues.isNotEmpty) {
      final fixedCount = await _fixContactIssues(contactIssues);
      result['contacts'] = fixedCount;
    }
    
    // 验证并修复用户设置数据
    final settingsIssues = await validateUserSettings();
    if (settingsIssues.isNotEmpty) {
      final fixedCount = await _fixUserSettingsIssues(settingsIssues);
      result['settings'] = fixedCount;
    }
    
    // 验证并修复提醒事件数据
    final eventIssues = await validateReminderEvents();
    if (eventIssues.isNotEmpty) {
      final fixedCount = await _fixReminderEventIssues(eventIssues);
      result['events'] = fixedCount;
    }
    
    return result;
  }

  /// 修复节日数据问题
  Future<int> _fixHolidayIssues(Map<String, List<String>> issues) async {
    int fixedCount = 0;
    
    for (final entry in issues.entries) {
      final holidayId = entry.key;
      final holidayIssues = entry.value;
      
      // 获取节日
      final holiday = _dbService.getHolidayById(holidayId);
      if (holiday == null) continue;
      
      bool isFixed = false;
      
      // 修复问题
      for (final issue in holidayIssues) {
        if (issue.contains('计算规则格式无效')) {
          // 尝试修复计算规则
          final fixedRule = _fixCalculationRule(holiday.calculationType, holiday.calculationRule);
          if (fixedRule != holiday.calculationRule) {
            holiday.calculationRule = fixedRule;
            isFixed = true;
          }
        }
        
        // 可以添加更多修复逻辑
      }
      
      // 保存修复后的节日
      if (isFixed) {
        await _dbService.saveHoliday(holiday);
        fixedCount++;
      }
    }
    
    return fixedCount;
  }

  /// 修复计算规则
  String _fixCalculationRule(DateCalculationType type, String rule) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        // 尝试修复格式：MM-DD
        final match = RegExp(r'(\d{1,2})[^\d](\d{1,2})').firstMatch(rule);
        if (match != null) {
          final month = match.group(1)!.padLeft(2, '0');
          final day = match.group(2)!.padLeft(2, '0');
          return '$month-$day';
        }
        return rule;
      case DateCalculationType.fixedLunar:
        // 尝试修复格式：MM-DDL
        final match = RegExp(r'(\d{1,2})[^\d](\d{1,2})').firstMatch(rule);
        if (match != null) {
          final month = match.group(1)!.padLeft(2, '0');
          final day = match.group(2)!.padLeft(2, '0');
          return '$month-${day}L';
        }
        return rule;
      default:
        return rule;
    }
  }

  /// 修复联系人数据问题
  Future<int> _fixContactIssues(Map<String, List<String>> issues) async {
    int fixedCount = 0;
    
    for (final entry in issues.entries) {
      final contactId = entry.key;
      final contactIssues = entry.value;
      
      // 获取联系人
      final contact = _dbService.getContactById(contactId);
      if (contact == null) continue;
      
      bool isFixed = false;
      
      // 修复问题
      for (final issue in contactIssues) {
        if (issue.contains('电话号码格式无效')) {
          // 尝试修复电话号码
          final fixedPhone = _fixPhoneNumber(contact.phoneNumber!);
          if (fixedPhone != contact.phoneNumber) {
            contact.phoneNumber = fixedPhone;
            isFixed = true;
          }
        }
        
        if (issue.contains('邮箱格式无效')) {
          // 尝试修复邮箱
          final fixedEmail = _fixEmail(contact.email!);
          if (fixedEmail != contact.email) {
            contact.email = fixedEmail;
            isFixed = true;
          }
        }
        
        // 可以添加更多修复逻辑
      }
      
      // 保存修复后的联系人
      if (isFixed) {
        await _dbService.saveContact(contact);
        fixedCount++;
      }
    }
    
    return fixedCount;
  }

  /// 修复电话号码
  String _fixPhoneNumber(String phoneNumber) {
    // 移除非数字、空格、括号和连字符以外的字符
    return phoneNumber.replaceAll(RegExp(r'[^\d\s\-\(\)\+]'), '');
  }

  /// 修复邮箱
  String _fixEmail(String email) {
    // 简单的邮箱修复，移除空格
    return email.replaceAll(' ', '');
  }

  /// 修复用户设置数据问题
  Future<int> _fixUserSettingsIssues(Map<String, List<String>> issues) async {
    int fixedCount = 0;
    
    // 获取用户设置
    final settings = _dbService.getUserSettings();
    if (settings == null) return 0;
    
    bool isFixed = false;
    
    // 修复问题
    if (issues.containsKey(settings.userId)) {
      final settingsIssues = issues[settings.userId]!;
      
      for (final issue in settingsIssues) {
        if (issue.contains('昵称为空')) {
          // 设置默认昵称
          settings.nickname = 'User';
          isFixed = true;
        }
        
        if (issue.contains('语言代码为空')) {
          // 设置默认语言代码
          settings.languageCode = 'zh';
          isFixed = true;
        }
        
        // 可以添加更多修复逻辑
      }
    }
    
    // 保存修复后的用户设置
    if (isFixed) {
      await _dbService.saveUserSettings(settings);
      fixedCount++;
    }
    
    return fixedCount;
  }

  /// 修复提醒事件数据问题
  Future<int> _fixReminderEventIssues(Map<String, List<String>> issues) async {
    int fixedCount = 0;
    
    for (final entry in issues.entries) {
      final eventId = entry.key;
      final eventIssues = entry.value;
      
      // 获取提醒事件
      final event = _dbService.getReminderEventById(eventId);
      if (event == null) continue;
      
      bool isFixed = false;
      
      // 修复问题
      for (final issue in eventIssues) {
        if (issue.contains('重复事件缺少重复规则')) {
          // 设置默认重复规则
          event.repeatRule = _getDefaultRepeatRule(event.type);
          isFixed = true;
        }
        
        if (issue.contains('完成状态与状态不一致')) {
          // 修复状态不一致
          if (event.isCompleted) {
            event.status = ReminderStatus.completed;
          } else {
            event.status = ReminderStatus.pending;
          }
          isFixed = true;
        }
        
        // 可以添加更多修复逻辑
      }
      
      // 保存修复后的提醒事件
      if (isFixed) {
        await _dbService.saveReminderEvent(event);
        fixedCount++;
      }
    }
    
    return fixedCount;
  }

  /// 获取默认重复规则
  String _getDefaultRepeatRule(ReminderEventType type) {
    switch (type) {
      case ReminderEventType.birthday:
        return 'FREQ=YEARLY;BYMONTH=${DateTime.now().month};BYMONTHDAY=${DateTime.now().day}';
      case ReminderEventType.anniversary:
        return 'FREQ=YEARLY;BYMONTH=${DateTime.now().month};BYMONTHDAY=${DateTime.now().day}';
      default:
        return 'FREQ=DAILY';
    }
  }
}
