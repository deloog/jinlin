import 'package:hive/hive.dart';
import 'package:jinlin_app/models/soft_deletable.dart';

// 这个文件将由build_runner生成
// 运行命令: flutter pub run build_runner build
part 'reminder_event_model.g.dart';

/// 提醒事件类型
@HiveType(typeId: 17)
enum ReminderEventType {
  @HiveField(0)
  birthday, // 生日

  @HiveField(1)
  anniversary, // 纪念日

  @HiveField(2)
  holiday, // 节日

  @HiveField(3)
  appointment, // 约会

  @HiveField(4)
  task, // 任务

  @HiveField(5)
  memorial, // 忌日

  @HiveField(6)
  other // 其他
}

/// 提醒状态
@HiveType(typeId: 18)
enum ReminderStatus {
  @HiveField(0)
  pending, // 待处理

  @HiveField(1)
  completed, // 已完成

  @HiveField(2)
  missed, // 已错过

  @HiveField(3)
  cancelled // 已取消
}

/// 提醒事件模型
@HiveType(typeId: 19)
class ReminderEventModel extends HiveObject implements SoftDeletable {
  // 基本信息
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  ReminderEventType type;

  @HiveField(4)
  DateTime? dueDate; // 到期日期

  @HiveField(5)
  bool isAllDay; // 是否全天事件

  @HiveField(6)
  bool isLunarDate; // 是否农历日期

  // 状态信息
  @HiveField(7)
  ReminderStatus status;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  DateTime? completedAt;

  // 重复设置
  @HiveField(10)
  bool isRepeating;

  @HiveField(11)
  String? repeatRule; // 重复规则，如 "FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1"

  @HiveField(12)
  DateTime? repeatUntil; // 重复截止日期

  // 提醒设置
  @HiveField(13)
  List<Map<String, dynamic>>? reminderTimes; // 提醒时间列表

  // 关联信息
  @HiveField(14)
  String? contactId; // 关联的联系人ID

  @HiveField(15)
  String? holidayId; // 关联的节日ID

  // 位置信息
  @HiveField(16)
  String? location;

  @HiveField(17)
  double? latitude;

  @HiveField(18)
  double? longitude;

  // 分类和标签
  @HiveField(19)
  List<String>? tags;

  @HiveField(20)
  String? category;

  // 多语言支持
  @HiveField(21)
  Map<String, String>? titles; // 多语言标题

  @HiveField(22)
  Map<String, String>? descriptions; // 多语言描述

  // AI 生成内容
  @HiveField(23)
  String? aiGeneratedDescription;

  @HiveField(24)
  List<String>? aiGeneratedGreetings;

  @HiveField(25)
  List<Map<String, dynamic>>? aiGeneratedGiftSuggestions;

  // 时间戳
  @HiveField(26)
  DateTime createdAt;

  @HiveField(27)
  DateTime? lastModified;

  // 用户设置
  @HiveField(28)
  int importance; // 重要性，0=普通，1=重要，2=非常重要

  @HiveField(29)
  String? customColor;

  @HiveField(30)
  String? customIcon;

  // 分享设置
  @HiveField(31)
  bool isShared;

  @HiveField(32)
  List<String>? sharedWith;

  // 云同步信息
  @HiveField(33)
  DateTime? lastSynced;

  @HiveField(34)
  bool isSyncConflict;

  // 软删除相关
  @HiveField(35)
  @override
  bool isDeleted = false;

  @HiveField(36)
  @override
  DateTime? deletedAt;

  @HiveField(37)
  @override
  String? deletionReason;

  ReminderEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.dueDate,
    this.isAllDay = false,
    this.isLunarDate = false,
    this.status = ReminderStatus.pending,
    this.isCompleted = false,
    this.completedAt,
    this.isRepeating = false,
    this.repeatRule,
    this.repeatUntil,
    this.reminderTimes,
    this.contactId,
    this.holidayId,
    this.location,
    this.latitude,
    this.longitude,
    this.tags,
    this.category,
    this.titles,
    this.descriptions,
    this.aiGeneratedDescription,
    this.aiGeneratedGreetings,
    this.aiGeneratedGiftSuggestions,
    DateTime? createdAt,
    this.lastModified,
    this.importance = 0,
    this.customColor,
    this.customIcon,
    this.isShared = false,
    this.sharedWith,
    this.lastSynced,
    this.isSyncConflict = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建提醒事件模型
  factory ReminderEventModel.fromJson(Map<String, dynamic> json) {
    return ReminderEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: _parseReminderEventType(json['type']),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isAllDay: json['isAllDay'] as bool? ?? false,
      isLunarDate: json['isLunarDate'] as bool? ?? false,
      status: _parseReminderStatus(json['status']),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isRepeating: json['isRepeating'] as bool? ?? false,
      repeatRule: json['repeatRule'] as String?,
      repeatUntil: json['repeatUntil'] != null
          ? DateTime.parse(json['repeatUntil'] as String)
          : null,
      reminderTimes: json['reminderTimes'] != null
          ? List<Map<String, dynamic>>.from(json['reminderTimes'] as List)
          : null,
      contactId: json['contactId'] as String?,
      holidayId: json['holidayId'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      category: json['category'] as String?,
      titles: json['titles'] != null
          ? Map<String, String>.from(json['titles'] as Map)
          : null,
      descriptions: json['descriptions'] != null
          ? Map<String, String>.from(json['descriptions'] as Map)
          : null,
      aiGeneratedDescription: json['aiGeneratedDescription'] as String?,
      aiGeneratedGreetings: json['aiGeneratedGreetings'] != null
          ? List<String>.from(json['aiGeneratedGreetings'] as List)
          : null,
      aiGeneratedGiftSuggestions: json['aiGeneratedGiftSuggestions'] != null
          ? List<Map<String, dynamic>>.from(json['aiGeneratedGiftSuggestions'] as List)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      importance: json['importance'] as int? ?? 0,
      customColor: json['customColor'] as String?,
      customIcon: json['customIcon'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      sharedWith: json['sharedWith'] != null
          ? List<String>.from(json['sharedWith'] as List)
          : null,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      isSyncConflict: json['isSyncConflict'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deletionReason: json['deletionReason'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'dueDate': dueDate?.toIso8601String(),
      'isAllDay': isAllDay,
      'isLunarDate': isLunarDate,
      'status': status.toString().split('.').last,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'isRepeating': isRepeating,
      'repeatRule': repeatRule,
      'repeatUntil': repeatUntil?.toIso8601String(),
      'reminderTimes': reminderTimes,
      'contactId': contactId,
      'holidayId': holidayId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'category': category,
      'titles': titles,
      'descriptions': descriptions,
      'aiGeneratedDescription': aiGeneratedDescription,
      'aiGeneratedGreetings': aiGeneratedGreetings,
      'aiGeneratedGiftSuggestions': aiGeneratedGiftSuggestions,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'importance': importance,
      'customColor': customColor,
      'customIcon': customIcon,
      'isShared': isShared,
      'sharedWith': sharedWith,
      'lastSynced': lastSynced?.toIso8601String(),
      'isSyncConflict': isSyncConflict,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletionReason': deletionReason,
    };
  }

  /// 创建带有更新时间的副本
  ReminderEventModel copyWithLastModified() {
    return ReminderEventModel(
      id: id,
      title: title,
      description: description,
      type: type,
      dueDate: dueDate,
      isAllDay: isAllDay,
      isLunarDate: isLunarDate,
      status: status,
      isCompleted: isCompleted,
      completedAt: completedAt,
      isRepeating: isRepeating,
      repeatRule: repeatRule,
      repeatUntil: repeatUntil,
      reminderTimes: reminderTimes,
      contactId: contactId,
      holidayId: holidayId,
      location: location,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
      category: category,
      titles: titles,
      descriptions: descriptions,
      aiGeneratedDescription: aiGeneratedDescription,
      aiGeneratedGreetings: aiGeneratedGreetings,
      aiGeneratedGiftSuggestions: aiGeneratedGiftSuggestions,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      importance: importance,
      customColor: customColor,
      customIcon: customIcon,
      isShared: isShared,
      sharedWith: sharedWith,
      lastSynced: lastSynced,
      isSyncConflict: isSyncConflict,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      deletionReason: deletionReason,
    );
  }

  /// 获取指定语言的标题
  String getLocalizedTitle(String languageCode) {
    if (titles != null && titles!.containsKey(languageCode)) {
      return titles![languageCode]!;
    }

    return title; // 默认返回主标题
  }

  /// 获取指定语言的描述
  String? getLocalizedDescription(String languageCode) {
    if (descriptions != null && descriptions!.containsKey(languageCode)) {
      return descriptions![languageCode];
    }

    return description; // 默认返回主描述
  }

  /// 创建带有修改的副本
  ReminderEventModel copyWith({
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletionReason,
    ReminderStatus? status,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ReminderEventModel(
      id: id,
      title: title,
      description: description,
      type: type,
      dueDate: dueDate,
      isAllDay: isAllDay,
      isLunarDate: isLunarDate,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isRepeating: isRepeating,
      repeatRule: repeatRule,
      repeatUntil: repeatUntil,
      reminderTimes: reminderTimes,
      contactId: contactId,
      holidayId: holidayId,
      location: location,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
      category: category,
      titles: titles,
      descriptions: descriptions,
      aiGeneratedDescription: aiGeneratedDescription,
      aiGeneratedGreetings: aiGeneratedGreetings,
      aiGeneratedGiftSuggestions: aiGeneratedGiftSuggestions,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      importance: importance,
      customColor: customColor,
      customIcon: customIcon,
      isShared: isShared,
      sharedWith: sharedWith,
      lastSynced: lastSynced,
      isSyncConflict: isSyncConflict,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionReason: deletionReason ?? this.deletionReason,
    );
  }

  /// 解析提醒事件类型
  static ReminderEventType _parseReminderEventType(dynamic value) {
    if (value is ReminderEventType) return value;
    if (value is String) {
      try {
        return ReminderEventType.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return ReminderEventType.other;
  }

  /// 解析提醒状态
  static ReminderStatus _parseReminderStatus(dynamic value) {
    if (value is ReminderStatus) return value;
    if (value is String) {
      try {
        return ReminderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return ReminderStatus.pending;
  }
}
