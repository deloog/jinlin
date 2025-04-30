import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';

/// 增强版节日缓存服务
///
/// 提供节日数据的缓存功能，减少数据库访问，提高性能
class HolidayCacheServiceEnhanced {
  // 私有构造函数
  HolidayCacheServiceEnhanced._();

  // 节日缓存
  static final Map<String, HolidayModelExtended> _holidayCache = {};

  // 按地区缓存的节日
  static final Map<String, List<HolidayModelExtended>> _regionHolidayCache = {};

  // 所有节日缓存
  static List<HolidayModelExtended>? _allHolidaysCache;

  // 缓存过期时间（毫秒）
  static const int _cacheExpirationTime = 3600000; // 1小时

  // 最后更新时间
  static DateTime? _lastUpdateTime;

  /// 缓存节日
  static void cacheHoliday(HolidayModelExtended holiday) {
    _holidayCache[holiday.id] = holiday;
    _updateLastUpdateTime();
  }

  /// 缓存多个节日
  static void cacheHolidays(List<HolidayModelExtended> holidays) {
    for (final holiday in holidays) {
      _holidayCache[holiday.id] = holiday;
    }
    _updateLastUpdateTime();
    debugPrint('缓存了 ${holidays.length} 个节日');
  }

  /// 缓存按地区的节日
  static void cacheHolidaysByRegion(String region, List<HolidayModelExtended> holidays) {
    _regionHolidayCache[region] = holidays;
    _updateLastUpdateTime();
  }

  /// 从缓存中获取节日
  static HolidayModelExtended? getHolidayFromCache(String id) {
    if (_isCacheExpired()) {
      _clearCache();
      return null;
    }
    return _holidayCache[id];
  }

  /// 从缓存中获取所有节日
  static List<HolidayModelExtended> getAllHolidaysFromCache() {
    if (_isCacheExpired() || _allHolidaysCache == null) {
      return [];
    }
    return _allHolidaysCache!;
  }

  /// 从缓存中获取按地区的节日
  static List<HolidayModelExtended> getHolidaysByRegionFromCache(String region) {
    if (_isCacheExpired()) {
      _clearCache();
      return [];
    }
    return _regionHolidayCache[region] ?? [];
  }

  /// 更新缓存中的节日
  static void updateHolidayInCache(HolidayModelExtended holiday) {
    _holidayCache[holiday.id] = holiday;
    
    // 更新地区缓存
    for (final entry in _regionHolidayCache.entries) {
      final regionHolidays = entry.value;
      final index = regionHolidays.indexWhere((h) => h.id == holiday.id);
      if (index != -1) {
        regionHolidays[index] = holiday;
      }
    }
    
    // 更新所有节日缓存
    if (_allHolidaysCache != null) {
      final index = _allHolidaysCache!.indexWhere((h) => h.id == holiday.id);
      if (index != -1) {
        _allHolidaysCache![index] = holiday;
      }
    }
    
    _updateLastUpdateTime();
    debugPrint('保存节日后更新缓存: ${holiday.id} (${holiday.name})');
  }

  /// 批量更新缓存中的节日
  static void updateHolidaysInCache(List<HolidayModelExtended> holidays) {
    for (final holiday in holidays) {
      _holidayCache[holiday.id] = holiday;
    }
    
    // 更新地区缓存
    for (final entry in _regionHolidayCache.entries) {
      final regionHolidays = entry.value;
      for (final holiday in holidays) {
        final index = regionHolidays.indexWhere((h) => h.id == holiday.id);
        if (index != -1) {
          regionHolidays[index] = holiday;
        }
      }
    }
    
    // 更新所有节日缓存
    if (_allHolidaysCache != null) {
      for (final holiday in holidays) {
        final index = _allHolidaysCache!.indexWhere((h) => h.id == holiday.id);
        if (index != -1) {
          _allHolidaysCache![index] = holiday;
        }
      }
    }
    
    _updateLastUpdateTime();
    debugPrint('批量更新 ${holidays.length} 个节日的缓存');
  }

  /// 从缓存中移除节日
  static void removeHolidayFromCache(String holidayId) {
    _holidayCache.remove(holidayId);
    
    // 更新地区缓存
    for (final entry in _regionHolidayCache.entries) {
      final regionHolidays = entry.value;
      regionHolidays.removeWhere((h) => h.id == holidayId);
    }
    
    // 更新所有节日缓存
    if (_allHolidaysCache != null) {
      _allHolidaysCache!.removeWhere((h) => h.id == holidayId);
    }
    
    _updateLastUpdateTime();
    debugPrint('从缓存中移除节日: $holidayId');
  }

  /// 清除缓存
  static void clearCache() {
    _clearCache();
    debugPrint('清除节日缓存');
  }

  /// 私有方法：清除缓存
  static void _clearCache() {
    _holidayCache.clear();
    _regionHolidayCache.clear();
    _allHolidaysCache = null;
    _lastUpdateTime = null;
  }

  /// 私有方法：更新最后更新时间
  static void _updateLastUpdateTime() {
    _lastUpdateTime = DateTime.now();
  }

  /// 私有方法：检查缓存是否过期
  static bool _isCacheExpired() {
    if (_lastUpdateTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdateTime!).inMilliseconds;
    return difference > _cacheExpirationTime;
  }
}
