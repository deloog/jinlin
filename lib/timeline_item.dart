import 'reminder.dart'; // 导入提醒类
import 'special_date.dart'; // 导入特殊日期类

// 定义时间线项目的类型
enum TimelineItemType {
  reminder,
  holiday,
}

// 时间线项目包装类
class TimelineItem implements Comparable<TimelineItem> {
  final DateTime? displayDate; // 用于排序和分组的日期 (可以为 null)
  final TimelineItemType itemType; // 项目类型
  final dynamic originalObject; // 原始的 Reminder 或 SpecialDate 对象

  TimelineItem({
    required this.displayDate,
    required this.itemType,
    required this.originalObject,
  });

  // 实现 Comparable 接口，用于排序
  @override
  int compareTo(TimelineItem other) {
    // 将没有日期的项目排在最后
    if (displayDate == null && other.displayDate == null) return 0; // 两者都无日期
    if (displayDate == null) return 1; // 当前项无日期，排在后面
    if (other.displayDate == null) return -1; // 另一项无日期，排在后面 (当前项有日期，排在前面)

    // 两者都有日期，按日期比较
    int dateComparison = displayDate!.compareTo(other.displayDate!);

    // 如果日期相同，可以添加次要排序规则 (可选)
    // 例如，让提醒优先于同一天的节日？或者按创建时间？
    // if (dateComparison == 0) {
    //   // 示例：如果日期相同，提醒排在节日前面
    //   if (itemType == TimelineItemType.reminder && other.itemType == TimelineItemType.holiday) {
    //     return -1;
    //   }
    //   if (itemType == TimelineItemType.holiday && other.itemType == TimelineItemType.reminder) {
    //     return 1;
    //   }
    // }

    return dateComparison;
  }

  // 辅助 getter，方便获取原始对象
  Reminder? get reminder => (itemType == TimelineItemType.reminder) ? originalObject as Reminder : null;
  SpecialDate? get holiday => (itemType == TimelineItemType.holiday) ? originalObject as SpecialDate : null;
}