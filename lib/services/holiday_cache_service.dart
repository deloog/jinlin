// 文件： lib/services/holiday_cache_service.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/special_date.dart' hide DateCalculationType, ImportanceLevel;

/// 节日缓存服务
///
/// 用于缓存节日数据，减少数据库访问次数
/// 实现智能缓存策略，支持增量更新
class HolidayCacheService {
  // 单例模式
  static final HolidayCacheService _instance = HolidayCacheService._internal();

  factory HolidayCacheService() {
    return _instance;
  }

  HolidayCacheService._internal();

  // 缓存数据
  final Map<String, List<HolidayModel>> _regionHolidaysCache = {};
  final Map<String, HolidayModel> _holidayByIdCache = {};
  final Map<String, int> _holidayImportanceCache = {};
  List<HolidayModel>? _allHolidaysCache;

  // 缓存最后更新时间
  DateTime? _lastCacheUpdateTime;

  // 缓存过期时间（默认10分钟）
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // 缓存是否有效
  bool _isCacheValid = false;

  /// 清除所有缓存
  void clearCache() {
    _regionHolidaysCache.clear();
    _holidayByIdCache.clear();
    _holidayImportanceCache.clear();
    _allHolidaysCache = null;
    _isCacheValid = false;
    _lastCacheUpdateTime = null;
    debugPrint('节日缓存已清除');
  }

  /// 清除特定节日的缓存
  void invalidateHolidayCache(String holidayId) {
    // 从ID缓存中移除
    _holidayByIdCache.remove(holidayId);

    // 从所有节日缓存中移除
    if (_allHolidaysCache != null) {
      _allHolidaysCache = _allHolidaysCache!.where((h) => h.id != holidayId).toList();
    }

    // 从地区缓存中移除
    for (final region in _regionHolidaysCache.keys) {
      final holidays = _regionHolidaysCache[region];
      if (holidays != null) {
        _regionHolidaysCache[region] = holidays.where((h) => h.id != holidayId).toList();
      }
    }

    debugPrint('节日 $holidayId 的缓存已失效');
  }

  /// 检查缓存是否过期
  bool isCacheExpired() {
    if (_lastCacheUpdateTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastCacheUpdateTime!) > _cacheExpiration;
  }

  /// 缓存是否有效
  bool get isCacheValid {
    // 如果缓存标记为无效或已过期，则返回false
    if (!_isCacheValid || isCacheExpired()) return false;
    return true;
  }

  /// 设置缓存有效性
  set isCacheValid(bool value) {
    _isCacheValid = value;
    if (value) {
      _lastCacheUpdateTime = DateTime.now();
    } else {
      _lastCacheUpdateTime = null;
    }
  }

  /// 缓存按地区分组的节日
  void cacheHolidaysByRegion(String region, List<HolidayModel> holidays) {
    _regionHolidaysCache[region] = List.from(holidays);

    // 同时更新按ID缓存
    for (final holiday in holidays) {
      _holidayByIdCache[holiday.id] = holiday;
    }

    // 更新缓存时间
    _lastCacheUpdateTime = DateTime.now();
    _isCacheValid = true;

    debugPrint('缓存了 ${holidays.length} 个 $region 地区的节日');
  }

  /// 获取缓存的按地区分组的节日
  List<HolidayModel>? getCachedHolidaysByRegion(String region) {
    if (!isCacheValid) return null;
    return _regionHolidaysCache[region];
  }

  /// 缓存节日
  void cacheHolidayById(String id, HolidayModel holiday) {
    _holidayByIdCache[id] = holiday;

    // 更新所有节日缓存（如果存在）
    if (_allHolidaysCache != null) {
      // 移除旧的节日（如果存在）
      _allHolidaysCache = _allHolidaysCache!.where((h) => h.id != id).toList();
      // 添加新的节日
      _allHolidaysCache!.add(holiday);
    }

    // 更新地区缓存
    for (final region in holiday.regions) {
      if (_regionHolidaysCache.containsKey(region)) {
        // 移除旧的节日（如果存在）
        _regionHolidaysCache[region] = _regionHolidaysCache[region]!.where((h) => h.id != id).toList();
        // 添加新的节日
        _regionHolidaysCache[region]!.add(holiday);
      }
    }

    // 更新缓存时间
    _lastCacheUpdateTime = DateTime.now();
    _isCacheValid = true;
  }

  /// 获取缓存的节日
  HolidayModel? getCachedHolidayById(String id) {
    if (!isCacheValid) return null;
    return _holidayByIdCache[id];
  }

  /// 缓存所有节日
  void cacheAllHolidays(List<HolidayModel> holidays) {
    _allHolidaysCache = List.from(holidays);

    // 同时更新按ID缓存
    for (final holiday in holidays) {
      _holidayByIdCache[holiday.id] = holiday;
    }

    // 更新缓存时间
    _lastCacheUpdateTime = DateTime.now();
    _isCacheValid = true;

    debugPrint('缓存了 ${holidays.length} 个节日');
  }

  /// 获取缓存的所有节日
  List<HolidayModel>? getCachedAllHolidays() {
    if (!isCacheValid) return null;
    return _allHolidaysCache;
  }

  /// 缓存节日重要性
  void cacheHolidayImportance(Map<String, int> importance) {
    _holidayImportanceCache.clear();
    _holidayImportanceCache.addAll(importance);

    // 更新缓存时间
    _lastCacheUpdateTime = DateTime.now();
    _isCacheValid = true;

    debugPrint('缓存了 ${importance.length} 个节日重要性设置');
  }

  /// 获取缓存的节日重要性
  Map<String, int>? getCachedHolidayImportance() {
    if (!isCacheValid) return null;
    return Map.from(_holidayImportanceCache);
  }

  /// 更新缓存的节日重要性
  void updateCachedHolidayImportance(String holidayId, int importance) {
    if (isCacheValid) {
      _holidayImportanceCache[holidayId] = importance;

      // 更新缓存时间
      _lastCacheUpdateTime = DateTime.now();

      debugPrint('更新了缓存中 $holidayId 的重要性为 $importance');
    }
  }

  /// 更新缓存中的节日
  void updateCachedHoliday(HolidayModel holiday) {
    if (!isCacheValid) {
      // 如果缓存无效，则只更新ID缓存
      _holidayByIdCache[holiday.id] = holiday;
      return;
    }

    // 更新ID缓存
    _holidayByIdCache[holiday.id] = holiday;

    // 更新所有节日缓存
    if (_allHolidaysCache != null) {
      // 移除旧的节日
      _allHolidaysCache = _allHolidaysCache!.where((h) => h.id != holiday.id).toList();
      // 添加新的节日
      _allHolidaysCache!.add(holiday);
    }

    // 更新地区缓存
    for (final region in _regionHolidaysCache.keys) {
      final holidays = _regionHolidaysCache[region];
      if (holidays != null) {
        // 检查这个节日是否属于该地区
        if (holiday.regions.contains(region)) {
          // 移除旧的节日
          _regionHolidaysCache[region] = holidays.where((h) => h.id != holiday.id).toList();
          // 添加新的节日
          _regionHolidaysCache[region]!.add(holiday);
        } else {
          // 如果节日不属于该地区，但缓存中有，则移除
          _regionHolidaysCache[region] = holidays.where((h) => h.id != holiday.id).toList();
        }
      }
    }

    // 更新缓存时间
    _lastCacheUpdateTime = DateTime.now();

    debugPrint('更新了缓存中的节日: ${holiday.id} (${holiday.name})');
  }

  /// 将HolidayModel转换为SpecialDate
  SpecialDate convertToSpecialDate(HolidayModel model, bool isChineseLocale) {
    // 根据语言环境选择正确的名称和描述
    final name = isChineseLocale || model.nameEn == null || model.nameEn!.isEmpty
        ? model.name
        : model.nameEn!;

    final description = isChineseLocale || model.descriptionEn == null || model.descriptionEn!.isEmpty
        ? model.description
        : model.descriptionEn;

    // 创建SpecialDate对象
    return SpecialDate(
      id: model.id,
      name: name,
      nameEn: model.nameEn,
      type: _convertToSpecialDateType(model.type),
      regions: model.regions,
      calculationType: _convertToSpecialDateCalculationType(model.calculationType),
      calculationRule: model.calculationRule,
      description: description,
      descriptionEn: model.descriptionEn,
      importanceLevel: _convertToSpecialImportanceLevel(model.importanceLevel),
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
  List<SpecialDate> convertToSpecialDates(List<HolidayModel> models, bool isChineseLocale) {
    return models.map((model) => convertToSpecialDate(model, isChineseLocale)).toList();
  }

  // 类型转换辅助方法
  SpecialDateType _convertToSpecialDateType(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return SpecialDateType.statutory;
      case HolidayType.traditional:
        return SpecialDateType.traditional;
      case HolidayType.solarTerm:
        return SpecialDateType.solarTerm;
      case HolidayType.memorial:
        return SpecialDateType.memorial;
      case HolidayType.custom:
        return SpecialDateType.custom;
      case HolidayType.other:
        return SpecialDateType.other;
      case HolidayType.religious:
      case HolidayType.international:
      case HolidayType.professional:
      case HolidayType.cultural:
        return SpecialDateType.other; // 映射到其他类型
    }
  }

  dynamic _convertToSpecialDateCalculationType(dynamic type) {
    // 将HolidayModel中的DateCalculationType转换为SpecialDate中的DateCalculationType
    // 由于我们使用了hide导入，这里需要手动映射
    final String typeStr = type.toString().split('.').last;
    return SpecialDate.getCalculationTypeFromString(typeStr);
  }

  dynamic _convertToSpecialImportanceLevel(dynamic level) {
    // 将HolidayModel中的ImportanceLevel转换为SpecialDate中的ImportanceLevel
    // 由于我们使用了hide导入，这里需要手动映射
    final String levelStr = level.toString().split('.').last;
    return SpecialDate.getImportanceLevelFromString(levelStr);
  }
}
