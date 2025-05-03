import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';

/// 提醒事项详情业务逻辑
///
/// 管理提醒事项详情屏幕的数据和状态
class ReminderDetailBloc extends ChangeNotifier {
  final ReminderRepository _reminderRepository;
  final LoggingService _logger;

  // 提醒事项
  final Reminder? _reminder;

  // 是否是编辑模式
  final bool _isEditing;

  // 加载状态
  bool _isLoading = false;

  // 保存状态
  bool _isSaving = false;

  // 表单数据
  String _title = '';
  String? _description;
  DateTime _date = DateTime.now();
  String? _time;
  bool _isAllDay = true;
  bool _isCompleted = false;
  bool _isRecurring = false;
  String? _recurrenceRule;
  int _importance = 0;
  Color? _color;
  IconData? _icon;

  /// 获取是否是编辑模式
  bool get isEditing => _isEditing;

  /// 获取是否正在加载
  bool get isLoading => _isLoading;

  /// 获取是否正在保存
  bool get isSaving => _isSaving;

  /// 获取标题
  String get title => _title;

  /// 设置标题
  set title(String value) {
    _title = value;
    notifyListeners();
  }

  /// 获取描述
  String? get description => _description;

  /// 设置描述
  set description(String? value) {
    _description = value;
    notifyListeners();
  }

  /// 获取日期
  DateTime get date => _date;

  /// 设置日期
  set date(DateTime value) {
    _date = value;
    notifyListeners();
  }

  /// 获取时间
  String? get time => _time;

  /// 设置时间
  set time(String? value) {
    _time = value;
    notifyListeners();
  }

  /// 获取时间（TimeOfDay格式）
  TimeOfDay get timeOfDay {
    if (_time != null) {
      final parts = _time!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return TimeOfDay.now();
  }

  /// 设置时间（TimeOfDay格式）
  set timeOfDay(TimeOfDay value) {
    _time = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  /// 获取是否全天事项
  bool get isAllDay => _isAllDay;

  /// 设置是否全天事项
  set isAllDay(bool value) {
    _isAllDay = value;
    notifyListeners();
  }

  /// 获取是否已完成
  bool get isCompleted => _isCompleted;

  /// 设置是否已完成
  set isCompleted(bool value) {
    _isCompleted = value;
    notifyListeners();
  }

  /// 获取是否重复
  bool get isRecurring => _isRecurring;

  /// 设置是否重复
  set isRecurring(bool value) {
    _isRecurring = value;
    notifyListeners();
  }

  /// 获取重复规则
  String? get recurrenceRule => _recurrenceRule;

  /// 设置重复规则
  set recurrenceRule(String? value) {
    _recurrenceRule = value;
    notifyListeners();
  }

  /// 获取重要性
  int get importance => _importance;

  /// 设置重要性
  set importance(int value) {
    _importance = value;
    notifyListeners();
  }

  /// 获取颜色
  Color? get color => _color;

  /// 设置颜色
  set color(Color? value) {
    _color = value;
    notifyListeners();
  }

  /// 获取图标
  IconData? get icon => _icon;

  /// 设置图标
  set icon(IconData? value) {
    _icon = value;
    notifyListeners();
  }

  ReminderDetailBloc({
    required ReminderRepository reminderRepository,
    required LoggingService logger,
    Reminder? reminder,
    required bool isEditing,
  }) :
    _reminderRepository = reminderRepository,
    _logger = logger,
    _reminder = reminder,
    _isEditing = isEditing {
    _logger.debug('初始化ReminderDetailBloc');

    if (reminder != null) {
      _loadReminder(reminder);
    }
  }

  /// 加载提醒事项
  void _loadReminder(Reminder reminder) {
    _isLoading = true;
    notifyListeners();

    try {
      _title = reminder.title;
      _description = reminder.description;
      _date = reminder.getDateTime();
      _time = reminder.time;
      _isAllDay = reminder.isAllDay;
      _isCompleted = reminder.isCompleted;
      _isRecurring = reminder.isRecurring;
      _recurrenceRule = reminder.recurrenceRule;
      _importance = reminder.importance;
      _color = reminder.color;
      _icon = reminder.icon;

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      _logger.error('加载提醒事项失败', e, stack);

      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存提醒事项
  Future<bool> saveReminder() async {
    if (_isSaving) return false;

    _isSaving = true;
    notifyListeners();

    try {
      _logger.debug('保存提醒事项');

      final dateString = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      if (_isEditing && _reminder != null) {
        // 更新提醒事项
        final updatedReminder = _reminder.copyWith(
          title: _title,
          description: _description,
          date: dateString,
          time: _isAllDay ? null : _time,
          isAllDay: _isAllDay,
          isCompleted: _isCompleted,
          isRecurring: _isRecurring,
          recurrenceRule: _isRecurring ? _recurrenceRule : null,
          importance: _importance,
          color: _color,
          icon: _icon,
          lastModified: DateTime.now(),
        );

        final success = await _reminderRepository.updateReminder(updatedReminder);

        _isSaving = false;
        notifyListeners();

        return success;
      } else {
        // 创建新提醒事项
        final newReminder = Reminder.create(
          title: _title,
          description: _description,
          date: dateString,
          time: _isAllDay ? null : _time,
          isAllDay: _isAllDay,
          isRecurring: _isRecurring,
          recurrenceRule: _isRecurring ? _recurrenceRule : null,
          importance: _importance,
          color: _color,
          icon: _icon,
        );

        final success = await _reminderRepository.saveReminder(newReminder);

        _isSaving = false;
        notifyListeners();

        return success;
      }
    } catch (e, stack) {
      _logger.error('保存提醒事项失败', e, stack);

      _isSaving = false;
      notifyListeners();

      return false;
    }
  }

  /// 删除提醒事项
  Future<bool> deleteReminder() async {
    if (_isSaving || !_isEditing || _reminder == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      _logger.debug('删除提醒事项: ${_reminder.id}');

      // 由于前面已经检查了_reminder是否为null，这里可以安全使用
      final success = await _reminderRepository.deleteReminder(_reminder.id);

      _isSaving = false;
      notifyListeners();

      return success;
    } catch (e, stack) {
      _logger.error('删除提醒事项失败', e, stack);

      _isSaving = false;
      notifyListeners();

      return false;
    }
  }
}
