import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../special_date.dart';

// 特殊纪念日列表（国际纪念日、职业节日等）
List<SpecialDate> getSpecialDays(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final isChinese = l10n.localeName.startsWith('zh');
  return [
    // --- 国际纪念日 ---
    SpecialDate(
      id: 'INTL_WorldDanceDay',
      name: isChinese ? '世界舞蹈日' : 'World Dance Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-29', // 4月29日
      importanceLevel: ImportanceLevel.medium, // 中等重要性
      description: isChinese
        ? '世界舞蹈日，也称为国际舞蹈日，每年4月29日庆祝。它由国际戏剧协会（ITI）舞蹈委员会于1982年设立，ITI是联合国教科文组织表演艺术的主要合作伙伴。这一天纪念现代芭蕾舞的创始人让-乔治·诺维尔（1727-1810）的生日。世界舞蹈日旨在庆祝舞蹈作为一种艺术形式，并促进其跨越政治、文化和种族障碍的普遍语言。全球各地的活动包括舞蹈表演、工作坊、教育项目和社区聚会，展示各种舞蹈风格和传统。'
        : 'World Dance Day, also known as International Dance Day, is celebrated on April 29th each year. It was established in 1982 by the Dance Committee of the International Theatre Institute (ITI), the main partner for the performing arts of UNESCO. The date commemorates the birthday of Jean-Georges Noverre (1727-1810), the creator of modern ballet. The day aims to celebrate dance as an art form and to promote its universal language that crosses political, cultural, and ethnic barriers. Events worldwide include dance performances, workshops, educational programs, and community gatherings that highlight various dance styles and traditions.',
    ),
    SpecialDate(
      id: 'INTL_EarthDay',
      name: isChinese ? '世界地球日' : 'Earth Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-22', // 4月22日
      description: isChinese
        ? '世界地球日是每年4月22日举行的年度活动，旨在表达对环境保护的支持。它首次在1970年庆祝，现在由地球日网络在全球范围内协调，在193多个国家庆祝。该活动由美国参议员盖洛德·尼尔森在目睹1969年圣巴巴拉石油泄漏的灾难性后果后创立。世界地球日旨在提高人们对污染、气候变化、生物多样性丧失和其他环境问题的认识。活动通常包括社区清洁、植树、教育研讨会和宣传活动。'
        : 'Earth Day is an annual event celebrated on April 22nd to demonstrate support for environmental protection. It was first celebrated in 1970, and is now coordinated globally by the Earth Day Network and celebrated in more than 193 countries. The event was founded by U.S. Senator Gaylord Nelson after witnessing the devastating 1969 Santa Barbara oil spill. Earth Day aims to raise awareness about issues such as pollution, climate change, biodiversity loss, and other environmental concerns. Activities often include community clean-ups, tree planting, educational workshops, and advocacy campaigns.',
    ),
    SpecialDate(
      id: 'INTL_WorldHealthDay',
      name: isChinese ? '世界卫生日' : 'World Health Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-07', // 4月7日
      description: isChinese
        ? '世界卫生日是在世界卫生组织（WHO）和其他相关组织的赞助下，每年4月7日庆祝的全球健康意识日。这一天标志着世界卫生组织于1948年的成立。每年，该组织都会选择一个主题，突出世界公共卫生关注的优先领域。这一天提供了一个机会，动员人们围绕全球关注的特定健康主题采取行动。全球各地组织各种活动，强调健康和福祉的重要性。'
        : 'World Health Day is a global health awareness day celebrated every year on April 7th, under the sponsorship of the World Health Organization (WHO) and other related organizations. The day marks the founding of WHO in 1948. Each year, the organization selects a theme highlighting a priority area of public health concern in the world. The day provides an opportunity to mobilize action around specific health topics that concern people all over the world. Activities and events are organized worldwide to highlight the importance of health and well-being.',
    ),
    SpecialDate(
      id: 'INTL_WorldEnvironmentDay',
      name: isChinese ? '世界环境日' : 'World Environment Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-05', // 6月5日
      description: isChinese
        ? '世界环境日每年6月5日庆祝，是联合国鼓励环境保护意识和行动的主要平台。自1974年首次举办以来，它一直是提高人们对海洋污染、人口过剩、全球变暖、可持续消费和野生动物犯罪等环境问题意识的平台。每年，这一天都围绕一个主题组织，关注特别紧迫的环境问题，不同国家轮流主办主要庆祝活动。'
        : 'World Environment Day is celebrated on June 5th each year and is the United Nations\' principal vehicle for encouraging awareness and action for the protection of the environment. First held in 1974, it has been a platform for raising awareness on environmental issues such as marine pollution, human overpopulation, global warming, sustainable consumption, and wildlife crime. Each year, the day is organized around a theme that focuses attention on a particularly pressing environmental concern, with different countries hosting the main celebrations.',
    ),
    SpecialDate(
      id: 'INTL_InternationalWomensDay',
      name: isChinese ? '国际妇女节' : 'International Women\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-08', // 3月8日
      description: isChinese
        ? '国际妇女节每年3月8日庆祝。它是妇女权利和性别平等运动的焦点。这一天纪念妇女在社会、经济、文化和政治方面的成就，同时也标志着加速性别平等的行动呼吁。第一个国际妇女节于1911年举行，得到了超过一百万人的支持。今天，它属于全球所有群体，不特定于任何国家、群体或组织。这一天通过集会、会议、社交活动、游行和全球各种庆祝活动来纪念。'
        : 'International Women\'s Day is celebrated on March 8th every year. It is a focal point in the movement for women\'s rights and gender equality. The day commemorates the social, economic, cultural, and political achievements of women, while also marking a call to action for accelerating gender parity. The first International Women\'s Day was observed in 1911, supported by over a million people. Today, it belongs to all groups collectively everywhere and is not specific to any country, group, or organization. The day is marked by rallies, conferences, networking events, marches, and various celebrations worldwide.',
    ),
    SpecialDate(
      id: 'INTL_WorldAIDSDay',
      name: isChinese ? '世界艾滋病日' : 'World AIDS Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-01', // 12月1日
      description: isChinese
        ? '世界艾滋病日每年12月1日纪念，致力于提高人们对艾滋病疫情的认识，并悼念那些死于这种疾病的人。成立于1988年，它是第一个全球健康日。这一天为全世界人民提供了一个团结起来共同抗击艾滋病毒的机会，表达对艾滋病毒感染者的支持，并纪念那些死于艾滋病相关疾病的人。许多人佩戴红丝带，这是对艾滋病毒感染者的认识和支持的普遍象征。'
        : 'World AIDS Day, observed on December 1st each year, is dedicated to raising awareness about the AIDS pandemic caused by the spread of HIV infection, and to mourning those who have died from the disease. Founded in 1988, it was the first ever global health day. The day provides an opportunity for people worldwide to unite in the fight against HIV, to show support for people living with HIV, and to commemorate those who have died from AIDS-related illnesses. Many people wear a red ribbon, the universal symbol of awareness and support for people living with HIV.',
    ),
    SpecialDate(
      id: 'INTL_WorldOceansDay',
      name: isChinese ? '世界海洋日' : 'World Oceans Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-08', // 6月8日
      description: isChinese
        ? '世界海洋日每年6月8日庆祝。这一概念最初于1992年在巴西里约热内卢地球峰会上提出，并于2008年得到联合国的正式认可。这一天是提高全球对人类从海洋获得的益处的认识，以及我们个人和集体可持续利用其资源的责任的机会。这一天通过各种活动来纪念，包括海滩清理、教育项目、艺术比赛、电影节和可持续海鲜活动。'
        : 'World Oceans Day is celebrated on June 8th each year. The concept was originally proposed in 1992 at the Earth Summit in Rio de Janeiro, Brazil, and was officially recognized by the United Nations in 2008. The day is an opportunity to raise global awareness of the benefits humankind derives from the ocean and our individual and collective duty to use its resources sustainably. The day is marked by a variety of events, including beach cleanups, educational programs, art contests, film festivals, and sustainable seafood events.',
    ),

    // 添加更多国际组织认可的纪念日
    SpecialDate(
      id: 'INTL_WorldWaterDay',
      name: isChinese ? '世界水日' : 'World Water Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-22', // 3月22日
      description: isChinese
        ? '世界水日是联合国于1993年设立的国际纪念日，每年3月22日庆祝。这一天旨在强调淡水的重要性，倡导淡水资源的可持续管理。每年都有一个特定的主题，聚焦于水资源面临的不同挑战，如水污染、水资源短缺、气候变化对水资源的影响等。世界各地举行各种活动，包括教育研讨会、艺术展览、清洁水源活动等，以提高人们对水资源保护的意识。'
        : 'World Water Day is an international observance day established by the United Nations in 1993, celebrated on March 22nd each year. The day highlights the importance of freshwater and advocates for the sustainable management of freshwater resources. Each year has a specific theme focusing on different challenges related to water, such as water pollution, water scarcity, and the impact of climate change on water resources. Various events are held worldwide, including educational seminars, art exhibitions, and water source cleaning activities, to raise awareness about water conservation.',
    ),
    SpecialDate(
      id: 'INTL_WorldFoodDay',
      name: isChinese ? '世界粮食日' : 'World Food Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-16', // 10月16日
      description: isChinese
        ? '世界粮食日是联合国粮食及农业组织（FAO）于1979年设立的国际纪念日，每年10月16日庆祝，纪念该组织1945年成立。这一天旨在提高人们对全球粮食问题的认识，促进粮食安全和营养均衡的饮食。世界各地举行各种活动，包括食品展览、慈善募捐、教育研讨会等，以解决饥饿、营养不良和粮食浪费等问题。'
        : 'World Food Day is an international observance day established by the Food and Agriculture Organization (FAO) of the United Nations in 1979, celebrated on October 16th each year to commemorate the founding of the organization in 1945. The day aims to raise awareness about global food issues and promote food security and nutritionally balanced diets. Various events are held worldwide, including food exhibitions, charity fundraisers, and educational seminars, to address issues such as hunger, malnutrition, and food waste.',
    ),
    SpecialDate(
      id: 'INTL_WorldMentalHealthDay',
      name: isChinese ? '世界精神卫生日' : 'World Mental Health Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-10', // 10月10日
      description: isChinese
        ? '世界精神卫生日是世界卫生组织（WHO）于1992年设立的国际纪念日，每年10月10日庆祝。这一天旨在提高人们对精神健康问题的认识，消除与精神疾病相关的污名，促进精神健康服务的可及性。每年都有一个特定的主题，聚焦于精神健康的不同方面。世界各地举行各种活动，包括教育研讨会、艺术展览、慈善募捐等，以支持精神健康事业。'
        : 'World Mental Health Day is an international observance day established by the World Health Organization (WHO) in 1992, celebrated on October 10th each year. The day aims to raise awareness about mental health issues, reduce the stigma associated with mental illness, and promote access to mental health services. Each year has a specific theme focusing on different aspects of mental health. Various events are held worldwide, including educational seminars, art exhibitions, and charity fundraisers, to support mental health initiatives.',
    ),
    SpecialDate(
      id: 'INTL_InternationalDayOfPeace',
      name: isChinese ? '国际和平日' : 'International Day of Peace',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-21', // 9月21日
      description: isChinese
        ? '国际和平日是联合国于1981年设立的国际纪念日，每年9月21日庆祝。这一天旨在加强和平理念，促进国家间和人民间的和平。在这一天，联合国呼吁全球停火24小时，让人们有机会反思战争的影响，思考如何促进和平。世界各地举行各种活动，包括和平游行、教育研讨会、艺术展览等，以宣传和平理念。'
        : 'The International Day of Peace is an international observance day established by the United Nations in 1981, celebrated on September 21st each year. The day aims to strengthen the ideals of peace and promote peace among nations and peoples. On this day, the UN calls for a global ceasefire for 24 hours, giving people an opportunity to reflect on the impact of war and consider how to promote peace. Various events are held worldwide, including peace marches, educational seminars, and art exhibitions, to promote the ideals of peace.',
    ),
    SpecialDate(
      id: 'INTL_HumanRightsDay',
      name: isChinese ? '世界人权日' : 'Human Rights Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-10', // 12月10日
      description: isChinese
        ? '世界人权日是联合国于1948年设立的国际纪念日，每年12月10日庆祝，纪念《世界人权宣言》的通过。这一天旨在提高人们对人权的认识，促进人权保护。每年都有一个特定的主题，聚焦于人权的不同方面。世界各地举行各种活动，包括教育研讨会、艺术展览、人权奖颁发等，以宣传人权理念。'
        : 'Human Rights Day is an international observance day established by the United Nations in 1948, celebrated on December 10th each year to commemorate the adoption of the Universal Declaration of Human Rights. The day aims to raise awareness about human rights and promote their protection. Each year has a specific theme focusing on different aspects of human rights. Various events are held worldwide, including educational seminars, art exhibitions, and human rights awards ceremonies, to promote the ideals of human rights.',
    ),

    // --- 中国特殊纪念日 ---
    SpecialDate(
      id: 'CN_JournalistsDay',
      name: '记者节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-08', // 11月8日
      importanceLevel: ImportanceLevel.medium, // 中等重要性
      description: '中国记者节是为纪念中国新闻工作者而设立的节日，定于每年11月8日。这一天是为了表彰新闻工作者的贡献，促进新闻事业的发展。1999年8月，中国国务院批准将每年的11月8日定为记者节。选择这一天是因为1937年11月8日，中华全国新闻工作者协会在武汉成立。在记者节这一天，全国各地会举行各种活动，表彰优秀新闻工作者，研讨新闻事业的发展。',
    ),
    SpecialDate(
      id: 'CN_TeachersDay',
      name: '教师节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-10', // 9月10日
      importanceLevel: ImportanceLevel.high, // 高重要性
      description: '中国教师节是为了表彰教师的贡献而设立的节日，定于每年9月10日。这一天是为了提高教师的社会地位，促进教育事业的发展。1985年1月，中国第六届全国人大常委会第九次会议通过了国务院关于建立教师节的议案，决定将每年的9月10日定为教师节。在教师节这一天，学生们会向老师表达感谢和敬意，学校和社会各界也会举行各种活动，表彰优秀教师。',
    ),
    SpecialDate(
      id: 'CN_YouthDay',
      name: '青年节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-04', // 5月4日
      importanceLevel: ImportanceLevel.high, // 高重要性
      description: '五四青年节是中国青年的节日，定于每年5月4日，纪念1919年5月4日爆发的五四运动。五四运动是一场以青年学生为主的爱国运动，它促进了马克思主义在中国的传播，为中国共产党的成立做了思想上和干部上的准备。1939年，陕甘宁边区西北青年救国联合会规定5月4日为中国青年节。1949年12月，中央人民政府政务院正式宣布5月4日为中国青年节。在青年节这一天，全国各地会举行各种活动，表彰优秀青年，激励青年为国家建设贡献力量。',
    ),
    SpecialDate(
      id: 'CN_HarvestFestival',
      name: '中国农民丰收节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-23', // 秋分日
      description: '中国农民丰收节是为了表彰农民的贡献，展示农业发展成就而设立的节日，定于每年秋分日。这一天是为了弘扬中华农耕文明，繁荣农村文化，推进乡村振兴。2018年6月，中国国务院批准将每年秋分设立为中国农民丰收节。选择秋分这一天，是因为它处于农作物收获的季节，具有深厚的农耕文化内涵。在丰收节这一天，全国各地会举行各种庆祝活动，如农产品展示、民俗表演、农事体验等。',
    ),
    SpecialDate(
      id: 'CN_NursesDay',
      name: '护士节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-12', // 5月12日
      description: '国际护士节是为了纪念现代护理学创始人南丁格尔而设立的节日，定于每年5月12日（南丁格尔的生日）。中国于1913年开始纪念这一节日。护士节旨在表彰护士的贡献，提高护士的社会地位，促进护理事业的发展。在护士节这一天，医院和社会各界会举行各种活动，表彰优秀护士，宣传护理知识，促进护患关系和谐。',
    ),
    SpecialDate(
      id: 'CN_ChildrensDay',
      name: '儿童节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-01', // 6月1日
      importanceLevel: ImportanceLevel.high, // 高重要性
      description: '国际儿童节是为了保障世界各国儿童的权利和福利而设立的节日，定于每年6月1日。中国于1949年12月正式确定每年6月1日为儿童节。儿童节旨在引起人们对儿童健康、教育和福利的关注，促进儿童之间的国际友谊和相互了解。在儿童节这一天，学校和社会各界会举行各种活动，如文艺表演、游园活动、知识竞赛等，让儿童度过一个快乐的节日。',
    ),

    // --- 其他国家特殊纪念日 ---
    // 美国特殊纪念日
    SpecialDate(
      id: 'US_IndependenceDay',
      name: isChinese ? '美国独立日' : 'Independence Day',
      type: SpecialDateType.statutory,
      regions: ['US'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-04', // 7月4日
      importanceLevel: ImportanceLevel.high, // 高重要性
      description: isChinese
        ? '美国独立日，也称为七月四日，是美国联邦假日，纪念1776年7月4日通过的《独立宣言》。大陆会议宣布十三个美洲殖民地不再受英国君主统治，现在是团结、自由和独立的国家。这一天通常通过烟花、游行、烧烤、嘉年华、集市、野餐、音乐会、棒球比赛、家庭聚会、政治演讲和仪式来庆祝。这是美国各地爱国庆祝和家庭活动的日子。'
        : 'Independence Day, also known as the Fourth of July, is a federal holiday in the United States commemorating the Declaration of Independence, which was adopted on July 4, 1776. The Continental Congress declared that the thirteen American colonies were no longer subject to the monarch of Britain and were now united, free, and independent states. The day is typically celebrated with fireworks, parades, barbecues, carnivals, fairs, picnics, concerts, baseball games, family reunions, political speeches, and ceremonies. It is a day of patriotic celebration and family events throughout the United States.',
    ),
    SpecialDate(
      id: 'US_ThanksgivingDay',
      name: isChinese ? '美国感恩节' : 'Thanksgiving Day',
      type: SpecialDateType.statutory,
      regions: ['US'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '11,4,4', // 11月第4个星期四
      description: isChinese
        ? '美国感恩节是美国的重要节日，定于每年11月的第四个星期四。这一天源于早期欧洲移民与美洲原住民分享丰收的传统。现代感恩节是家人团聚的重要时刻，人们通常享用火鸡大餐，表达对生活中美好事物的感谢。这一天也标志着圣诞购物季的开始，次日的"黑色星期五"是美国最大的购物日。'
        : 'Thanksgiving Day is a significant holiday in the United States, observed on the fourth Thursday of November each year. The day originated from early European settlers sharing harvest with Native Americans. Modern Thanksgiving is an important time for family gatherings, where people typically enjoy a turkey dinner and express gratitude for the good things in life. The day also marks the beginning of the Christmas shopping season, with "Black Friday" the following day being the biggest shopping day in the U.S.',
    ),
    SpecialDate(
      id: 'US_MLKDay',
      name: isChinese ? '马丁·路德·金纪念日' : 'Martin Luther King Jr. Day',
      type: SpecialDateType.memorial,
      regions: ['US'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '1,3,1', // 1月第3个星期一
      description: isChinese
        ? '马丁·路德·金纪念日是美国联邦假日，定于每年1月的第三个星期一，纪念美国民权运动领袖马丁·路德·金博士。这一天旨在纪念金博士为争取种族平等和民权所做的贡献。许多美国人将这一天视为服务日，参与社区服务活动。学校和政府机构通常在这一天关闭，许多企业也会举行特别活动或提供特别优惠。'
        : 'Martin Luther King Jr. Day is a federal holiday in the United States observed on the third Monday of January each year, honoring the American civil rights leader Dr. Martin Luther King Jr. The day commemorates Dr. King\'s contributions to the struggle for racial equality and civil rights. Many Americans view this day as a day of service, participating in community service activities. Schools and government institutions are typically closed, and many businesses hold special events or offer special promotions.',
    ),

    // 英国特殊纪念日
    SpecialDate(
      id: 'UK_GuyFawkesNight',
      name: isChinese ? '盖伊·福克斯之夜' : 'Guy Fawkes Night',
      type: SpecialDateType.traditional,
      regions: ['UK'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-05', // 11月5日
      description: isChinese
        ? '盖伊·福克斯之夜，也称为篝火之夜，是英国每年11月5日举行的纪念活动。它标志着1605年火药阴谋的失败，当时一群天主教阴谋者，包括盖伊·福克斯，试图炸毁伦敦的国会大厦。当福克斯被发现守卫放置在上议院下方的炸药时，阴谋被挫败。这一天通过篝火、烟花和焚烧盖伊·福克斯的人偶来庆祝。传统食物包括太妃糖苹果、帕金（一种姜饼蛋糕）和在篝火灰烤制的土豆。'
        : 'Guy Fawkes Night, also known as Bonfire Night, is an annual commemoration observed on November 5th in the United Kingdom. It marks the failure of the Gunpowder Plot of 1605, when a group of Catholic conspirators, including Guy Fawkes, attempted to blow up the Houses of Parliament in London. The plot was foiled when Fawkes was discovered guarding explosives placed beneath the House of Lords. The day is celebrated with bonfires, fireworks, and the burning of effigies of Guy Fawkes. Traditional foods include toffee apples, parkin (a kind of gingerbread cake), and baked potatoes cooked in the bonfire ashes.',
    ),
    SpecialDate(
      id: 'UK_RemembranceDay',
      name: isChinese ? '英国阵亡将士纪念日' : 'Remembrance Day',
      type: SpecialDateType.memorial,
      regions: ['UK'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-11', // 11月11日
      description: isChinese
        ? '阵亡将士纪念日，也称为和平纪念日，是英国和英联邦国家每年11月11日举行的纪念活动，纪念在第一次世界大战和后续冲突中牺牲的军人。这一天选择在11月11日，因为第一次世界大战于1918年11月11日11时结束。人们通常会佩戴红色罂粟花，象征在战场上生长的罂粟花，并在11时保持两分钟的默哀。'
        : 'Remembrance Day, also known as Armistice Day, is observed on November 11th each year in the United Kingdom and Commonwealth countries to commemorate the servicemen and women who sacrificed their lives in World War I and subsequent conflicts. The day is observed on November 11th because World War I ended at 11 a.m. on that day in 1918. People typically wear red poppies, symbolizing the poppies that grew on the battlefields, and observe two minutes of silence at 11 a.m.',
    ),

    // 法国特殊纪念日
    SpecialDate(
      id: 'FR_BastilleDay',
      name: isChinese ? '法国国庆日' : 'Bastille Day',
      type: SpecialDateType.statutory,
      regions: ['FR'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-14', // 7月14日
      description: isChinese
        ? '法国国庆日，官方称为法国国庆节（Fête nationale），每年7月14日庆祝。它纪念1789年7月14日攻占巴士底狱，这是法国大革命的转折点，以及1790年7月14日庆祝法国人民团结的联邦节。这一天通过军事游行、烟花、音乐会和舞会来纪念。欧洲最大和最古老的军事游行在7月14日上午在巴黎香榭丽舍大街举行，共和国总统、法国官员和外国客人在场观看。'
        : 'Bastille Day, officially known as French National Day (Fête nationale), is celebrated on July 14th each year. It commemorates the Storming of the Bastille on July 14, 1789, a turning point of the French Revolution, as well as the Fête de la Fédération which celebrated the unity of the French people on July 14, 1790. The day is marked by military parades, fireworks, concerts, and balls. The largest and oldest military parade in Europe is held on the morning of July 14th on the Champs-Élysées in Paris in front of the President of the Republic, French officials, and foreign guests.',
    ),
    SpecialDate(
      id: 'FR_AllSaintsDay',
      name: isChinese ? '法国诸圣节' : 'All Saints\' Day',
      type: SpecialDateType.traditional,
      regions: ['FR'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-01', // 11月1日
      description: isChinese
        ? '诸圣节是法国的重要宗教节日，每年11月1日庆祝，是天主教和其他基督教会纪念所有圣人的节日。在法国，这一天是公共假日，人们通常会去墓地祭奠亲人，在墓碑上放置菊花。这一天也标志着冬季的开始，许多法国人会利用这个长周末（如果11月1日靠近周末）进行短途旅行。'
        : 'All Saints\' Day is an important religious holiday in France, celebrated on November 1st each year. It is a day when Catholics and other Christian denominations honor all saints. In France, it is a public holiday, and people typically visit cemeteries to pay respects to deceased family members, placing chrysanthemums on graves. The day also marks the beginning of winter, and many French people use the long weekend (if November 1st is close to a weekend) for short trips.',
    ),

    // 澳大利亚特殊纪念日
    SpecialDate(
      id: 'AU_AustraliaDay',
      name: isChinese ? '澳大利亚国庆日' : 'Australia Day',
      type: SpecialDateType.statutory,
      regions: ['AU'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-26', // 1月26日
      description: isChinese
        ? '澳大利亚国庆日是澳大利亚的官方国庆节，每年1月26日庆祝。它标志着1788年第一舰队英国船只抵达新南威尔士州杰克逊港，以及亚瑟·菲利普总督在悉尼湾升起大不列颠国旗的周年纪念。这一天是澳大利亚每个州和领地的官方公共假日，庆祝活动包括入籍仪式、颁奖典礼、社区节日、音乐会和烟花表演。然而，这个日期对一些澳大利亚人，特别是澳大利亚原住民来说也是有争议的，他们认为这标志着殖民化和剥夺的开始。'
        : 'Australia Day is the official national day of Australia, celebrated annually on January 26th. It marks the anniversary of the 1788 arrival of the First Fleet of British ships at Port Jackson, New South Wales, and the raising of the Flag of Great Britain at Sydney Cove by Governor Arthur Phillip. The day is an official public holiday in every state and territory of Australia, and celebrations include citizenship ceremonies, award presentations, community festivals, concerts, and fireworks. However, the date is also controversial for some Australians, particularly Indigenous Australians, who see it as marking the beginning of colonization and dispossession.',
    ),
    SpecialDate(
      id: 'AU_ANZACDay',
      name: isChinese ? '澳新军团日' : 'ANZAC Day',
      type: SpecialDateType.memorial,
      regions: ['AU', 'NZ'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-25', // 4月25日
      description: isChinese
        ? '澳新军团日是澳大利亚和新西兰每年4月25日举行的纪念活动，纪念在所有战争、冲突和维和行动中服役和牺牲的澳大利亚和新西兰军人。这一天选择在4月25日，因为这是1915年第一次世界大战期间澳新军团在加里波利登陆的日子。这一天通常以黎明仪式、游行和纪念活动来纪念，人们会佩戴罂粟花和迷迭香，象征纪念和不忘。'
        : 'ANZAC Day is observed on April 25th each year in Australia and New Zealand to commemorate all Australians and New Zealanders who served and died in all wars, conflicts, and peacekeeping operations. The day is chosen as it marks the anniversary of the landing of the Australian and New Zealand Army Corps (ANZAC) at Gallipoli during World War I in 1915. The day is typically commemorated with dawn services, parades, and memorial ceremonies, with people wearing poppies and rosemary as symbols of remembrance.',
    ),

    // 加拿大特殊纪念日
    SpecialDate(
      id: 'CA_CanadaDay',
      name: isChinese ? '加拿大国庆日' : 'Canada Day',
      type: SpecialDateType.statutory,
      regions: ['CA'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-01', // 7月1日
      description: isChinese
        ? '加拿大国庆日是加拿大的国庆节，每年7月1日庆祝。它纪念1867年7月1日《英属北美法案》（今称《宪法法案》）的颁布，该法案将加拿大省、新斯科舍省和新不伦瑞克省三个独立殖民地统一为英帝国内称为加拿大的单一自治领。最初称为自治领日，1982年《加拿大法案》通过后更名为加拿大国庆日。这一天通过游行、音乐会、烟花和入籍仪式来纪念。主要庆祝活动在首都渥太华举行，以及在各省首府和全国其他城镇举行。'
        : 'Canada Day is the national day of Canada, celebrated on July 1st each year. It commemorates the anniversary of the July 1, 1867, enactment of the British North America Act, 1867 (today called the Constitution Act, 1867), which united the three separate colonies of the Province of Canada, Nova Scotia, and New Brunswick into a single Dominion within the British Empire called Canada. Originally called Dominion Day, the holiday was renamed in 1982 when the Canada Act was passed. The day is marked by parades, concerts, fireworks, and citizenship ceremonies. Major celebrations take place in Ottawa, the national capital, as well as in provincial capitals and other cities and towns across the country.',
    ),
    SpecialDate(
      id: 'CA_ThanksgivingDay',
      name: isChinese ? '加拿大感恩节' : 'Canadian Thanksgiving',
      type: SpecialDateType.statutory,
      regions: ['CA'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '10,2,1', // 10月第2个星期一
      description: isChinese
        ? '加拿大感恩节是加拿大的法定假日，定于每年10月的第二个星期一。与美国感恩节类似，它是一个感谢丰收和祝福的节日。这一天，加拿大人通常会与家人团聚，享用传统的感恩节大餐，包括火鸡、南瓜派和其他应季食物。许多人也会利用这个长周末进行户外活动，欣赏加拿大美丽的秋色。'
        : 'Canadian Thanksgiving is a statutory holiday in Canada, observed on the second Monday of October each year. Similar to American Thanksgiving, it is a day of giving thanks for the harvest and blessings of the past year. On this day, Canadians typically gather with family for a traditional Thanksgiving dinner, which includes turkey, pumpkin pie, and other seasonal foods. Many people also use the long weekend for outdoor activities, enjoying Canada\'s beautiful fall colors.',
    ),



  ];
}

// 根据地区获取特殊纪念日列表
List<SpecialDate> getSpecialDaysForRegion(BuildContext context, String regionCode) {
  final specialDays = getSpecialDays(context);
  return specialDays.where((day) => day.regions.contains(regionCode) || day.regions.contains('ALL')).toList();
}
