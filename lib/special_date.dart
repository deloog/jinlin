import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart'; // 引入 lunar 包用于农历计算
import 'package:intl/intl.dart'; // 用于日期格式化
import 'package:intl/date_symbol_data_local.dart'; // 确保中文星期名称可用
import 'package:jinlin_app/services/layout_service.dart'; // 布局服务

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

// 定义特殊日期的重要性级别
enum ImportanceLevel {
  low,     // 低重要性，只在临近时显示
  medium,  // 中等重要性，提前较长时间显示
  high     // 高重要性，始终显示
}



// 特殊日期数据模型类 (增加了多语言支持)
class SpecialDate {
  final String id;
  final String name;
  final SpecialDateType type;
  final List<String> regions;
  final DateCalculationType calculationType;
  final String calculationRule;
  final String? description;
  final ImportanceLevel importanceLevel;

  // 多语言支持
  final String? nameEn;          // 英文名称
  final String? descriptionEn;   // 英文描述

  // 新增字段
  final String? customs;         // 习俗
  final String? taboos;          // 禁忌
  final String? foods;           // 传统食物
  final String? greetings;       // 传统问候语
  final String? activities;      // 相关活动
  final String? history;         // 历史背景
  final String? imageUrl;        // 图片URL

  // 发生日期（计算得出）
  DateTime? occurrenceDate;

  SpecialDate({
    required this.id,
    required this.name,
    required this.type,
    required this.regions,
    required this.calculationType,
    required this.calculationRule,
    this.description,
    this.importanceLevel = ImportanceLevel.low, // 默认为低重要性
    this.nameEn,                 // 英文名称
    this.descriptionEn,          // 英文描述
    this.customs,
    this.taboos,
    this.foods,
    this.greetings,
    this.activities,
    this.history,
    this.imageUrl,
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
             // 基于节气的计算 (如清明节)
             // 注意：这里使用固定日期作为近似值，将来可以使用更精确的计算方法
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

   // 根据节日类型和ID获取图标
   IconData get typeIcon {
     // 首先检查特定节日的图标
     final specificIcon = _getSpecificHolidayIcon(id);
     if (specificIcon != null) {
       return specificIcon;
     }

     // 如果没有特定图标，则根据类型返回默认图标
     switch (type) {
       case SpecialDateType.statutory:
         return Icons.flag_circle; // 法定节日
       case SpecialDateType.traditional:
         return Icons.cake; // 传统节日
       case SpecialDateType.solarTerm:
         return Icons.wb_sunny; // 节气
       case SpecialDateType.memorial:
         return Icons.star_border; // 纪念日
       case SpecialDateType.custom:
         return Icons.person; // 自定义
       default:
         return Icons.calendar_today;
     }
   }

   // 根据节日ID获取特定图标
   IconData? _getSpecificHolidayIcon(String holidayId) {
     // 中国节日
     if (holidayId == 'CN_SpringFestival') return Icons.fireplace; // 春节
     if (holidayId == 'CN_LanternFestival') return Icons.lightbulb; // 元宵节
     if (holidayId == 'CN_ChingMing') return Icons.nature_people; // 清明节
     if (holidayId == 'CN_DragonBoatFestival') return Icons.directions_boat; // 端午节
     if (holidayId == 'CN_MidAutumnFestival') return Icons.nightlight_round; // 中秋节
     if (holidayId == 'CN_DoubleSeventhFestival') return Icons.favorite; // 七夕节
     if (holidayId == 'CN_DoubleNinthFestival') return Icons.terrain; // 重阳节
     if (holidayId == 'CN_LabaFestival') return Icons.soup_kitchen; // 腊八节
     if (holidayId == 'CN_NationalDay') return Icons.flag; // 国庆节

     // 西方节日
     if (holidayId == 'WEST_Christmas') return Icons.card_giftcard; // 圣诞节
     if (holidayId == 'WEST_Easter') return Icons.egg; // 复活节
     if (holidayId == 'WEST_Halloween') return Icons.face_retouching_natural; // 万圣节
     if (holidayId == 'WEST_Thanksgiving') return Icons.dinner_dining; // 感恩节
     if (holidayId == 'WEST_StPatricksDay') return Icons.grass; // 圣帕特里克节

     // 国际节日
     if (holidayId == 'INTL_NewYearDay') return Icons.celebration; // 元旦
     if (holidayId == 'INTL_ValentinesDay') return Icons.favorite_border; // 情人节
     if (holidayId == 'INTL_EarthDay') return Icons.public; // 地球日
     if (holidayId == 'WEST_NewYearsEve') return Icons.watch_later; // 除夕

     // 日本节日
     if (holidayId == 'JP_NewYear') return Icons.temple_buddhist; // 正月
     if (holidayId == 'JP_SetuBun') return Icons.grain; // 節分
     if (holidayId == 'JP_Hinamatsuri') return Icons.emoji_people; // ひな祭り
     if (holidayId == 'JP_GoldenWeek') return Icons.weekend; // 黄金周
     if (holidayId == 'JP_Tanabata') return Icons.auto_awesome; // 七夕
     if (holidayId == 'JP_Obon') return Icons.local_fire_department; // お盆
     if (holidayId == 'JP_Shichigosan') return Icons.child_care; // 七五三

     // 韩国节日
     if (holidayId == 'KR_Seollal') return Icons.home; // 설날
     if (holidayId == 'KR_Chuseok') return Icons.agriculture; // 추석
     if (holidayId == 'KR_BuddhasBirthday') return Icons.brightness_5; // 부처님 오신 날

     // 印度节日
     if (holidayId == 'IN_Diwali') return Icons.emoji_objects; // दीवाली
     if (holidayId == 'IN_Holi') return Icons.palette; // होली
     if (holidayId == 'IN_Dussehra') return Icons.security; // दशहरा

     // 纪念日
     if (holidayId.contains('MothersDay')) return Icons.pregnant_woman; // 母亲节
     if (holidayId.contains('FathersDay')) return Icons.face; // 父亲节
     if (holidayId.contains('TreePlanting')) return Icons.park; // 植树节

     // 没有特定图标，返回null，使用类型默认图标
     return null;
   }

   // 获取节日的颜色
   Color getHolidayColor() {
     // 获取布局服务
     final layoutService = LayoutService();

     // 获取颜色饱和度
     final colorSaturation = layoutService.colorSaturation;

     // 根据节日类型获取基础颜色
     Color baseColor;
     switch (type) {
       case SpecialDateType.statutory:
         baseColor = Colors.red[700]!; // 法定节日用红色
         break;
       case SpecialDateType.traditional:
         baseColor = Colors.orange[700]!; // 传统节日用橙色
         break;
       case SpecialDateType.solarTerm:
         baseColor = Colors.green[700]!; // 节气用绿色
         break;
       case SpecialDateType.memorial:
         baseColor = Colors.blue[700]!; // 纪念日用蓝色
         break;
       case SpecialDateType.custom:
         baseColor = Colors.purple[700]!; // 自定义用紫色
         break;
       default:
         baseColor = Colors.grey[700]!;
         break;
     }

     // 调整颜色饱和度
     final HSLColor hslColor = HSLColor.fromColor(baseColor);
     return hslColor.withSaturation(colorSaturation).toColor();
   }

   // 获取计算类型
   static DateCalculationType getCalculationTypeFromString(String typeStr) {
     switch (typeStr) {
       case 'fixedGregorian':
         return DateCalculationType.fixedGregorian;
       case 'fixedLunar':
         return DateCalculationType.fixedLunar;
       case 'nthWeekdayOfMonth':
         return DateCalculationType.nthWeekdayOfMonth;
       case 'solarTermBased':
         return DateCalculationType.solarTermBased;
       case 'relativeTo':
         return DateCalculationType.relativeTo;
       default:
         return DateCalculationType.fixedGregorian;
     }
   }

   // 获取重要性级别
   static ImportanceLevel getImportanceLevelFromString(String levelStr) {
     switch (levelStr) {
       case 'low':
         return ImportanceLevel.low;
       case 'medium':
         return ImportanceLevel.medium;
       case 'high':
         return ImportanceLevel.high;
       default:
         return ImportanceLevel.low;
     }
   }
}