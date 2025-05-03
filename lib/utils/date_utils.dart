import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jinlin_app/models/unified/holiday.dart' as app_holiday;
import 'package:lunar/lunar.dart';

/// 日期工具类
///
/// 提供日期相关的工具方法
class AppDateUtils {
  // 防止实例化
  AppDateUtils._();

  /// 计算节日发生日期
  static List<DateTime> calculateHolidayDates(
    app_holiday.Holiday holiday,
    DateTime startDate,
    DateTime endDate,
  ) {
    switch (holiday.calculationType) {
      case app_holiday.DateCalculationType.fixedGregorian:
        return _calculateFixedSolarDates(
          holiday.calculationRule,
          startDate,
          endDate,
        );
      case app_holiday.DateCalculationType.fixedLunar:
        return _calculateFixedLunarDates(
          holiday.calculationRule,
          startDate,
          endDate,
        );
      case app_holiday.DateCalculationType.variableRule:
        return _calculateVariableRuleDates(
          holiday.calculationRule,
          startDate,
          endDate,
        );
      case app_holiday.DateCalculationType.custom:
        return _calculateCustomDates(
          holiday.calculationRule,
          startDate,
          endDate,
        );
    }
  }

  /// 计算固定公历日期
  static List<DateTime> _calculateFixedSolarDates(
    String rule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];

    // 解析规则，格式为 "MM-DD"
    final parts = rule.split('-');
    if (parts.length != 2) return [];

    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);

    if (month == null || day == null) return [];

    // 计算从开始年份到结束年份的所有日期
    for (var year = startDate.year; year <= endDate.year; year++) {
      final date = DateTime(year, month, day);

      if (date.isAfter(startDate) && date.isBefore(endDate) ||
          date.isAtSameMomentAs(startDate) || date.isAtSameMomentAs(endDate)) {
        dates.add(date);
      }
    }

    return dates;
  }

  /// 计算固定农历日期
  static List<DateTime> _calculateFixedLunarDates(
    String rule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];

    // 解析规则，格式为 "MM-DD"
    final parts = rule.split('-');
    if (parts.length != 2) return [];

    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);

    if (month == null || day == null) return [];

    // 计算从开始年份到结束年份的所有日期
    for (var year = startDate.year; year <= endDate.year; year++) {
      try {
        // 使用农历库计算对应的公历日期
        final solar = Solar.fromYmd(year, month, day);
        // 这里不需要lunar变量，直接使用solar
        final date = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());

        if (date.isAfter(startDate) && date.isBefore(endDate) ||
            date.isAtSameMomentAs(startDate) || date.isAtSameMomentAs(endDate)) {
          dates.add(date);
        }
      } catch (e) {
        // 忽略无效日期
        debugPrint('无效农历日期: $year-$month-$day, 错误: $e');
      }
    }

    return dates;
  }

  /// 计算可变规则日期
  static List<DateTime> _calculateVariableRuleDates(
    String rule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];

    // 解析规则
    // 例如: "thanksgiving:11:4:4" 表示感恩节：11月第4个星期四
    final parts = rule.split(':');
    if (parts.length < 4) return [];

    final month = int.tryParse(parts[1]);
    final weekNumber = int.tryParse(parts[2]);
    final weekday = int.tryParse(parts[3]);

    if (month == null || weekNumber == null || weekday == null) return [];

    // 计算从开始年份到结束年份的所有日期
    for (var year = startDate.year; year <= endDate.year; year++) {
      final date = _calculateNthWeekdayOfMonth(year, month, weekNumber, weekday);

      if (date != null &&
          (date.isAfter(startDate) && date.isBefore(endDate) ||
           date.isAtSameMomentAs(startDate) || date.isAtSameMomentAs(endDate))) {
        dates.add(date);
      }
    }

    return dates;
  }

  /// 计算自定义日期
  static List<DateTime> _calculateCustomDates(
    String rule,
    DateTime startDate,
    DateTime endDate,
  ) {
    // 自定义规则处理
    // 这里可以实现更复杂的日期计算逻辑
    return [];
  }

  /// 计算某月第n个星期几
  static DateTime? _calculateNthWeekdayOfMonth(
    int year,
    int month,
    int weekNumber,
    int weekday,
  ) {
    // 获取该月第一天
    final firstDayOfMonth = DateTime(year, month, 1);

    // 计算该月第一个指定星期几的日期
    var daysToAdd = (weekday - firstDayOfMonth.weekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;

    final firstWeekdayOfMonth = firstDayOfMonth.add(Duration(days: daysToAdd));

    // 计算第n个星期几
    final nthWeekday = firstWeekdayOfMonth.add(Duration(days: (weekNumber - 1) * 7));

    // 检查是否在同一个月内
    if (nthWeekday.month != month) return null;

    return nthWeekday;
  }

  /// 格式化日期
  static String formatDate(DateTime date, {String locale = 'zh'}) {
    final formatter = DateFormat.yMd(locale);
    return formatter.format(date);
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime date, {String locale = 'zh'}) {
    final formatter = DateFormat.yMd(locale).add_Hm();
    return formatter.format(date);
  }

  /// 格式化时间
  static String formatTime(DateTime date, {String locale = 'zh'}) {
    final formatter = DateFormat.Hm(locale);
    return formatter.format(date);
  }

  /// 获取星期几
  static String getWeekday(DateTime date, {String locale = 'zh'}) {
    if (locale == 'zh') {
      final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      return weekdays[date.weekday - 1];
    } else {
      final formatter = DateFormat.EEEE(locale);
      return formatter.format(date);
    }
  }

  /// 获取农历日期
  static String getLunarDate(DateTime date) {
    try {
      final solar = Solar.fromDate(date);
      final lunar = Lunar.fromSolar(solar);
      return lunar.toString();
    } catch (e) {
      return '';
    }
  }

  /// 获取今天的日期
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 获取明天的日期
  static DateTime tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// 获取昨天的日期
  static DateTime yesterday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1);
  }

  /// 获取本周的开始日期（星期一）
  static DateTime startOfWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day - weekday + 1);
  }

  /// 获取本周的结束日期（星期日）
  static DateTime endOfWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day + (7 - weekday));
  }

  /// 获取本月的开始日期
  static DateTime startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// 获取本月的结束日期
  static DateTime endOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// 获取本年的开始日期
  static DateTime startOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  /// 获取本年的结束日期
  static DateTime endOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31);
  }

  /// 检查两个日期是否是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  /// 检查日期是否是今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// 检查日期是否是明天
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// 检查日期是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 检查日期是否是周末
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 检查日期是否是工作日
  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  /// 获取两个日期之间的天数
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// 获取两个日期之间的月数
  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }

  /// 获取两个日期之间的年数
  static int yearsBetween(DateTime from, DateTime to) {
    return to.year - from.year;
  }
}
