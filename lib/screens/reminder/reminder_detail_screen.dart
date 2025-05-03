import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/screens/reminder/reminder_detail_bloc.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:jinlin_app/utils/date_utils.dart';

/// 提醒事项详情屏幕
///
/// 用于创建或编辑提醒事项
class ReminderDetailScreen extends StatelessWidget {
  /// 提醒事项（如果是编辑模式）
  final Reminder? reminder;

  /// 是否是编辑模式
  final bool isEditing;

  const ReminderDetailScreen({
    super.key,
    this.reminder,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReminderDetailBloc(
        reminderRepository: Provider.of<ReminderRepository>(context, listen: false),
        logger: Provider.of<LoggingService>(context, listen: false),
        reminder: reminder,
        isEditing: isEditing,
      ),
      child: const _ReminderDetailContent(),
    );
  }
}

class _ReminderDetailContent extends StatefulWidget {
  const _ReminderDetailContent();

  @override
  State<_ReminderDetailContent> createState() => _ReminderDetailContentState();
}

class _ReminderDetailContentState extends State<_ReminderDetailContent> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 初始化表单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = Provider.of<ReminderDetailBloc>(context, listen: false);

      _titleController.text = bloc.title;
      _descriptionController.text = bloc.description ?? '';

      // 监听文本变化
      _titleController.addListener(() {
        bloc.title = _titleController.text;
      });

      _descriptionController.addListener(() {
        bloc.description = _descriptionController.text;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<ReminderDetailBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(bloc.isEditing ? '编辑提醒' : '新建提醒'),
        actions: [
          if (bloc.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, bloc),
              tooltip: '删除',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: bloc.isSaving ? null : () => _saveReminder(context, bloc),
            tooltip: '保存',
          ),
        ],
      ),
      body: bloc.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(context, bloc),
    );
  }

  /// 构建表单
  Widget _buildForm(BuildContext context, ReminderDetailBloc bloc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '输入提醒标题',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 描述
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述',
              hintText: '输入提醒描述（可选）',
              border: OutlineInputBorder(),
            ),
            maxLength: 500,
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 日期
          ListTile(
            title: const Text('日期'),
            subtitle: Text(AppDateUtils.formatDate(bloc.date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, bloc),
          ),
          const Divider(),

          // 全天事项
          SwitchListTile(
            title: const Text('全天事项'),
            value: bloc.isAllDay,
            onChanged: (value) => bloc.isAllDay = value,
          ),

          // 时间（如果不是全天事项）
          if (!bloc.isAllDay)
            ListTile(
              title: const Text('时间'),
              subtitle: Text(bloc.time ?? '未设置'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, bloc),
            ),
          const Divider(),

          // 重复
          SwitchListTile(
            title: const Text('重复'),
            value: bloc.isRecurring,
            onChanged: (value) => bloc.isRecurring = value,
          ),

          // 重复规则（如果启用重复）
          if (bloc.isRecurring)
            ListTile(
              title: const Text('重复规则'),
              subtitle: Text(_getRecurrenceRuleText(bloc.recurrenceRule)),
              trailing: const Icon(Icons.repeat),
              onTap: () => _selectRecurrenceRule(context, bloc),
            ),
          const Divider(),

          // 重要性
          ListTile(
            title: const Text('重要性'),
            subtitle: Text(_getImportanceText(bloc.importance)),
            trailing: const Icon(Icons.priority_high),
            onTap: () => _selectImportance(context, bloc),
          ),

          // 颜色
          ListTile(
            title: const Text('颜色'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bloc.color ?? Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _selectColor(context, bloc),
          ),

          // 图标
          ListTile(
            title: const Text('图标'),
            trailing: Icon(bloc.icon ?? Icons.notifications),
            onTap: () => _selectIcon(context, bloc),
          ),

          const SizedBox(height: 32),

          // 完成状态（仅编辑模式）
          if (bloc.isEditing)
            CheckboxListTile(
              title: const Text('已完成'),
              value: bloc.isCompleted,
              onChanged: (value) => bloc.isCompleted = value ?? false,
            ),
        ],
      ),
    );
  }

  /// 选择日期
  Future<void> _selectDate(BuildContext context, ReminderDetailBloc bloc) async {
    final initialDate = bloc.date;
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 10));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      bloc.date = selectedDate;
    }
  }

  /// 选择时间
  Future<void> _selectTime(BuildContext context, ReminderDetailBloc bloc) async {
    final initialTime = bloc.timeOfDay;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      bloc.timeOfDay = selectedTime;
    }
  }

  /// 选择重复规则
  void _selectRecurrenceRule(BuildContext context, ReminderDetailBloc bloc) {
    // TODO: 实现选择重复规则
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('选择重复规则功能尚未实现')),
    );
  }

  /// 选择重要性
  void _selectImportance(BuildContext context, ReminderDetailBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择重要性'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('普通'),
              value: 0,
              groupValue: bloc.importance,
              onChanged: (value) {
                bloc.importance = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('重要'),
              value: 1,
              groupValue: bloc.importance,
              onChanged: (value) {
                bloc.importance = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('非常重要'),
              value: 2,
              groupValue: bloc.importance,
              onChanged: (value) {
                bloc.importance = value!;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 选择颜色
  void _selectColor(BuildContext context, ReminderDetailBloc bloc) {
    // TODO: 实现选择颜色
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('选择颜色功能尚未实现')),
    );
  }

  /// 选择图标
  void _selectIcon(BuildContext context, ReminderDetailBloc bloc) {
    // TODO: 实现选择图标
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('选择图标功能尚未实现')),
    );
  }

  /// 保存提醒事项
  Future<void> _saveReminder(BuildContext context, ReminderDetailBloc bloc) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    final success = await bloc.saveReminder();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }

  /// 确认删除
  void _confirmDelete(BuildContext context, ReminderDetailBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除提醒'),
        content: const Text('确定要删除这个提醒吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await bloc.deleteReminder();

              if (!mounted) return;

              if (success) {
                Navigator.of(context).pop();
              } else {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('删除失败，请重试')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 获取重要性文本
  String _getImportanceText(int importance) {
    switch (importance) {
      case 0:
        return '普通';
      case 1:
        return '重要';
      case 2:
        return '非常重要';
      default:
        return '普通';
    }
  }

  /// 获取重复规则文本
  String _getRecurrenceRuleText(String? rule) {
    if (rule == null || rule.isEmpty) {
      return '每天';
    }

    // TODO: 解析重复规则
    return rule;
  }
}
