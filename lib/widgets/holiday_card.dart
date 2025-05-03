import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/utils/date_utils.dart';

/// 节日卡片
///
/// 显示节日信息的卡片
class HolidayCard extends StatelessWidget {
  /// 节日
  final Holiday holiday;

  /// 发生日期
  final DateTime occurrenceDate;

  const HolidayCard({
    Key? key,
    required this.holiday,
    required this.occurrenceDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = holiday.getName('zh');
    final description = holiday.getDescription('zh') ?? '';

    // 计算距离今天的天数
    final today = DateTime.now();
    final daysUntil = AppDateUtils.daysBetween(
      DateTime(today.year, today.month, today.day),
      DateTime(occurrenceDate.year, occurrenceDate.month, occurrenceDate.day),
    );

    // 确定卡片颜色
    Color cardColor;
    if (daysUntil == 0) {
      // 今天
      cardColor = Colors.red.shade100;
    } else if (daysUntil > 0 && daysUntil <= 7) {
      // 一周内
      cardColor = Colors.orange.shade100;
    } else if (daysUntil > 0 && daysUntil <= 30) {
      // 一个月内
      cardColor = Colors.yellow.shade100;
    } else if (daysUntil < 0) {
      // 已过去
      cardColor = Colors.grey.shade100;
    } else {
      // 更远的未来
      cardColor = Colors.blue.shade50;
    }

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildHolidayIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDateText(daysUntil),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildImportanceBadge(context),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildHolidayTags(context),
          ],
        ),
      ),
    );
  }

  /// 构建节日图标
  Widget _buildHolidayIcon() {
    IconData iconData;
    Color iconColor;

    switch (holiday.type) {
      case HolidayType.traditional:
        iconData = Icons.celebration;
        iconColor = Colors.red;
        break;
      case HolidayType.international:
        iconData = Icons.public;
        iconColor = Colors.blue;
        break;
      case HolidayType.religious:
        iconData = Icons.church;
        iconColor = Colors.purple;
        break;
      case HolidayType.memorial:
        iconData = Icons.history_edu;
        iconColor = Colors.brown;
        break;
      case HolidayType.professional:
        iconData = Icons.work;
        iconColor = Colors.teal;
        break;
      case HolidayType.custom:
        iconData = Icons.person;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.event;
        iconColor = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  /// 构建重要性徽章
  Widget _buildImportanceBadge(BuildContext context) {
    Color badgeColor;
    String badgeText;

    switch (holiday.importanceLevel) {
      case ImportanceLevel.high:
        badgeColor = Colors.red;
        badgeText = '重要';
        break;
      case ImportanceLevel.medium:
        badgeColor = Colors.orange;
        badgeText = '中等';
        break;
      case ImportanceLevel.low:
        badgeColor = Colors.green;
        badgeText = '普通';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12,
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建节日标签
  Widget _buildHolidayTags(BuildContext context) {
    final tags = <Widget>[];

    // 添加节日类型标签
    tags.add(_buildTag(
      context,
      _getHolidayTypeText(holiday.type),
      _getHolidayTypeColor(holiday.type),
    ));

    // 添加地区标签
    if (holiday.regions.isNotEmpty) {
      tags.add(_buildTag(
        context,
        holiday.regions.first,
        Colors.blue,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags,
    );
  }

  /// 构建标签
  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  /// 获取日期文本
  String _getDateText(int daysUntil) {
    if (daysUntil == 0) {
      return '今天';
    } else if (daysUntil > 0) {
      return '还有 $daysUntil 天';
    } else {
      return '已过去 ${-daysUntil} 天';
    }
  }

  /// 获取节日类型文本
  String _getHolidayTypeText(HolidayType type) {
    switch (type) {
      case HolidayType.traditional:
        return '传统节日';
      case HolidayType.international:
        return '国际节日';
      case HolidayType.religious:
        return '宗教节日';
      case HolidayType.memorial:
        return '纪念日';
      case HolidayType.professional:
        return '行业节日';
      case HolidayType.custom:
        return '自定义节日';
      default:
        return '其他节日';
    }
  }

  /// 获取节日类型颜色
  Color _getHolidayTypeColor(HolidayType type) {
    switch (type) {
      case HolidayType.traditional:
        return Colors.red;
      case HolidayType.international:
        return Colors.blue;
      case HolidayType.religious:
        return Colors.purple;
      case HolidayType.memorial:
        return Colors.brown;
      case HolidayType.professional:
        return Colors.teal;
      case HolidayType.custom:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
