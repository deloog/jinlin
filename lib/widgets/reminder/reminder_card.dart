import 'package:flutter/material.dart';
import 'package:jinlin_app/reminder.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/widgets/common/expandable_text.dart';

/// 提醒事项卡片组件
///
/// 显示提醒事项信息的卡片
class ReminderCard extends StatelessWidget {
  /// 提醒事项数据
  final Reminder reminder;

  /// 是否显示详细信息
  final bool showDetails;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 完成状态变更回调
  final ValueChanged<bool>? onCompletedChanged;

  /// 构造函数
  const ReminderCard({
    super.key,
    required this.reminder,
    this.showDetails = false,
    this.onTap,
    this.onLongPress,
    this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算与今天的天数差
    final today = AppDateUtils.today();
    final daysUntil = reminder.dueDate != null ? AppDateUtils.daysBetween(today, reminder.dueDate!) : 0;

    // 确定卡片颜色
    Color cardColor;
    if (reminder.isCompleted) {
      // 已完成
      cardColor = theme.colorScheme.surfaceContainerHighest.withAlpha(179);
    } else if (daysUntil < 0) {
      // 已过期
      cardColor = theme.colorScheme.errorContainer.withAlpha(179);
    } else if (daysUntil == 0) {
      // 今天
      cardColor = theme.colorScheme.primaryContainer;
    } else if (daysUntil <= 3) {
      // 三天内
      cardColor = theme.colorScheme.secondaryContainer;
    } else {
      // 未来
      cardColor = theme.colorScheme.surface;
    }

    return Card(
      color: cardColor,
      elevation: (daysUntil == 0 && !reminder.isCompleted) ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 完成状态复选框
                  Checkbox(
                    value: reminder.isCompleted,
                    onChanged: onCompletedChanged != null
                        ? (value) => onCompletedChanged!(value ?? false)
                        : null,
                    shape: const CircleBorder(),
                  ),
                  const SizedBox(width: 8),
                  // 提醒事项信息部分
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.dueDate != null ? _formatDateString(reminder.dueDate!, daysUntil) : '无日期',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 优先级标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(reminder.priority, theme),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getPriorityText(reminder.priority),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (showDetails && reminder.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: ExpandableText(
                    text: reminder.description,
                    maxLines: 2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: reminder.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化日期字符串
  String _formatDateString(DateTime date, int daysUntil) {
    final dateStr = AppDateUtils.formatDate(date);

    if (daysUntil == 0) {
      return '今天 $dateStr';
    } else if (daysUntil == 1) {
      return '明天 $dateStr';
    } else if (daysUntil == -1) {
      return '昨天 $dateStr';
    } else if (daysUntil > 0) {
      return '$daysUntil天后 $dateStr';
    } else {
      return '${-daysUntil}天前 $dateStr';
    }
  }

  /// 获取优先级文本
  String _getPriorityText(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return '高';
      case ReminderPriority.medium:
        return '中';
      case ReminderPriority.low:
        return '低';
      default:
        return '无';
    }
  }

  /// 获取优先级颜色
  Color _getPriorityColor(ReminderPriority priority, ThemeData theme) {
    switch (priority) {
      case ReminderPriority.high:
        return Colors.red;
      case ReminderPriority.medium:
        return Colors.orange;
      case ReminderPriority.low:
        return Colors.green;
      default:
        return theme.colorScheme.secondary;
    }
  }
}
