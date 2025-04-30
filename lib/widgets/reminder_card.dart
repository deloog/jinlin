import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../reminder.dart';
import '../utils/date_formatter.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final bool isToday;
  final VoidCallback onTap;
  final Function(bool?) onToggleComplete;
  final bool showAnimation;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.isToday = false,
    required this.onTap,
    required this.onToggleComplete,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 文本样式
    final titleStyle = reminder.isCompleted
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          )
        : TextStyle(
            color: theme.textTheme.titleMedium?.color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          );

    final descriptionStyle = reminder.isCompleted
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey[400],
            fontSize: 14,
          )
        : TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 14,
          );

    final dateStyle = reminder.isCompleted
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey[400],
            fontSize: 12,
          )
        : TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );

    // 卡片颜色
    Color cardColor;
    if (isToday) {
      cardColor = theme.brightness == Brightness.dark
          ? Colors.blue.shade900.withOpacity(0.3)
          : Colors.blue.shade50;
    } else {
      cardColor = theme.brightness == Brightness.dark
          ? theme.cardColor.withOpacity(0.8)
          : theme.cardColor;
    }

    // 根据提醒类型设置图标和强调色
    IconData typeIcon;
    Color accentColor;

    switch (reminder.type) {
      case ReminderType.birthday:
        typeIcon = Icons.cake;
        accentColor = Colors.pink;
        break;
      case ReminderType.anniversary:
        typeIcon = Icons.favorite;
        accentColor = Colors.red;
        break;
      case ReminderType.chineseFestival:
        typeIcon = Icons.celebration;
        accentColor = Colors.orange;
        break;
      case ReminderType.memorialDay:
        typeIcon = Icons.sentiment_very_dissatisfied;
        accentColor = Colors.purple;
        break;
      case ReminderType.general:
      default:
        typeIcon = Icons.event_note;
        accentColor = theme.colorScheme.primary;
        break;
    }

    // 构建卡片内容
    Widget cardContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 复选框
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: reminder.isCompleted,
              onChanged: onToggleComplete,
              activeColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),

          // 类型图标 - 改进版，移除模糊效果
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              typeIcon,
              color: Colors.white,
              size: 20,
            ),
          ),

          // 提醒内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reminder.description.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    reminder.description,
                    style: descriptionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (reminder.dueDate != null) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: dateStyle.color,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        formatReminderDate(context, reminder.dueDate, reminder.type),
                        style: dateStyle,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 右侧箭头
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );

    // 构建卡片
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Card(
        elevation: isToday ? 2.0 : 1.0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: isToday
              ? BorderSide(color: accentColor.withOpacity(0.5), width: 1.0)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: cardContent,
        ),
      ),
    );
  }
}
