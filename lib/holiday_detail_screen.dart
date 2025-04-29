import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';

class HolidayDetailScreen extends StatelessWidget {
  final SpecialDate holiday;
  final DateTime occurrenceDate;

  const HolidayDetailScreen({
    Key? key,
    required this.holiday,
    required this.occurrenceDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // 格式化公历日期
    final dateFormatter = DateFormat.yMMMMd(Localizations.localeOf(context).toString());
    final formattedDate = dateFormatter.format(occurrenceDate);

    // 计算农历日期（如果是农历节日）
    String? lunarDateString;
    if (holiday.calculationType == DateCalculationType.fixedLunar &&
        Localizations.localeOf(context).languageCode == 'zh') {
      try {
        final solar = Solar.fromDate(occurrenceDate);
        final lunar = solar.getLunar();
        lunarDateString = '${lunar.getYearInChinese()}年${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
      } catch (e) {
        debugPrint("Error formatting lunar date: $e");
      }
    }

    // 计算倒计时天数
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final holidayDate = DateTime(occurrenceDate.year, occurrenceDate.month, occurrenceDate.day);
    final daysRemaining = holidayDate.difference(today).inDays;

    String countdownText;
    if (daysRemaining == 0) {
      countdownText = l10n.today;
    } else if (daysRemaining == 1) {
      countdownText = l10n.tomorrow;
    } else if (daysRemaining > 0) {
      countdownText = l10n.daysRemaining(daysRemaining);
    } else {
      countdownText = l10n.daysAgo(daysRemaining.abs());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(holiday.name),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节日卡片
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期信息
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: theme.textTheme.titleMedium,
                              ),
                              if (lunarDateString != null)
                                Text(
                                  lunarDateString,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: daysRemaining == 0
                                ? Colors.red[100]
                                : daysRemaining > 0
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            countdownText,
                            style: TextStyle(
                              color: daysRemaining == 0
                                  ? Colors.red[800]
                                  : daysRemaining > 0
                                      ? Colors.blue[800]
                                      : Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // 节日类型
                    Row(
                      children: [
                        Icon(Icons.category, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          _getHolidayTypeText(holiday.type, l10n),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 节日区域
                    Row(
                      children: [
                        Icon(Icons.public, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          _getRegionsText(holiday.regions),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 节日描述标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.aboutHoliday,
                style: theme.textTheme.titleLarge,
              ),
            ),

            // 节日描述内容
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  holiday.description ?? '',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 节日习俗标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.holidayCustoms,
                style: theme.textTheme.titleLarge,
              ),
            ),

            // 节日习俗内容（这部分内容可以根据节日ID动态生成）
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getHolidayCustoms(holiday.id, l10n).map((custom) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(custom, style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取节日类型的本地化文本
  String _getHolidayTypeText(SpecialDateType type, AppLocalizations l10n) {
    switch (type) {
      case SpecialDateType.statutory:
        return l10n.statutoryHoliday;
      case SpecialDateType.traditional:
        return l10n.traditionalHoliday;
      case SpecialDateType.memorial:
        return l10n.memorialDay;
      case SpecialDateType.other:
        return l10n.otherHoliday;
      default:
        return l10n.holiday;
    }
  }

  // 获取节日区域的文本
  String _getRegionsText(List<String> regions) {
    if (regions.contains('ALL')) {
      return 'Worldwide';
    } else if (regions.contains('WEST')) {
      return 'Western Countries';
    } else if (regions.contains('CN')) {
      return 'China';
    } else if (regions.contains('JP')) {
      return 'Japan';
    } else if (regions.contains('KR')) {
      return 'Korea';
    } else if (regions.contains('IN')) {
      return 'India';
    } else {
      return regions.join(', ');
    }
  }

  // 根据节日ID获取习俗列表
  List<String> _getHolidayCustoms(String holidayId, AppLocalizations l10n) {
    // 这里可以根据节日ID返回相应的习俗列表
    // 为简化代码，这里只实现几个主要节日的习俗

    switch (holidayId) {
      case 'CN_SpringFestival':
        return [
          '贴春联：在门上贴红色的对联，象征好运和幸福',
          '放鞭炮：传统上认为噪音可以驱赶邪灵',
          '红包：长辈给晚辈发装有钱的红色信封',
          '年夜饭：除夕夜全家团聚共进晚餐',
          '守岁：除夕夜熬夜到新年',
        ];
      case 'CN_MidAutumnFestival':
        return [
          '赏月：全家人一起观赏满月',
          '吃月饼：分享圆形的月饼，象征团圆',
          '点灯笼：挂起彩色灯笼装饰',
          '猜灯谜：解答写在灯笼上的谜语',
        ];
      case 'WEST_Christmas':
        return [
          '装饰圣诞树：用彩灯、装饰品和礼物装饰常青树',
          '交换礼物：家人和朋友之间互赠礼物',
          '圣诞晚餐：家人共享传统的节日大餐',
          '圣诞颂歌：唱传统的圣诞歌曲',
          '圣诞老人：孩子们相信圣诞老人会在平安夜送来礼物',
        ];
      case 'INTL_NewYearDay':
        return [
          '倒计时：在午夜倒计时迎接新年',
          '新年决心：制定新年目标和计划',
          '烟花：放烟花庆祝新年',
          '新年派对：与亲友一起庆祝',
        ];
      case 'JP_Obon':
        return [
          '迎火：点燃迎接祖先灵魂的火',
          '送火：送祖先灵魂回去的火',
          '盂兰盆舞：传统舞蹈庆祝',
          '扫墓：清扫和装饰祖先坟墓',
          '供奉祭品：为祖先准备食物和礼物',
        ];
      case 'KR_Chuseok':
        return [
          '祭祖：举行祭祀仪式纪念祖先',
          '扫墓：清扫祖先坟墓',
          '松糕：制作和分享传统松糕',
          '民间游戏：参与传统游戏和活动',
          '穿韩服：穿着传统服装',
        ];
      case 'IN_Diwali':
        return [
          '点灯：点亮油灯和蜡烛',
          '兰戈利：在门前创作彩色图案',
          '礼物：交换礼物和甜食',
          '普佳：举行祈祷仪式',
          '烟花：放烟花庆祝',
        ];
      default:
        // 对于其他节日，返回通用的习俗描述
        return [
          l10n.genericCustom1,
          l10n.genericCustom2,
          l10n.genericCustom3,
        ];
    }
  }
}
