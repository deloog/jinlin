import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 需要访问 l10n
import '../reminder.dart';

String formatReminderDate(BuildContext context, DateTime? date, ReminderType reminderType) {
  if (date == null) {
    return AppLocalizations.of(context).dateNotSet;
  }

  final locale = Localizations.localeOf(context);
  String formatPattern = 'yyyy-MM-dd HH:mm'; // 公历格式
  String gregorianDateString = DateFormat(formatPattern, locale.toString()).format(date);

  String fullDateString = gregorianDateString;

  // 如果是中文环境，添加农历信息
  bool shouldShowLunar = locale.languageCode == 'zh' &&
      (reminderType == ReminderType.birthday ||
       reminderType == ReminderType.chineseFestival ||
       reminderType == ReminderType.memorialDay);
       // 你可以根据需要调整这里的类型判断

  if (shouldShowLunar) {
    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();
    // 获取农历月日
    final lunarMonth = lunar.getMonthInChinese();
    final lunarDay = lunar.getDayInChinese();
    final lunarDateString = '(${AppLocalizations.of(context).lunar} $lunarMonth月$lunarDay)'; // 简洁格式
    // 或者 final lunarDateString = '(农历 $lunarYear年$lunarMonth月$lunarDay)';

    fullDateString += ' $lunarDateString';
  }

  return fullDateString;
}