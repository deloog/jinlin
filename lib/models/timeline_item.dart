import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';

/// 节日发生日期
class HolidayOccurrence {
  /// 节日
  final Holiday holiday;

  /// 发生日期
  final DateTime date;

  HolidayOccurrence({
    required this.holiday,
    required this.date,
  });
}

/// 时间线项目类型
enum TimelineItemType {
  /// 节日
  holiday,

  /// 提醒事项
  reminder,
}

/// 时间线项目
///
/// 表示时间线上的一个项目，可以是节日或提醒事项
class TimelineItem {
  /// 日期
  final DateTime date;

  /// 类型
  final TimelineItemType type;

  /// 节日（如果类型是节日）
  final Holiday? holiday;

  /// 提醒事项（如果类型是提醒事项）
  final Reminder? reminder;

  /// 构造函数
  TimelineItem({
    required this.date,
    required this.type,
    this.holiday,
    this.reminder,
  });

  /// 创建节日时间线项目
  factory TimelineItem.holiday({
    required DateTime date,
    required Holiday holiday,
  }) {
    return TimelineItem(
      date: date,
      type: TimelineItemType.holiday,
      holiday: holiday,
    );
  }

  /// 创建提醒事项时间线项目
  factory TimelineItem.reminder({
    required DateTime date,
    required Reminder reminder,
  }) {
    return TimelineItem(
      date: date,
      type: TimelineItemType.reminder,
      reminder: reminder,
    );
  }

  /// 是否是节日
  bool get isHoliday => type == TimelineItemType.holiday;

  /// 是否是提醒事项
  bool get isReminder => type == TimelineItemType.reminder;

  /// 获取标题
  String get title {
    if (isHoliday) {
      return holiday!.getName('zh');
    } else {
      return reminder!.title;
    }
  }

  /// 获取描述
  String? get description {
    if (isHoliday) {
      return holiday!.getDescription('zh');
    } else {
      return reminder!.description;
    }
  }

  /// 获取重要性
  int get importance {
    if (isHoliday) {
      return holiday!.importanceLevel.index;
    } else {
      return reminder!.importance;
    }
  }

  @override
  String toString() {
    if (isHoliday) {
      return 'TimelineItem(date: $date, holiday: ${holiday!.id})';
    } else {
      return 'TimelineItem(date: $date, reminder: ${reminder!.id})';
    }
  }
}
