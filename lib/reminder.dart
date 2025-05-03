// 文件： jinlin_app/lib/reminder.dart
import 'package:uuid/uuid.dart';

enum ReminderType {
  general, // 普通提醒
  birthday,
  anniversary,
  chineseFestival, // 农历节日 (春节, 端午等)
  memorialDay // 忌日
  // 可以根据需要添加更多类型
}

/// 提醒事项优先级
enum ReminderPriority {
  /// 无优先级
  none,

  /// 低优先级
  low,

  /// 中优先级
  medium,

  /// 高优先级
  high,
}
class Reminder {
  final String id;
  String title;
  String description;
  final DateTime? dueDate;
  bool isCompleted;
  final ReminderType type;// <--- 新增：标记是否已完成
  DateTime? completedDate;
  final ReminderPriority priority; // 优先级
  String? notes; // 备注

  Reminder({
    String? id,
    required this.title,
    required this.description,
    this.dueDate,
    this.isCompleted = false, // <--- 构造函数：默认值为 false
    this.type = ReminderType.general,
    this.completedDate,
    this.priority = ReminderPriority.none,
    this.notes,
  }): id = id ?? const Uuid().v4();

  // 从 JSON 对象创建 Reminder 实例
  factory Reminder.fromJson(Map<String, dynamic> json) {
  // 辅助函数：将字符串安全转换为 ReminderType
  ReminderType typeFromString(String? typeString) {
    if (typeString == null) return ReminderType.general;
    // 从 ReminderType.values 中查找匹配的枚举值
    return ReminderType.values.firstWhere(
          (e) => e.toString() == typeString,
          orElse: () => ReminderType.general // 如果找不到匹配的，默认为 general
        );
  }

  // 辅助函数：将字符串安全转换为 ReminderPriority
  ReminderPriority priorityFromString(String? priorityString) {
    if (priorityString == null) return ReminderPriority.none;
    // 从 ReminderPriority.values 中查找匹配的枚举值
    return ReminderPriority.values.firstWhere(
          (e) => e.toString() == priorityString,
          orElse: () => ReminderPriority.none // 如果找不到匹配的，默认为 none
        );
  }

  return Reminder(
    id: json['id'] ?? const Uuid().v4(),
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
    isCompleted: json['isCompleted'] ?? false,
    type: typeFromString(json['type']), // 从字符串转换回枚举
    priority: priorityFromString(json['priority']), // 从字符串转换回枚举
    notes: json['notes'],
    completedDate: json['completedDate'] != null ? DateTime.tryParse(json['completedDate']) : null,
  );
}

  Map<String, dynamic> toJson() => {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'type': type.toString(), // 将枚举转为字符串存储
      'priority': priority.toString(), // 将枚举转为字符串存储
      'notes': notes,
      'completedDate': completedDate?.toIso8601String(),
    };
  // 在 Reminder 类内部添加
Reminder copyWith({
  String? id,
  String? title,
  String? description,
  DateTime? dueDate,
  bool? isCompleted,
  ReminderType? type,
  DateTime? completedDate,
  ReminderPriority? priority,
  String? notes,
}) {
  return Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    dueDate: dueDate ?? this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    type: type ?? this.type,
    completedDate: completedDate ?? this.completedDate,
    priority: priority ?? this.priority,
    notes: notes ?? this.notes,
  );
}

// 切换完成状态的方法，返回一个新的Reminder实例
Reminder toggleComplete() {
  return copyWith(
    isCompleted: !isCompleted,
    completedDate: !isCompleted ? DateTime.now() : null,
  );
}
}