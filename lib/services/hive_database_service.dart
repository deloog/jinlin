import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/holiday_cache_service.dart';

/// Hive数据库服务
///
/// 用于初始化Hive数据库，并提供节日数据的存储和获取功能。
class HiveDatabaseService {
  static const String _holidaysBoxName = 'holidays';
  static const String _userPreferencesBoxName = 'userPreferences';
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

      // 确保所有适配器都已注册
      _ensureAllAdaptersRegistered();

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

  /// 确保所有适配器都已注册
  static void _ensureAllAdaptersRegistered() {
    try {
      // 确保所有必要的适配器都已注册
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

      // 注意：如果需要注册其他适配器，可以在这里添加

      debugPrint('所有适配器注册成功');
    } catch (e) {
      debugPrint('注册适配器失败: $e');
    }
  }

  /// 获取节日盒子
  static Box<HolidayModel> get _holidaysBox => Hive.box<HolidayModel>(_holidaysBoxName);

  /// 获取用户偏好盒子
  static Box<dynamic> get _userPreferencesBox => Hive.box<dynamic>(_userPreferencesBoxName);

  /// 保存节日
  static Future<void> saveHoliday(HolidayModel holiday) async {
    // 如果没有设置最后修改时间，则设置为当前时间
    HolidayModel holidayToSave;
    if (holiday.lastModified == null) {
      // 创建一个带有当前时间的副本
      holidayToSave = HolidayModel(
        id: holiday.id,
        name: holiday.name,
        type: holiday.type,
        regions: holiday.regions,
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
        lastModified: DateTime.now(),
      );
      await _holidaysBox.put(holidayToSave.id, holidayToSave);
      debugPrint("保存节日并更新最后修改时间: ${holidayToSave.id} (${holidayToSave.name})");
    } else {
      holidayToSave = holiday;
      await _holidaysBox.put(holidayToSave.id, holidayToSave);
      debugPrint("保存节日: ${holidayToSave.id} (${holidayToSave.name})");
    }

    // 更新缓存（而不是清除）
    final cacheService = HolidayCacheService();
    cacheService.updateCachedHoliday(holidayToSave);
    debugPrint("保存节日后更新缓存: ${holidayToSave.id} (${holidayToSave.name})");
  }

  /// 批量保存节日
  static Future<void> saveHolidays(List<HolidayModel> holidays) async {
    final Map<String, HolidayModel> holidaysMap = {};
    final List<HolidayModel> savedHolidays = [];

    // 检查每个节日是否有最后修改时间，如果没有则设置为当前时间
    for (var holiday in holidays) {
      HolidayModel holidayToSave;
      if (holiday.lastModified == null) {
        // 创建一个带有当前时间的副本
        holidayToSave = HolidayModel(
          id: holiday.id,
          name: holiday.name,
          type: holiday.type,
          regions: holiday.regions,
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
          lastModified: DateTime.now(),
        );
      } else {
        holidayToSave = holiday;
      }

      holidaysMap[holidayToSave.id] = holidayToSave;
      savedHolidays.add(holidayToSave);
    }

    await _holidaysBox.putAll(holidaysMap);

    // 更新缓存（而不是清除）
    final cacheService = HolidayCacheService();

    // 如果保存的节日数量超过一定阈值，则清除缓存重新加载
    // 这样可以避免大量更新时的性能问题
    if (savedHolidays.length > 10) {
      cacheService.clearCache();
      debugPrint("批量保存 ${savedHolidays.length} 个节日后清除缓存（数量超过阈值）");
    } else {
      // 逐个更新缓存
      for (var holiday in savedHolidays) {
        cacheService.updateCachedHoliday(holiday);
      }
      debugPrint("批量保存 ${savedHolidays.length} 个节日后更新缓存");
    }
  }

  /// 获取所有节日
  static List<HolidayModel> getAllHolidays() {
    // 检查缓存
    final cacheService = HolidayCacheService();
    final cachedHolidays = cacheService.getCachedAllHolidays();

    if (cachedHolidays != null) {
      debugPrint("从缓存中获取 ${cachedHolidays.length} 个节日记录");
      return cachedHolidays;
    }

    // 从数据库获取
    final holidays = _holidaysBox.values.toList();
    debugPrint("从数据库中获取 ${holidays.length} 个节日记录");

    // 更新缓存
    cacheService.cacheAllHolidays(holidays);
    cacheService.isCacheValid = true;

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
    // 检查缓存
    final cacheService = HolidayCacheService();
    final cachedHoliday = cacheService.getCachedHolidayById(id);

    if (cachedHoliday != null) {
      debugPrint("从缓存中获取节日: $id (${cachedHoliday.name})");
      return cachedHoliday;
    }

    // 从数据库获取
    final holiday = _holidaysBox.get(id);

    // 更新缓存
    if (holiday != null) {
      cacheService.cacheHolidayById(id, holiday);
      debugPrint("从数据库中获取节日: $id (${holiday.name})");
    }

    return holiday;
  }

  /// 根据地区获取节日
  static List<HolidayModel> getHolidaysByRegion(String region, {bool isChineseLocale = false}) {
    // 检查缓存
    final cacheService = HolidayCacheService();
    final cachedHolidays = cacheService.getCachedHolidaysByRegion(region);

    if (cachedHolidays != null) {
      debugPrint("从缓存中获取 ${cachedHolidays.length} 个 $region 地区的节日");
      return cachedHolidays;
    }

    // 获取所有节日
    final allHolidays = getAllHolidays();

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

    // 更新缓存
    cacheService.cacheHolidaysByRegion(region, result);
    cacheService.isCacheValid = true;

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
      // 创建一个带有更新重要性和最后修改时间的副本
      final updatedHoliday = HolidayModel(
        id: holiday.id,
        name: holiday.name,
        type: holiday.type,
        regions: holiday.regions,
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
        userImportance: importance, // 更新重要性
        nameEn: holiday.nameEn,
        descriptionEn: holiday.descriptionEn,
        lastModified: DateTime.now(), // 更新最后修改时间
      );

      await _holidaysBox.put(updatedHoliday.id, updatedHoliday);

      // 更新缓存
      final cacheService = HolidayCacheService();
      cacheService.updateCachedHolidayImportance(holidayId, importance);
      cacheService.updateCachedHoliday(updatedHoliday); // 同时更新节日缓存
      debugPrint("更新节日重要性: ${holiday.id} (${holiday.name}) -> $importance");
    }
  }

  /// 获取节日重要性
  static Map<String, int> getHolidayImportance() {
    // 检查缓存
    final cacheService = HolidayCacheService();
    final cachedImportance = cacheService.getCachedHolidayImportance();

    if (cachedImportance != null) {
      debugPrint("从缓存中获取 ${cachedImportance.length} 个节日重要性设置");
      return cachedImportance;
    }

    // 从数据库获取
    final Map<String, int> result = {};
    for (var holiday in _holidaysBox.values) {
      if (holiday.userImportance > 0) {
        result[holiday.id] = holiday.userImportance;
      }
    }

    // 更新缓存
    cacheService.cacheHolidayImportance(result);
    cacheService.isCacheValid = true;

    debugPrint("从数据库中获取 ${result.length} 个节日重要性设置");
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

  /// 删除指定ID的节日
  static Future<void> deleteHoliday(String id) async {
    if (_holidaysBox.containsKey(id)) {
      await _holidaysBox.delete(id);

      // 只清除该节日的缓存，而不是清除所有缓存
      final cacheService = HolidayCacheService();
      cacheService.invalidateHolidayCache(id);

      debugPrint('节日已删除: $id');
    } else {
      debugPrint('节日不存在，无法删除: $id');
    }
  }
}
