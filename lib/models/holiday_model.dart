import 'package:hive/hive.dart';

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
  other // 其他
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
  relativeTo // 相对于另一个特殊日期的日期，如 "HOLIDAY_ID,+/-N"
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
  });

  // 从SpecialDate转换为HolidayModel
  factory HolidayModel.fromSpecialDate(dynamic specialDate) {
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
      userImportance: 0, // 默认为普通重要性
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
}
