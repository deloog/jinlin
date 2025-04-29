import '../special_date.dart';
import 'package:flutter/material.dart';

// 中国地区预设的特殊日期列表
List<SpecialDate> getChineseHolidays(BuildContext context) {
  return [
    // --- 法定节假日 ---
    SpecialDate(
      id: 'CN_NewYearDay',
      name: '元旦',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-01', // MM-DD
      description: '元旦是公历新年的第一天，标志着新一年的开始。在中国，元旦成为法定节日始于1914年，是人们辞旧迎新、相互祝福的重要日子。传统上，人们会举行倒计时、烟花表演和家庭聚会来庆祝。',
    ),
    SpecialDate(
      id: 'CN_SpringFestival',
      name: '春节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '01-01L', // LMM-LDD (农历正月初一)
      description: '春节是中国最重要的传统节日，农历正月初一，象征着新的一年开始。有着超过4000年的历史，传统习俗包括贴春联、放鞭炮、舞龙舞狮、吃团圆饭和发红包等。春节期间，全国各地都有独特的庆祝方式，体现了中华民族深厚的文化底蕴和家庭团圆的核心价值观。',
      history: '春节的起源可以追溯到商朝（公元前1600年-公元前1046年），最初是祭祀祖先和神灵的仪式。到了汉代（公元前202年-公元220年），春节已成为重要的节日。唐宋时期（公元618年-公元1279年），春节庆祝活动更加丰富多彩，形成了许多至今仍在延续的传统习俗。明清时期（公元1368年-公元1912年），春节庆祝达到鼎盛，各种民俗活动广泛流行。如今，春节已成为中华文化的重要象征，也是全球华人共同的文化纽带。',
      customs: '贴春联：在门上贴红色的对联，象征好运和幸福\n放鞭炮：传统上认为噪音可以驱赶邪灵\n贴窗花：剪纸艺术，象征美好生活\n守岁：除夕夜全家团聚，等待新年到来\n拜年：向亲友长辈祝福新年\n舞龙舞狮：在街头表演，为新年带来好运',
      taboos: '打破物品：春节期间打破碗碟等物品被视为不吉利\n使用负面词语：如"死"、"破"、"完"等词语被认为会带来厄运\n在初一洗头发：民间认为会"洗掉"好运\n在初一打扫：被认为会"扫走"财运\n借钱给他人：被认为会导致全年都在借钱',
      foods: '饺子：形状像元宝，象征财富\n年糕：谐音"年高"，寓意步步高升\n鱼：谐音"余"，象征年年有余\n汤圆：圆形象征团圆\n长面：象征长寿\n八宝饭：多种食材混合，象征丰收和好运',
      greetings: '恭喜发财：祝愿对方财运亨通\n新年快乐：祝愿新的一年幸福快乐\n万事如意：祝愿一切顺利\n年年有余：祝愿生活富足\n福寿安康：祝愿健康长寿\n大吉大利：祝愿好运连连',
      activities: '逛庙会：参观传统集市，购买年货和小吃\n看春晚：观看中央电视台的新年晚会\n走亲访友：拜访亲友，互相祝福\n发红包：长辈给晚辈发装有钱的红色信封\n放烟花：庆祝新年的到来',
      imageUrl: 'https://img.freepik.com/free-vector/chinese-new-year-red-lantern-decoration_1017-33343.jpg',
    ),
    SpecialDate(
      id: 'CN_ChingMing',
      name: '清明节',
      type: SpecialDateType.statutory, // 也可算作 solarTerm
      regions: ['CN'],
      calculationType: DateCalculationType.solarTermBased, // 需要特殊计算
      calculationRule: 'QingMing', // 规则待定，可能需要查表或专用库
      description: '清明节是中国传统的重要节气和节日，通常在公历4月4日或5日，是祭祖和缅怀逝者的日子。源于周代的"寒食节"，距今已有2500多年历史。传统习俗包括扫墓、祭祀祖先、踏青郊游和放风筝等。清明也是农耕季节的开始，有"清明前后，种瓜点豆"的农谚。',
    ),
    SpecialDate(
      id: 'CN_LabourDay',
      name: '劳动节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-01', // MM-DD
      description: '劳动节源于19世纪美国芝加哥工人争取八小时工作制的运动，现已成为全球性节日。中国从1949年起将5月1日定为法定假日，以表彰劳动人民的贡献。这一天，各地会举办各种庆祝活动，如文艺演出、表彰先进工作者等，同时也是人们休闲旅游的黄金时期。',
    ),
    SpecialDate(
      id: 'CN_DragonBoatFestival',
      name: '端午节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '05-05L', // LMM-LDD
      description: '端午节在农历五月初五，是中国古老的传统节日，已有2000多年历史，2009年被列入世界非物质文化遗产。最初是为纪念战国时期爱国诗人屈原投江自尽。传统习俗包括赛龙舟、吃粽子、挂艾草和菖蒲、佩香囊等，具有驱邪避瘟、祈福纳祥的寓意。各地还有独特的庆祝方式，如北京的"斗百草"、广东的"龙舟竞渡"等。',
    ),
    SpecialDate(
      id: 'CN_MidAutumnFestival',
      name: '中秋节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '08-15L', // LMM-LDD
      description: '中秋节在农历八月十五，是中国仅次于春节的第二大传统节日，也被称为"团圆节"。起源于古代对月亮的崇拜和秋季丰收的庆祝，至少有3000年历史。这一天，人们会赏月、吃月饼、赏桂花、饮桂花酒等。中秋节象征着团圆和思念，海外游子尤其珍视这个节日。各地还有不同的庆祝方式，如广州的"舞火龙"、香港的"放孔明灯"等。',
      history: '中秋节的起源可以追溯到上古时期的祭月活动。周代（公元前1046年-公元前256年）已有秋天祭月的记载。汉代（公元前202年-公元220年）开始有了中秋赏月的习俗。到了唐代（公元618年-公元907年），中秋赏月已成为固定节日。宋代（公元960年-公元1279年）是中秋节发展的重要时期，"中秋"一词正式出现在文献中，赏月风俗更加普及。元代（公元1271年-公元1368年）开始有吃月饼的习俗。明清时期（公元1368年-公元1912年），中秋节庆祝活动达到鼎盛。',
      customs: '赏月：全家人一起观赏满月，象征团圆\n吃月饼：分享圆形的月饼，象征团圆和圆满\n点灯笼：挂起彩色灯笼装饰家园\n赏桂花：欣赏和品尝桂花及桂花制品\n祭月：摆设祭品，向月亮祈福\n猜灯谜：解答写在灯笼上的谜语',
      taboos: '将月饼切成两半：应该掰开分享，切开被认为不吉利\n在月下哭泣：被认为会带来厄运\n在月亮升起前吃月饼：传统上应等月亮升起后再享用\n对着月亮指指点点：被认为不敬重\n在中秋夜晚洗衣服：民间认为会冲犯月神',
      foods: '月饼：圆形象征团圆，各地有不同馅料\n桂花糕：用桂花制作的甜点\n芋头：中秋时节成熟的应季食物\n鸭子：中秋时节肥美，有"秋风起，吃鸭子"的说法\n柚子：谐音"佑子"，寓意保佑子孙\n螃蟹：中秋前后是品尝螃蟹的最佳时节',
      greetings: '中秋快乐：祝愿节日愉快\n月圆人圆事事圆：祝愿家庭团圆，事事圆满\n但愿人长久，千里共婵娟：引用苏轼《水调歌头》名句，表达思念之情\n花好月圆：祝愿生活美满\n月到中秋分外明：赞美中秋月色之美\n天涯共此时：表达虽然相隔遥远，但共享同一轮明月的情感',
      activities: '家庭聚餐：全家团聚共进晚餐\n赏月会：朋友聚会一起赏月\n放天灯：在一些地区，人们会放飞天灯\n舞火龙：广东地区特有的庆祝活动\n猜灯谜：解答灯笼上的谜语\n赏花灯：欣赏各种彩灯',
      imageUrl: 'https://img.freepik.com/free-vector/mid-autumn-festival-concept-illustration_114360-8220.jpg',
    ),
    SpecialDate(
      id: 'CN_NationalDay',
      name: '国庆节',
      type: SpecialDateType.statutory,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-01', // MM-DD
      description: '国庆节是庆祝中华人民共和国成立的重要节日，定于每年10月1日。1949年10月1日，毛泽东主席在北京天安门广场宣告中华人民共和国成立。每逢国庆，全国举行盛大庆典，包括阅兵式（逢十大庆）、升国旗仪式、文艺演出等。北京天安门广场是庆祝活动的中心，全国各地也会举行各种庆祝活动。国庆节也是"黄金周"假期，人们通常会旅游、探亲或参加各种文化活动。',
    ),

    // --- 传统节日 (示例) ---
    SpecialDate(
      id: 'CN_LanternFestival',
      name: '元宵节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '01-15L', // LMM-LDD
      description: '元宵节在农历正月十五，是春节后的第一个重要节日，也是中国传统新年庆祝活动的最后一天。起源于汉代，距今已有2000多年历史。这一天，人们会观赏彩灯、猜灯谜、吃元宵（汤圆）、舞龙舞狮等。元宵象征着团圆和祥和，各地有不同的庆祝方式，如南京的"秦淮灯会"、台湾的"平溪天灯节"等。元宵节也是中国传统的"上元节"，是一年中第一个月圆之夜。',
    ),
    SpecialDate(
      id: 'CN_DoubleSeventhFestival',
      name: '七夕节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '07-07L', // LMM-LDD
      description: '七夕节在农历七月初七，被誉为中国的"情人节"。源于牛郎织女的爱情传说，距今已有2000多年历史。传说每年这一天，喜鹊会在银河上搭桥，让分居两岸的牛郎织女相会。传统习俗包括女子"乞巧"（祈求灵巧的手艺）、穿针引线、晒书晒衣、观星等。现代人则多以送礼物、共进晚餐等方式庆祝。七夕也是中国传统的"七巧节"，体现了中国古代对爱情的美好向往和对技艺的追求。',
    ),
    SpecialDate(
      id: 'CN_DoubleNinthFestival',
      name: '重阳节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '09-09L', // LMM-LDD
      description: '重阳节在农历九月初九，因为"九九"谐音"久久"，象征长久，被赋予了敬老、祝寿的美好寓意。起源于战国时期，距今已有2500多年历史。2012年，重阳节被确定为中国法定的"老人节"。传统习俗包括登高望远、赏菊花、饮菊花酒、佩戴茱萸、吃重阳糕等。在现代社会，重阳节更多地体现为关爱老人、尊敬老人的节日，各地会举办敬老活动，子女也会回家看望父母长辈。',
    ),
    SpecialDate(
      id: 'CN_LabaFestival',
      name: '腊八节',
      type: SpecialDateType.traditional,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '12-08L', // LMM-LDD (农历腊月初八)
      description: '腊八节在农历腊月初八，是中国传统节日，也是佛教的重要节日。相传这一天是佛祖释迦牟尼成道之日，也是古代祭祀祖先和神灵的日子。最著名的习俗是喝腊八粥，这种粥通常由多种谷物、豆类、果仁和干果熬制而成，象征着丰收和福气。在北方地区，人们还有腌制腊八蒜的习俗。腊八节也标志着春节临近，人们开始准备年货和大扫除。在佛教寺院，这一天会举行"腊八施粥"活动，向民众免费施舍腊八粥。',
    ),

    // --- 纪念日 (示例) ---
    SpecialDate(
      id: 'CN_TreePlantingDay',
      name: '植树节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-12', // MM-DD
      description: '植树节在每年3月12日，是为了激发人们爱林、造林的热情而设立的节日。中国的植树节始于1979年，是为纪念孙中山先生逝世而确定的。这一天，全国各地都会组织植树活动，学校、企业和政府机构都会积极参与。中国有"谁知盘中餐，粒粒皆辛苦"的古训，植树节不仅是保护环境的实际行动，也是培养珍惜资源、热爱自然的意识。现在，植树造林已成为中国生态文明建设的重要组成部分，对改善环境、应对气候变化具有重要意义。',
    ),
    SpecialDate(
      id: 'CN_MothersDay',
      name: '母亲节',
      type: SpecialDateType.memorial, // 国际节日
      regions: ['CN', 'US', 'ALL'], // 可能适用多个地区
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '5,2,0', // 5月第2个周日 (0=周日)
      description: '母亲节在每年5月第二个星期日，是感谢母亲养育之恩的节日。起源于20世纪初的美国，现已成为全球性节日。1913年，美国国会通过决议，将每年5月第二个星期日定为母亲节；1914年，美国总统威尔逊签署法令，正式确立这一节日。中国从20世纪80年代开始逐渐流行过母亲节。这一天，人们会向母亲送花（尤其是康乃馨）、贺卡或礼物，陪伴母亲，表达感恩之情。母亲节提醒人们珍视亲情，感恩母爱的伟大和无私。',
    ),
    SpecialDate(
      id: 'CN_FathersDay',
      name: '父亲节',
      type: SpecialDateType.memorial, // 国际节日
      regions: ['CN', 'US', 'ALL'], // 可能适用多个地区
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '6,3,0', // 6月第3个周日 (0=周日)
      description: '父亲节在每年6月第三个星期日，是感谢父亲养育之恩的节日。起源于20世纪初的美国，由母亲节启发而来。1966年，美国总统约翰逊签署公告，将每年6月第三个星期日定为父亲节；1972年，尼克松总统签署法令，使其成为永久性国定假日。中国从20世纪80年代开始逐渐流行过父亲节。这一天，人们会向父亲送礼物（如领带、剃须刀等）、贺卡，或陪伴父亲，表达感恩之情。父亲节提醒人们感谢父亲的付出和责任担当，珍视父爱的坚韧与无私。',
    ),
  ];
}

// 根据地区获取节日列表
List<SpecialDate> getHolidaysForRegion(BuildContext context, String regionCode) {
  final holidays = getChineseHolidays(context);
  return holidays.where((h) => h.regions.contains(regionCode) || h.regions.contains('ALL')).toList();
}