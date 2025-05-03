import 'package:flutter/foundation.dart';
import 'package:jinlin_app/services/api_service_provider.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/utils/event_bus.dart';

/// 节日数据同步事件
class HolidaySyncEvent {
  final String regionCode;
  final bool success;
  final int itemCount;

  HolidaySyncEvent(this.regionCode, this.success, this.itemCount);
}

/// 节日数据同步服务
///
/// 负责在客户端和服务器之间同步节日数据
class HolidayDataSyncService {
  final DatabaseManagerUnified _dbManager;
  final ApiServiceProvider _apiServiceProvider;

  // 标记是否正在同步，防止重复同步
  bool _isSyncing = false;

  // 同步状态
  String _syncStatus = '空闲';

  // 上次同步时间
  DateTime? _lastSyncTime;

  /// 获取同步状态
  String get syncStatus => _syncStatus;

  /// 获取上次同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  HolidayDataSyncService(this._dbManager, this._apiServiceProvider);

  /// 同步特定地区和语言的节日数据
  Future<bool> syncHolidayData(String regionCode, String languageCode) async {
    // 防止重复同步
    if (_isSyncing) {
      debugPrint('HolidayDataSyncService: 已有同步任务正在进行，跳过');
      _syncStatus = '已有同步任务正在进行';
      return false;
    }

    _isSyncing = true;
    _syncStatus = '正在同步 $regionCode 地区数据...';

    try {
      debugPrint('HolidayDataSyncService: 开始同步 $regionCode 地区的节日数据...');

      // 获取API服务
      final apiService = _apiServiceProvider.getApiService();

      // 1. 获取本地数据版本
      final localVersion = await _dbManager.getDataVersion(regionCode);
      debugPrint('HolidayDataSyncService: 本地数据版本: $localVersion');

      // 2. 检查服务器数据版本
      final serverVersions = await apiService.getVersions([regionCode]);
      final serverVersion = serverVersions[regionCode] ?? 0;
      debugPrint('HolidayDataSyncService: 服务器数据版本: $serverVersion');

      // 3. 如果服务器版本更新，则获取更新
      if (serverVersion > localVersion) {
        debugPrint('HolidayDataSyncService: 发现新版本，开始获取更新...');
        _syncStatus = '正在获取 $regionCode 地区数据更新...';

        // 获取增量更新
        final updates = await apiService.getHolidayUpdates(
          regionCode,
          localVersion,
          languageCode
        );

        final totalChanges = updates.added.length + updates.updated.length + updates.deleted.length;
        debugPrint('HolidayDataSyncService: 获取到 ${updates.added.length} 个新增节日，${updates.updated.length} 个更新节日，${updates.deleted.length} 个删除节日');

        // 应用更新到本地数据库
        if (updates.added.isNotEmpty) {
          _syncStatus = '正在保存 ${updates.added.length} 个新增节日...';
          await _dbManager.saveHolidays(updates.added);
          debugPrint('HolidayDataSyncService: 保存新增节日完成');
        }

        if (updates.updated.isNotEmpty) {
          _syncStatus = '正在更新 ${updates.updated.length} 个节日...';
          await _dbManager.updateHolidays(updates.updated);
          debugPrint('HolidayDataSyncService: 更新节日完成');
        }

        if (updates.deleted.isNotEmpty) {
          _syncStatus = '正在删除 ${updates.deleted.length} 个节日...';
          await _dbManager.deleteHolidays(updates.deleted);
          debugPrint('HolidayDataSyncService: 删除节日完成');
        }

        // 更新本地版本号
        await _dbManager.updateDataVersion(regionCode, updates.newVersion);
        debugPrint('HolidayDataSyncService: 更新本地数据版本为 ${updates.newVersion}');

        _lastSyncTime = DateTime.now();
        _syncStatus = '同步完成，共更新 $totalChanges 个节日';

        // 发送同步事件
        EventBus.instance.fire(HolidaySyncEvent(regionCode, true, totalChanges));

        return true;
      } else {
        debugPrint('HolidayDataSyncService: 本地数据已是最新版本，无需更新');
        _lastSyncTime = DateTime.now();
        _syncStatus = '数据已是最新版本';

        // 发送同步事件
        EventBus.instance.fire(HolidaySyncEvent(regionCode, true, 0));

        return true;
      }
    } catch (e, stack) {
      debugPrint('HolidayDataSyncService: 同步节日数据失败: $e');
      debugPrint('HolidayDataSyncService: 堆栈: $stack');
      _syncStatus = '同步失败: $e';

      // 发送同步事件
      EventBus.instance.fire(HolidaySyncEvent(regionCode, false, 0));

      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// 初始加载特定地区和语言的节日数据
  Future<bool> initialLoadHolidayData(String regionCode, String languageCode) async {
    try {
      debugPrint('HolidayDataSyncService: 开始初始加载 $regionCode 地区的节日数据...');
      _syncStatus = '正在初始加载 $regionCode 地区数据...';

      // 检查是否已加载
      final isLoaded = await _dbManager.isRegionDataLoaded(regionCode);
      if (isLoaded) {
        debugPrint('HolidayDataSyncService: $regionCode 地区数据已加载，跳过初始加载');
        _syncStatus = '$regionCode 地区数据已加载';
        return true;
      }

      // 获取API服务
      final apiService = _apiServiceProvider.getApiService();

      // 从服务器获取完整数据
      final response = await apiService.getHolidays(regionCode, languageCode);
      debugPrint('HolidayDataSyncService: 从服务器获取到 ${response.holidays.length} 个节日');

      // 保存到本地数据库
      _syncStatus = '正在保存 ${response.holidays.length} 个节日...';
      await _dbManager.saveHolidays(response.holidays);
      debugPrint('HolidayDataSyncService: 保存节日数据完成');

      // 保存版本信息
      await _dbManager.updateDataVersion(regionCode, response.version);
      debugPrint('HolidayDataSyncService: 保存版本信息完成: ${response.version}');

      // 标记该地区数据已加载
      await _dbManager.markRegionDataLoaded(regionCode);
      debugPrint('HolidayDataSyncService: 标记 $regionCode 地区数据已加载');

      _lastSyncTime = DateTime.now();
      _syncStatus = '初始加载完成，共加载 ${response.holidays.length} 个节日';

      // 发送同步事件
      EventBus.instance.fire(HolidaySyncEvent(regionCode, true, response.holidays.length));

      return true;
    } catch (e, stack) {
      debugPrint('HolidayDataSyncService: 初始加载节日数据失败: $e');
      debugPrint('HolidayDataSyncService: 堆栈: $stack');
      _syncStatus = '初始加载失败: $e';

      // 发送同步事件
      EventBus.instance.fire(HolidaySyncEvent(regionCode, false, 0));

      return false;
    }
  }

  /// 检查服务器连接
  Future<bool> checkServerConnection() async {
    try {
      return await _apiServiceProvider.checkServerConnection();
    } catch (e) {
      debugPrint('HolidayDataSyncService: 检查服务器连接失败: $e');
      return false;
    }
  }
}
