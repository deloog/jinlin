// 文件： lib/reminder_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reminder.dart';
import 'add_reminder_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunar/lunar.dart';
import 'utils/date_formatter.dart';
import 'widgets/page_transitions.dart';

class ReminderDetailScreen extends StatelessWidget {
  final Reminder reminder;
  final int originalIndex;
  final List<Reminder> existingReminders;
  // final VoidCallback onDelete; // 示例回调

  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.originalIndex,
    required this.existingReminders,
    // required this.onDelete,
  });

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ... (对话框代码保持不变) ...
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteConfirmationTitle), // TODO: 本地化
          content: Text(l10n.deleteConfirmationContent), // TODO: 本地化
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancelButton), // TODO: 本地化
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.deleteButtonTooltip), // TODO: 本地化
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
     final l10n = AppLocalizations.of(context);

    // 提前格式化日期
    String formattedDate = reminder.dueDate != null
        ? DateFormat('yyyy-MM-dd HH:mm', locale).format(reminder.dueDate!)
        : l10n.dateNotSet; // TODO: 本地化

    // 根据是否完成设置文本样式
    final titleStyle = reminder.isCompleted
        ? textTheme.headlineMedium?.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey)
        : textTheme.headlineMedium;
    final bodyStyle = reminder.isCompleted
        ? textTheme.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey)
        : textTheme.bodyLarge;
    final dateStyle = reminder.isCompleted
        ? textTheme.titleMedium?.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey)
        : textTheme.titleMedium;

    // 判断是否适合显示 AI 功能 (示例：生日、纪念日等 - 需要更复杂的逻辑)
    bool showAiFeatures = reminder.title.contains('生日') || reminder.title.contains('纪念日'); // TODO: 替换为更可靠的判断逻辑

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminderDetailTitle), // TODO: 本地化
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editButtonTooltip, // TODO: 本地化
            onPressed: () {
              Navigator.push(
                context,
                SlidePageRoute(
                  page: AddReminderScreen(
                    initialReminder: reminder, // 传递当前提醒
                    reminderIndex: originalIndex,
                    existingReminders: existingReminders, // 传递索引
                    // 传递现有的提醒列表（如果 AddReminderScreen 还需要）
                    // 注意：这里可能需要从主页一路传递下来，或者使用状态管理
                    // 暂时假设 AddReminderScreen 不需要完整的列表来进行编辑本身
                    // 如果需要，你需要修改导航链条以传递 existingReminders
                    // existingReminders: ???
                  ),
                  direction: SlideDirection.up,
                ),
          ).then((result) {
            // 当从 AddReminderScreen 返回结果时
            if (result != null && result is Map && result.containsKey('reminder') && context.mounted) {
              // 如果是编辑结果，则将此结果直接 pop 回主页
              Navigator.of(context).pop({
                 'action': 'edited', // 添加一个 action 标识
                 'index': result['index'],
                 'reminder': result['reminder']
              });
            }
            // 如果从 AddReminderScreen 返回的不是预期的编辑结果，则什么也不做
          });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteButtonTooltip, // TODO: 本地化
            onPressed: () async {
              final confirmDelete = await _showDeleteConfirmationDialog(context);
              if (confirmDelete == true && context.mounted) {
                 Navigator.of(context).pop({
               'action': 'deleted',
               'index': originalIndex // 使用 widget. 访问 StatelessWidget 的属性
             });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // 使用 ListView 方便扩展
          children: <Widget>[
            // --- 基本信息 ---
            Text(reminder.title, style: titleStyle),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Icon(Icons.calendar_today, color: reminder.isCompleted ? Colors.grey : Colors.blueGrey),
                const SizedBox(width: 8.0),
                Text(formatReminderDate(context, reminder.dueDate,reminder.type), style: dateStyle),
              ],
            ),
             const SizedBox(height: 16.0),
             if (reminder.description.isNotEmpty) ...[ // 仅当描述不为空时显示
               const Divider(),
               const SizedBox(height: 16.0),
               Text(l10n.descriptionSectionTitle, style: textTheme.titleLarge), // TODO: 本地化
               const SizedBox(height: 8.0),
               Text(reminder.description, style: bodyStyle),
               const SizedBox(height: 24.0),
             ] else ... [
               const SizedBox(height: 8.0), // 如果没描述，也留点空间
             ],

             // --- AI 功能占位符 ---
             if (showAiFeatures) ...[
                const Divider(),
                const SizedBox(height: 16.0),
                _buildSectionHeader(context, l10n.aiAssistantSectionTitle, Icons.auto_awesome), // TODO: 本地化
                const SizedBox(height: 16.0),

                // 祝福语区域
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(l10n.aiBlessingSectionTitle, style: textTheme.titleMedium), // TODO: 本地化
                         const SizedBox(height: 8.0),
                         Text(l10n.aiBlessingsPlaceholder), // TODO: 本地化
                         Align(
                           alignment: Alignment.centerRight,
                           child: TextButton(
                             onPressed: () {
                               // TODO: 实现 "换一批" 逻辑 (可能涉及订阅检查)
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text(l10n.swapBlessingsButton)),
                               );
                             },
                             child: Text(l10n.swapBlessingsButton), // TODO: 本地化
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // 礼物推荐区域
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.aiGiftSectionTitle, style: textTheme.titleMedium), // TODO: 本地化
                        const SizedBox(height: 8.0),
                        Text(l10n.aiGiftsPlaceholder), // TODO: 本地化
                        // 可以添加按钮让用户明确请求推荐
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
             ],

             // 其他提示（可能所有提醒都有）
             const Divider(),
             const SizedBox(height: 16.0),
             _buildSectionHeader(context, l10n.smartTipsSectionTitle, Icons.lightbulb_outline), // TODO: 本地化
             const SizedBox(height: 8.0),
             Text(l10n.aiTipsPlaceholder), // TODO: 本地化

             const SizedBox(height: 24.0), // 底部留白
          ],
        ),
      ),
    );
  }

  // 辅助方法：构建带图标的区域标题
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
     return Row(
       children: [
         Icon(icon, color: Theme.of(context).colorScheme.primary),
         const SizedBox(width: 8.0),
         Text(title, style: Theme.of(context).textTheme.titleLarge),
       ],
     );
  }
}