import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lunar/lunar.dart'; // 引入 lunar 包用于农历计算
import 'package:intl/intl.dart'; // 用于日期格式化
import 'package:intl/date_symbol_data_local.dart'; // 确保中文星期名称可用

// 定义特殊日期的类型 (保持不变)
enum SpecialDateType {
  statutory, traditional, solarTerm, memorial, custom, other
}

// 定义日期计算规则的类型
enum DateCalculationType {
  fixedGregorian, // 固定公历日期，如 MM-DD
  fixedLunar,     // 固定农历日期，如 MM-DDL
  nthWeekdayOfMonth, // 某月第n个星期几，如 MM,N,W
  solarTermBased, // 基于节气的日期，如 "QingMing"
  relativeTo      // 相对于另一个特殊日期的日期，如 "HOLIDAY_ID,+/-N"
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

                  // 添加调试信息
                  if (name == '腊八节') {
                    debugPrint('腊八节计算: 农历 $year 年 $lMonth 月 $lDay 日');
                  }

                  final lunarDate = Lunar.fromYmd(year, lMonth, lDay);
                  final solarDate = lunarDate.getSolar();

                  // 添加调试信息
                  if (name == '腊八节') {
                    debugPrint('腊八节转换: 公历 ${solarDate.getYear()} 年 ${solarDate.getMonth()} 月 ${solarDate.getDay()} 日');
                    debugPrint('腊八节农历: ${lunarDate.getYearInChinese()}年${lunarDate.getMonthInChinese()}月${lunarDate.getDayInChinese()}');
                  }

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
             // 暂时使用固定日期作为近似值
             if (calculationRule == 'QingMing') {
               // 清明节通常在4月4日或5日
               calculatedDate = DateTime(year, 4, 5);
             }
             break;
           case DateCalculationType.relativeTo:
             // 相对于另一个特殊日期的日期，格式: "HOLIDAY_ID,+/-N"
             final parts = calculationRule.split(',');
             if (parts.length == 2) {
               final relativeToId = parts[0];
               final daysOffset = int.parse(parts[1]);

               // 这里需要获取相对参考的节日日期
               // 注意：这需要一个全局的节日查找机制，暂时使用简化实现
               DateTime? referenceDate;

               // 简化实现：仅支持几个常见节日作为参考
               if (relativeToId == 'WEST_Easter') {
                 // 简化的复活节计算 (4月第一个周日)
                 DateTime firstOfApril = DateTime(year, 4, 1);
                 int daysUntilSunday = (7 - firstOfApril.weekday) % 7;
                 referenceDate = firstOfApril.add(Duration(days: daysUntilSunday));
               }

               if (referenceDate != null) {
                 calculatedDate = referenceDate.add(Duration(days: daysOffset));
               }
             }
             break;
         }
      } catch (e) {
          debugPrint("Error calculating date for $name ($calculationRule): $e");
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
  String formatUpcomingDate(DateTime upcomingDate, DateTime currentDate, {String? locale}) {
    // 确保 currentDate 也是日期部分，忽略时间
    DateTime currentDay = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final difference = upcomingDate.difference(currentDay).inDays;

    // 根据语言环境选择格式
    final String actualLocale = locale ?? 'en';
    final bool isChinese = actualLocale.startsWith('zh');

    // 确保初始化日期格式
    initializeDateFormatting(actualLocale, null);

    // 根据语言环境选择不同的日期格式
    final formattedDate = isChinese
        ? DateFormat('yyyy-MM-dd (E)', 'zh_CN').format(upcomingDate)
        : DateFormat('MMM d, yyyy (EEE)', actualLocale).format(upcomingDate);

    if (difference == 0) {
      return isChinese
          ? '$formattedDate (今天)'
          : '$formattedDate (Today)';
    } else if (difference == 1) {
      return isChinese
          ? '$formattedDate (明天)'
          : '$formattedDate (Tomorrow)';
    } else if (difference == 2) {
      return isChinese
          ? '$formattedDate (后天)'
          : '$formattedDate (Day after tomorrow)';
    } else if (difference > 0) {
      return isChinese
          ? '$formattedDate (还有 $difference 天)'
          : '$formattedDate ($difference days left)';
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