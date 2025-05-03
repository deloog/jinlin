import 'package:jinlin_app/models/unified/holiday.dart';

/// 节日存储库接口
///
/// 定义节日存储库的方法
abstract class HolidayRepositoryInterface {
  /// 初始化节日存储库
  Future<void> initialize();
  
  /// 获取所有节日
  Future<List<Holiday>> getHolidays({
    String? languageCode,
    String? regionCode,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDeleted = false,
    bool forceRefresh = false,
  });
  
  /// 获取单个节日
  Future<Holiday?> getHoliday(String id, {bool forceRefresh = false});
  
  /// 保存节日
  Future<Holiday> saveHoliday(Holiday holiday);
  
  /// 批量保存节日
  Future<List<Holiday>> saveHolidays(List<Holiday> holidays);
  
  /// 删除节日
  Future<bool> deleteHoliday(String id, {bool hardDelete = false});
  
  /// 批量删除节日
  Future<bool> deleteHolidays(List<String> ids, {bool hardDelete = false});
  
  /// 获取节日数量
  Future<int> getHolidayCount();
  
  /// 获取已删除节日数量
  Future<int> getDeletedHolidayCount();
  
  /// 获取所有已删除的节日
  Future<List<Holiday>> getDeletedHolidays();
  
  /// 恢复已删除的节日
  Future<Holiday?> restoreHoliday(String id);
  
  /// 清空已删除的节日
  Future<void> purgeDeletedHolidays();
  
  /// 同步节日数据
  Future<void> syncHolidays();
  
  /// 获取节日更新
  Future<List<Holiday>> getHolidayUpdates(DateTime lastSyncTime);
  
  /// 导入节日数据
  Future<int> importHolidays(List<Holiday> holidays);
  
  /// 导出节日数据
  Future<List<Holiday>> exportHolidays();
  
  /// 获取节日统计信息
  Future<Map<String, dynamic>> getHolidayStats();
  
  /// 关闭节日存储库
  Future<void> close();
}
