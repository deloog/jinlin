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
    return _holidaysBox.values.toList();
  }

  /// 根据ID获取节日
  static HolidayModel? getHolidayById(String id) {
    return _holidaysBox.get(id);
  }

  /// 根据地区获取节日
  static List<HolidayModel> getHolidaysByRegion(String region) {
    // 获取所有节日
    final allHolidays = _holidaysBox.values.toList();

    // 创建一个集合，用于存储已处理的节日名称
    final Set<String> processedHolidayNames = {};

    // 创建结果列表
    final List<HolidayModel> result = [];

    // 首先添加当前地区的节日
    for (var holiday in allHolidays) {
      if (holiday.regions.contains(region)) {
        // 如果节日名称尚未处理，则添加到结果列表
        if (!processedHolidayNames.contains(holiday.name)) {
          result.add(holiday);
          processedHolidayNames.add(holiday.name);
        }
      }
    }

    // 然后添加国际节日
    for (var holiday in allHolidays) {
      if (holiday.regions.contains('INTL') || holiday.regions.contains('ALL')) {
        // 如果节日名称尚未处理，则添加到结果列表
        if (!processedHolidayNames.contains(holiday.name)) {
          result.add(holiday);
          processedHolidayNames.add(holiday.name);
        }
      }
    }

    return result;
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
}
