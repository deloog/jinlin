import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jinlin_app/adapters/reminder_adapter.dart';
import 'package:jinlin_app/models/timeline_item.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/widgets/holiday_card.dart';
import 'package:jinlin_app/widgets/reminder_card.dart';

/// 时间线列表
///
/// 显示时间线项目的列表
class TimelineList extends StatelessWidget {
  /// 时间线项目
  final List<TimelineItem> items;

  /// 项目点击回调
  final Function(TimelineItem)? onItemTap;

  const TimelineList({
    Key? key,
    required this.items,
    this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 按日期分组
    final groupedItems = _groupItemsByDate(items);

    return ListView.builder(
      itemCount: groupedItems.length,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemBuilder: (context, index) {
        final date = groupedItems.keys.elementAt(index);
        final dateItems = groupedItems[date]!;

        return _buildDateGroup(context, date, dateItems);
      },
    );
  }

  /// 按日期分组
  Map<DateTime, List<TimelineItem>> _groupItemsByDate(List<TimelineItem> items) {
    final groupedItems = <DateTime, List<TimelineItem>>{};

    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);

      if (!groupedItems.containsKey(date)) {
        groupedItems[date] = [];
      }

      groupedItems[date]!.add(item);
    }

    return groupedItems;
  }

  /// 构建日期组
  Widget _buildDateGroup(BuildContext context, DateTime date, List<TimelineItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(context, date),
        ...items.map((item) => _buildTimelineItem(context, item)),
      ],
    );
  }

  /// 构建日期头部
  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String dateText;
    if (date.isAtSameMomentAs(today)) {
      dateText = '今天';
    } else if (date.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateText = '明天';
    } else if (date.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = '昨天';
    } else {
      final formatter = DateFormat('yyyy年M月d日');
      dateText = formatter.format(date);
    }

    final weekday = AppDateUtils.getWeekday(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            weekday,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const Spacer(),
          if (AppDateUtils.isWeekend(date))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withAlpha(51),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '周末',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建时间线项目
  Widget _buildTimelineItem(BuildContext context, TimelineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        borderRadius: BorderRadius.circular(12.0),
        child: item.isHoliday
            ? HolidayCard(
                holiday: item.holiday!,
                occurrenceDate: item.date,
              )
            : ReminderCard(
                reminder: ReminderAdapter.adapt(item.reminder!),
                onTap: () => onItemTap?.call(item),
                onToggleComplete: (_) {},
              ),
      ),
    );
  }
}
