import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/database/database_factory.dart';
import 'package:jinlin_app/services/holiday_data_loader_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:lunar/lunar.dart' hide Holiday; // 导入lunar包用于农历计算，但隐藏其Holiday类

/// 统一数据库管理服务
///
/// 作为应用程序与数据库之间的桥梁，提供所有必要的数据操作方法
class DatabaseManagerUnified {
  static final DatabaseManagerUnified _instance = DatabaseManagerUnified._internal();

  factory DatabaseManagerUnified() {
    return _instance;
  }

  DatabaseManagerUnified._internal();

  // 数据库服务
  final DatabaseInterface _db = kIsWeb
      ? DatabaseFactory.create(DatabaseType.hive)
      : DatabaseFactory.create(DatabaseType.sqlite);

  // 初始化状态
  bool _isInitialized = false;

  /// 获取数据库是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化数据库
  ///
  /// [skipHolidayLoading] 如果为 true，则跳过节日数据加载，避免无限循环
  Future<bool> initialize(BuildContext? context, {bool skipHolidayLoading = false}) async {
    if (_isInitialized) return true;

    try {
      // 初始化数据库
      await _db.initialize();

      // 初始化节日数据（如果不跳过）
      if (!skipHolidayLoading) {
        try {
          // 使用HolidayDataLoaderService加载基础节日数据
          final holidayDataLoader = HolidayDataLoaderService();
          await holidayDataLoader.initializeBasicData();
        } catch (e, stack) {
          // 节日数据初始化失败不应该阻止整个应用程序的启动
          debugPrint('节日数据初始化失败: $e');
          debugPrint('堆栈: $stack');
        }
      } else {
        debugPrint('跳过节日数据加载，避免无限循环');
      }

      _isInitialized = true;
      debugPrint('数据库管理服务初始化成功');
      return true;
    } catch (e, stack) {
      debugPrint('数据库管理服务初始化失败: $e');
      debugPrint('堆栈: $stack');
      return false;
    }
  }

  /// 获取所有节日
  Future<List<Holiday>> getAllHolidays() async {
    return await _db.getAllHolidays();
  }

  /// 根据ID获取节日
  Future<Holiday?> getHolidayById(String id) async {
    return await _db.getHolidayById(id);
  }

  /// 根据地区获取节日
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'}) async {
    return await _db.getHolidaysByRegion(region, languageCode: languageCode);
  }

  /// 保存节日
  Future<void> saveHoliday(Holiday holiday) async {
    await _db.saveHoliday(holiday);
  }

  /// 批量保存节日
  Future<void> saveHolidays(List<Holiday> holidays) async {
    // 确保类型一致性
    final List<Holiday> typedHolidays = List<Holiday>.from(holidays);
    await _db.saveHolidays(typedHolidays);
  }

  /// 删除节日
  Future<void> deleteHoliday(String id) async {
    await _db.deleteHoliday(id);
  }

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String id, int importance) async {
    await _db.updateHolidayImportance(id, importance);
  }

  /// 获取用户所在地区的节日
  Future<List<Holiday>> getUserRegionHolidays(BuildContext context) async {
    // 获取用户地区
    final userRegion = LocalizationService.getUserRegion(context);

    // 获取用户语言
    final languageCode = Localizations.localeOf(context).languageCode;

    // 获取该地区的节日
    return await getHolidaysByRegion(userRegion, languageCode: languageCode);
  }

  /// 获取即将到来的节日
  ///
  /// 优化版本：分批处理，减少内存使用
  Future<List<Holiday>> getUpcomingHolidays(BuildContext context, int days) async {
    try {
      // 当前日期
      final now = DateTime.now();

      // 计算截止日期
      final endDate = now.add(Duration(days: days));

      // 获取用户地区
      final userRegion = LocalizationService.getUserRegion(context);

      // 获取用户语言
      final languageCode = Localizations.localeOf(context).languageCode;

      // 分批获取节日数据，每批最多处理100个节日
      const batchSize = 100;
      int offset = 0;
      bool hasMore = true;

      final upcomingHolidays = <Holiday>[];

      while (hasMore) {
        // 获取一批节日数据
        final batch = await _getBatchHolidaysByRegion(userRegion, languageCode, offset, batchSize);

        // 如果没有更多数据，退出循环
        if (batch.isEmpty) {
          hasMore = false;
          continue;
        }

        debugPrint('处理第 ${offset ~/ batchSize + 1} 批节日数据，数量: ${batch.length}');

        // 处理这批节日数据
        for (final holiday in batch) {
          try {
            // 计算下一个发生日期
            final occurrenceDate = _calculateOccurrenceDate(holiday, now);

            // 如果在指定范围内，添加到结果列表
            if (occurrenceDate != null &&
                !occurrenceDate.isBefore(now) &&
                (occurrenceDate.isBefore(endDate) || occurrenceDate.isAtSameMomentAs(endDate))) {
              upcomingHolidays.add(holiday);
            }
          } catch (e) {
            debugPrint('计算节日日期失败 (${holiday.id}): $e');
          }
        }

        // 更新偏移量
        offset += batch.length;

        // 如果获取的数据少于批次大小，说明没有更多数据了
        if (batch.length < batchSize) {
          hasMore = false;
        }

        // 添加短暂延迟，让系统有时间进行垃圾回收
        await Future.delayed(const Duration(milliseconds: 50));
      }

      debugPrint('共找到 ${upcomingHolidays.length} 个即将到来的节日');

      // 按日期排序
      upcomingHolidays.sort((a, b) {
        final dateA = _calculateOccurrenceDate(a, now);
        final dateB = _calculateOccurrenceDate(b, now);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateA.compareTo(dateB);
      });

      return upcomingHolidays;
    } catch (e) {
      debugPrint('获取即将到来的节日失败: $e');
      return [];
    }
  }

  /// 分批获取指定地区的节日
  Future<List<Holiday>> _getBatchHolidaysByRegion(String region, String languageCode, int offset, int limit) async {
    try {
      // 使用数据库接口获取一批节日数据
      // 注意：这里假设数据库接口支持分页查询，如果不支持，需要修改数据库接口
      // 由于当前的接口不支持分页，我们先获取所有数据，然后在内存中分页
      // 这不是最优解，但是在不修改数据库接口的情况下的临时解决方案

      // 获取所有节日
      final allHolidays = await _db.getHolidaysByRegion(region, languageCode: languageCode);

      // 如果偏移量超出范围，返回空列表
      if (offset >= allHolidays.length) {
        return [];
      }

      // 计算结束位置
      final end = (offset + limit < allHolidays.length) ? offset + limit : allHolidays.length;

      // 返回指定范围的节日
      return allHolidays.sublist(offset, end);
    } catch (e) {
      debugPrint('分批获取节日失败: $e');
      return [];
    }
  }

  /// 计算第N个星期几的日期
  DateTime? _calculateNthWeekday(int year, int month, int weekNumber, int weekday) {
    // 获取该月第一天
    final firstDayOfMonth = DateTime(year, month, 1);

    // 计算该月第一个星期几的日期
    int daysUntilFirstWeekday = (weekday - firstDayOfMonth.weekday) % 7;
    if (daysUntilFirstWeekday < 0) daysUntilFirstWeekday += 7;

    final firstWeekdayDate = firstDayOfMonth.add(Duration(days: daysUntilFirstWeekday));

    // 计算第N个星期几的日期
    final nthWeekdayDate = firstWeekdayDate.add(Duration(days: (weekNumber - 1) * 7));

    // 检查是否在当月内
    if (nthWeekdayDate.month != month) return null;

    return nthWeekdayDate;
  }

  /// 计算节日的发生日期
  DateTime? _calculateOccurrenceDate(Holiday holiday, DateTime fromDate) {
    try {
      switch (holiday.calculationType) {
        case DateCalculationType.fixedGregorian:
          // 固定公历日期，格式：MM-DD
          final parts = holiday.calculationRule.split('-');
          if (parts.length == 2) {
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);

            // 计算今年的日期
            DateTime thisYearDate = DateTime(fromDate.year, month, day);

            // 如果今年的日期已过，则计算明年的日期
            if (thisYearDate.isBefore(fromDate)) {
              return DateTime(fromDate.year + 1, month, day);
            } else {
              return thisYearDate;
            }
          }
          break;

        case DateCalculationType.fixedLunar:
          // 固定农历日期，格式：MM-DDL
          final rule = holiday.calculationRule.replaceFirst('L', '');
          final parts = rule.split('-');
          if (parts.length == 2) {
            final lunarMonth = int.parse(parts[0]);
            final lunarDay = int.parse(parts[1]);

            // 使用lunar包计算今年的公历日期
            try {
              // 创建今年的农历日期
              final lunar = Lunar.fromYmd(fromDate.year, lunarMonth, lunarDay);

              // 转换为公历日期
              final solar = lunar.getSolar();
              DateTime thisYearDate = DateTime(
                solar.getYear(),
                solar.getMonth(),
                solar.getDay(),
              );

              // 如果今年的日期已过，则计算明年的日期
              if (thisYearDate.isBefore(fromDate)) {
                final nextLunar = Lunar.fromYmd(fromDate.year + 1, lunarMonth, lunarDay);
                final nextSolar = nextLunar.getSolar();
                return DateTime(
                  nextSolar.getYear(),
                  nextSolar.getMonth(),
                  nextSolar.getDay(),
                );
              } else {
                return thisYearDate;
              }
            } catch (e) {
              debugPrint('计算农历日期失败: $e');
            }
          }
          break;

        case DateCalculationType.variableRule:
          // 可变规则，格式：MM,N,W (第N个星期W)
          final parts = holiday.calculationRule.split(',');
          if (parts.length == 3) {
            final month = int.parse(parts[0]);
            final weekNumber = int.parse(parts[1]); // 第几个星期
            final weekday = int.parse(parts[2]); // 星期几 (1-7, 1=周一)

            // 计算今年的日期
            DateTime? thisYearDate = _calculateNthWeekday(fromDate.year, month, weekNumber, weekday);

            // 如果今年的日期已过或无效，则计算明年的日期
            if (thisYearDate == null || thisYearDate.isBefore(fromDate)) {
              return _calculateNthWeekday(fromDate.year + 1, month, weekNumber, weekday);
            } else {
              return thisYearDate;
            }
          }
          break;

        case DateCalculationType.custom:
          // 自定义规则，暂不支持
          debugPrint('不支持的计算类型: ${holiday.calculationType}');
          break;
      }
    } catch (e) {
      debugPrint('计算节日日期失败 (${holiday.id}): $e');
    }

    return null;
  }

  /// 检查是否是首次启动
  Future<bool> isFirstLaunch() async {
    try {
      final result = await _db.getAppSetting('first_launch');
      return result == null || result == '1';
    } catch (e) {
      debugPrint('检查首次启动失败: $e');
      return true;
    }
  }

  /// 标记首次启动完成
  Future<void> markFirstLaunchComplete() async {
    try {
      await _db.setAppSetting('first_launch', '0');
      debugPrint('标记首次启动完成');
    } catch (e) {
      debugPrint('标记首次启动完成失败: $e');
    }
  }

  /// 获取数据版本
  Future<int> getDataVersion([String? regionCode]) async {
    try {
      final key = regionCode != null ? 'data_version_$regionCode' : 'data_version';
      final result = await _db.getAppSetting(key);
      if (result == null) {
        return 0;
      }
      return int.tryParse(result) ?? 0;
    } catch (e) {
      debugPrint('获取数据版本失败: $e');
      return 0;
    }
  }

  /// 更新数据版本
  Future<void> updateDataVersion(String regionCode, int version) async {
    try {
      final key = 'data_version_$regionCode';
      await _db.setAppSetting(key, version.toString());
      debugPrint('更新 $regionCode 地区数据版本: $version');
    } catch (e) {
      debugPrint('更新数据版本失败: $e');
    }
  }

  /// 检查指定地区的节日数据是否已加载
  Future<bool> isRegionDataLoaded(String regionCode) async {
    try {
      final key = 'region_data_loaded_$regionCode';
      final result = await _db.getAppSetting(key);
      return result == '1';
    } catch (e) {
      debugPrint('检查地区数据是否已加载失败: $e');
      return false;
    }
  }

  /// 标记指定地区的节日数据已加载
  Future<void> markRegionDataLoaded(String regionCode) async {
    try {
      final key = 'region_data_loaded_$regionCode';
      await _db.setAppSetting(key, '1');
      debugPrint('标记 $regionCode 地区数据已加载');
    } catch (e) {
      debugPrint('标记地区数据已加载失败: $e');
    }
  }

  /// 更新节日数据
  Future<void> updateHolidays(List<Holiday> holidays) async {
    try {
      for (final holiday in holidays) {
        // 使用saveHolidays方法，因为它会覆盖现有数据
        await saveHolidays([holiday]);
      }
      debugPrint('更新 ${holidays.length} 个节日数据成功');
    } catch (e) {
      debugPrint('更新节日数据失败: $e');
      rethrow;
    }
  }

  /// 删除节日数据
  Future<void> deleteHolidays(List<String> holidayIds) async {
    try {
      for (final id in holidayIds) {
        // 使用现有的删除方法
        await _db.deleteHoliday(id);
      }
      debugPrint('删除 ${holidayIds.length} 个节日数据成功');
    } catch (e) {
      debugPrint('删除节日数据失败: $e');
      rethrow;
    }
  }

  /// 获取应用设置
  Future<String?> getAppSetting(String key) async {
    try {
      return await _db.getAppSetting(key);
    } catch (e) {
      debugPrint('获取应用设置失败: $e');
      return null;
    }
  }

  /// 设置应用设置
  Future<void> setAppSetting(String key, String value) async {
    try {
      await _db.setAppSetting(key, value);
      debugPrint('设置应用设置: $key = $value');
    } catch (e) {
      debugPrint('设置应用设置失败: $e');
    }
  }

  /// 关闭数据库连接
  Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
      debugPrint('数据库管理服务已关闭');
    }
  }
}
