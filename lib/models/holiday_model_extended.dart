import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jinlin_app/services/localization_service.dart';

// 这个文件将由build_runner生成
// 运行命令: flutter pub run build_runner build
part 'holiday_model_extended.g.dart';

/// 节日类型
@HiveType(typeId: 1)
enum HolidayType {
  @HiveField(0)
  statutory, // 法定节日

  @HiveField(1)
  traditional, // 传统节日

  @HiveField(2)
  solarTerm, // 节气

  @HiveField(3)
  memorial, // 纪念日

  @HiveField(4)
  custom, // 自定义

  @HiveField(5)
  other, // 其他

  @HiveField(6)
  religious, // 宗教节日

  @HiveField(7)
  international, // 国际节日

  @HiveField(8)
  professional, // 职业节日

  @HiveField(9)
  cultural // 文化节日
}

/// 日期计算规则类型
@HiveType(typeId: 2)
enum DateCalculationType {
  @HiveField(0)
  fixedGregorian, // 固定公历日期，如 MM-DD

  @HiveField(1)
  fixedLunar, // 固定农历日期，如 MM-DDL

  @HiveField(2)
  nthWeekdayOfMonth, // 某月第n个星期几，如 MM,N,W

  @HiveField(3)
  solarTermBased, // 基于节气的日期，如 "QingMing"

  @HiveField(4)
  relativeTo, // 相对于另一个特殊日期的日期，如 "HOLIDAY_ID,+/-N"

  @HiveField(5)
  lastWeekdayOfMonth, // 某月最后一个星期几，如 MM,W

  @HiveField(6)
  easterBased, // 基于复活节的日期，如 "Easter,+/-N"

  @HiveField(7)
  lunarPhase, // 基于月相的日期，如 "FullMoon,MM"（某月的满月）

  @HiveField(8)
  seasonBased, // 基于季节的日期，如 "Spring,N"（春季第N天）

  @HiveField(9)
  weekOfYear // 基于年份周数的日期，如 "WW,D"（第WW周的第D天）
}

/// 重要性级别
@HiveType(typeId: 3)
enum ImportanceLevel {
  @HiveField(0)
  low, // 低重要性，只在临近时显示

  @HiveField(1)
  medium, // 中等重要性，提前较长时间显示

  @HiveField(2)
  high // 高重要性，始终显示
}

/// 提醒类型
@HiveType(typeId: 10)
enum ReminderType {
  @HiveField(0)
  notification, // 通知提醒

  @HiveField(1)
  email, // 邮件提醒

  @HiveField(2)
  sms, // 短信提醒

  @HiveField(3)
  alarm // 闹钟提醒
}

/// 节日数据模型（扩展版）
@HiveType(typeId: 11)
class HolidayModelExtended extends HiveObject {
  // 基本信息
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  HolidayType type;

  @HiveField(3)
  List<String> regions;

  @HiveField(4)
  DateCalculationType calculationType;

  @HiveField(5)
  String calculationRule;

  @HiveField(6)
  String? description;

  @HiveField(7)
  ImportanceLevel importanceLevel;

  // 详细信息
  @HiveField(8)
  String? customs;

  @HiveField(9)
  String? taboos;

  @HiveField(10)
  String? foods;

  @HiveField(11)
  String? greetings;

  @HiveField(12)
  String? activities;

  @HiveField(13)
  String? history;

  @HiveField(14)
  String? imageUrl;

  // 用户设置
  @HiveField(15)
  int userImportance; // 用户自定义重要性，0=普通，1=重要，2=非常重要

  // 多语言支持（旧版）
  @HiveField(16)
  String? nameEn; // 英文名称

  @HiveField(17)
  String? descriptionEn; // 英文描述

  @HiveField(18)
  DateTime? lastModified; // 最后修改时间

  // 多语言支持（新版）
  @HiveField(19)
  Map<String, String>? names; // 多语言名称 {'zh': '中文名', 'en': 'English Name', 'ja': '日本語名', ...}

  @HiveField(20)
  Map<String, String>? descriptions; // 多语言描述

  @HiveField(21)
  Map<String, String>? customsMultilingual; // 多语言习俗

  @HiveField(22)
  Map<String, String>? taboosMultilingual; // 多语言禁忌

  @HiveField(23)
  Map<String, String>? foodsMultilingual; // 多语言食物

  @HiveField(24)
  Map<String, String>? greetingsMultilingual; // 多语言祝福语

  @HiveField(25)
  Map<String, String>? activitiesMultilingual; // 多语言活动

  @HiveField(26)
  Map<String, String>? historyMultilingual; // 多语言历史

  // 联系人关联
  @HiveField(27)
  String? contactId; // 关联的联系人ID

  @HiveField(28)
  String? contactName; // 联系人名称

  @HiveField(29)
  String? contactRelation; // 与联系人的关系

  @HiveField(30)
  String? contactAvatar; // 联系人头像URL

  // 分组和标签
  @HiveField(31)
  List<String>? tags; // 标签列表

  @HiveField(32)
  String? groupId; // 分组ID

  // AI 生成内容
  @HiveField(33)
  List<String>? aiGeneratedGreetings; // AI 生成的祝福语列表

  @HiveField(34)
  List<Map<String, dynamic>>? aiGeneratedGiftSuggestions; // AI 生成的礼物建议

  @HiveField(35)
  Map<String, String>? aiGeneratedTips; // AI 生成的提示信息

  // 提醒设置
  @HiveField(36)
  List<Map<String, dynamic>>? reminderSettings; // 提醒设置列表，包含提醒时间、提醒方式等

  @HiveField(37)
  bool isRepeating; // 是否重复提醒

  @HiveField(38)
  String? repeatRule; // 重复规则

  // 分享设置
  @HiveField(39)
  bool isShared; // 是否已分享

  @HiveField(40)
  List<String>? sharedWith; // 分享给的用户ID列表

  @HiveField(41)
  Map<String, bool>? sharingPermissions; // 分享权限设置

  // 云同步信息
  @HiveField(42)
  DateTime? lastSynced; // 最后同步时间

  @HiveField(43)
  bool isSyncConflict; // 是否存在同步冲突

  // 显示设置
  @HiveField(44)
  bool showLunarDate; // 是否显示农历日期

  @HiveField(45)
  String? customColor; // 自定义颜色

  @HiveField(46)
  String? customIcon; // 自定义图标

  // 创建和过期信息
  @HiveField(47)
  DateTime createdAt; // 创建时间

  @HiveField(48)
  bool isExpired; // 是否已过期

  @HiveField(49)
  bool isHidden; // 是否隐藏

  HolidayModelExtended({
    required this.id,
    required this.name,
    required this.type,
    required this.regions,
    required this.calculationType,
    required this.calculationRule,
    this.description,
    this.importanceLevel = ImportanceLevel.low,
    this.customs,
    this.taboos,
    this.foods,
    this.greetings,
    this.activities,
    this.history,
    this.imageUrl,
    this.userImportance = 0,
    this.nameEn,
    this.descriptionEn,
    this.lastModified,
    this.names,
    this.descriptions,
    this.customsMultilingual,
    this.taboosMultilingual,
    this.foodsMultilingual,
    this.greetingsMultilingual,
    this.activitiesMultilingual,
    this.historyMultilingual,
    this.contactId,
    this.contactName,
    this.contactRelation,
    this.contactAvatar,
    this.tags,
    this.groupId,
    this.aiGeneratedGreetings,
    this.aiGeneratedGiftSuggestions,
    this.aiGeneratedTips,
    this.reminderSettings,
    this.isRepeating = false,
    this.repeatRule,
    this.isShared = false,
    this.sharedWith,
    this.sharingPermissions,
    this.lastSynced,
    this.isSyncConflict = false,
    this.showLunarDate = false,
    this.customColor,
    this.customIcon,
    DateTime? createdAt,
    this.isExpired = false,
    this.isHidden = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从旧版 HolidayModel 转换
  factory HolidayModelExtended.fromHolidayModel(dynamic holiday) {
    return HolidayModelExtended(
      id: holiday.id,
      name: holiday.name,
      type: holiday.type,
      regions: List<String>.from(holiday.regions),
      calculationType: holiday.calculationType,
      calculationRule: holiday.calculationRule,
      description: holiday.description,
      importanceLevel: holiday.importanceLevel,
      customs: holiday.customs,
      taboos: holiday.taboos,
      foods: holiday.foods,
      greetings: holiday.greetings,
      activities: holiday.activities,
      history: holiday.history,
      imageUrl: holiday.imageUrl,
      userImportance: holiday.userImportance,
      nameEn: holiday.nameEn,
      descriptionEn: holiday.descriptionEn,
      lastModified: holiday.lastModified,
      // 初始化新字段
      names: {
        'zh': holiday.name,
        if (holiday.nameEn != null) 'en': holiday.nameEn!,
      },
      descriptions: {
        if (holiday.description != null) 'zh': holiday.description!,
        if (holiday.descriptionEn != null) 'en': holiday.descriptionEn!,
      },
      isRepeating: _isRepeatingHoliday(holiday.type),
      createdAt: holiday.lastModified ?? DateTime.now(),
    );
  }

  /// 判断节日类型是否为重复性节日
  static bool _isRepeatingHoliday(HolidayType type) {
    return type == HolidayType.statutory ||
           type == HolidayType.traditional ||
           type == HolidayType.solarTerm ||
           type == HolidayType.religious ||
           type == HolidayType.international;
  }

  /// 从JSON创建节日模型
  factory HolidayModelExtended.fromJson(Map<String, dynamic> json) {
    return HolidayModelExtended(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculationType']),
      calculationRule: json['calculationRule'] as String,
      description: json['description'] as String?,
      importanceLevel: _parseImportanceLevel(json['importanceLevel']),
      customs: json['customs'] as String?,
      taboos: json['taboos'] as String?,
      foods: json['foods'] as String?,
      greetings: json['greetings'] as String?,
      activities: json['activities'] as String?,
      history: json['history'] as String?,
      imageUrl: json['imageUrl'] as String?,
      userImportance: json['userImportance'] as int? ?? 0,
      nameEn: json['nameEn'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      names: json['names'] != null
          ? Map<String, String>.from(json['names'] as Map)
          : null,
      descriptions: json['descriptions'] != null
          ? Map<String, String>.from(json['descriptions'] as Map)
          : null,
      customsMultilingual: json['customsMultilingual'] != null
          ? Map<String, String>.from(json['customsMultilingual'] as Map)
          : null,
      taboosMultilingual: json['taboosMultilingual'] != null
          ? Map<String, String>.from(json['taboosMultilingual'] as Map)
          : null,
      foodsMultilingual: json['foodsMultilingual'] != null
          ? Map<String, String>.from(json['foodsMultilingual'] as Map)
          : null,
      greetingsMultilingual: json['greetingsMultilingual'] != null
          ? Map<String, String>.from(json['greetingsMultilingual'] as Map)
          : null,
      activitiesMultilingual: json['activitiesMultilingual'] != null
          ? Map<String, String>.from(json['activitiesMultilingual'] as Map)
          : null,
      historyMultilingual: json['historyMultilingual'] != null
          ? Map<String, String>.from(json['historyMultilingual'] as Map)
          : null,
      contactId: json['contactId'] as String?,
      contactName: json['contactName'] as String?,
      contactRelation: json['contactRelation'] as String?,
      contactAvatar: json['contactAvatar'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      groupId: json['groupId'] as String?,
      aiGeneratedGreetings: json['aiGeneratedGreetings'] != null
          ? List<String>.from(json['aiGeneratedGreetings'] as List)
          : null,
      aiGeneratedGiftSuggestions: json['aiGeneratedGiftSuggestions'] != null
          ? List<Map<String, dynamic>>.from(json['aiGeneratedGiftSuggestions'] as List)
          : null,
      aiGeneratedTips: json['aiGeneratedTips'] != null
          ? Map<String, String>.from(json['aiGeneratedTips'] as Map)
          : null,
      reminderSettings: json['reminderSettings'] != null
          ? List<Map<String, dynamic>>.from(json['reminderSettings'] as List)
          : null,
      isRepeating: json['isRepeating'] as bool? ?? false,
      repeatRule: json['repeatRule'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      sharedWith: json['sharedWith'] != null
          ? List<String>.from(json['sharedWith'] as List)
          : null,
      sharingPermissions: json['sharingPermissions'] != null
          ? Map<String, bool>.from(json['sharingPermissions'] as Map)
          : null,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      isSyncConflict: json['isSyncConflict'] as bool? ?? false,
      showLunarDate: json['showLunarDate'] as bool? ?? false,
      customColor: json['customColor'] as String?,
      customIcon: json['customIcon'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isExpired: json['isExpired'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'regions': regions,
      'calculationType': calculationType.toString().split('.').last,
      'calculationRule': calculationRule,
      'description': description,
      'importanceLevel': importanceLevel.toString().split('.').last,
      'customs': customs,
      'taboos': taboos,
      'foods': foods,
      'greetings': greetings,
      'activities': activities,
      'history': history,
      'imageUrl': imageUrl,
      'userImportance': userImportance,
      'nameEn': nameEn,
      'descriptionEn': descriptionEn,
      'lastModified': lastModified?.toIso8601String(),
      'names': names,
      'descriptions': descriptions,
      'customsMultilingual': customsMultilingual,
      'taboosMultilingual': taboosMultilingual,
      'foodsMultilingual': foodsMultilingual,
      'greetingsMultilingual': greetingsMultilingual,
      'activitiesMultilingual': activitiesMultilingual,
      'historyMultilingual': historyMultilingual,
      'contactId': contactId,
      'contactName': contactName,
      'contactRelation': contactRelation,
      'contactAvatar': contactAvatar,
      'tags': tags,
      'groupId': groupId,
      'aiGeneratedGreetings': aiGeneratedGreetings,
      'aiGeneratedGiftSuggestions': aiGeneratedGiftSuggestions,
      'aiGeneratedTips': aiGeneratedTips,
      'reminderSettings': reminderSettings,
      'isRepeating': isRepeating,
      'repeatRule': repeatRule,
      'isShared': isShared,
      'sharedWith': sharedWith,
      'sharingPermissions': sharingPermissions,
      'lastSynced': lastSynced?.toIso8601String(),
      'isSyncConflict': isSyncConflict,
      'showLunarDate': showLunarDate,
      'customColor': customColor,
      'customIcon': customIcon,
      'createdAt': createdAt.toIso8601String(),
      'isExpired': isExpired,
      'isHidden': isHidden,
    };
  }

  /// 创建带有更新时间的副本
  HolidayModelExtended copyWithLastModified() {
    return HolidayModelExtended(
      id: id,
      name: name,
      type: type,
      regions: regions,
      calculationType: calculationType,
      calculationRule: calculationRule,
      description: description,
      importanceLevel: importanceLevel,
      customs: customs,
      taboos: taboos,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
      imageUrl: imageUrl,
      userImportance: userImportance,
      nameEn: nameEn,
      descriptionEn: descriptionEn,
      lastModified: DateTime.now(),
      names: names,
      descriptions: descriptions,
      customsMultilingual: customsMultilingual,
      taboosMultilingual: taboosMultilingual,
      foodsMultilingual: foodsMultilingual,
      greetingsMultilingual: greetingsMultilingual,
      activitiesMultilingual: activitiesMultilingual,
      historyMultilingual: historyMultilingual,
      contactId: contactId,
      contactName: contactName,
      contactRelation: contactRelation,
      contactAvatar: contactAvatar,
      tags: tags,
      groupId: groupId,
      aiGeneratedGreetings: aiGeneratedGreetings,
      aiGeneratedGiftSuggestions: aiGeneratedGiftSuggestions,
      aiGeneratedTips: aiGeneratedTips,
      reminderSettings: reminderSettings,
      isRepeating: isRepeating,
      repeatRule: repeatRule,
      isShared: isShared,
      sharedWith: sharedWith,
      sharingPermissions: sharingPermissions,
      lastSynced: lastSynced,
      isSyncConflict: isSyncConflict,
      showLunarDate: showLunarDate,
      customColor: customColor,
      customIcon: customIcon,
      createdAt: createdAt,
      isExpired: isExpired,
      isHidden: isHidden,
    );
  }

  /// 获取指定语言的名称
  String getLocalizedName(String languageCode) {
    if (names != null && names!.containsKey(languageCode)) {
      return names![languageCode]!;
    }

    if (languageCode == 'en' && nameEn != null) {
      return nameEn!;
    }

    return name; // 默认返回主名称（通常是中文）
  }

  /// 获取指定语言的描述
  String? getLocalizedDescription(String languageCode) {
    if (descriptions != null && descriptions!.containsKey(languageCode)) {
      return descriptions![languageCode];
    }

    if (languageCode == 'en' && descriptionEn != null) {
      return descriptionEn;
    }

    return description; // 默认返回主描述（通常是中文）
  }

  /// 获取指定语言的习俗
  String? getLocalizedCustoms(String languageCode) {
    if (customsMultilingual != null && customsMultilingual!.containsKey(languageCode)) {
      return customsMultilingual![languageCode];
    }
    return customs; // 默认返回主习俗（通常是中文）
  }

  /// 获取指定语言的禁忌
  String? getLocalizedTaboos(String languageCode) {
    if (taboosMultilingual != null && taboosMultilingual!.containsKey(languageCode)) {
      return taboosMultilingual![languageCode];
    }
    return taboos; // 默认返回主禁忌（通常是中文）
  }

  /// 获取指定语言的食物
  String? getLocalizedFoods(String languageCode) {
    if (foodsMultilingual != null && foodsMultilingual!.containsKey(languageCode)) {
      return foodsMultilingual![languageCode];
    }
    return foods; // 默认返回主食物（通常是中文）
  }

  /// 获取指定语言的祝福语
  String? getLocalizedGreetings(String languageCode) {
    if (greetingsMultilingual != null && greetingsMultilingual!.containsKey(languageCode)) {
      return greetingsMultilingual![languageCode];
    }
    return greetings; // 默认返回主祝福语（通常是中文）
  }

  /// 获取指定语言的活动
  String? getLocalizedActivities(String languageCode) {
    if (activitiesMultilingual != null && activitiesMultilingual!.containsKey(languageCode)) {
      return activitiesMultilingual![languageCode];
    }
    return activities; // 默认返回主活动（通常是中文）
  }

  /// 获取指定语言的历史
  String? getLocalizedHistory(String languageCode) {
    if (historyMultilingual != null && historyMultilingual!.containsKey(languageCode)) {
      return historyMultilingual![languageCode];
    }
    return history; // 默认返回主历史（通常是中文）
  }

  /// 获取当前语言环境下的名称
  String getLocalizedNameByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedName(languageCode);
  }

  /// 获取当前语言环境下的描述
  String? getLocalizedDescriptionByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedDescription(languageCode);
  }

  /// 获取当前语言环境下的习俗
  String? getLocalizedCustomsByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedCustoms(languageCode);
  }

  /// 获取当前语言环境下的禁忌
  String? getLocalizedTaboosByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedTaboos(languageCode);
  }

  /// 获取当前语言环境下的食物
  String? getLocalizedFoodsByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedFoods(languageCode);
  }

  /// 获取当前语言环境下的祝福语
  String? getLocalizedGreetingsByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedGreetings(languageCode);
  }

  /// 获取当前语言环境下的活动
  String? getLocalizedActivitiesByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedActivities(languageCode);
  }

  /// 获取当前语言环境下的历史
  String? getLocalizedHistoryByContext(BuildContext context) {
    final languageCode = LocalizationService.getCurrentLanguageCode(context);
    return getLocalizedHistory(languageCode);
  }

  /// 更新多语言名称
  void updateLocalizedName(String languageCode, String value) {
    names ??= {};
    names![languageCode] = value;

    // 同时更新兼容字段
    if (languageCode == 'en') {
      nameEn = value;
    } else if (languageCode == 'zh') {
      name = value;
    }

    lastModified = DateTime.now();
  }

  /// 更新多语言描述
  void updateLocalizedDescription(String languageCode, String? value) {
    if (value == null) return;

    descriptions ??= {};
    descriptions![languageCode] = value;

    // 同时更新兼容字段
    if (languageCode == 'en') {
      descriptionEn = value;
    } else if (languageCode == 'zh') {
      description = value;
    }

    lastModified = DateTime.now();
  }

  /// 解析节日类型
  static HolidayType _parseHolidayType(dynamic value) {
    if (value is HolidayType) return value;
    if (value is String) {
      try {
        return HolidayType.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return HolidayType.other;
  }

  /// 解析计算类型
  static DateCalculationType _parseCalculationType(dynamic value) {
    if (value is DateCalculationType) return value;
    if (value is String) {
      try {
        return DateCalculationType.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return DateCalculationType.fixedGregorian;
  }

  /// 解析重要性级别
  static ImportanceLevel _parseImportanceLevel(dynamic value) {
    if (value is ImportanceLevel) return value;
    if (value is String) {
      try {
        return ImportanceLevel.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return ImportanceLevel.medium;
  }
}
