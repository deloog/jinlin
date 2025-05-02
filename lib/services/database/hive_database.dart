import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';

/// Hive数据库实现
class HiveDatabase implements DatabaseInterface {
  static final HiveDatabase _instance = HiveDatabase._internal();

  factory HiveDatabase() {
    return _instance;
  }

  HiveDatabase._internal();

  // 数据库是否已初始化
  bool _initialized = false;

  // 盒子名称
  static const String _holidaysBoxName = 'holidays_unified';
  static const String _prefsBoxName = 'preferences_unified';

  // 盒子
  Box<Map>? _holidaysBox;
  Box<String>? _prefsBox;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化Hive
      await Hive.initFlutter();

      // 打开盒子
      _holidaysBox = await Hive.openBox<Map>(_holidaysBoxName);
      _prefsBox = await Hive.openBox<String>(_prefsBoxName);

      // 如果偏好设置盒子为空，初始化默认设置
      if (_prefsBox!.isEmpty) {
        await _prefsBox!.put('is_first_launch', '1');
        await _prefsBox!.put('data_version', '1');
      }

      _initialized = true;
      debugPrint('Hive数据库初始化成功');
    } catch (e) {
      debugPrint('Hive数据库初始化失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_holidaysBox != null) {
      await _holidaysBox!.close();
    }
    if (_prefsBox != null) {
      await _prefsBox!.close();
    }
    _initialized = false;
  }

  @override
  Future<void> clearAll() async {
    await _checkInitialized();

    // 清空节日盒子
    await _holidaysBox!.clear();

    debugPrint('数据库已清空');
  }

  // 检查数据库是否已初始化
  Future<void> _checkInitialized() async {
    if (!_initialized) {
      throw Exception('数据库未初始化');
    }
  }

  @override
  Future<void> saveHoliday(Holiday holiday) async {
    await _checkInitialized();

    try {
      // 将Holiday对象转换为Map
      final Map<String, dynamic> holidayMap = holiday.toMap();

      // 保存到数据库
      await _holidaysBox!.put(holiday.id, holidayMap);

      debugPrint('保存节日: ${holiday.id}');
    } catch (e) {
      debugPrint('保存节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveHolidays(List<Holiday> holidays) async {
    await _checkInitialized();

    try {
      // 创建一个Map，用于批量保存
      final Map<String, Map<String, dynamic>> holidaysMap = {};

      // 将每个Holiday对象转换为Map并添加到holidaysMap
      for (final holiday in holidays) {
        holidaysMap[holiday.id] = holiday.toMap();
      }

      // 批量保存到数据库
      await _holidaysBox!.putAll(holidaysMap);

      debugPrint('批量保存 ${holidays.length} 个节日');
    } catch (e) {
      debugPrint('批量保存节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Holiday>> getAllHolidays() async {
    await _checkInitialized();

    try {
      // 获取所有节日
      final List<Holiday> holidays = [];

      // 遍历所有节日Map，转换为Holiday对象
      for (final key in _holidaysBox!.keys) {
        final Map<dynamic, dynamic>? holidayMap = _holidaysBox!.get(key);
        if (holidayMap != null) {
          // 将Map<dynamic, dynamic>转换为Map<String, dynamic>
          final Map<String, dynamic> stringMap = {};
          holidayMap.forEach((key, value) {
            stringMap[key.toString()] = value;
          });

          // 创建Holiday对象
          final holiday = Holiday.fromMap(stringMap);
          holidays.add(holiday);
        }
      }

      return holidays;
    } catch (e) {
      debugPrint('获取所有节日失败: $e');
      return [];
    }
  }

  @override
  Future<Holiday?> getHolidayById(String id) async {
    await _checkInitialized();

    try {
      // 获取节日Map
      final Map<dynamic, dynamic>? holidayMap = _holidaysBox!.get(id);

      if (holidayMap == null) {
        return null;
      }

      // 将Map<dynamic, dynamic>转换为Map<String, dynamic>
      final Map<String, dynamic> stringMap = {};
      holidayMap.forEach((key, value) {
        stringMap[key.toString()] = value;
      });

      // 创建Holiday对象
      return Holiday.fromMap(stringMap);
    } catch (e) {
      debugPrint('根据ID获取节日失败: $e');
      return null;
    }
  }

  @override
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    await _checkInitialized();

    try {
      // 获取所有节日
      final allHolidays = await getAllHolidays();

      // 筛选出指定地区的节日
      return allHolidays.where((holiday) {
        return holiday.regions.contains(region) || holiday.regions.contains('ALL');
      }).toList();
    } catch (e) {
      debugPrint('根据地区获取节日失败: $e');
      return [];
    }
  }

  @override
  Future<void> deleteHoliday(String id) async {
    await _checkInitialized();

    try {
      // 删除节日
      await _holidaysBox!.delete(id);

      debugPrint('删除节日: $id');
    } catch (e) {
      debugPrint('删除节日失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _checkInitialized();

    try {
      // 获取节日
      final holiday = await getHolidayById(id);
      if (holiday == null) {
        debugPrint('节日不存在，无法更新重要性: $id');
        return;
      }

      // 创建一个新的Holiday对象，包含更新后的重要性
      final updatedHoliday = Holiday(
        id: holiday.id,
        isSystemHoliday: holiday.isSystemHoliday,
        names: holiday.names,
        type: holiday.type,
        regions: holiday.regions,
        calculationType: holiday.calculationType,
        calculationRule: holiday.calculationRule,
        descriptions: holiday.descriptions,
        importanceLevel: holiday.importanceLevel,
        customs: holiday.customs,
        taboos: holiday.taboos,
        foods: holiday.foods,
        greetings: holiday.greetings,
        activities: holiday.activities,
        history: holiday.history,
        imageUrl: holiday.imageUrl,
        userImportance: importance, // 更新重要性
        contactId: holiday.contactId,
        createdAt: holiday.createdAt,
        lastModified: DateTime.now(), // 更新最后修改时间
      );

      // 保存更新后的节日
      await saveHoliday(updatedHoliday);

      debugPrint('更新节日重要性: $id -> $importance');
    } catch (e) {
      debugPrint('更新节日重要性失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isInitialized() async {
    return _initialized;
  }

  @override
  Future<bool> isFirstLaunch() async {
    await _checkInitialized();

    try {
      // 获取首次启动标志
      final isFirstLaunch = _prefsBox!.get('is_first_launch');

      if (isFirstLaunch == null) {
        return true;
      }

      return isFirstLaunch == '1';
    } catch (e) {
      debugPrint('检查是否首次启动失败: $e');
      return true;
    }
  }

  @override
  Future<void> markFirstLaunchComplete() async {
    await _checkInitialized();

    try {
      // 标记首次启动完成
      await _prefsBox!.put('is_first_launch', '0');

      debugPrint('标记首次启动完成');
    } catch (e) {
      debugPrint('标记首次启动完成失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> getDataVersion() async {
    await _checkInitialized();

    try {
      // 获取数据版本
      final dataVersion = _prefsBox!.get('data_version');

      if (dataVersion == null) {
        return 1;
      }

      return int.parse(dataVersion);
    } catch (e) {
      debugPrint('获取数据版本失败: $e');
      return 1;
    }
  }

  @override
  Future<void> updateDataVersion(int version) async {
    await _checkInitialized();

    try {
      // 更新数据版本
      await _prefsBox!.put('data_version', version.toString());

      debugPrint('更新数据版本: $version');
    } catch (e) {
      debugPrint('更新数据版本失败: $e');
      rethrow;
    }
  }

  /// 获取应用设置
  @override
  Future<String?> getAppSetting(String key) async {
    await _checkInitialized();

    try {
      // 获取设置
      final value = _prefsBox!.get(key);
      return value?.toString();
    } catch (e) {
      debugPrint('获取应用设置失败: $e');
      return null;
    }
  }

  /// 设置应用设置
  @override
  Future<void> setAppSetting(String key, String value) async {
    await _checkInitialized();

    try {
      // 设置应用设置
      await _prefsBox!.put(key, value);
      debugPrint('设置应用设置成功: $key');
    } catch (e) {
      debugPrint('设置应用设置失败: $e');
      rethrow;
    }
  }
}
