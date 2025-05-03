/// 提醒事项优先级
enum ReminderPriority {
  /// 无优先级
  none,
  
  /// 低优先级
  low,
  
  /// 中优先级
  medium,
  
  /// 高优先级
  high,
}

/// 将整数转换为优先级
ReminderPriority intToPriority(int value) {
  switch (value) {
    case 0:
      return ReminderPriority.none;
    case 1:
      return ReminderPriority.low;
    case 2:
      return ReminderPriority.medium;
    case 3:
      return ReminderPriority.high;
    default:
      return ReminderPriority.none;
  }
}

/// 将优先级转换为整数
int priorityToInt(ReminderPriority priority) {
  switch (priority) {
    case ReminderPriority.none:
      return 0;
    case ReminderPriority.low:
      return 1;
    case ReminderPriority.medium:
      return 2;
    case ReminderPriority.high:
      return 3;
  }
}
