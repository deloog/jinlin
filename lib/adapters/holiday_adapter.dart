import 'package:jinlin_app/models/holiday_model.dart' as hive;
import 'package:jinlin_app/models/unified/holiday.dart' as unified;
import 'package:jinlin_app/special_date.dart' as app;

/// 节日适配器
///
/// 用于将Hive模型转换为应用程序中使用的SpecialDate类。
class HolidayAdapter {
  /// 将HolidayModel转换为SpecialDate
  static app.SpecialDate toSpecialDate(hive.HolidayModel model) {
    return app.SpecialDate(
      id: model.id,
      name: model.name,
      type: _convertToSpecialDateType(model.type),
      regions: model.regions,
      calculationType: _convertToDateCalculationType(model.calculationType),
      calculationRule: model.calculationRule,
      description: model.description,
      importanceLevel: _convertToImportanceLevel(model.importanceLevel),
      customs: model.customs,
      taboos: model.taboos,
      foods: model.foods,
      greetings: model.greetings,
      activities: model.activities,
      history: model.history,
      imageUrl: model.imageUrl,
    );
  }

  /// 将HolidayModel列表转换为SpecialDate列表
  static List<app.SpecialDate> toSpecialDateList(List<hive.HolidayModel> models) {
    return models.map((model) => toSpecialDate(model)).toList();
  }

  /// 将SpecialDate转换为HolidayModel
  static hive.HolidayModel fromSpecialDate(app.SpecialDate specialDate) {
    return hive.HolidayModel(
      id: specialDate.id,
      name: specialDate.name,
      type: _convertToHolidayType(specialDate.type),
      regions: List<String>.from(specialDate.regions),
      calculationType: _convertToHiveCalculationType(specialDate.calculationType),
      calculationRule: specialDate.calculationRule,
      description: specialDate.description,
      importanceLevel: _convertToHiveImportanceLevel(specialDate.importanceLevel),
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

  /// 将SpecialDate列表转换为HolidayModel列表
  static List<hive.HolidayModel> fromSpecialDateList(List<app.SpecialDate> specialDates) {
    return specialDates.map((specialDate) => fromSpecialDate(specialDate)).toList();
  }

  // 转换节日类型（从Hive到App）
  static app.SpecialDateType _convertToSpecialDateType(hive.HolidayType type) {
    switch (type) {
      case hive.HolidayType.statutory:
        return app.SpecialDateType.statutory;
      case hive.HolidayType.traditional:
        return app.SpecialDateType.traditional;
      case hive.HolidayType.solarTerm:
        return app.SpecialDateType.solarTerm;
      case hive.HolidayType.memorial:
        return app.SpecialDateType.memorial;
      case hive.HolidayType.custom:
        return app.SpecialDateType.custom;
      case hive.HolidayType.religious:
        return app.SpecialDateType.other; // 宗教节日映射到其他类型
      case hive.HolidayType.international:
        return app.SpecialDateType.other; // 国际节日映射到其他类型
      case hive.HolidayType.professional:
        return app.SpecialDateType.other; // 职业节日映射到其他类型
      case hive.HolidayType.cultural:
        return app.SpecialDateType.other; // 文化节日映射到其他类型
      case hive.HolidayType.other:
        return app.SpecialDateType.other;
    }
  }

  // 转换节日类型（从App到Hive）
  static hive.HolidayType _convertToHolidayType(app.SpecialDateType type) {
    switch (type) {
      case app.SpecialDateType.statutory:
        return hive.HolidayType.statutory;
      case app.SpecialDateType.traditional:
        return hive.HolidayType.traditional;
      case app.SpecialDateType.solarTerm:
        return hive.HolidayType.solarTerm;
      case app.SpecialDateType.memorial:
        return hive.HolidayType.memorial;
      case app.SpecialDateType.custom:
        return hive.HolidayType.custom;
      case app.SpecialDateType.other:
        return hive.HolidayType.other;
    }
  }

  // 转换日期计算规则类型（从Hive到App）
  static app.DateCalculationType _convertToDateCalculationType(hive.DateCalculationType type) {
    switch (type) {
      case hive.DateCalculationType.fixedGregorian:
        return app.DateCalculationType.fixedGregorian;
      case hive.DateCalculationType.fixedLunar:
        return app.DateCalculationType.fixedLunar;
      case hive.DateCalculationType.nthWeekdayOfMonth:
        return app.DateCalculationType.nthWeekdayOfMonth;
      case hive.DateCalculationType.solarTermBased:
        return app.DateCalculationType.solarTermBased;
      case hive.DateCalculationType.relativeTo:
        return app.DateCalculationType.relativeTo;
      case hive.DateCalculationType.lastWeekdayOfMonth:
        return app.DateCalculationType.nthWeekdayOfMonth; // 映射到最接近的类型
      case hive.DateCalculationType.easterBased:
        return app.DateCalculationType.relativeTo; // 映射到相对日期类型
      case hive.DateCalculationType.lunarPhase:
        return app.DateCalculationType.relativeTo; // 映射到相对日期类型
      case hive.DateCalculationType.seasonBased:
        return app.DateCalculationType.relativeTo; // 映射到相对日期类型
      case hive.DateCalculationType.weekOfYear:
        return app.DateCalculationType.relativeTo; // 映射到相对日期类型
    }
  }

  // 转换日期计算规则类型（从App到Hive）
  static hive.DateCalculationType _convertToHiveCalculationType(app.DateCalculationType type) {
    switch (type) {
      case app.DateCalculationType.fixedGregorian:
        return hive.DateCalculationType.fixedGregorian;
      case app.DateCalculationType.fixedLunar:
        return hive.DateCalculationType.fixedLunar;
      case app.DateCalculationType.nthWeekdayOfMonth:
        return hive.DateCalculationType.nthWeekdayOfMonth;
      case app.DateCalculationType.solarTermBased:
        return hive.DateCalculationType.solarTermBased;
      case app.DateCalculationType.relativeTo:
        return hive.DateCalculationType.relativeTo;
    }
  }

  // 转换重要性级别（从Hive到App）
  static app.ImportanceLevel _convertToImportanceLevel(hive.ImportanceLevel level) {
    switch (level) {
      case hive.ImportanceLevel.low:
        return app.ImportanceLevel.low;
      case hive.ImportanceLevel.medium:
        return app.ImportanceLevel.medium;
      case hive.ImportanceLevel.high:
        return app.ImportanceLevel.high;
    }
  }

  // 转换重要性级别（从App到Hive）
  static hive.ImportanceLevel _convertToHiveImportanceLevel(app.ImportanceLevel level) {
    switch (level) {
      case app.ImportanceLevel.low:
        return hive.ImportanceLevel.low;
      case app.ImportanceLevel.medium:
        return hive.ImportanceLevel.medium;
      case app.ImportanceLevel.high:
        return hive.ImportanceLevel.high;
    }
  }

  /// 获取统一模型的节日日期
  static DateTime getDate(unified.Holiday holiday, DateTime? occurrenceDate) {
    // 如果提供了发生日期，则使用发生日期
    if (occurrenceDate != null) {
      return occurrenceDate;
    }

    // 否则，使用当前日期（这是一个简化处理，实际应该根据计算规则计算日期）
    return DateTime.now();
  }

  /// 检查统一模型的节日是否为农历节日
  static bool isLunar(unified.Holiday holiday) {
    return holiday.calculationType == unified.DateCalculationType.fixedLunar;
  }

  /// 获取统一模型的节日名称
  static String getName(unified.Holiday holiday, String languageCode) {
    return holiday.getLocalizedName(languageCode);
  }

  /// 获取统一模型的节日描述
  static String? getDescription(unified.Holiday holiday, String languageCode) {
    return holiday.getLocalizedDescription(languageCode);
  }

  /// 将统一模型的HolidayType.statutory映射为HolidayType.national
  static unified.HolidayType mapHolidayType(unified.HolidayType type) {
    if (type == unified.HolidayType.statutory) {
      // 将法定节日映射为国际节日
      return unified.HolidayType.international;
    }
    return type;
  }
}
