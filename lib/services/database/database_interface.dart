import 'package:jinlin_app/models/unified/holiday.dart';

/// 数据库接口
///
/// 定义所有数据库操作的抽象接口，不同平台可以提供不同的实现
abstract class DatabaseInterface {
  /// 初始化数据库
  Future<void> initialize();

  /// 关闭数据库
  Future<void> close();

  /// 清空数据库
  Future<void> clearAll();

  // 节日相关操作

  /// 保存节日
  Future<void> saveHoliday(Holiday holiday);

  /// 批量保存节日
  Future<void> saveHolidays(List<Holiday> holidays);

  /// 获取所有节日
  Future<List<Holiday>> getAllHolidays();

  /// 根据ID获取节日
  Future<Holiday?> getHolidayById(String id);

  /// 根据地区获取节日
  Future<List<Holiday>> getHolidaysByRegion(String region, {String languageCode = 'en'});

  /// 删除节日
  Future<void> deleteHoliday(String id);

  /// 更新节日重要性
  Future<void> updateHolidayImportance(String id, int importance);

  /// 检查数据库是否已初始化
  Future<bool> isInitialized();

  /// 检查是否是首次启动
  Future<bool> isFirstLaunch();

  /// 标记首次启动完成
  Future<void> markFirstLaunchComplete();

  /// 获取数据版本
  Future<int> getDataVersion();

  /// 更新数据版本
  Future<void> updateDataVersion(int version);
}
