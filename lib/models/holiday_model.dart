import 'package:hive/hive.dart';
import 'package:jinlin_app/special_date.dart';

part 'holiday_model.g.dart';

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

/// 节日数据模型
@HiveType(typeId: 0)
class HolidayModel extends HiveObject {
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

  @HiveField(15)
  int userImportance; // 用户自定义重要性，0=普通，1=重要，2=非常重要

  @HiveField(16)
  String? nameEn; // 英文名称

  @HiveField(17)
  String? descriptionEn; // 英文描述

  @HiveField(18)
  DateTime? lastModified; // 最后修改时间

  @HiveField(19)
  bool isSystemHoliday = true; // 是否为系统节日

  @HiveField(20)
  String? contactId; // 关联的联系人ID

  @HiveField(21)
  DateTime createdAt = DateTime.now(); // 创建时间

  HolidayModel({
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
    this.isSystemHoliday = true,
    this.contactId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 从SpecialDate转换为HolidayModel
  factory HolidayModel.fromSpecialDate(dynamic specialDate) {
    // 根据节日类型设置用户重要性
    int userImportance = 2; // 默认设置为非常重要，确保显示在首页

    // 如果是自定义节日，则设置为普通重要性
    if (specialDate.type == SpecialDateType.custom) {
      userImportance = 0;
    }

    return HolidayModel(
      id: specialDate.id,
      name: specialDate.name,
      type: _convertToHolidayType(specialDate.type),
      regions: List<String>.from(specialDate.regions),
      calculationType: _convertToDateCalculationType(specialDate.calculationType),
      calculationRule: specialDate.calculationRule,
      description: specialDate.description,
      importanceLevel: _convertToImportanceLevel(specialDate.importanceLevel),
      customs: specialDate.customs,
      taboos: specialDate.taboos,
      foods: specialDate.foods,
      greetings: specialDate.greetings,
      activities: specialDate.activities,
      history: specialDate.history,
      imageUrl: specialDate.imageUrl,
      userImportance: userImportance, // 设置为非常重要，确保显示在首页
      nameEn: specialDate.nameEn,
      descriptionEn: specialDate.descriptionEn,
      lastModified: DateTime.now(), // 设置当前时间为最后修改时间
      isSystemHoliday: specialDate.type != SpecialDateType.custom, // 自定义节日不是系统节日
      contactId: null, // 默认没有关联联系人
      createdAt: DateTime.now(), // 设置当前时间为创建时间
    );
  }

  // 转换节日类型
  static HolidayType _convertToHolidayType(dynamic type) {
    switch (type.toString()) {
      case 'SpecialDateType.statutory':
        return HolidayType.statutory;
      case 'SpecialDateType.traditional':
        return HolidayType.traditional;
      case 'SpecialDateType.solarTerm':
        return HolidayType.solarTerm;
      case 'SpecialDateType.memorial':
        return HolidayType.memorial;
      case 'SpecialDateType.custom':
        return HolidayType.custom;
      default:
        return HolidayType.other;
    }
  }

  // 转换日期计算规则类型
  static DateCalculationType _convertToDateCalculationType(dynamic type) {
    switch (type.toString()) {
      case 'DateCalculationType.fixedGregorian':
        return DateCalculationType.fixedGregorian;
      case 'DateCalculationType.fixedLunar':
        return DateCalculationType.fixedLunar;
      case 'DateCalculationType.nthWeekdayOfMonth':
        return DateCalculationType.nthWeekdayOfMonth;
      case 'DateCalculationType.solarTermBased':
        return DateCalculationType.solarTermBased;
      default:
        return DateCalculationType.relativeTo;
    }
  }

  // 转换重要性级别
  static ImportanceLevel _convertToImportanceLevel(dynamic level) {
    switch (level.toString()) {
      case 'ImportanceLevel.low':
        return ImportanceLevel.low;
      case 'ImportanceLevel.medium':
        return ImportanceLevel.medium;
      case 'ImportanceLevel.high':
        return ImportanceLevel.high;
      default:
        return ImportanceLevel.low;
    }
  }

  /// 从JSON创建节日模型
  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
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
      isSystemHoliday: json['isSystemHoliday'] as bool? ?? true,
      contactId: json['contactId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
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
      'isSystemHoliday': isSystemHoliday,
      'contactId': contactId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 创建带有更新时间的副本
  HolidayModel copyWithLastModified() {
    return HolidayModel(
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
      isSystemHoliday: isSystemHoliday,
      contactId: contactId,
      createdAt: createdAt,
    );
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
