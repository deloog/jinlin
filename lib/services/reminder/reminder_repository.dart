import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/api/api_client.dart';
import 'package:jinlin_app/services/api/api_endpoints.dart';
import 'package:jinlin_app/services/api/api_exception.dart';
import 'package:jinlin_app/services/database/database_service.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 提醒事项存储库
///
/// 负责管理提醒事项的获取、存储和同步
class ReminderRepository {
  final ApiClient _apiClient;
  final DatabaseService _databaseService;
  final EventBus _eventBus;
  final LoggingService _logger = LoggingService();

  // 是否正在同步
  bool _isSyncing = false;

  // 同步状态
  String _syncStatus = '空闲';

  // 上次同步时间
  DateTime? _lastSyncTime;

  /// 获取同步状态
  String get syncStatus => _syncStatus;

  /// 获取上次同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 获取是否正在同步
  bool get isSyncing => _isSyncing;

  ReminderRepository({
    required ApiClient apiClient,
    required DatabaseService databaseService,
    EventBus? eventBus,
  }) :
    _apiClient = apiClient,
    _databaseService = databaseService,
    _eventBus = eventBus ?? EventBus() {
    _logger.debug('初始化提醒事项存储库');
  }

  /// 获取所有提醒事项
  Future<List<Reminder>> getReminders() async {
    try {
      _logger.debug('获取所有提醒事项');

      // 尝试从API获取数据
      try {
        final response = await _apiClient.get<Map<String, dynamic>>(
          ApiEndpoints.reminders,
          fromJson: (json) => json,
        );

        // 解析响应
        final remindersJson = response['reminders'] as List<dynamic>;
        final reminders = remindersJson
            .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.debug('从API获取到 ${reminders.length} 个提醒事项');

        // 保存到本地数据库
        await _databaseService.saveReminders(reminders);

        return reminders;
      } on ApiException catch (e) {
        _logger.warning('从API获取提醒事项失败: $e，尝试从本地数据库获取');
        // 如果API请求失败，尝试从本地数据库获取
      }

      // 从本地数据库获取
      final reminders = await _databaseService.getReminders();
      _logger.debug('从本地数据库获取到 ${reminders.length} 个提醒事项');

      return reminders;
    } catch (e, stack) {
      _logger.error('获取提醒事项失败', e, stack);
      return [];
    }
  }

  /// 获取特定日期的提醒事项
  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    try {
      _logger.debug('获取 ${date.toIso8601String().split('T')[0]} 的提醒事项');

      // 从本地数据库获取
      final reminders = await _databaseService.getRemindersByDate(date);
      _logger.debug('获取到 ${reminders.length} 个提醒事项');

      return reminders;
    } catch (e, stack) {
      _logger.error('获取特定日期的提醒事项失败', e, stack);
      return [];
    }
  }

  /// 获取特定ID的提醒事项
  Future<Reminder?> getReminderById(String id) async {
    try {
      _logger.debug('获取ID为 $id 的提醒事项');

      // 从本地数据库获取
      final reminder = await _databaseService.getReminderById(id);

      if (reminder != null) {
        _logger.debug('成功获取提醒事项');
      } else {
        _logger.debug('未找到ID为 $id 的提醒事项');
      }

      return reminder;
    } catch (e, stack) {
      _logger.error('获取特定ID的提醒事项失败', e, stack);
      return null;
    }
  }

  /// 保存提醒事项
  Future<bool> saveReminder(Reminder reminder) async {
    try {
      _logger.debug('保存提醒事项: ${reminder.id}');

      // 尝试发送到API
      try {
        await _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.reminders,
          body: reminder.toJson(),
          fromJson: (json) => json,
        );

        _logger.debug('成功保存提醒事项到API');

        // 保存到本地数据库
        await _databaseService.saveReminder(reminder);

        // 发送事件通知
        _eventBus.fire(ReminderUpdatedEvent(reminderId: reminder.id));

        return true;
      } on ApiException catch (e) {
        _logger.warning('保存提醒事项到API失败: $e，仅保存到本地数据库');
        // 如果API请求失败，仅保存到本地数据库
      }

      // 保存到本地数据库，并标记为需要同步
      await _databaseService.saveReminder(reminder, needsSync: true);

      // 发送事件通知
      _eventBus.fire(ReminderUpdatedEvent(reminderId: reminder.id));

      return true;
    } catch (e, stack) {
      _logger.error('保存提醒事项失败', e, stack);
      return false;
    }
  }

  /// 更新提醒事项
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      _logger.debug('更新提醒事项: ${reminder.id}');

      // 尝试发送到API
      try {
        await _apiClient.put<Map<String, dynamic>>(
          '${ApiEndpoints.reminders}/${reminder.id}',
          body: reminder.toJson(),
          fromJson: (json) => json,
        );

        _logger.debug('成功更新提醒事项到API');

        // 更新本地数据库
        await _databaseService.updateReminder(reminder);

        // 发送事件通知
        _eventBus.fire(ReminderUpdatedEvent(reminderId: reminder.id));

        return true;
      } on ApiException catch (e) {
        _logger.warning('更新提醒事项到API失败: $e，仅更新本地数据库');
        // 如果API请求失败，仅更新本地数据库
      }

      // 更新本地数据库，并标记为需要同步
      await _databaseService.updateReminder(reminder, needsSync: true);

      // 发送事件通知
      _eventBus.fire(ReminderUpdatedEvent(reminderId: reminder.id));

      return true;
    } catch (e, stack) {
      _logger.error('更新提醒事项失败', e, stack);
      return false;
    }
  }

  /// 删除提醒事项
  Future<bool> deleteReminder(String id) async {
    try {
      _logger.debug('删除提醒事项: $id');

      // 尝试发送到API
      try {
        await _apiClient.delete<Map<String, dynamic>>(
          '${ApiEndpoints.reminders}/$id',
          fromJson: (json) => json,
        );

        _logger.debug('成功从API删除提醒事项');

        // 从本地数据库删除
        await _databaseService.deleteReminder(id);

        // 发送事件通知
        _eventBus.fire(ReminderUpdatedEvent(reminderId: id));

        return true;
      } on ApiException catch (e) {
        _logger.warning('从API删除提醒事项失败: $e，仅从本地数据库删除');
        // 如果API请求失败，仅从本地数据库删除
      }

      // 从本地数据库删除，并标记为需要同步
      await _databaseService.deleteReminder(id, needsSync: true);

      // 发送事件通知
      _eventBus.fire(ReminderUpdatedEvent(reminderId: id));

      return true;
    } catch (e, stack) {
      _logger.error('删除提醒事项失败', e, stack);
      return false;
    }
  }

  /// 同步提醒事项
  Future<bool> syncReminders() async {
    // 防止重复同步
    if (_isSyncing) {
      _logger.debug('已有同步任务正在进行，跳过');
      return false;
    }

    _isSyncing = true;
    _syncStatus = '正在同步提醒事项...';

    try {
      _logger.debug('开始同步提醒事项...');

      // 检查网络连接
      final isConnected = await _apiClient.checkConnection();
      if (!isConnected) {
        _logger.warning('无法连接到服务器，同步取消');
        _syncStatus = '无法连接到服务器';
        _isSyncing = false;
        return false;
      }

      // 获取需要同步的本地更改
      final localChanges = await _databaseService.getUnsyncedReminders();
      _logger.debug('获取到 ${localChanges.length} 个需要同步的本地更改');

      if (localChanges.isNotEmpty) {
        _syncStatus = '正在上传本地更改...';

        // 发送本地更改到服务器
        await _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.reminderSync,
          body: {
            'changes': localChanges.map((reminder) => reminder.toJson()).toList(),
          },
          fromJson: (json) => json,
        );

        // 标记本地更改已同步
        await _databaseService.markRemindersSynced(localChanges.map((r) => r.id).toList());
        _logger.debug('本地更改已上传并标记为已同步');
      }

      // 获取服务器更改
      _syncStatus = '正在获取服务器更改...';
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.reminderSync,
        queryParams: {
          'since': _lastSyncTime?.toIso8601String() ?? '1970-01-01T00:00:00.000Z',
        },
        fromJson: (json) => json,
      );

      // 解析服务器更改
      final serverChangesJson = response['changes'] as List<dynamic>;
      final serverChanges = serverChangesJson
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.debug('从服务器获取到 ${serverChanges.length} 个更改');

      if (serverChanges.isNotEmpty) {
        _syncStatus = '正在应用服务器更改...';

        // 应用服务器更改到本地数据库
        await _databaseService.applyReminderChanges(serverChanges);
        _logger.debug('服务器更改已应用到本地数据库');
      }

      _lastSyncTime = DateTime.now();
      _syncStatus = '同步完成';

      // 发送同步事件
      _eventBus.fire(ReminderUpdatedEvent());

      return true;
    } catch (e, stack) {
      _logger.error('同步提醒事项失败', e, stack);
      _syncStatus = '同步失败: $e';
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
