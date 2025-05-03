import 'package:jinlin_app/models/unified/holiday.dart' as app_holiday;
import 'package:jinlin_app/models/unified/reminder.dart';

/// 通知服务接口
///
/// 定义通知服务的方法
abstract class NotificationServiceInterface {
  /// 初始化通知服务
  Future<void> initialize();

  /// 检查通知权限
  Future<bool> checkPermission();

  /// 请求通知权限
  Future<bool> requestPermission();

  /// 调度提醒事项通知
  Future<void> scheduleReminderNotification(Reminder reminder);

  /// 调度节日通知
  Future<void> scheduleHolidayNotification(app_holiday.Holiday holiday, DateTime occurrenceDate);

  /// 取消提醒事项通知
  Future<void> cancelReminderNotification(String reminderId);

  /// 取消节日通知
  Future<void> cancelHolidayNotification(String holidayId);

  /// 取消所有通知
  Future<void> cancelAllNotifications();

  /// 显示即时通知
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  });

  /// 处理通知点击
  void handleNotificationClick(String? payload);

  /// 添加通知点击监听器
  void addNotificationClickListener(void Function(String? payload) listener);

  /// 移除通知点击监听器
  void removeNotificationClickListener(void Function(String? payload) listener);

  /// 关闭通知服务
  Future<void> close();
}
