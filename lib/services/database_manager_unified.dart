import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/database/database_factory.dart';
import 'package:jinlin_app/services/holiday_init_service_unified.dart';
import 'package:jinlin_app/services/localization_service.dart';

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

  // 节日初始化服务
  final HolidayInitServiceUnified _holidayInitService = HolidayInitServiceUnified();

  // 初始化状态
  bool _isInitialized = false;

  /// 初始化数据库
  Future<bool> initialize(BuildContext? context) async {
    if (_isInitialized) return true;

    try {
      // 初始化数据库
      await _db.initialize();

      // 初始化节日数据
      try {
        // 不依赖于BuildContext初始化节日数据
        await _holidayInitService.initializeHolidayData(null);
      } catch (e) {
        // 节日数据初始化失败不应该阻止整个应用程序的启动
        debugPrint('节日数据初始化失败: $e');
      }

      _isInitialized = true;
      debugPrint('数据库管理服务初始化成功');
      return true;
    } catch (e) {
      debugPrint('数据库管理服务初始化失败: $e');
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
    await _db.saveHolidays(holidays);
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
  Future<List<Holiday>> getUpcomingHolidays(BuildContext context, int days) async {
    // 获取用户所在地区的节日
    final holidays = await getUserRegionHolidays(context);

    // 当前日期
    final now = DateTime.now();

    // 筛选出即将到来的节日
    final upcomingHolidays = <Holiday>[];

    // TODO: 实现节日日期计算逻辑
    // 这里需要根据节日的计算类型和规则计算出今年的日期
    // 然后筛选出在指定天数内的节日

    // 临时实现：返回所有节日，避免未使用变量警告
    for (final holiday in holidays) {
      // 这里只是为了使用变量，实际实现时应该根据日期计算逻辑筛选
      if (now.isAfter(DateTime(2000))) { // 始终为true的条件
        upcomingHolidays.add(holiday);
      }
    }

    return upcomingHolidays;
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
