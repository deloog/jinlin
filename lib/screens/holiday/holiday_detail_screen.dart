import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/providers/app_state.dart';
import 'package:jinlin_app/providers/settings_provider.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/widgets/common/expandable_text.dart';
import 'package:provider/provider.dart';

/// 节日详情屏幕
///
/// 显示节日的详细信息
class HolidayDetailScreen extends StatelessWidget {
  /// 节日
  final Holiday holiday;

  /// 节日发生日期
  final DateTime? occurrenceDate;

  /// 构造函数
  const HolidayDetailScreen({
    super.key,
    required this.holiday,
    this.occurrenceDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 使用 Provider.of 而不是变量
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final appState = Provider.of<AppState>(context);

    // 使用节日发生日期或当前日期
    final date = occurrenceDate ?? DateTime.now();

    // 计算与今天的天数差
    final today = AppDateUtils.today();
    final daysUntil = AppDateUtils.daysBetween(today, date);

    return Scaffold(
      appBar: AppBar(
        title: Text(holiday.getLocalizedName('zh')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 导航到编辑节日屏幕
              // TODO: 实现编辑节日功能
            },
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 分享节日信息
              // TODO: 实现分享功能
            },
            tooltip: '分享',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节日卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 节日名称和类型
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            holiday.getLocalizedName('zh'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 16),

                    // 日期信息
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date.toString().substring(0, 10),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 倒计时信息
                    Row(
                      children: [
                        Icon(
                          daysUntil > 0 ? Icons.hourglass_empty : Icons.hourglass_full,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCountdown(daysUntil),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: daysUntil == 0
                                ? theme.colorScheme.primary
                                : daysUntil > 0
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // 农历信息
                    if (settingsProvider.showLunar) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.brightness_4,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '农历日期',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],

                    // 节气信息
                    if (settingsProvider.showSolarTerms) ...[
                      const SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: Future.value(""),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.wb_sunny,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '节气: ${snapshot.data}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 节日描述
            if (holiday.getLocalizedDescription('zh') != null) ...[
              Text(
                '节日描述',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExpandableText(
                    text: holiday.getLocalizedDescription('zh') ?? '',
                    maxLines: 5,
                    expanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 相关提醒事项
            Text(
              '相关提醒事项',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: Future.value(appState.getRemindersByDate(date)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '加载提醒事项失败: ${snapshot.error}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  );
                }

                final reminders = snapshot.data ?? [];

                if (reminders.isEmpty) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '没有相关提醒事项',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // 导航到添加提醒事项屏幕
                              // TODO: 实现添加提醒事项功能
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('添加提醒事项'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: reminder.description != null && reminder.description!.isNotEmpty
                            ? Text(
                                reminder.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  decoration: reminder.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              )
                            : null,
                        leading: Checkbox(
                          value: reminder.isCompleted,
                          onChanged: (value) {
                            if (value == true) {
                              appState.markReminderAsCompleted(reminder.id);
                            } else {
                              appState.markReminderAsIncomplete(reminder.id);
                            }
                          },
                          shape: const CircleBorder(),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // 导航到编辑提醒事项屏幕
                            // TODO: 实现编辑提醒事项功能
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 导航到添加提醒事项屏幕，预填节日信息
          // TODO: 实现添加提醒事项功能
        },
        tooltip: '添加提醒',
        child: const Icon(Icons.add_alert),
      ),
    );
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
      case HolidayType.cultural:
        return '文化';
      case HolidayType.solarTerm:
        return '节气';
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
      case HolidayType.cultural:
        return Colors.deepPurple;
      case HolidayType.solarTerm:
        return Colors.amber;
      case HolidayType.other:
        return theme.colorScheme.secondary;
    }
  }

  /// 格式化倒计时
  String _formatCountdown(int daysUntil) {
    if (daysUntil == 0) {
      return '今天';
    } else if (daysUntil == 1) {
      return '明天';
    } else if (daysUntil == -1) {
      return '昨天';
    } else if (daysUntil > 0) {
      return '还有 $daysUntil 天';
    } else {
      return '已过去 ${-daysUntil} 天';
    }
  }
}
