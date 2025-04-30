import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:jinlin_app/widgets/card_icon.dart';

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
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CardIcon(
              icon: holiday.typeIcon,
              color: holiday.getHolidayColor(),
              size: 36.0,
            ),
          ),
        ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: holiday.getHolidayColor(),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 节日图标和类型
                    Row(
                      children: [
                        CardIcon(
                          icon: holiday.typeIcon,
                          color: holiday.getHolidayColor(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getHolidayTypeText(holiday.type, l10n),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: holiday.getHolidayColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),
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

                    // 节日区域
                    Row(
                      children: [
                        Icon(Icons.public, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getRegionsText(holiday.regions, l10n),
                            style: theme.textTheme.bodyLarge,
                          ),
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
                  isChinese
                      ? (holiday.description ?? '')
                      : (holiday.descriptionEn ?? holiday.description ?? ''),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 历史背景（如果有）
            if (holiday.history != null && holiday.history!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isChinese ? '历史背景' : 'History',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    holiday.history!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 节日习俗标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.holidayCustoms,
                style: theme.textTheme.titleLarge,
              ),
            ),

            // 节日习俗内容
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (holiday.customs != null && holiday.customs!.isNotEmpty)
                      ? _formatBulletPoints(holiday.customs!, theme.colorScheme.primary)
                      : _getHolidayCustoms(holiday.id, l10n).map((custom) {
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

            const SizedBox(height: 24),

            // 传统食物（如果有）
            if (holiday.foods != null && holiday.foods!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isChinese ? '传统食物' : 'Traditional Foods',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _formatBulletPoints(holiday.foods!, Colors.orange[700]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 传统活动（如果有）
            if (holiday.activities != null && holiday.activities!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isChinese ? '相关活动' : 'Activities',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _formatBulletPoints(holiday.activities!, Colors.green[700]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 传统问候语（如果有）
            if (holiday.greetings != null && holiday.greetings!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isChinese ? '传统问候语' : 'Traditional Greetings',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _formatBulletPoints(holiday.greetings!, Colors.blue[700]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 节日禁忌标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.holidayTaboos,
                style: theme.textTheme.titleLarge,
              ),
            ),

            // 节日禁忌内容
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (holiday.taboos != null && holiday.taboos!.isNotEmpty)
                      ? _formatBulletPoints(holiday.taboos!, Colors.red[700]!)
                      : _getHolidayTaboos(holiday.id, l10n).map((taboo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.do_not_disturb, size: 14, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(taboo, style: theme.textTheme.bodyMedium),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ),

            // 节日图片（如果有）
            if (holiday.imageUrl != null && holiday.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isChinese ? '节日图片' : 'Holiday Image',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      holiday.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.grey[600],
                              size: 48,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
      case SpecialDateType.solarTerm:
        return l10n.solarTerm;
      case SpecialDateType.other:
        return l10n.otherHoliday;
      case SpecialDateType.custom:
        return l10n.customEvent;
    }
  }

  // 获取节日区域的文本
  String _getRegionsText(List<String> regions, AppLocalizations l10n) {
    // 使用传入的 l10n 来判断语言环境
    final isChinese = l10n.localeName.startsWith('zh');

    if (regions.contains('ALL')) {
      return isChinese ? '全球' : 'Worldwide';
    } else if (regions.contains('WEST')) {
      return isChinese ? '西方国家' : 'Western Countries';
    } else if (regions.contains('CN')) {
      return isChinese ? '中国' : 'China';
    } else if (regions.contains('JP')) {
      return isChinese ? '日本' : 'Japan';
    } else if (regions.contains('KR')) {
      return isChinese ? '韩国' : 'Korea';
    } else if (regions.contains('IN')) {
      return isChinese ? '印度' : 'India';
    } else {
      return regions.join(', ');
    }
  }

  // 根据节日ID获取习俗列表
  List<String> _getHolidayCustoms(String holidayId, AppLocalizations l10n) {
    // 获取当前语言环境
    final isChinese = l10n.localeName.startsWith('zh');

    // 这里可以根据节日ID返回相应的习俗列表
    // 为简化代码，这里只实现几个主要节日的习俗

    switch (holidayId) {
      case 'CN_SpringFestival':
        return isChinese ? [
          '贴春联：在门上贴红色的对联，象征好运和幸福',
          '放鞭炮：传统上认为噪音可以驱赶邪灵',
          '红包：长辈给晚辈发装有钱的红色信封',
          '年夜饭：除夕夜全家团聚共进晚餐',
          '守岁：除夕夜熬夜到新年',
        ] : [
          'Spring Couplets: Pasting red couplets on doors for good luck',
          'Firecrackers: Traditionally believed to drive away evil spirits',
          'Red Envelopes: Elders give money in red envelopes to younger family members',
          'Reunion Dinner: Family gathering on New Year\'s Eve',
          'Staying Up: Staying awake until midnight to welcome the new year',
        ];
      case 'CN_MidAutumnFestival':
        return isChinese ? [
          '赏月：全家人一起观赏满月',
          '吃月饼：分享圆形的月饼，象征团圆',
          '点灯笼：挂起彩色灯笼装饰',
          '猜灯谜：解答写在灯笼上的谜语',
        ] : [
          'Moon Gazing: Families gather to appreciate the full moon',
          'Mooncakes: Sharing round mooncakes symbolizing reunion',
          'Lanterns: Hanging colorful lanterns for decoration',
          'Riddles: Solving riddles written on lanterns',
        ];
      case 'WEST_Christmas':
        return isChinese ? [
          '装饰圣诞树：用彩灯、装饰品和礼物装饰常青树',
          '交换礼物：家人和朋友之间互赠礼物',
          '圣诞晚餐：家人共享传统的节日大餐',
          '圣诞颂歌：唱传统的圣诞歌曲',
          '圣诞老人：孩子们相信圣诞老人会在平安夜送来礼物',
        ] : [
          'Christmas Tree: Decorating evergreen trees with lights and ornaments',
          'Gift Exchange: Sharing presents with family and friends',
          'Christmas Dinner: Enjoying a traditional feast with family',
          'Christmas Carols: Singing traditional holiday songs',
          'Santa Claus: Children believe Santa brings gifts on Christmas Eve',
        ];
      case 'INTL_NewYearDay':
        return isChinese ? [
          '倒计时：在午夜倒计时迎接新年',
          '新年决心：制定新年目标和计划',
          '烟花：放烟花庆祝新年',
          '新年派对：与亲友一起庆祝',
        ] : [
          'Countdown: Counting down to midnight to welcome the new year',
          'New Year Resolutions: Setting goals and plans for the new year',
          'Fireworks: Celebrating with fireworks displays',
          'New Year Parties: Celebrating with family and friends',
        ];
      case 'JP_Obon':
        return isChinese ? [
          '迎火：点燃迎接祖先灵魂的火',
          '送火：送祖先灵魂回去的火',
          '盂兰盆舞：传统舞蹈庆祝',
          '扫墓：清扫和装饰祖先坟墓',
          '供奉祭品：为祖先准备食物和礼物',
        ] : [
          'Mukaebi: Lighting welcoming fires to guide ancestors\' spirits home',
          'Okuribi: Lighting farewell fires to send ancestors\' spirits back',
          'Bon Odori: Traditional dance celebrations',
          'Grave Visits: Cleaning and decorating ancestors\' graves',
          'Offerings: Preparing food and gifts for ancestors',
        ];
      case 'KR_Chuseok':
        return isChinese ? [
          '祭祖：举行祭祀仪式纪念祖先',
          '扫墓：清扫祖先坟墓',
          '松糕：制作和分享传统松糕',
          '民间游戏：参与传统游戏和活动',
          '穿韩服：穿着传统服装',
        ] : [
          'Charye: Performing ancestral memorial ceremonies',
          'Seongmyo: Visiting and cleaning ancestors\' graves',
          'Songpyeon: Making and sharing traditional rice cakes',
          'Folk Games: Participating in traditional games and activities',
          'Hanbok: Wearing traditional Korean clothing',
        ];
      case 'IN_Diwali':
        return isChinese ? [
          '点灯：点亮油灯和蜡烛',
          '兰戈利：在门前创作彩色图案',
          '礼物：交换礼物和甜食',
          '普佳：举行祈祷仪式',
          '烟花：放烟花庆祝',
        ] : [
          'Lighting Diyas: Illuminating oil lamps and candles',
          'Rangoli: Creating colorful patterns at entrances',
          'Gifts: Exchanging presents and sweets',
          'Puja: Performing prayer ceremonies',
          'Fireworks: Celebrating with fireworks displays',
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

  // 格式化项目符号列表
  List<Widget> _formatBulletPoints(String content, Color bulletColor) {
    // 将内容按换行符分割成列表
    final List<String> items = content.split('\n')
        .where((item) => item.trim().isNotEmpty)
        .toList();

    // 为每个项目创建带项目符号的行
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 10, color: bulletColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.trim(), style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }).toList();
  }

  // 根据节日ID获取禁忌列表
  List<String> _getHolidayTaboos(String holidayId, AppLocalizations l10n) {
    // 获取当前语言环境
    final isChinese = l10n.localeName.startsWith('zh');

    // 这里可以根据节日ID返回相应的禁忌列表
    switch (holidayId) {
      case 'CN_SpringFestival':
        return isChinese ? [
          '避免打破物品：春节期间打破碗碟等物品被视为不吉利',
          '避免使用负面词语：如"死"、"破"、"完"等词语被认为会带来厄运',
          '避免在初一洗头发：民间认为会"洗掉"好运',
          '避免在初一打扫：被认为会"扫走"财运',
          '避免借钱给他人：被认为会导致全年都在借钱',
        ] : [
          'Avoid breaking things: Breaking dishes during Spring Festival is considered unlucky',
          'Avoid negative words: Words like "death" or "broken" are believed to bring bad luck',
          'Avoid washing hair on the first day: Believed to wash away good fortune',
          'Avoid sweeping on the first day: Believed to sweep away wealth',
          'Avoid lending money: Believed to lead to lending money all year',
        ];
      case 'CN_QingMing':
        return isChinese ? [
          '避免穿鲜艳的衣服：扫墓时应穿素色衣服以示尊重',
          '避免在祭祀时说不吉利的话：如"再见"等',
          '避免在雨天扫墓：民间认为会影响逝者安宁',
          '避免空手而归：应带一些土或树叶回家，象征带回好运',
        ] : [
          'Avoid bright clothing: Wear subdued colors when visiting graves as a sign of respect',
          'Avoid unlucky phrases: Don\'t say words like "goodbye" during ceremonies',
          'Avoid tomb sweeping in the rain: Believed to disturb the peace of the deceased',
          'Avoid returning empty-handed: Bring some soil or leaves home to symbolize bringing back good fortune',
        ];
      case 'CN_DragonBoatFestival':
        return isChinese ? [
          '避免在水中游泳：民间认为这一天水中的龙会捉人',
          '避免晒衣服：被认为会招来不幸',
          '避免午睡：被认为会导致疾病',
        ] : [
          'Avoid swimming: Folk belief says dragons in the water may catch people on this day',
          'Avoid hanging clothes to dry: Believed to bring misfortune',
          'Avoid napping at noon: Believed to cause illness',
        ];
      case 'CN_MidAutumnFestival':
        return isChinese ? [
          '避免将月饼切成两半：应该掰开分享，切开被认为不吉利',
          '避免在月下哭泣：被认为会带来厄运',
          '避免在月亮升起前吃月饼：传统上应等月亮升起后再享用',
        ] : [
          'Avoid cutting mooncakes in half: They should be broken by hand, as cutting is considered unlucky',
          'Avoid crying under the moon: Believed to bring bad luck',
          'Avoid eating mooncakes before moonrise: Traditionally, one should wait until the moon rises',
        ];
      case 'JP_NewYear':
        return isChinese ? [
          '避免打扫：日本新年前三天不应打扫，以免"扫走"好运',
          '避免使用刀具：被认为会"切断"好运',
          '避免在新年说负面词语：如"死"、"分离"等',
        ] : [
          'Avoid cleaning: No cleaning for the first three days to avoid sweeping away good fortune',
          'Avoid using knives: Believed to "cut off" good luck',
          'Avoid negative words: Words like "death" or "separation" should not be spoken',
        ];
      case 'JP_Obon':
        return isChinese ? [
          '避免在盂兰盆节期间举行婚礼：被认为不吉利',
          '避免在这段时间游泳：民间认为祖先的灵魂可能会将人拉入水中',
          '避免在祭坛前拍照：被认为不尊重祖先',
          '避免在送火时回头看：民间认为会带来厄运',
        ] : [
          'Avoid weddings during Obon: Considered unlucky',
          'Avoid swimming during this period: Folk belief says ancestors\' spirits may pull people into water',
          'Avoid taking photos at altars: Considered disrespectful to ancestors',
          'Avoid looking back during Okuribi: Folk belief says it brings bad luck',
        ];
      case 'KR_Chuseok':
        return isChinese ? [
          '避免穿鲜艳的衣服：祭祀时应穿素色衣服',
          '避免空手拜访亲友：应带礼物表示尊重',
          '避免在祭祀时说不吉利的话',
        ] : [
          'Avoid bright clothing: Wear subdued colors during ceremonies',
          'Avoid visiting relatives empty-handed: Bring gifts as a sign of respect',
          'Avoid saying unlucky words during ceremonies',
        ];
      case 'IN_Diwali':
        return isChinese ? [
          '避免在排灯节当天打扫：被认为会"扫走"财神',
          '避免在这一天借钱或还钱：被认为会影响财运',
          '避免穿黑色或白色衣服：这些颜色在印度文化中与丧事相关',
          '避免在排灯节期间剪头发或指甲：被认为不吉利',
        ] : [
          'Avoid cleaning on Diwali day: Believed to "sweep away" the goddess of wealth',
          'Avoid lending or repaying money on this day: Believed to affect financial fortune',
          'Avoid wearing black or white clothes: These colors are associated with mourning in Indian culture',
          'Avoid cutting hair or nails during Diwali: Considered unlucky',
        ];
      case 'WEST_Christmas':
        return isChinese ? [
          '避免在圣诞节取下装饰：传统上应在1月6日（主显节）之后才取下',
          '避免送尖锐的礼物：如刀具，被认为会"切断"关系',
          '避免在圣诞树下放空礼物盒：被认为会带来一年的失望',
        ] : [
          'Avoid taking down decorations on Christmas: Traditionally should be left until after January 6 (Epiphany)',
          'Avoid giving sharp gifts: Items like knives are believed to "cut" relationships',
          'Avoid empty gift boxes under the tree: Believed to bring a year of disappointment',
        ];
      default:
        // 对于其他节日，返回通用的禁忌描述
        return [
          l10n.genericTaboo1,
          l10n.genericTaboo2,
          l10n.genericTaboo3,
        ];
    }
  }
}
