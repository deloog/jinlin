import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jinlin_app/providers/app_settings_provider.dart';
import 'package:jinlin_app/services/api/api_client.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 设置业务逻辑
///
/// 管理设置屏幕的数据和状态
class SettingsBloc extends ChangeNotifier {
  final AppSettingsProvider _appSettingsProvider;
  final ApiClient _apiClient;
  final HolidayRepository _holidayRepository;
  final ReminderRepository _reminderRepository;
  final LoggingService _logger;

  // 应用版本
  String _appVersion = '1.0.0';

  // 同步状态
  bool _isSyncing = false;

  // 上次同步时间
  DateTime? _lastSyncTime;

  /// 获取主题模式
  ThemeMode get themeMode => _appSettingsProvider.themeMode;

  /// 获取语言代码
  String get languageCode => _appSettingsProvider.languageCode;

  /// 获取服务器URL
  String get serverUrl => _apiClient.baseUrl;

  /// 获取是否使用模拟数据
  bool get useMockData => _appSettingsProvider.useMockData;

  /// 获取应用版本
  String get appVersion => _appVersion;

  /// 获取是否正在同步
  bool get isSyncing => _isSyncing;

  /// 获取上次同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  SettingsBloc({
    required AppSettingsProvider appSettingsProvider,
    required ApiClient apiClient,
    required HolidayRepository holidayRepository,
    required ReminderRepository reminderRepository,
    required LoggingService logger,
  }) :
    _appSettingsProvider = appSettingsProvider,
    _apiClient = apiClient,
    _holidayRepository = holidayRepository,
    _reminderRepository = reminderRepository,
    _logger = logger {
    _logger.debug('初始化SettingsBloc');

    // 获取应用版本
    _getAppVersion();

    // 获取上次同步时间
    _getLastSyncTime();
  }

  /// 获取应用版本
  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      notifyListeners();
    } catch (e, stack) {
      _logger.error('获取应用版本失败', e, stack);
    }
  }

  /// 获取上次同步时间
  Future<void> _getLastSyncTime() async {
    try {
      _lastSyncTime = _holidayRepository.lastSyncTime;
      notifyListeners();
    } catch (e, stack) {
      _logger.error('获取上次同步时间失败', e, stack);
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _appSettingsProvider.setThemeMode(mode);
      notifyListeners();

      // 发送主题变更事件
      eventBus.fire(ThemeChangedEvent(mode));
    } catch (e, stack) {
      _logger.error('设置主题模式失败', e, stack);
    }
  }

  /// 设置语言
  Future<void> setLanguage(String languageCode) async {
    try {
      await _appSettingsProvider.setLanguage(languageCode);
      notifyListeners();

      // 发送语言变更事件
      eventBus.fire(LanguageChangedEvent(languageCode));
    } catch (e, stack) {
      _logger.error('设置语言失败', e, stack);
    }
  }

  /// 设置服务器URL
  Future<void> setServerUrl(String url) async {
    try {
      // TODO: 实现设置服务器URL
      notifyListeners();
    } catch (e, stack) {
      _logger.error('设置服务器URL失败', e, stack);
    }
  }

  /// 设置是否使用模拟数据
  Future<void> setUseMockData(bool useMock) async {
    try {
      await _appSettingsProvider.setUseMockData(useMock);
      notifyListeners();
    } catch (e, stack) {
      _logger.error('设置是否使用模拟数据失败', e, stack);
    }
  }

  /// 同步数据
  Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      _logger.debug('同步数据');

      // 同步节日
      final holidaySyncResult = await _holidayRepository.syncHolidays('CN', 'zh');
      _logger.debug('节日同步结果: $holidaySyncResult');

      // 同步提醒事项
      final reminderSyncResult = await _reminderRepository.syncReminders();
      _logger.debug('提醒事项同步结果: $reminderSyncResult');

      // 更新上次同步时间
      _lastSyncTime = DateTime.now();

      _isSyncing = false;
      notifyListeners();

      // 发送同步完成事件
      eventBus.fire(SyncCompletedEvent(
        true,
        '同步完成',
      ));
    } catch (e, stack) {
      _logger.error('同步数据失败', e, stack);

      _isSyncing = false;
      notifyListeners();

      // 发送同步失败事件
      eventBus.fire(SyncCompletedEvent(
        false,
        '同步失败: $e',
      ));
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    try {
      _logger.debug('清除缓存');

      // TODO: 实现清除缓存

      // 发送缓存清除事件
      eventBus.fire(RefreshTimelineEvent());
    } catch (e, stack) {
      _logger.error('清除缓存失败', e, stack);
    }
  }

  /// 检查更新
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      _logger.debug('检查更新');

      // TODO: 实现检查更新

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前已是最新版本'),
        ),
      );
    } catch (e, stack) {
      _logger.error('检查更新失败', e, stack);

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查更新失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 格式化日期时间
  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }
}
