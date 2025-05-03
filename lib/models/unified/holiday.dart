import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:jinlin_app/models/soft_deletable.dart';

/// 节日类型
enum HolidayType {
  statutory,    // 法定节日
  traditional,  // 传统节日
  solarTerm,    // 节气
  memorial,     // 纪念日
  custom,       // 自定义
  religious,    // 宗教节日
  international, // 国际节日
  professional, // 职业节日
  cultural,     // 文化节日
  other         // 其他
}

/// 日期计算类型
enum DateCalculationType {
  fixedGregorian, // 固定公历日期 (如 01-01)
  fixedLunar,     // 固定农历日期 (如 L01-01)
  variableRule,   // 可变规则 (如感恩节：11月第4个星期四)
  custom          // 自定义规则
}

/// 重要性级别
enum ImportanceLevel {
  low,    // 低
  medium, // 中
  high    // 高
}

/// 统一的节日数据模型
class Holiday implements SoftDeletable {
  final String id;
  final bool isSystemHoliday; // 是否为系统预设节日

  // 基本信息
  final Map<String, String> names; // 多语言名称 {'zh': '中文名', 'en': 'English Name', ...}
  final HolidayType type;
  final List<String> regions;
  final DateCalculationType calculationType;
  final String calculationRule;
  final Map<String, String> descriptions; // 多语言描述
  final ImportanceLevel importanceLevel;

  // 详细信息
  final Map<String, String>? customs; // 多语言习俗
  final Map<String, String>? taboos; // 多语言禁忌
  final Map<String, String>? foods; // 多语言食物
  final Map<String, String>? greetings; // 多语言祝福语
  final Map<String, String>? activities; // 多语言活动
  final Map<String, String>? history; // 多语言历史
  final String? imageUrl;

  // 用户设置
  final int userImportance; // 用户自定义重要性，0=普通，1=重要，2=非常重要

  // 元数据
  final DateTime createdAt;
  final DateTime? lastModified;

  // 软删除相关
  @override
  final bool isDeleted;

  @override
  final DateTime? deletedAt;

  @override
  final String? deletionReason;

  // 联系人关联
  final String? contactId; // 关联的联系人ID

  Holiday({
    required this.id,
    this.isSystemHoliday = false,
    required Map<String, String> names,
    required this.type,
    required this.regions,
    required this.calculationType,
    required this.calculationRule,
    Map<String, String>? descriptions,
    this.importanceLevel = ImportanceLevel.low,
    this.customs,
    this.taboos,
    this.foods,
    this.greetings,
    this.activities,
    this.history,
    this.imageUrl,
    this.userImportance = 0,
    this.contactId,
    DateTime? createdAt,
    this.lastModified,
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
  }) :
    names = Map.unmodifiable(names),
    descriptions = Map.unmodifiable(descriptions ?? {}),
    createdAt = createdAt ?? DateTime.now();

  // 从API JSON创建对象
  factory Holiday.fromApiJson(Map<String, dynamic> json) {
    // 解析类型
    HolidayType type;
    try {
      type = HolidayType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => HolidayType.other
      );
    } catch (_) {
      type = HolidayType.other;
    }

    // 解析计算类型
    DateCalculationType calculationType;
    try {
      calculationType = DateCalculationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['calculationType'],
        orElse: () => DateCalculationType.fixedGregorian
      );
    } catch (_) {
      calculationType = DateCalculationType.fixedGregorian;
    }

    // 解析重要性级别
    ImportanceLevel importanceLevel;
    try {
      importanceLevel = ImportanceLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['importanceLevel'].toString(),
        orElse: () => ImportanceLevel.medium
      );
    } catch (_) {
      importanceLevel = ImportanceLevel.medium;
    }

    return Holiday(
      id: json['id'],
      isSystemHoliday: true,
      names: {json['language_code'] ?? 'en': json['name']},
      descriptions: {json['language_code'] ?? 'en': json['description'] ?? ''},
      type: type,
      regions: json['regions'] is List
          ? List<String>.from(json['regions'])
          : [json['region_code'] ?? 'GLOBAL'],
      calculationType: calculationType,
      calculationRule: json['calculationRule'],
      importanceLevel: importanceLevel,
      customs: json['customs'] != null ? {json['language_code'] ?? 'en': json['customs']} : null,
      foods: json['foods'] != null ? {json['language_code'] ?? 'en': json['foods']} : null,
      greetings: json['greetings'] != null ? {json['language_code'] ?? 'en': json['greetings']} : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // 从Map创建对象（用于从数据库加载）
  factory Holiday.fromMap(Map<String, dynamic> map) {
    return Holiday(
      id: map['id'],
      isSystemHoliday: map['is_system_holiday'] == 1,
      names: Map<String, String>.from(map['names'] != null
          ? (map['names'] is String ? jsonDecode(map['names']) : map['names'])
          : {'zh': map['name_zh'] ?? '', 'en': map['name_en'] ?? ''}),
      type: HolidayType.values[map['type_id'] ?? 0],
      regions: (map['regions'] != null)
          ? (map['regions'] is String
              ? (jsonDecode(map['regions']) as List).cast<String>()
              : (map['regions'] as List).cast<String>())
          : [],
      calculationType: DateCalculationType.values[map['calculation_type_id'] ?? 0],
      calculationRule: map['calculation_rule'] ?? '',
      descriptions: Map<String, String>.from(map['descriptions'] != null
          ? (map['descriptions'] is String ? jsonDecode(map['descriptions']) : map['descriptions'])
          : {'zh': map['description_zh'] ?? '', 'en': map['description_en'] ?? ''}),
      importanceLevel: ImportanceLevel.values[map['importance_level'] ?? 0],
      customs: map['customs'] != null
          ? Map<String, String>.from(map['customs'] is String
              ? jsonDecode(map['customs'])
              : map['customs'])
          : null,
      taboos: map['taboos'] != null
          ? Map<String, String>.from(map['taboos'] is String
              ? jsonDecode(map['taboos'])
              : map['taboos'])
          : null,
      foods: map['foods'] != null
          ? Map<String, String>.from(map['foods'] is String
              ? jsonDecode(map['foods'])
              : map['foods'])
          : null,
      greetings: map['greetings'] != null
          ? Map<String, String>.from(map['greetings'] is String
              ? jsonDecode(map['greetings'])
              : map['greetings'])
          : null,
      activities: map['activities'] != null
          ? Map<String, String>.from(map['activities'] is String
              ? jsonDecode(map['activities'])
              : map['activities'])
          : null,
      history: map['history'] != null
          ? Map<String, String>.from(map['history'] is String
              ? jsonDecode(map['history'])
              : map['history'])
          : null,
      imageUrl: map['image_url'],
      userImportance: map['user_importance'] ?? 0,
      contactId: map['contact_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'])
          : null,
      isDeleted: map['is_deleted'] == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'])
          : null,
      deletionReason: map['deletion_reason'],
    );
  }

  // 转换为Map（用于保存到数据库）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_system_holiday': isSystemHoliday ? 1 : 0,
      'names': jsonEncode(names),
      'type_id': type.index,
      'regions': jsonEncode(regions),
      'calculation_type_id': calculationType.index,
      'calculation_rule': calculationRule,
      'descriptions': jsonEncode(descriptions),
      'importance_level': importanceLevel.index,
      'customs': customs != null ? jsonEncode(customs) : null,
      'taboos': taboos != null ? jsonEncode(taboos) : null,
      'foods': foods != null ? jsonEncode(foods) : null,
      'greetings': greetings != null ? jsonEncode(greetings) : null,
      'activities': activities != null ? jsonEncode(activities) : null,
      'history': history != null ? jsonEncode(history) : null,
      'image_url': imageUrl,
      'user_importance': userImportance,
      'contact_id': contactId,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'deletion_reason': deletionReason,
    };
  }

  // 创建带有更新时间的副本
  Holiday copyWithLastModified() {
    return Holiday(
      id: id,
      isSystemHoliday: isSystemHoliday,
      names: Map<String, String>.from(names),
      type: type,
      regions: List<String>.from(regions),
      calculationType: calculationType,
      calculationRule: calculationRule,
      descriptions: Map<String, String>.from(descriptions),
      importanceLevel: importanceLevel,
      customs: customs != null ? Map<String, String>.from(customs!) : null,
      taboos: taboos != null ? Map<String, String>.from(taboos!) : null,
      foods: foods != null ? Map<String, String>.from(foods!) : null,
      greetings: greetings != null ? Map<String, String>.from(greetings!) : null,
      activities: activities != null ? Map<String, String>.from(activities!) : null,
      history: history != null ? Map<String, String>.from(history!) : null,
      imageUrl: imageUrl,
      userImportance: userImportance,
      contactId: contactId,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      deletionReason: deletionReason,
    );
  }



  // 从旧模型转换
  factory Holiday.fromHolidayModel(dynamic oldModel) {
    // 创建名称映射
    final Map<String, String> names = {
      'zh': oldModel.name,
    };

    // 如果有英文名称，添加到映射
    if (oldModel.nameEn != null && oldModel.nameEn.isNotEmpty) {
      names['en'] = oldModel.nameEn;
    }

    // 创建描述映射
    final Map<String, String> descriptions = {};

    // 如果有中文描述，添加到映射
    if (oldModel.description != null && oldModel.description.isNotEmpty) {
      descriptions['zh'] = oldModel.description;
    }

    // 如果有英文描述，添加到映射
    if (oldModel.descriptionEn != null && oldModel.descriptionEn.isNotEmpty) {
      descriptions['en'] = oldModel.descriptionEn;
    }

    // 创建习俗映射
    Map<String, String>? customs;
    if (oldModel.customs != null && oldModel.customs.isNotEmpty) {
      customs = {'zh': oldModel.customs};
    }

    // 创建禁忌映射
    Map<String, String>? taboos;
    if (oldModel.taboos != null && oldModel.taboos.isNotEmpty) {
      taboos = {'zh': oldModel.taboos};
    }

    // 创建食物映射
    Map<String, String>? foods;
    if (oldModel.foods != null && oldModel.foods.isNotEmpty) {
      foods = {'zh': oldModel.foods};
    }

    // 创建祝福语映射
    Map<String, String>? greetings;
    if (oldModel.greetings != null && oldModel.greetings.isNotEmpty) {
      greetings = {'zh': oldModel.greetings};
    }

    // 创建活动映射
    Map<String, String>? activities;
    if (oldModel.activities != null && oldModel.activities.isNotEmpty) {
      activities = {'zh': oldModel.activities};
    }

    // 创建历史映射
    Map<String, String>? history;
    if (oldModel.history != null && oldModel.history.isNotEmpty) {
      history = {'zh': oldModel.history};
    }

    // 如果是扩展模型，处理多语言字段
    if (oldModel.runtimeType.toString().contains('Extended')) {
      // 处理多语言名称
      if (oldModel.names != null && oldModel.names.isNotEmpty) {
        names.addAll(Map<String, String>.from(oldModel.names));
      }

      // 处理多语言描述
      if (oldModel.descriptions != null && oldModel.descriptions.isNotEmpty) {
        descriptions.addAll(Map<String, String>.from(oldModel.descriptions));
      }

      // 处理多语言习俗
      if (oldModel.customsMultilingual != null && oldModel.customsMultilingual.isNotEmpty) {
        customs = Map<String, String>.from(oldModel.customsMultilingual);
      }

      // 处理多语言禁忌
      if (oldModel.taboosMultilingual != null && oldModel.taboosMultilingual.isNotEmpty) {
        taboos = Map<String, String>.from(oldModel.taboosMultilingual);
      }

      // 处理多语言食物
      if (oldModel.foodsMultilingual != null && oldModel.foodsMultilingual.isNotEmpty) {
        foods = Map<String, String>.from(oldModel.foodsMultilingual);
      }

      // 处理多语言祝福语
      if (oldModel.greetingsMultilingual != null && oldModel.greetingsMultilingual.isNotEmpty) {
        greetings = Map<String, String>.from(oldModel.greetingsMultilingual);
      }

      // 处理多语言活动
      if (oldModel.activitiesMultilingual != null && oldModel.activitiesMultilingual.isNotEmpty) {
        activities = Map<String, String>.from(oldModel.activitiesMultilingual);
      }

      // 处理多语言历史
      if (oldModel.historyMultilingual != null && oldModel.historyMultilingual.isNotEmpty) {
        history = Map<String, String>.from(oldModel.historyMultilingual);
      }
    }

    return Holiday(
      id: oldModel.id,
      isSystemHoliday: false, // 默认为用户自定义节日
      names: names,
      type: oldModel.type,
      regions: List<String>.from(oldModel.regions),
      calculationType: oldModel.calculationType,
      calculationRule: oldModel.calculationRule,
      descriptions: descriptions,
      importanceLevel: oldModel.importanceLevel,
      customs: customs,
      taboos: taboos,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
      imageUrl: oldModel.imageUrl,
      userImportance: oldModel.userImportance,
      contactId: oldModel.runtimeType.toString().contains('Extended') ? oldModel.contactId : null,
      createdAt: DateTime.now(),
      lastModified: oldModel.lastModified,
    );
  }

  // 获取指定语言的名称
  String getLocalizedName(String languageCode) {
    if (names.containsKey(languageCode)) {
      return names[languageCode]!;
    } else if (names.containsKey('en')) {
      return names['en']!;
    } else if (names.containsKey('zh')) {
      return names['zh']!;
    } else {
      return names.values.first;
    }
  }

  // 获取名称（简化方法）
  String getName(String languageCode) => getLocalizedName(languageCode);

  // 获取指定语言的描述
  String? getLocalizedDescription(String languageCode) {
    if (descriptions.containsKey(languageCode)) {
      return descriptions[languageCode];
    } else if (descriptions.containsKey('en')) {
      return descriptions['en'];
    } else if (descriptions.containsKey('zh')) {
      return descriptions['zh'];
    } else if (descriptions.isNotEmpty) {
      return descriptions.values.first;
    } else {
      return null;
    }
  }

  // 获取描述（简化方法）
  String? getDescription(String languageCode) => getLocalizedDescription(languageCode);

  // 获取指定语言的习俗
  String? getLocalizedCustoms(String languageCode) {
    if (customs == null) return null;

    if (customs!.containsKey(languageCode)) {
      return customs![languageCode];
    } else if (customs!.containsKey('en')) {
      return customs!['en'];
    } else if (customs!.containsKey('zh')) {
      return customs!['zh'];
    } else if (customs!.isNotEmpty) {
      return customs!.values.first;
    } else {
      return null;
    }
  }

  // 获取指定语言的禁忌
  String? getLocalizedTaboos(String languageCode) {
    if (taboos == null) return null;

    if (taboos!.containsKey(languageCode)) {
      return taboos![languageCode];
    } else if (taboos!.containsKey('en')) {
      return taboos!['en'];
    } else if (taboos!.containsKey('zh')) {
      return taboos!['zh'];
    } else if (taboos!.isNotEmpty) {
      return taboos!.values.first;
    } else {
      return null;
    }
  }

  // 获取指定语言的食物
  String? getLocalizedFoods(String languageCode) {
    if (foods == null) return null;

    if (foods!.containsKey(languageCode)) {
      return foods![languageCode];
    } else if (foods!.containsKey('en')) {
      return foods!['en'];
    } else if (foods!.containsKey('zh')) {
      return foods!['zh'];
    } else if (foods!.isNotEmpty) {
      return foods!.values.first;
    } else {
      return null;
    }
  }

  // 获取指定语言的祝福语
  String? getLocalizedGreetings(String languageCode) {
    if (greetings == null) return null;

    if (greetings!.containsKey(languageCode)) {
      return greetings![languageCode];
    } else if (greetings!.containsKey('en')) {
      return greetings!['en'];
    } else if (greetings!.containsKey('zh')) {
      return greetings!['zh'];
    } else if (greetings!.isNotEmpty) {
      return greetings!.values.first;
    } else {
      return null;
    }
  }

  // 创建新的节日实例
  static Holiday createNew({
    required String name,
    required String nameEn,
    required HolidayType type,
    required List<String> regions,
    required DateCalculationType calculationType,
    required String calculationRule,
    String? description,
    String? descriptionEn,
    ImportanceLevel importanceLevel = ImportanceLevel.medium,
    String? customs,
    String? taboos,
    String? foods,
    String? greetings,
    String? activities,
    String? history,
    String? imageUrl,
    int userImportance = 0,
    String? contactId,
  }) {
    // 生成唯一ID
    const uuid = Uuid();
    final id = 'holiday_${uuid.v4()}';

    // 创建多语言映射
    final names = <String, String>{
      'zh': name,
      'en': nameEn,
    };

    final descriptions = <String, String>{};
    if (description != null && description.isNotEmpty) {
      descriptions['zh'] = description;
    }
    if (descriptionEn != null && descriptionEn.isNotEmpty) {
      descriptions['en'] = descriptionEn;
    }

    // 创建其他多语言映射
    Map<String, String>? customsMap;
    if (customs != null && customs.isNotEmpty) {
      customsMap = {'zh': customs};
    }

    Map<String, String>? taboosMap;
    if (taboos != null && taboos.isNotEmpty) {
      taboosMap = {'zh': taboos};
    }

    Map<String, String>? foodsMap;
    if (foods != null && foods.isNotEmpty) {
      foodsMap = {'zh': foods};
    }

    Map<String, String>? greetingsMap;
    if (greetings != null && greetings.isNotEmpty) {
      greetingsMap = {'zh': greetings};
    }

    Map<String, String>? activitiesMap;
    if (activities != null && activities.isNotEmpty) {
      activitiesMap = {'zh': activities};
    }

    Map<String, String>? historyMap;
    if (history != null && history.isNotEmpty) {
      historyMap = {'zh': history};
    }

    // 创建并返回新的节日实例
    return Holiday(
      id: id,
      isSystemHoliday: false,
      names: names,
      type: type,
      regions: regions,
      calculationType: calculationType,
      calculationRule: calculationRule,
      descriptions: descriptions,
      importanceLevel: importanceLevel,
      customs: customsMap,
      taboos: taboosMap,
      foods: foodsMap,
      greetings: greetingsMap,
      activities: activitiesMap,
      history: historyMap,
      imageUrl: imageUrl,
      userImportance: userImportance,
      contactId: contactId,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  // 创建带有修改的副本
  Holiday copyWith({
    String? id,
    bool? isSystemHoliday,
    Map<String, String>? names,
    HolidayType? type,
    List<String>? regions,
    DateCalculationType? calculationType,
    String? calculationRule,
    Map<String, String>? descriptions,
    ImportanceLevel? importanceLevel,
    Map<String, String>? customs,
    Map<String, String>? taboos,
    Map<String, String>? foods,
    Map<String, String>? greetings,
    Map<String, String>? activities,
    Map<String, String>? history,
    String? imageUrl,
    int? userImportance,
    String? contactId,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletionReason,
  }) {
    return Holiday(
      id: id ?? this.id,
      isSystemHoliday: isSystemHoliday ?? this.isSystemHoliday,
      names: names ?? Map<String, String>.from(this.names),
      type: type ?? this.type,
      regions: regions ?? List<String>.from(this.regions),
      calculationType: calculationType ?? this.calculationType,
      calculationRule: calculationRule ?? this.calculationRule,
      descriptions: descriptions ?? Map<String, String>.from(this.descriptions),
      importanceLevel: importanceLevel ?? this.importanceLevel,
      customs: customs ?? (this.customs != null ? Map<String, String>.from(this.customs!) : null),
      taboos: taboos ?? (this.taboos != null ? Map<String, String>.from(this.taboos!) : null),
      foods: foods ?? (this.foods != null ? Map<String, String>.from(this.foods!) : null),
      greetings: greetings ?? (this.greetings != null ? Map<String, String>.from(this.greetings!) : null),
      activities: activities ?? (this.activities != null ? Map<String, String>.from(this.activities!) : null),
      history: history ?? (this.history != null ? Map<String, String>.from(this.history!) : null),
      imageUrl: imageUrl ?? this.imageUrl,
      userImportance: userImportance ?? this.userImportance,
      contactId: contactId ?? this.contactId,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionReason: deletionReason ?? this.deletionReason,
    );
  }

  // 比较两个节日是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Holiday &&
      other.id == id &&
      other.isSystemHoliday == isSystemHoliday &&
      mapEquals(other.names, names) &&
      other.type == type &&
      listEquals(other.regions, regions) &&
      other.calculationType == calculationType &&
      other.calculationRule == calculationRule &&
      mapEquals(other.descriptions, descriptions) &&
      other.importanceLevel == importanceLevel &&
      other.userImportance == userImportance &&
      other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      isSystemHoliday.hashCode ^
      names.hashCode ^
      type.hashCode ^
      regions.hashCode ^
      calculationType.hashCode ^
      calculationRule.hashCode ^
      descriptions.hashCode ^
      importanceLevel.hashCode ^
      userImportance.hashCode ^
      isDeleted.hashCode;
  }
}
