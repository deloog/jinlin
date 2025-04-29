// 文件： jinlin_app/lib/add_reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'reminder.dart';
import 'deepseek_service.dart';
import 'speech_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ScreenMode { add, edit }

class AddReminderScreen extends StatefulWidget {
  final Reminder? initialReminder;
  final int? reminderIndex;
  final List<Reminder> existingReminders;
  const AddReminderScreen({ super.key, this.initialReminder, this.reminderIndex,required this.existingReminders, });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  // --- State Variables ---
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DeepseekService _deepseekService = DeepseekService();
  final SpeechService _speechService = SpeechService();

  final bool _isListening = false;
  final String _spokenText = '';
  final bool _isInitializingSpeech = false;
  bool _isProcessingSmartInput = false;
  DateTime? _selectedDateTime;
  List<Map<String, String?>>? _detectedEvents; // 用于存储识别出的事件列表
  Set<int> _selectedEventIndices = {};

  // --- Computed Property ---
  ScreenMode get _screenMode => widget.initialReminder == null ? ScreenMode.add : ScreenMode.edit;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (_screenMode == ScreenMode.edit && widget.initialReminder != null) {
      _titleController.text = widget.initialReminder!.title;
      _descriptionController.text = widget.initialReminder!.description;
      _selectedDateTime = widget.initialReminder!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  // --- Helper Methods (Speech, DeepSeek Desc, DateTime Pickers) ---
  // _initSpeech, _toggleListening, _startListening, _stopListening 不变
  Future<void> _initSpeech() async { /* ... */ }
  Future<void> _toggleListening() async { /* ... */ }
  Future<void> _startListening() async { /* ... */ }
  Future<void> _stopListening() async { /* ... */ }
  // 已移除 _processWithDeepSeek 方法，因为描述现在随事件一起生成
  // _pickDate, _pickTime, _clearDateTime 不变
  Future<void> _pickDate() async { /* ... */ }
  Future<void> _pickTime(DateTime pickedDate) async { /* ... */ }
  void _clearDateTime() { /* ... */ }


  // --- 处理自然语言输入的智能识别 ---
  // --- 用这个版本替换原来的 _processNaturalLanguageInput 方法 ---
Future<void> _processNaturalLanguageInput() async {
  final l10n = AppLocalizations.of(context)!; // 确保 l10n 在顶部获取
  final userInput = _titleController.text.trim();
  if (userInput.isEmpty) {
    _showInfoSnackBar(l10n.inputTitleFirstInfo);
    return;
  }
  if (!mounted) return;
  FocusScope.of(context).unfocus(); // 收起键盘

  // 先设置加载状态，但不立即 setState
  bool processingError = false; // 标记是否发生错误
  List<Map<String, String?>>? results; // 存储结果

  // 手动 setState 一次，显示加载状态
  setState(() {
     _isProcessingSmartInput = true;
     _detectedEvents = null; // 清空上次结果
  });

  try {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.analyzingText, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        );
      },
    );

    results = await _deepseekService.extractReminderInfo(userInput);

    // 关闭加载指示器
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  } catch (e) {
    // 关闭加载指示器（如果存在）
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // 使用日志记录而不是 print
    debugPrint("智能识别处理失败: $e");
    processingError = true; // 标记错误
    if (mounted) {
      // 考虑使用 l10n.smartInputFailedError(e.toString())
      _showErrorSnackBar("智能识别失败: ${e.toString()}");
    }
  }

  // --- 重要的修改：在 await 之后，只调用一次 setState ---
  if (mounted) {
    setState(() {
      if (!processingError && results != null) { // 如果没有错误且有结果
        if (results.isNotEmpty) {
          _detectedEvents = results; // 存储结果
          // 显示提示信息 (可以在这里显示，或者等 build 方法渲染)
          if (results.length > 1) {
             // 可以考虑延迟显示 SnackBar，避免 setState 冲突
             WidgetsBinding.instance.addPostFrameCallback((_) =>
                _showInfoSnackBar(l10n.multipleEventsDetected(results!.length))
             );
          } else {
             WidgetsBinding.instance.addPostFrameCallback((_) =>
               _showInfoSnackBar(l10n.singleEventDetected)
             );
          }
        } else {
          _detectedEvents = null; // AI 返回空列表
           WidgetsBinding.instance.addPostFrameCallback((_) =>
             _showInfoSnackBar(l10n.noValidEventsDetected)
           );
        }
      } else {
         // 如果出错或 results 为 null (理论上 catch 会处理)
         _detectedEvents = null;
      }
      // 无论成功失败，都在这里结束加载状态
      _isProcessingSmartInput = false;
    });
  }
}
// --- 替换结束 ---


  // --- Action Methods ---

  // --- Snackbar Methods ---
  // _showErrorSnackBar, _showInfoSnackBar 不变
  void _showErrorSnackBar(String message) { /* ... */ }
  void _showInfoSnackBar(String message) { /* ... */ }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    debugPrint('>>> AddScreen - build - DateTime is: $_selectedDateTime');
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenMode == ScreenMode.add ? l10n.addReminderTitle : l10n.editReminderTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            // 标题输入框
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.reminderContentLabel,
                hintText: l10n.reminderContentHint,
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isProcessingSmartInput
                      ? Container( width: 48, height: 48, padding: const EdgeInsets.all(12.0), child: const CircularProgressIndicator(strokeWidth: 2), )
                      : IconButton( icon: const Icon(Icons.auto_awesome), tooltip: l10n.smartInputTooltip, onPressed: _isProcessingSmartInput ? null : _processNaturalLanguageInput, ),
                    IconButton( icon: Icon(_isListening ? Icons.mic_off : Icons.mic), tooltip: _isListening ? l10n.micStopTooltip : l10n.micListenTooltip, onPressed: _isInitializingSpeech || _isProcessingSmartInput ? null : _toggleListening, ),
                  ],
                ),
              ),
              maxLines: null, minLines: 1,
              keyboardType: TextInputType.multiline,
            ), // TextField 结束

            // --- 修正：确保 if 条件块后的逗号存在 ---
            // 语音状态提示
            if (_isListening)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(l10n.listeningStatus, style: const TextStyle(color: Colors.blue)),
                ), // <--- 逗号在这里!
            if (_isInitializingSpeech)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row( children: [ const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Text(l10n.speechInitStatus), ], ),
                ), // <--- 逗号在这里!

            const SizedBox(height: 16), // <--- 这个和上面的 if Padding 之间要有逗号

            // 描述输入框
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration( labelText: l10n.descriptionLabel, hintText: l10n.descriptionHint, border: const OutlineInputBorder(), ),
              maxLines: 3,
            ), // TextField 结束

            const SizedBox(height: 16),

            // 日期时间选择器
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text( _selectedDateTime == null ? l10n.addDateTimeButton : DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!), ),
              trailing: _selectedDateTime != null ? IconButton( icon: const Icon(Icons.clear), tooltip: l10n.clearDateTimeTooltip, onPressed: _clearDateTime, ) : null,
              onTap: _pickDate,
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Colors.grey.shade400) ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ), // ListTile 结束



            if (_detectedEvents != null && _detectedEvents!.isNotEmpty) ...[ // 只有识别出结果才显示
            const SizedBox(height: 16), // 加点间距
            Text(l10n.detectedEventsTitle, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Column(
   // 使用 .asMap().entries.map 来同时获取索引和事件数据
   children: _detectedEvents!.asMap().entries.map((entry) {
      int index = entry.key;       // 获取当前项的索引
      Map<String, String?> event = entry.value; // 获取当前项的事件数据

      final title = event['title'] ?? l10n.noTitlePlaceholder;
      final dateStr = event['due_date'] ?? l10n.noDatePlaceholder;
      final description = event['description'] ?? ''; // 获取AI生成的描述
      String formattedDate = dateStr;
      try {
         if (event['due_date'] != null) {
            formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(event['due_date']!));
         }
      } catch (_) {
         // 解析失败，保留原始字符串
      }
      // 检查当前项是否被选中
      final bool isSelected = _selectedEventIndices.contains(index);

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              // leading 改为 Checkbox
              leading: Checkbox(
                value: isSelected, // Checkbox 的值取决于是否在选中集合中
                onChanged: (bool? newValue) {
                  // 当 Checkbox 状态改变时
                  setState(() {
                    if (newValue == true) {
                      _selectedEventIndices.add(index); // 选中，则添加到集合
                    } else {
                      _selectedEventIndices.remove(index); // 取消选中，则从集合移除
                    }
                  });
                },
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(formattedDate),
              dense: true,
            ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(56.0, 0, 16.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        l10n.notesTitle,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    ...description.split('\n').map((item) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
   }).toList(),
),
           const Divider(),
           const SizedBox(height: 8), // 加点间距
    ],
           // --- 显示识别结果的 UI 结束 ---

           // ... 其他控件 (如描述框、日期选择、按钮等) ...

            const SizedBox(height: 16),

            // 移除了单独的AI生成描述按钮，因为现在描述会随事件一起生成

            const SizedBox(height: 24),

            // 保存/更新按钮
            ElevatedButton(
  // 只有当 _selectedEventIndices 不为空（即至少选中了一项）时，
  // 才启用按钮并设置 onPressed 为 _saveSelectedReminders (我们稍后创建这个方法)
  // 否则 onPressed 为 null (禁用按钮)
  onPressed: _selectedEventIndices.isNotEmpty ? _saveSelectedReminders : null,
  style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      disabledBackgroundColor: Colors.grey, // 禁用时的背景色
  ),
  // 修改按钮文字，可以加上选中数量的提示
  child: Text(
    _selectedEventIndices.isEmpty
        ? l10n.selectEventsToSave
        : l10n.saveSelectedEvents(_selectedEventIndices.length),
    style: const TextStyle(fontSize: 16, color: Colors.white),
  ),
),

          ], // children 列表结束
        ), // Column 结束
      ), // SingleChildScrollView 结束
    ); // Scaffold 结束
  } // build 结束


Future<void> _saveSelectedReminders() async {
  final l10n = AppLocalizations.of(context);
  if (_detectedEvents == null || _selectedEventIndices.isEmpty) {
    // 如果没有识别结果或没有选中项，理论上按钮是禁用的，但也做个检查
    return;
  }

  List<Reminder> remindersToSave = []; // 创建一个空列表来存储要保存的 Reminder 对象

  // 遍历所有选中的索引
  for (int index in _selectedEventIndices) {
    // 确保索引有效
    if (index >= 0 && index < _detectedEvents!.length) {
      final event = _detectedEvents![index]; // 获取选中的事件数据
      final String? title = event['title'];
      final String? dateStr = event['due_date'];
      final String? description = event['description']; // 获取AI生成的描述
      DateTime? parsedDate;

      // 解析日期 (和 onTap 里的逻辑类似)
      if (dateStr != null) {
        try {
          parsedDate = DateTime.tryParse(dateStr);
        } catch (e) {
          // 使用日志记录而不是print
          // print("警告：为事件 '$title' 解析日期 '$dateStr' 时出错: $e");
          parsedDate = null; // 解析失败则日期为 null
        }
      }

      // 简单的标题检查，避免保存完全空的事件
      if (title != null && title.isNotEmpty) {
        // --- 这里判断提醒类型可以更智能 ---
        // （可以复用之前 _saveReminder 里的逻辑，或者根据需要简化/增强）
        ReminderType determinedType = ReminderType.general;
        if (title.contains('生日')) {
          determinedType = ReminderType.birthday;
        } else if (title.contains('忌日')) {
           determinedType = ReminderType.memorialDay;
        } else if (title.contains('春节') || title.contains('元宵') ||
                  title.contains('端午') || title.contains('七夕') ||
                  title.contains('中秋') || title.contains('重阳')) {
           determinedType = ReminderType.chineseFestival;
        }
         // ... 可以添加更多类型判断 ...

        // 创建 Reminder 对象
        final newReminder = Reminder(
          // id 会自动生成
          title: title,
          description: description ?? '', // 使用AI生成的描述，如果为null则使用空字符串
          dueDate: parsedDate,
          isCompleted: false, // 新添加的默认未完成
          type: determinedType,
        );
        remindersToSave.add(newReminder); //添加到待保存列表
      } else {
         // 使用日志记录而不是print
         // print("警告：跳过了一个没有有效标题的选中事件。");
      }
    }
  }

  // 检查是否真的创建了任何 Reminder 对象
  if (remindersToSave.isNotEmpty) {
    if (mounted) { // 检查 context 是否仍然有效
       // 通过 Navigator.pop 返回包含多个 Reminder 的列表
       Navigator.pop(context, remindersToSave);
    }
  } else {
     // 如果没有选中任何有效事件（比如只选中了无标题的），可以给个提示
     _showInfoSnackBar(l10n.noValidEventsSelected);
  }
}
// --- _saveSelectedReminders 方法结束 ---

  Reminder? _findConflict(DateTime newDueDate, List<Reminder> remindersToCheck) {
    for (final existingReminder in remindersToCheck) {
      // 跳过自身（编辑模式）
      if (_screenMode == ScreenMode.edit && existingReminder == widget.initialReminder) {
        continue;
      }

      // 只比较有日期的提醒
      if (existingReminder.dueDate == null) {
        continue;
      }

      // 检查是否是同一天
      final isSameDay = newDueDate.year == existingReminder.dueDate!.year &&
                        newDueDate.month == existingReminder.dueDate!.month &&
                        newDueDate.day == existingReminder.dueDate!.day;

      if (isSameDay) {
        // 简单冲突检查：小时和分钟完全相同
        final isSameTime = newDueDate.hour == existingReminder.dueDate!.hour &&
                           newDueDate.minute == existingReminder.dueDate!.minute;

        // 更复杂的检查可以考虑时间段重叠，例如：
        // Duration eventDuration = const Duration(hours: 1); // 假设事件持续1小时
        // DateTime newEndTime = newDueDate.add(eventDuration);
        // DateTime existingEndTime = existingReminder.dueDate!.add(eventDuration);
        // bool overlap = newDueDate.isBefore(existingEndTime) && newEndTime.isAfter(existingReminder.dueDate!);

        if (isSameTime) { // 或者使用 overlap 变量
          return existingReminder; // 找到冲突，返回冲突的事件
        }
      }
    }
    return null; // 没有找到冲突
  }

  Future<bool?> _showConflictDialog(BuildContext context, String conflictingTitle) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.conflictDialogTitle),
        content: Text(l10n.conflictDialogContent(conflictingTitle)), // 传递参数
        actions: <Widget>[
          TextButton(
            child: Text(l10n.cancelButton), // 使用 l10n
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(l10n.saveAnywayButton), // 使用 l10n
            onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

} // _AddReminderScreenState 结束
