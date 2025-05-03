import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:jinlin_app/utils/date_utils.dart';

/// 应用程序状态
///
/// 管理应用程序的全局状态
class AppState extends ChangeNotifier {
  // 节日存储库
  final HolidayRepository _holidayRepository;

  // 提醒事项存储库
  final ReminderRepository _reminderRepository;

  // 日志服务
  final LoggingService _logger = LoggingService();

  // 当前选择的日期
  DateTime _selectedDate = DateTime.now();

  // 当前选择的地区
  String _selectedRegion = 'CN';

  // 当前选择的语言
  String _selectedLanguage = 'zh';

  // 节日列表
  List<Holiday> _holidays = [];

  // 提醒事项列表
  List<Reminder> _reminders = [];

  // 是否正在加载
  bool _isLoading = false;

  // 是否正在同步
  bool _isSyncing = false;

  // 错误消息
  String? _errorMessage;

  /// 构造函数
  AppState({
    required HolidayRepository holidayRepository,
    required ReminderRepository reminderRepository,
  }) :
    _holidayRepository = holidayRepository,
    _reminderRepository = reminderRepository {
    _logger.debug('初始化应用程序状态');

    // 初始化数据
    _loadData();
  }

  /// 获取当前选择的日期
  DateTime get selectedDate => _selectedDate;

  /// 获取当前选择的地区
  String get selectedRegion => _selectedRegion;

  /// 获取当前选择的语言
  String get selectedLanguage => _selectedLanguage;

  /// 获取节日列表
  List<Holiday> get holidays => _holidays;

  /// 获取提醒事项列表
  List<Reminder> get reminders => _reminders;

  /// 获取是否正在加载
  bool get isLoading => _isLoading;

  /// 获取是否正在同步
  bool get isSyncing => _isSyncing;

  /// 获取错误消息
  String? get errorMessage => _errorMessage;

  /// 获取今天的节日
  List<Holiday> get todayHolidays {
    final today = AppDateUtils.today();
    return _holidays.where((holiday) {
      // 这里需要根据节日的计算规则判断是否是今天的节日
      // 简化实现，仅检查日期字符串是否匹配
      return holiday.calculationRule.contains('${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
    }).toList();
  }

  /// 获取今天的提醒事项
  List<Reminder> get todayReminders {
    final today = AppDateUtils.formatDate(AppDateUtils.today());
    return _reminders.where((reminder) => reminder.date == today && !reminder.isDeleted).toList();
  }

  /// 获取未完成的提醒事项
  List<Reminder> get incompleteReminders {
    return _reminders.where((reminder) => !reminder.isCompleted && !reminder.isDeleted).toList();
  }

  /// 获取已完成的提醒事项
  List<Reminder> get completedReminders {
    return _reminders.where((reminder) => reminder.isCompleted && !reminder.isDeleted).toList();
  }

  /// 获取特定日期的节日
  List<Holiday> getHolidaysByDate(DateTime date) {
    // 这里需要根据节日的计算规则判断是否是特定日期的节日
    // 简化实现，仅检查日期字符串是否匹配
    final dateString = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays.where((holiday) => holiday.calculationRule.contains(dateString)).toList();
  }

  /// 获取特定日期的提醒事项
  List<Reminder> getRemindersByDate(DateTime date) {
    final dateString = AppDateUtils.formatDate(date);
    return _reminders.where((reminder) => reminder.date == dateString && !reminder.isDeleted).toList();
  }

  /// 设置当前选择的日期
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 设置当前选择的地区
  Future<void> setSelectedRegion(String region) async {
    if (_selectedRegion == region) return;

    _selectedRegion = region;
    notifyListeners();

    // 重新加载节日数据
    await _loadHolidays();
  }

  /// 设置当前选择的语言
  Future<void> setSelectedLanguage(String language) async {
    if (_selectedLanguage == language) return;

    _selectedLanguage = language;
    notifyListeners();

    // 重新加载节日数据
    await _loadHolidays();
  }

  /// 加载数据
  Future<void> _loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 并行加载节日和提醒事项
      await Future.wait([
        _loadHolidays(),
        _loadReminders(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载数据失败', e, stack);
      _isLoading = false;
      _errorMessage = '加载数据失败: $e';
      notifyListeners();
    }
  }

  /// 加载节日数据
  Future<void> _loadHolidays() async {
    try {
      _holidays = await _holidayRepository.getHolidaysByRegion(_selectedRegion, _selectedLanguage);
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载节日数据失败', e, stack);
      _errorMessage = '加载节日数据失败: $e';
      notifyListeners();
    }
  }

  /// 加载提醒事项数据
  Future<void> _loadReminders() async {
    try {
      _reminders = await _reminderRepository.getReminders();
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载提醒事项数据失败', e, stack);
      _errorMessage = '加载提醒事项数据失败: $e';
      notifyListeners();
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _loadData();
  }

  /// 同步数据
  Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 同步节日数据
      await _holidayRepository.syncHolidays(_selectedRegion, _selectedLanguage);

      // 同步提醒事项数据
      await _reminderRepository.syncReminders();

      // 重新加载数据
      await _loadData();

      _isSyncing = false;
      notifyListeners();
    } catch (e, stack) {
      _logger.error('同步数据失败', e, stack);
      _isSyncing = false;
      _errorMessage = '同步数据失败: $e';
      notifyListeners();
    }
  }

  /// 添加提醒事项
  Future<bool> addReminder(Reminder reminder) async {
    try {
      final success = await _reminderRepository.saveReminder(reminder);

      if (success) {
        // 重新加载提醒事项数据
        await _loadReminders();
      }

      return success;
    } catch (e, stack) {
      _logger.error('添加提醒事项失败', e, stack);
      _errorMessage = '添加提醒事项失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 更新提醒事项
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      final success = await _reminderRepository.updateReminder(reminder);

      if (success) {
        // 重新加载提醒事项数据
        await _loadReminders();
      }

      return success;
    } catch (e, stack) {
      _logger.error('更新提醒事项失败', e, stack);
      _errorMessage = '更新提醒事项失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除提醒事项
  Future<bool> deleteReminder(String id) async {
    try {
      final success = await _reminderRepository.deleteReminder(id);

      if (success) {
        // 重新加载提醒事项数据
        await _loadReminders();
      }

      return success;
    } catch (e, stack) {
      _logger.error('删除提醒事项失败', e, stack);
      _errorMessage = '删除提醒事项失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 标记提醒事项为已完成
  Future<bool> markReminderAsCompleted(String id) async {
    try {
      // 获取提醒事项
      final reminder = _reminders.firstWhere((r) => r.id == id);

      // 标记为已完成
      final updatedReminder = reminder.copyWith(
        isCompleted: true,
        lastModified: DateTime.now(),
      );

      // 更新提醒事项
      final success = await _reminderRepository.updateReminder(updatedReminder);

      if (success) {
        // 更新本地状态
        final index = _reminders.indexWhere((r) => r.id == id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
          notifyListeners();
        }
      }

      return success;
    } catch (e, stack) {
      _logger.error('标记提醒事项为已完成失败', e, stack);
      _errorMessage = '标记提醒事项为已完成失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 标记提醒事项为未完成
  Future<bool> markReminderAsIncomplete(String id) async {
    try {
      // 获取提醒事项
      final reminder = _reminders.firstWhere((r) => r.id == id);

      // 标记为未完成
      final updatedReminder = reminder.copyWith(
        isCompleted: false,
        lastModified: DateTime.now(),
      );

      // 更新提醒事项
      final success = await _reminderRepository.updateReminder(updatedReminder);

      if (success) {
        // 更新本地状态
        final index = _reminders.indexWhere((r) => r.id == id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
          notifyListeners();
        }
      }

      return success;
    } catch (e, stack) {
      _logger.error('标记提醒事项为未完成失败', e, stack);
      _errorMessage = '标记提醒事项为未完成失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
