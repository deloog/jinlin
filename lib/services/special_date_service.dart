// 文件: lib/services/special_date_service.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/holiday_storage_service.dart';

/// 特殊日期服务
/// 
/// 用于获取和管理特殊日期（节日、纪念日等）
class SpecialDateService {
  // 缓存
  static List<SpecialDate>? _cachedSpecialDates;
  
  /// 清除缓存
  /// 
  /// 强制下次获取特殊日期时从数据库重新加载
  static Future<void> clearCache() async {
    _cachedSpecialDates = null;
    debugPrint('节日缓存已清除');
  }
  
  /// 获取即将到来的特殊日期
  /// 
  /// [context] 上下文
  /// [daysRange] 天数范围，默认为10天
  /// [selectedTypes] 选中的特殊日期类型
  static Future<List<SpecialDate>> getUpcomingSpecialDates(
    BuildContext context,
    int daysRange,
    Set<SpecialDateType> selectedTypes,
  ) async {
    try {
      // 获取当前日期
      final now = DateTime.now();
      
      // 获取用户所在地区
      final String region;
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'zh') {
        region = 'CN'; // 中文环境
      } else if (locale.languageCode == 'ja') {
        region = 'JP'; // 日语环境
      } else if (locale.languageCode == 'ko') {
        region = 'KR'; // 韩语环境
      } else {
        region = 'INTL'; // 其他语言环境
      }
      
      // 检查数据库迁移是否完成
      final migrationComplete = HiveDatabaseService.isMigrationComplete();
      
      // 获取特殊日期列表
      List<SpecialDate> specialDates = [];
      
      // 如果有缓存，直接使用缓存
      if (_cachedSpecialDates != null) {
        specialDates = _cachedSpecialDates!;
        debugPrint('从缓存中获取 ${specialDates.length} 个节日');
      } else {
        // 如果数据库迁移已完成，从数据库获取节日
        if (migrationComplete) {
          // 获取当前语言环境
          final isChineseLocale = locale.languageCode == 'zh';
          
          // 获取用户所在地区的节日，并传递语言环境参数
          final holidayModels = HiveDatabaseService.getHolidaysByRegion(region, isChineseLocale: isChineseLocale);
          
          // 将HolidayModel转换为SpecialDate
          specialDates = _convertHolidayModelsToSpecialDates(holidayModels, context);
          debugPrint('从Hive数据库加载了 ${specialDates.length} 个节日 (语言环境: ${isChineseLocale ? '中文' : '非中文'})');
        } else {
          // 如果数据库迁移未完成，使用本地存储服务获取节日
          final holidayModels = HolidayStorageService.getHolidaysForRegion(context, region);
          specialDates = _convertHolidayModelsToSpecialDates(holidayModels, context);
          debugPrint('从本地存储服务加载了 ${specialDates.length} 个节日');
        }
        
        // 更新缓存
        _cachedSpecialDates = specialDates;
      }
      
      // 获取用户自定义的节日重要性
      Map<String, int> holidayImportance;
      
      // 如果数据库迁移已完成，从数据库获取节日重要性
      if (migrationComplete) {
        holidayImportance = HiveDatabaseService.getHolidayImportance();
      } else {
        // 如果数据库迁移未完成，使用本地存储服务获取节日重要性
        holidayImportance = await HolidayStorageService.getHolidayImportance();
      }
      
      // 过滤和处理特殊日期
      final List<SpecialDate> upcomingSpecialDates = [];
      
      for (var specialDate in specialDates) {
        // 检查类型是否匹配
        if (selectedTypes.contains(specialDate.type)) {
          // 获取下一个发生日期
          final occurrence = specialDate.getUpcomingOccurrence(now);
          
          if (occurrence != null) {
            // 计算与当前日期的天数差
            final daysDifference = occurrence.difference(now).inDays;
            
            // 获取当前节日的重要性
            int importance = 0;
            
            // 如果数据库迁移已完成，从数据库获取节日重要性
            if (migrationComplete) {
              final holidayModel = HiveDatabaseService.getHolidayById(specialDate.id);
              if (holidayModel != null) {
                importance = holidayModel.userImportance;
              }
            } else {
              // 如果数据库迁移未完成，使用本地存储服务获取节日重要性
              importance = holidayImportance[specialDate.id] ?? 0;
            }
            
            // 根据重要性和时间范围决定是否显示
            bool shouldShow = false;
            
            // 非常重要的节日始终显示
            if (importance == 2) {
              shouldShow = true;
            }
            // 重要的节日在较长时间范围内显示（2倍范围）
            else if (importance == 1) {
              shouldShow = daysDifference >= 0 && daysDifference <= daysRange * 2;
            }
            // 普通重要性的节日只在指定范围内显示
            else {
              shouldShow = daysDifference >= 0 && daysDifference <= daysRange;
            }
            
            // 如果应该显示，则添加到列表中
            if (shouldShow) {
              // 创建一个新的SpecialDate对象，并设置发生日期
              final specialDateWithOccurrence = SpecialDate(
                id: specialDate.id,
                name: specialDate.name,
                nameEn: specialDate.nameEn,
                type: specialDate.type,
                regions: specialDate.regions,
                calculationType: specialDate.calculationType,
                calculationRule: specialDate.calculationRule,
                description: specialDate.description,
                descriptionEn: specialDate.descriptionEn,
                importanceLevel: specialDate.importanceLevel,
                customs: specialDate.customs,
                taboos: specialDate.taboos,
                foods: specialDate.foods,
                greetings: specialDate.greetings,
                activities: specialDate.activities,
                history: specialDate.history,
                imageUrl: specialDate.imageUrl,
              );
              
              // 设置发生日期
              specialDateWithOccurrence.occurrenceDate = occurrence;
              
              upcomingSpecialDates.add(specialDateWithOccurrence);
            }
          }
        }
      }
      
      return upcomingSpecialDates;
    } catch (e) {
      debugPrint('获取即将到来的特殊日期失败: $e');
      return [];
    }
  }
  
  /// 将HolidayModel列表转换为SpecialDate列表
  static List<SpecialDate> _convertHolidayModelsToSpecialDates(List<dynamic> models, BuildContext context) {
    final List<SpecialDate> result = [];
    
    // 获取当前语言环境
    final isChineseLocale = Localizations.localeOf(context).languageCode == 'zh';
    
    for (final model in models) {
      try {
        // 根据语言环境选择正确的名称和描述
        final name = isChineseLocale || model.nameEn == null || model.nameEn.isEmpty
            ? model.name
            : model.nameEn;
        
        final description = isChineseLocale || model.descriptionEn == null || model.descriptionEn.isEmpty
            ? model.description
            : model.descriptionEn;
        
        // 创建SpecialDate对象
        final specialDate = SpecialDate(
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
        
        result.add(specialDate);
      } catch (e) {
        debugPrint('转换HolidayModel到SpecialDate失败: $e');
      }
    }
    
    return result;
  }
  
  /// 将HolidayType转换为SpecialDateType
  static SpecialDateType _convertToSpecialDateType(dynamic type) {
    switch (type.toString()) {
      case 'HolidayType.statutory':
        return SpecialDateType.statutory;
      case 'HolidayType.traditional':
        return SpecialDateType.traditional;
      case 'HolidayType.solarTerm':
        return SpecialDateType.solarTerm;
      case 'HolidayType.memorial':
        return SpecialDateType.memorial;
      case 'HolidayType.custom':
        return SpecialDateType.custom;
      default:
        return SpecialDateType.other;
    }
  }
  
  /// 将DateCalculationType转换为DateCalculationType
  static DateCalculationType _convertToSpecialDateCalculationType(dynamic type) {
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
  
  /// 将ImportanceLevel转换为ImportanceLevel
  static ImportanceLevel _convertToSpecialImportanceLevel(dynamic level) {
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
