import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart'; // 引入 lunar 包用于农历计算
import 'package:intl/intl.dart'; // 用于日期格式化
import 'package:intl/date_symbol_data_local.dart'; // 确保中文星期名称可用

// 定义特殊日期的类型 (保持不变)
enum SpecialDateType {
  statutory, traditional, solarTerm, memorial, custom, other
}

// 定义日期计算规则的类型 (保持不变)
enum DateCalculationType {
  fixedGregorian, fixedLunar, nthWeekdayOfMonth, solarTermBased
}

// 特殊日期数据模型类 (增加了一个工具方法)
class SpecialDate {
  final String id;
  final String name;
  final SpecialDateType type;
  final List<String> regions;
  final DateCalculationType calculationType;
  final String calculationRule;
  final String? description;

  SpecialDate({
    required this.id,
    required this.name,
    required this.type,
    required this.regions,
    required this.calculationType,
    required this.calculationRule,
    this.description,
  });

  // 计算从指定日期开始的下一个发生日期 (优化逻辑)
  // 返回 null 如果无法计算或规则不支持
  DateTime? getUpcomingOccurrence(DateTime fromDate) {
    // 为了避免计算跨度太大，我们通常只计算今年和明年的日期
    for (int year = fromDate.year; year <= fromDate.year + 2; year++) {
      DateTime? calculatedDate;
      try {
         switch (calculationType) {
           case DateCalculationType.fixedGregorian:
             final parts = calculationRule.split('-');
             if (parts.length == 2) {
               final month = int.parse(parts[0]);
               final day = int.parse(parts[1]);
               calculatedDate = DateTime(year, month, day);
             }
             break;
           case DateCalculationType.fixedLunar:
              final parts = calculationRule.replaceFirst('L', '').split('-');
              if (parts.length == 2) {
                  final lMonth = int.parse(parts[0]);
                  final lDay = int.parse(parts[1]);
                  final lunarDate = Lunar.fromYmd(year, lMonth, lDay);
                  final solarDate = lunarDate.getSolar();
                  // Lunar库转换有时年份会偏差，强制使用我们指定的年份
                  calculatedDate = DateTime(year, solarDate.getMonth(), solarDate.getDay());
              }
              break;
           case DateCalculationType.nthWeekdayOfMonth:
              final parts = calculationRule.split(',');
              if (parts.length == 3) {
                  final month = int.parse(parts[0]);
                  final n = int.parse(parts[1]);
                  final weekday = int.parse(parts[2]); // 0=Sun..6=Sat
                  int targetWeekday = (weekday == 0) ? 7 : weekday; // DateTime: 1=Mon..7=Sun

                  DateTime firstOfMonth = DateTime(year, month, 1);
                  int daysUntilFirstTargetDay = (targetWeekday - firstOfMonth.weekday + 7) % 7;
                  DateTime firstTargetDayOfMonth = firstOfMonth.add(Duration(days: daysUntilFirstTargetDay));
                  DateTime potentialDate = firstTargetDayOfMonth.add(Duration(days: (n - 1) * 7));

                  // 必须确保计算出的日期仍在同一个月
                  if (potentialDate.month == month) {
                      calculatedDate = potentialDate;
                  }
              }
              break;
           case DateCalculationType.solarTermBased:
             // TODO: 实现基于节气的计算 (如清明节)
             // print("Solar term calculation not implemented yet for $name");
             break;
         }
      } catch (e) {
          print("Error calculating date for $name ($calculationRule): $e");
          calculatedDate = null;
      }

      // --- 关键检查 ---
      // 1. 必须成功计算出日期 (calculatedDate != null)
      // 2. 计算出的日期必须在 'fromDate' 当天或之后
      //    (使用 !isBefore 来包含当天)
      if (calculatedDate != null && !calculatedDate.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
          // 如果找到符合条件的日期，立即返回
          return calculatedDate;
      }
      // 如果今年的日期已过或无效，循环会自动进入下一年进行尝试
    }

    // 如果两年内都找不到未来的有效日期，返回 null
    return null;
  }

  // 辅助方法：格式化即将到来的日期和剩余天数
  String formatUpcomingDate(DateTime upcomingDate, DateTime currentDate) {
     // 确保 currentDate 也是日期部分，忽略时间
    DateTime currentDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final difference = upcomingDate.difference(currentDay).inDays;
    // 确保初始化中文格式
    initializeDateFormatting('zh_CN', null);
    final formattedDate = DateFormat('yyyy-MM-dd (E)', 'zh_CN').format(upcomingDate);

    if (difference == 0) {
      return '$formattedDate (今天)';
    } else if (difference == 1) {
      return '$formattedDate (明天)';
    } else if (difference == 2) {
      return '$formattedDate (后天)';
    } else if (difference > 0) {
       return '$formattedDate (还有 $difference 天)';
    } else {
       // 一般不应出现这种情况，因为 getUpcomingOccurrence 会返回未来日期
       return formattedDate;
    }
  }

   // 新增：辅助方法，根据类型获取图标 (示例)
   IconData get typeIcon {
     switch (type) {
       case SpecialDateType.statutory:
         return Icons.flag_circle; // 法定
       case SpecialDateType.traditional:
         return Icons.cake; // 传统
       case SpecialDateType.solarTerm:
         return Icons.wb_sunny; // 节气
       case SpecialDateType.memorial:
         return Icons.star_border; // 纪念
       case SpecialDateType.custom:
         return Icons.person; // 自定义
       default:
         return Icons.calendar_today;
     }
   }
}