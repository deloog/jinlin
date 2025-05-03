import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/widgets/expandable_text.dart';
// 暂时注释掉未安装的依赖
// import 'package:share_plus/share_plus.dart';

/// 节日详情屏幕
///
/// 显示节日的详细信息
class HolidayDetailScreen extends StatelessWidget {
  /// 节日
  final Holiday holiday;

  /// 发生日期
  final DateTime? occurrenceDate;

  const HolidayDetailScreen({
    super.key,
    required this.holiday,
    this.occurrenceDate,
  });

  @override
  Widget build(BuildContext context) {
    final name = holiday.getName('zh');
    final description = holiday.getDescription('zh') ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareHoliday(context),
            tooltip: '分享',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节日图片
            if (holiday.imageUrl != null && holiday.imageUrl!.isNotEmpty)
              Image.network(
                holiday.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: _getHolidayTypeColor(holiday.type).withAlpha(51),
                  child: Center(
                    child: Icon(
                      _getHolidayTypeIcon(holiday.type),
                      size: 80,
                      color: _getHolidayTypeColor(holiday.type),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: _getHolidayTypeColor(holiday.type).withAlpha(51),
                child: Center(
                  child: Icon(
                    _getHolidayTypeIcon(holiday.type),
                    size: 80,
                    color: _getHolidayTypeColor(holiday.type),
                  ),
                ),
              ),

            // 基本信息
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 节日名称
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 日期信息
                  if (occurrenceDate != null) ...[
                    Text(
                      '日期: ${AppDateUtils.formatDate(occurrenceDate!)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '星期: ${AppDateUtils.getWeekday(occurrenceDate!)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                    if (holiday.type == HolidayType.traditional) ...[
                      const SizedBox(height: 4),
                      Text(
                        '农历日期',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _getCountdownText(occurrenceDate!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getCountdownColor(context, occurrenceDate!),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(
                        context,
                        _getHolidayTypeText(holiday.type),
                        _getHolidayTypeColor(holiday.type),
                      ),
                      _buildTag(
                        context,
                        _getImportanceLevelText(holiday.importanceLevel),
                        _getImportanceLevelColor(holiday.importanceLevel),
                      ),
                      if (holiday.regions.isNotEmpty)
                        ...holiday.regions.map((region) => _buildTag(
                          context,
                          region,
                          Colors.blue,
                        )),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 描述
                  const Text(
                    '描述',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpandableText(
                    description.isEmpty ? '暂无描述' : description,
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 习俗
                  if (holiday.customs != null && holiday.customs!.isNotEmpty) ...[
                    const Text(
                      '习俗',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.customs!['zh'] ?? holiday.customs!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 禁忌
                  if (holiday.taboos != null && holiday.taboos!.isNotEmpty) ...[
                    const Text(
                      '禁忌',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.taboos!['zh'] ?? holiday.taboos!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 美食
                  if (holiday.foods != null && holiday.foods!.isNotEmpty) ...[
                    const Text(
                      '美食',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.foods!['zh'] ?? holiday.foods!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 祝福语
                  if (holiday.greetings != null && holiday.greetings!.isNotEmpty) ...[
                    const Text(
                      '祝福语',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.greetings!['zh'] ?? holiday.greetings!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 活动
                  if (holiday.activities != null && holiday.activities!.isNotEmpty) ...[
                    const Text(
                      '活动',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.activities!['zh'] ?? holiday.activities!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 历史
                  if (holiday.history != null && holiday.history!.isNotEmpty) ...[
                    const Text(
                      '历史',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExpandableText(
                      holiday.history!['zh'] ?? holiday.history!.values.first,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addReminder(context),
        tooltip: '添加提醒',
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        return '个人节日';
      case HolidayType.statutory:
        return '法定节日';
      case HolidayType.cultural:
        return '文化节日';
      case HolidayType.solarTerm:
        return '节气';
      case HolidayType.other:
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
      case HolidayType.statutory:
        return Colors.red.shade800;
      case HolidayType.cultural:
        return Colors.deepPurple;
      case HolidayType.solarTerm:
        return Colors.amber;
      case HolidayType.other:
        return Colors.grey;
    }
  }

  /// 获取节日类型图标
  IconData _getHolidayTypeIcon(HolidayType type) {
    switch (type) {
      case HolidayType.traditional:
        return Icons.celebration;
      case HolidayType.international:
        return Icons.public;
      case HolidayType.religious:
        return Icons.church;
      case HolidayType.memorial:
        return Icons.history_edu;
      case HolidayType.professional:
        return Icons.work;
      case HolidayType.custom:
        return Icons.person;
      case HolidayType.statutory:
        return Icons.gavel;
      case HolidayType.cultural:
        return Icons.theater_comedy;
      case HolidayType.solarTerm:
        return Icons.wb_sunny;
      case HolidayType.other:
        return Icons.event;
    }
  }

  /// 获取重要性文本
  String _getImportanceLevelText(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.high:
        return '重要';
      case ImportanceLevel.medium:
        return '中等';
      case ImportanceLevel.low:
        return '普通';
    }
  }

  /// 获取重要性颜色
  Color _getImportanceLevelColor(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.high:
        return Colors.red;
      case ImportanceLevel.medium:
        return Colors.orange;
      case ImportanceLevel.low:
        return Colors.green;
    }
  }

  /// 获取倒计时文本
  String _getCountdownText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final daysUntil = AppDateUtils.daysBetween(today, targetDate);

    if (daysUntil == 0) {
      return '今天';
    } else if (daysUntil > 0) {
      return '还有 $daysUntil 天';
    } else {
      return '已过去 ${-daysUntil} 天';
    }
  }

  /// 获取倒计时颜色
  Color _getCountdownColor(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final daysUntil = AppDateUtils.daysBetween(today, targetDate);

    if (daysUntil == 0) {
      return Colors.red;
    } else if (daysUntil > 0 && daysUntil <= 7) {
      return Colors.orange;
    } else if (daysUntil > 0) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Colors.grey;
    }
  }

  /// 分享节日
  void _shareHoliday(BuildContext context) {
    final name = holiday.getName('zh');
    final description = holiday.getDescription('zh') ?? '';

    String shareText = '$name\n';

    if (occurrenceDate != null) {
      shareText += '日期: ${AppDateUtils.formatDate(occurrenceDate!)}\n';
    }

    if (description.isNotEmpty) {
      shareText += '\n$description\n';
    }

    shareText += '\n来自 CetaMind Reminder';

    // 暂时使用简单的提示，等依赖安装后再启用真正的分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享内容: $shareText')),
    );

    // 注释掉Share相关代码，等依赖安装后再启用
    // Share.share(shareText);
  }

  /// 添加提醒
  void _addReminder(BuildContext context) {
    // TODO: 实现添加提醒功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加提醒功能尚未实现')),
    );
  }
}
