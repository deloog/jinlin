import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:path_provider/path_provider.dart';

/// Hive数据库服务
///
/// 用于初始化Hive数据库，并提供节日数据的存储和获取功能。
class HiveDatabaseService {
  static const String _holidaysBoxName = 'holidays';
  static const String _userPreferencesBoxName = 'userPreferences';
  static const String _holidayImportanceKey = 'holidayImportance';
  static const String _migrationCompleteKey = 'migrationComplete';

  static bool _initialized = false;

  /// 初始化Hive数据库
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化Hive
      await Hive.initFlutter();

      // 注册适配器（如果尚未注册）
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HolidayModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(HolidayTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DateCalculationTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ImportanceLevelAdapter());
      }

      // 打开盒子
      await Hive.openBox<HolidayModel>(_holidaysBoxName);
      await Hive.openBox<dynamic>(_userPreferencesBoxName);

      _initialized = true;
      debugPrint('Hive数据库初始化成功');
    } catch (e) {
      debugPrint('Hive数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 获取节日盒子
  static Box<HolidayModel> get _holidaysBox => Hive.box<HolidayModel>(_holidaysBoxName);

  /// 获取用户偏好盒子
  static Box<dynamic> get _userPreferencesBox => Hive.box<dynamic>(_userPreferencesBoxName);

  /// 保存节日
  static Future<void> saveHoliday(HolidayModel holiday) async {
    await _holidaysBox.put(holiday.id, holiday);
  }

  /// 批量保存节日
  static Future<void> saveHolidays(List<HolidayModel> holidays) async {
    final Map<String, HolidayModel> holidaysMap = {
      for (var holiday in holidays) holiday.id: holiday
    };
    await _holidaysBox.putAll(holidaysMap);
  }

  /// 获取所有节日
  static List<HolidayModel> getAllHolidays() {
    final holidays = _holidaysBox.values.toList();
    debugPrint("数据库中共有 ${holidays.length} 个节日记录");
    return holidays;
  }

  /// 打印所有节日信息（调试用）
  static void printAllHolidays() {
    final holidays = getAllHolidays();
    debugPrint("========== 数据库中的所有节日 ==========");
    for (var holiday in holidays) {
      debugPrint("ID: ${holiday.id}, 名称: ${holiday.name}, 地区: ${holiday.regions.join(', ')}, 计算规则: ${holiday.calculationRule}");
    }
    debugPrint("======================================");

    // 特别检查劳动节相关记录
    debugPrint("========== 劳动节相关记录 ==========");
    final labourDayHolidays = holidays.where((h) =>
        h.calculationRule == "05-01" ||
        h.name.toLowerCase().contains("labour") ||
        h.name.contains("劳动")).toList();

    for (var holiday in labourDayHolidays) {
      debugPrint("ID: ${holiday.id}, 名称: ${holiday.name}, 地区: ${holiday.regions.join(', ')}, 计算规则: ${holiday.calculationRule}");
    }
    debugPrint("======================================");
  }

  /// 根据ID获取节日
  static HolidayModel? getHolidayById(String id) {
    return _holidaysBox.get(id);
  }

  /// 根据地区获取节日
  static List<HolidayModel> getHolidaysByRegion(String region, {bool isChineseLocale = false}) {
    // 获取所有节日
    final allHolidays = _holidaysBox.values.toList();

    // 创建一个映射，用于存储每个计算规则对应的最佳节日
    // 键是"计算规则"，值是节日模型
    final Map<String, HolidayModel> bestHolidayByRule = {};

    // 首先处理当前地区的节日
    for (var holiday in allHolidays) {
      if (holiday.regions.contains(region)) {
        String key = holiday.calculationRule;

        // 检查节日名称是否与当前语言环境匹配
        bool isNameMatchLocale = isChineseLocale
            ? _isChinese(holiday.name)  // 中文环境下检查是否为中文名称
            : !_isChinese(holiday.name); // 非中文环境下检查是否为非中文名称

        // 如果这个计算规则还没有对应的节日，或者当前节日名称更符合语言环境，则更新
        if (!bestHolidayByRule.containsKey(key) || isNameMatchLocale) {
          bestHolidayByRule[key] = holiday;
          debugPrint("添加/更新地区节日: ${holiday.id} (${holiday.name}) - ${holiday.calculationRule} - 匹配语言: $isNameMatchLocale");
        }
      }
    }

    // 然后处理国际节日
    for (var holiday in allHolidays) {
      if (holiday.regions.contains('INTL') || holiday.regions.contains('ALL')) {
        String key = holiday.calculationRule;

        // 如果这个计算规则已经有对应的节日，则跳过
        if (bestHolidayByRule.containsKey(key)) {
          debugPrint("跳过国际节日(已有地区节日): ${holiday.id} (${holiday.name}) - ${holiday.calculationRule}");
          continue;
        }

        // 检查节日名称是否与当前语言环境匹配
        bool isNameMatchLocale = isChineseLocale
            ? _isChinese(holiday.name)  // 中文环境下检查是否为中文名称
            : !_isChinese(holiday.name); // 非中文环境下检查是否为非中文名称

        // 如果这个计算规则还没有对应的节日，或者当前节日名称更符合语言环境，则更新
        if (!bestHolidayByRule.containsKey(key) || isNameMatchLocale) {
          bestHolidayByRule[key] = holiday;
          debugPrint("添加/更新国际节日: ${holiday.id} (${holiday.name}) - ${holiday.calculationRule} - 匹配语言: $isNameMatchLocale");
        }
      }
    }

    // 将映射中的节日转换为列表
    final result = bestHolidayByRule.values.toList();

    // 特别检查劳动节相关记录
    final labourDayHolidays = result.where((h) =>
        h.calculationRule == "05-01" ||
        h.name.toLowerCase().contains("labour") ||
        h.name.contains("劳动")).toList();

    if (labourDayHolidays.length > 1) {
      debugPrint("警告：发现多个劳动节记录！");
      for (var holiday in labourDayHolidays) {
        debugPrint("  ID: ${holiday.id}, 名称: ${holiday.name}, 地区: ${holiday.regions.join(', ')}, 计算规则: ${holiday.calculationRule}");
      }

      // 只保留一个劳动节记录
      final preferredLabourDay = labourDayHolidays.firstWhere(
        (h) => isChineseLocale ? _isChinese(h.name) : !_isChinese(h.name),
        orElse: () => labourDayHolidays.first
      );

      // 从结果中移除其他劳动节记录
      result.removeWhere((h) =>
          h.calculationRule == "05-01" &&
          h.id != preferredLabourDay.id);

      debugPrint("保留的劳动节记录: ID: ${preferredLabourDay.id}, 名称: ${preferredLabourDay.name}");
    }

    debugPrint("总共获取到 ${result.length} 个节日 (语言环境: ${isChineseLocale ? '中文' : '非中文'})");
    return result;
  }

  /// 判断文本是否为中文
  static bool _isChinese(String text) {
    // 简单判断：如果包含中文字符，则认为是中文
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
  }

  /// 更新节日重要性
  static Future<void> updateHolidayImportance(String holidayId, int importance) async {
    final holiday = _holidaysBox.get(holidayId);
    if (holiday != null) {
      holiday.userImportance = importance;
      await holiday.save();
    }
  }

  /// 获取节日重要性
  static Map<String, int> getHolidayImportance() {
    final Map<String, int> result = {};
    for (var holiday in _holidaysBox.values) {
      if (holiday.userImportance > 0) {
        result[holiday.id] = holiday.userImportance;
      }
    }
    return result;
  }

  /// 保存节日重要性
  static Future<void> saveHolidayImportance(Map<String, int> importance) async {
    for (var entry in importance.entries) {
      await updateHolidayImportance(entry.key, entry.value);
    }
  }

  /// 检查数据迁移是否完成
  static bool isMigrationComplete() {
    return _userPreferencesBox.get(_migrationCompleteKey, defaultValue: false);
  }

  /// 设置数据迁移完成
  static Future<void> setMigrationComplete(bool complete) async {
    await _userPreferencesBox.put(_migrationCompleteKey, complete);
  }

  /// 从SpecialDate列表迁移数据
  static Future<void> migrateFromSpecialDates(List<dynamic> specialDates) async {
    final List<HolidayModel> holidays = [];
    final Set<String> existingIds = _holidaysBox.keys.cast<String>().toSet();

    for (var specialDate in specialDates) {
      try {
        final holiday = HolidayModel.fromSpecialDate(specialDate);

        // 检查节日ID是否已存在
        if (!existingIds.contains(holiday.id)) {
          holidays.add(holiday);
          existingIds.add(holiday.id);
        } else {
          debugPrint('节日ID已存在，跳过: ${holiday.id} (${holiday.name})');
        }
      } catch (e) {
        debugPrint('Error converting SpecialDate to HolidayModel: $e');
      }
    }

    if (holidays.isNotEmpty) {
      await saveHolidays(holidays);
      debugPrint('成功迁移 ${holidays.length} 个节日');
    } else {
      debugPrint('没有新节日需要迁移');
    }
  }

  /// 清空所有数据
  static Future<void> clearAll() async {
    await _holidaysBox.clear();
    await _userPreferencesBox.clear();
    _initialized = false;
  }

  /// 只清空节日数据，保留用户偏好设置
  static Future<void> clearHolidays() async {
    await _holidaysBox.clear();
    debugPrint('节日数据已清空');
  }
}
