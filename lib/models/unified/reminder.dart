import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:jinlin_app/models/soft_deletable.dart';

/// 提醒事项
///
/// 表示用户创建的提醒事项
class Reminder implements SoftDeletable {
  /// 唯一标识符
  final String id;

  /// 标题
  final String title;

  /// 描述
  final String? description;

  /// 日期（YYYY-MM-DD格式）
  final String date;

  /// 时间（HH:MM格式，可选）
  final String? time;

  /// 是否全天事项
  final bool isAllDay;

  /// 是否已完成
  final bool isCompleted;

  /// 是否重复
  final bool isRecurring;

  /// 重复规则（iCalendar RRULE格式）
  final String? recurrenceRule;

  /// 重要性（0=普通，1=重要，2=非常重要）
  final int importance;

  /// 颜色
  final Color? color;

  /// 图标
  final IconData? icon;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime? lastModified;

  /// 是否已删除
  @override
  final bool isDeleted;

  /// 删除时间
  @override
  final DateTime? deletedAt;

  /// 删除原因
  @override
  final String? deletionReason;

  /// 构造函数
  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.isAllDay = true,
    this.isCompleted = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.importance = 0,
    this.color,
    this.icon,
    DateTime? createdAt,
    this.lastModified,
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: json['date'],
      time: json['time'],
      isAllDay: json['is_all_day'] ?? true,
      isCompleted: json['is_completed'] ?? false,
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: json['recurrence_rule'],
      importance: json['importance'] ?? 0,
      color: json['color'] != null ? Color(json['color']) : null,
      icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      lastModified: json['last_modified'] != null ? DateTime.parse(json['last_modified']) : null,
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      deletionReason: json['deletion_reason'],
    );
  }

  /// 从Map创建（用于数据库）
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      time: map['time'],
      isAllDay: map['is_all_day'] == 1,
      isCompleted: map['is_completed'] == 1,
      isRecurring: map['is_recurring'] == 1,
      recurrenceRule: map['recurrence_rule'],
      importance: map['importance'] ?? 0,
      color: map['color'] != null ? Color(map['color']) : null,
      icon: map['icon'] != null ? IconData(map['icon'], fontFamily: 'MaterialIcons') : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      lastModified: map['last_modified'] != null ? DateTime.parse(map['last_modified']) : null,
      isDeleted: map['is_deleted'] == 1,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
      deletionReason: map['deletion_reason'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'is_all_day': isAllDay,
      'is_completed': isCompleted,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'importance': importance,
      'color': color?.toString(),
      'icon': icon?.codePoint,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'deletion_reason': deletionReason,
    };
  }

  /// 转换为Map（用于数据库）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'is_all_day': isAllDay ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'importance': importance,
      'color': color?.toString(),
      'icon': icon?.codePoint,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'deletion_reason': deletionReason,
    };
  }

  /// 创建副本
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    bool? isAllDay,
    bool? isCompleted,
    bool? isRecurring,
    String? recurrenceRule,
    int? importance,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletionReason,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      isAllDay: isAllDay ?? this.isAllDay,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      importance: importance ?? this.importance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionReason: deletionReason ?? this.deletionReason,
    );
  }

  /// 创建已完成的副本
  Reminder markAsCompleted() {
    return copyWith(
      isCompleted: true,
      lastModified: DateTime.now(),
    );
  }

  /// 创建未完成的副本
  Reminder markAsIncomplete() {
    return copyWith(
      isCompleted: false,
      lastModified: DateTime.now(),
    );
  }

  /// 创建已删除的副本
  Reminder markAsDeleted({String? reason}) {
    return copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      deletionReason: reason,
      lastModified: DateTime.now(),
    );
  }

  /// 创建新的提醒事项
  static Reminder create({
    required String title,
    String? description,
    required String date,
    String? time,
    bool isAllDay = true,
    bool isRecurring = false,
    String? recurrenceRule,
    int importance = 0,
    Color? color,
    IconData? icon,
  }) {
    const uuid = Uuid();
    final id = 'reminder_${uuid.v4()}';

    return Reminder(
      id: id,
      title: title,
      description: description,
      date: date,
      time: time,
      isAllDay: isAllDay,
      isCompleted: false,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      importance: importance,
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  /// 获取日期时间
  DateTime getDateTime() {
    final dateParts = date.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    if (time != null && !isAllDay) {
      final timeParts = time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } else {
      return DateTime(year, month, day);
    }
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, date: $date, time: $time, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reminder &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.date == date &&
      other.time == time &&
      other.isAllDay == isAllDay &&
      other.isCompleted == isCompleted &&
      other.isRecurring == isRecurring &&
      other.recurrenceRule == recurrenceRule &&
      other.importance == importance;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      date.hashCode ^
      time.hashCode ^
      isAllDay.hashCode ^
      isCompleted.hashCode ^
      isRecurring.hashCode ^
      recurrenceRule.hashCode ^
      importance.hashCode;
  }
}
