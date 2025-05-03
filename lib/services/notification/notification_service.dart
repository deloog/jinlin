import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jinlin_app/models/unified/holiday.dart' as app_holiday;
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/notification/notification_service_interface.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 通知服务
///
/// 提供通知功能
class NotificationService implements NotificationServiceInterface {
  // 单例实例
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 日志服务
  final LoggingService _logger = LoggingService();

  // 通知插件
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 通知点击监听器
  final List<void Function(String? payload)> _notificationClickListeners = [];

  // 是否已初始化
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _logger.info('初始化通知服务...');

    try {
      // 初始化时区
      tz.initializeTimeZones();

      // 初始化通知插件
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings darwinInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      _initialized = true;
      _logger.info('通知服务初始化完成');
    } catch (e, stack) {
      _logger.error('通知服务初始化失败', e, stack);
    }
  }

  @override
  Future<bool> checkPermission() async {
    _logger.debug('检查通知权限');

    try {
      if (Platform.isIOS) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );

        return result ?? false;
      } else if (Platform.isAndroid) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();

        return result ?? false;
      }

      return false;
    } catch (e, stack) {
      _logger.error('检查通知权限失败', e, stack);
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    _logger.debug('请求通知权限');

    try {
      if (Platform.isIOS) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );

        return result ?? false;
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // 使用requestNotificationsPermission方法
          final result = await androidImplementation.requestNotificationsPermission();
          return result ?? false;
        }

        return false;
      }

      return false;
    } catch (e, stack) {
      _logger.error('请求通知权限失败', e, stack);
      return false;
    }
  }

  @override
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    _logger.debug('调度提醒事项通知: ${reminder.id}');

    try {
      if (reminder.date.isEmpty) {
        _logger.warning('提醒事项没有日期，无法调度通知');
        return;
      }

      // 创建通知详情
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'reminder_channel',
        '提醒事项',
        channelDescription: '提醒事项通知',
        importance: Importance.high,
        priority: Priority.high,
        ticker: '提醒事项',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        categoryIdentifier: 'reminder',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      // 创建通知时间
      // 解析日期字符串
      final dateParts = reminder.date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // 解析时间字符串
      int hour = 9;
      int minute = 0;
      if (reminder.time != null) {
        final timeParts = reminder.time!.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      final notificationTime = tz.TZDateTime.from(
        DateTime(year, month, day, hour, minute),
        tz.local,
      );

      // 如果通知时间已过，不调度通知
      if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
        _logger.warning('提醒事项通知时间已过，不调度通知');
        return;
      }

      // 调度通知
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.id.hashCode,
        reminder.title,
        reminder.description ?? '',
        notificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reminder:${reminder.id}',
      );

      _logger.debug('提醒事项通知调度成功');
    } catch (e, stack) {
      _logger.error('调度提醒事项通知失败', e, stack);
    }
  }

  @override
  Future<void> scheduleHolidayNotification(app_holiday.Holiday holiday, DateTime occurrenceDate) async {
    _logger.debug('调度节日通知: ${holiday.id}');

    try {
      // 创建通知详情
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'holiday_channel',
        '节日',
        channelDescription: '节日通知',
        importance: Importance.high,
        priority: Priority.high,
        ticker: '节日',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        categoryIdentifier: 'holiday',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      // 创建通知时间（提前一天）
      final notificationTime = tz.TZDateTime.from(
        DateTime(
          occurrenceDate.year,
          occurrenceDate.month,
          occurrenceDate.day - 1,
          9,
          0,
        ),
        tz.local,
      );

      // 如果通知时间已过，不调度通知
      if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
        _logger.warning('节日通知时间已过，不调度通知');
        return;
      }

      // 调度通知
      final holidayName = holiday.getLocalizedName('zh');
      final holidayDescription = holiday.getLocalizedDescription('zh') ?? '';

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        holiday.id.hashCode,
        '明天是$holidayName',
        holidayDescription,
        notificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'holiday:${holiday.id}',
      );

      _logger.debug('节日通知调度成功');
    } catch (e, stack) {
      _logger.error('调度节日通知失败', e, stack);
    }
  }

  @override
  Future<void> cancelReminderNotification(String reminderId) async {
    _logger.debug('取消提醒事项通知: $reminderId');

    try {
      await _flutterLocalNotificationsPlugin.cancel(reminderId.hashCode);
      _logger.debug('提醒事项通知取消成功');
    } catch (e, stack) {
      _logger.error('取消提醒事项通知失败', e, stack);
    }
  }

  @override
  Future<void> cancelHolidayNotification(String holidayId) async {
    _logger.debug('取消节日通知: $holidayId');

    try {
      await _flutterLocalNotificationsPlugin.cancel(holidayId.hashCode);
      _logger.debug('节日通知取消成功');
    } catch (e, stack) {
      _logger.error('取消节日通知失败', e, stack);
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.debug('取消所有通知');

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _logger.debug('所有通知取消成功');
    } catch (e, stack) {
      _logger.error('取消所有通知失败', e, stack);
    }
  }

  @override
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _logger.debug('显示即时通知');

    try {
      // 创建通知详情
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'instant_channel',
        '即时通知',
        channelDescription: '即时通知',
        importance: Importance.high,
        priority: Priority.high,
        ticker: '即时通知',
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        categoryIdentifier: 'instant',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      // 显示通知
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      _logger.debug('即时通知显示成功');
    } catch (e, stack) {
      _logger.error('显示即时通知失败', e, stack);
    }
  }

  @override
  void handleNotificationClick(String? payload) {
    _logger.debug('处理通知点击: $payload');

    if (payload == null) return;

    try {
      if (payload.startsWith('reminder:')) {
        // 导航到提醒事项详情页
        // 提醒事项ID: payload.substring(9)
        // 将在未来实现
      } else if (payload.startsWith('holiday:')) {
        // 导航到节日详情页
        // 节日ID: payload.substring(8)
        // 将在未来实现
      }
    } catch (e, stack) {
      _logger.error('处理通知点击失败', e, stack);
    }

    // 通知监听器
    for (final listener in _notificationClickListeners) {
      listener(payload);
    }
  }

  @override
  void addNotificationClickListener(void Function(String? payload) listener) {
    _notificationClickListeners.add(listener);
  }

  @override
  void removeNotificationClickListener(void Function(String? payload) listener) {
    _notificationClickListeners.remove(listener);
  }

  @override
  Future<void> close() async {
    _logger.debug('关闭通知服务');

    // 清空监听器
    _notificationClickListeners.clear();

    _initialized = false;
  }

  /// 处理iOS本地通知
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    _logger.debug('收到iOS本地通知: $id, $title, $body, $payload');

    // 处理通知点击
    handleNotificationClick(payload);
  }

  /// 处理通知响应
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.debug('收到通知响应: ${response.payload}');

    // 处理通知点击
    handleNotificationClick(response.payload);
  }
}
