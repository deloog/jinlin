import 'package:flutter/material.dart';
import 'package:jinlin_app/adapters/holiday_adapter.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/widgets/common/expandable_text.dart';

/// 节日卡片组件
///
/// 显示节日信息的卡片
class HolidayCard extends StatelessWidget {
  /// 节日数据
  final Holiday holiday;

  /// 节日发生日期
  final DateTime? occurrenceDate;

  /// 是否显示详细信息
  final bool showDetails;

  /// 是否显示农历信息
  final bool showLunar;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 构造函数
  const HolidayCard({
    super.key,
    required this.holiday,
    this.occurrenceDate,
    this.showDetails = false,
    this.showLunar = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = HolidayAdapter.getDate(holiday, occurrenceDate);

    // 计算与今天的天数差
    final today = AppDateUtils.today();
    final daysUntil = AppDateUtils.daysBetween(today, date);

    // 确定卡片颜色
    Color cardColor;
    if (daysUntil == 0) {
      // 今天
      cardColor = theme.colorScheme.primaryContainer;
    } else if (daysUntil > 0 && daysUntil <= 7) {
      // 一周内
      cardColor = theme.colorScheme.secondaryContainer;
    } else if (daysUntil < 0) {
      // 已过去
      cardColor = theme.colorScheme.surfaceContainerHighest;
    } else {
      // 未来
      cardColor = theme.colorScheme.surface;
    }

    return Card(
      color: cardColor,
      elevation: daysUntil == 0 ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap ?? () {
          AppRouter.navigateToHolidayDetail(
            holiday,
            occurrenceDate: occurrenceDate,
          );
        },
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
                  // 日期部分
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getMonthAbbreviation(date.month),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 节日信息部分
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HolidayAdapter.getName(holiday, 'zh'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateString(date, daysUntil),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (showLunar && HolidayAdapter.isLunar(holiday)) ...[
                          const SizedBox(height: 4),
                          Text(
                            '农历: ${AppDateUtils.getLunarDate(date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getHolidayTypeColor(holiday.type, theme),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getHolidayTypeText(holiday.type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 16),
                ExpandableText(
                  text: HolidayAdapter.getDescription(holiday, 'zh') ?? '',
                  maxLines: 2,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 获取月份缩写
  String _getMonthAbbreviation(int month) {
    const months = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'];
    return months[month - 1];
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

  /// 获取节日类型文本
  String _getHolidayTypeText(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return '法定';
      case HolidayType.international:
        return '国际';
      case HolidayType.traditional:
        return '传统';
      case HolidayType.religious:
        return '宗教';
      case HolidayType.professional:
        return '行业';
      case HolidayType.memorial:
        return '纪念';
      case HolidayType.custom:
        return '自定义';
      case HolidayType.solarTerm:
        return '节气';
      case HolidayType.cultural:
        return '文化';
      case HolidayType.other:
        return '其他';
    }
  }

  /// 获取节日类型颜色
  Color _getHolidayTypeColor(HolidayType type, ThemeData theme) {
    switch (type) {
      case HolidayType.statutory:
        return Colors.red;
      case HolidayType.international:
        return Colors.blue;
      case HolidayType.traditional:
        return Colors.orange;
      case HolidayType.religious:
        return Colors.purple;
      case HolidayType.professional:
        return Colors.teal;
      case HolidayType.memorial:
        return Colors.brown;
      case HolidayType.custom:
        return Colors.green;
      case HolidayType.solarTerm:
        return Colors.amber;
      case HolidayType.cultural:
        return Colors.indigo;
      case HolidayType.other:
        return theme.colorScheme.secondary;
    }
  }
}
