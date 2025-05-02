import 'package:jinlin_app/special_date.dart';

class Holiday {
  final String id;
  final String nameZh;
  final String nameEn;
  final String typeId;
  final String calculationType;
  final String calculationRule;
  final String? descriptionZh;
  final String? descriptionEn;
  final int importanceLevel;
  final List<String> regionIds;

  Holiday({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.typeId,
    required this.calculationType,
    required this.calculationRule,
    this.descriptionZh,
    this.descriptionEn,
    this.importanceLevel = 0,
    required this.regionIds,
  });

  // 从数据库映射创建对象
  factory Holiday.fromMap(Map<String, dynamic> map, List<String> regionIds) {
    return Holiday(
      id: map['id'],
      nameZh: map['name_zh'],
      nameEn: map['name_en'],
      typeId: map['type_id'],
      calculationType: map['calculation_type'],
      calculationRule: map['calculation_rule'],
      descriptionZh: map['description_zh'],
      descriptionEn: map['description_en'],
      importanceLevel: map['importance_level'] ?? 0,
      regionIds: regionIds,
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_zh': nameZh,
      'name_en': nameEn,
      'type_id': typeId,
      'calculation_type': calculationType,
      'calculation_rule': calculationRule,
      'description_zh': descriptionZh,
      'description_en': descriptionEn,
      'importance_level': importanceLevel,
    };
  }

  // 转换为 SpecialDate 对象
  SpecialDate toSpecialDate(bool isChinese) {
    return SpecialDate(
      id: id,
      name: isChinese ? nameZh : nameEn,
      type: _getSpecialDateType(typeId),
      regions: regionIds,
      calculationType: _getCalculationType(calculationType),
      calculationRule: calculationRule,
      description: isChinese ? descriptionZh : descriptionEn,
      importanceLevel: _getImportanceLevel(importanceLevel),
    );
  }

  // 从 SpecialDate 对象创建
  factory Holiday.fromSpecialDate(SpecialDate specialDate) {
    return Holiday(
      id: specialDate.id,
      nameZh: specialDate.name, // 假设当前是中文环境
      nameEn: specialDate.name, // 假设当前是英文环境
      typeId: _getTypeId(specialDate.type),
      calculationType: _getCalculationTypeString(specialDate.calculationType),
      calculationRule: specialDate.calculationRule,
      descriptionZh: specialDate.description, // 假设当前是中文环境
      descriptionEn: specialDate.description, // 假设当前是英文环境
      importanceLevel: _getImportanceLevelInt(specialDate.importanceLevel),
      regionIds: specialDate.regions,
    );
  }

  // 辅助方法：将字符串类型ID转换为 SpecialDateType
  static SpecialDateType _getSpecialDateType(String typeId) {
    switch (typeId) {
      case 'statutory':
        return SpecialDateType.statutory;
      case 'traditional':
        return SpecialDateType.traditional;
      case 'memorial':
        return SpecialDateType.memorial;
      case 'solarTerm':
        return SpecialDateType.solarTerm;
      default:
        return SpecialDateType.memorial;
    }
  }

  // 辅助方法：将 SpecialDateType 转换为字符串类型ID
  static String _getTypeId(SpecialDateType type) {
    switch (type) {
      case SpecialDateType.statutory:
        return 'statutory';
      case SpecialDateType.traditional:
        return 'traditional';
      case SpecialDateType.memorial:
        return 'memorial';
      case SpecialDateType.solarTerm:
        return 'solarTerm';
      default:
        return 'memorial';
    }
  }

  // 辅助方法：将字符串计算类型转换为 DateCalculationType
  static DateCalculationType _getCalculationType(String calculationType) {
    switch (calculationType) {
      case 'fixedGregorian':
        return DateCalculationType.fixedGregorian;
      case 'fixedLunar':
        return DateCalculationType.fixedLunar;
      case 'nthWeekdayOfMonth':
        return DateCalculationType.nthWeekdayOfMonth;
      case 'solarTermBased':
        return DateCalculationType.solarTermBased;
      case 'relativeTo':
        return DateCalculationType.relativeTo;
      default:
        return DateCalculationType.fixedGregorian;
    }
  }

  // 辅助方法：将 DateCalculationType 转换为字符串
  static String _getCalculationTypeString(DateCalculationType calculationType) {
    switch (calculationType) {
      case DateCalculationType.fixedGregorian:
        return 'fixedGregorian';
      case DateCalculationType.fixedLunar:
        return 'fixedLunar';
      case DateCalculationType.nthWeekdayOfMonth:
        return 'nthWeekdayOfMonth';
      case DateCalculationType.solarTermBased:
        return 'solarTermBased';
      case DateCalculationType.relativeTo:
        return 'relativeTo';
      // 所有枚举值都已处理完毕
      // 如果将来添加新的枚举值，在这里处理
    }
  }

  // 辅助方法：将整数重要性转换为 ImportanceLevel
  static ImportanceLevel _getImportanceLevel(int importanceLevel) {
    switch (importanceLevel) {
      case 0:
        return ImportanceLevel.low;
      case 1:
        return ImportanceLevel.medium;
      case 2:
        return ImportanceLevel.high;
      default:
        return ImportanceLevel.low;
    }
  }

  // 辅助方法：将 ImportanceLevel 转换为整数
  static int _getImportanceLevelInt(ImportanceLevel importanceLevel) {
    switch (importanceLevel) {
      case ImportanceLevel.low:
        return 0;
      case ImportanceLevel.medium:
        return 1;
      case ImportanceLevel.high:
        return 2;
      // 所有枚举值都已处理完毕
      // 如果将来添加新的枚举值，在这里处理
    }
  }
}
