import 'package:jinlin_app/models/unified/reminder.dart' as unified;
import 'package:jinlin_app/reminder.dart' as legacy;

/// 提醒事项适配器
///
/// 用于将统一的Reminder模型转换为旧的Reminder模型，以便在旧的UI组件中使用
class ReminderAdapter {
  /// 将统一的Reminder模型转换为旧的Reminder模型
  static legacy.Reminder adapt(unified.Reminder reminder) {
    // 解析日期
    final dateParts = reminder.date.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    // 创建日期时间
    DateTime? dueDate;
    if (reminder.time != null && !reminder.isAllDay) {
      final timeParts = reminder.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      dueDate = DateTime(year, month, day, hour, minute);
    } else {
      dueDate = DateTime(year, month, day);
    }

    // 确定提醒类型
    legacy.ReminderType type = legacy.ReminderType.general;

    // 确定优先级
    legacy.ReminderPriority priority;
    switch (reminder.importance) {
      case 1:
        priority = legacy.ReminderPriority.low;
        break;
      case 2:
        priority = legacy.ReminderPriority.medium;
        break;
      case 3:
        priority = legacy.ReminderPriority.high;
        break;
      default:
        priority = legacy.ReminderPriority.none;
    }

    return legacy.Reminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description ?? '',
      dueDate: dueDate,
      isCompleted: reminder.isCompleted,
      type: type,
      priority: priority,
      completedDate: reminder.isCompleted ? DateTime.now() : null,
      notes: reminder.description,
    );
  }

  /// 将旧的Reminder模型转换为统一的Reminder模型
  static unified.Reminder adaptBack(legacy.Reminder reminder) {
    // 格式化日期
    String date = '';
    String? time;

    if (reminder.dueDate != null) {
      date = '${reminder.dueDate!.year}-${reminder.dueDate!.month.toString().padLeft(2, '0')}-${reminder.dueDate!.day.toString().padLeft(2, '0')}';

      if (reminder.dueDate!.hour != 0 || reminder.dueDate!.minute != 0) {
        time = '${reminder.dueDate!.hour.toString().padLeft(2, '0')}:${reminder.dueDate!.minute.toString().padLeft(2, '0')}';
      }
    }

    return unified.Reminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      date: date,
      time: time,
      isAllDay: time == null,
      isCompleted: reminder.isCompleted,
      importance: 0,
    );
  }
}
