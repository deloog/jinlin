import 'package:flutter/material.dart';
import '../special_date.dart';

// 特殊纪念日列表（国际纪念日、职业节日等）
List<SpecialDate> getSpecialDays(BuildContext context) {
  return [
    // --- 国际纪念日 ---
    SpecialDate(
      id: 'INTL_WorldDanceDay',
      name: 'World Dance Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-29', // 4月29日
      description: 'World Dance Day, also known as International Dance Day, is celebrated on April 29th each year. It was established in 1982 by the Dance Committee of the International Theatre Institute (ITI), the main partner for the performing arts of UNESCO. The date commemorates the birthday of Jean-Georges Noverre (1727-1810), the creator of modern ballet. The day aims to celebrate dance as an art form and to promote its universal language that crosses political, cultural, and ethnic barriers. Events worldwide include dance performances, workshops, educational programs, and community gatherings that highlight various dance styles and traditions.',
    ),
    SpecialDate(
      id: 'INTL_EarthDay',
      name: 'Earth Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-22', // 4月22日
      description: 'Earth Day is an annual event celebrated on April 22nd to demonstrate support for environmental protection. It was first celebrated in 1970, and is now coordinated globally by the Earth Day Network and celebrated in more than 193 countries. The event was founded by U.S. Senator Gaylord Nelson after witnessing the devastating 1969 Santa Barbara oil spill. Earth Day aims to raise awareness about issues such as pollution, climate change, biodiversity loss, and other environmental concerns. Activities often include community clean-ups, tree planting, educational workshops, and advocacy campaigns.',
    ),
    SpecialDate(
      id: 'INTL_WorldHealthDay',
      name: 'World Health Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-07', // 4月7日
      description: 'World Health Day is a global health awareness day celebrated every year on April 7th, under the sponsorship of the World Health Organization (WHO) and other related organizations. The day marks the founding of WHO in 1948. Each year, the organization selects a theme highlighting a priority area of public health concern in the world. The day provides an opportunity to mobilize action around specific health topics that concern people all over the world. Activities and events are organized worldwide to highlight the importance of health and well-being.',
    ),
    SpecialDate(
      id: 'INTL_WorldEnvironmentDay',
      name: 'World Environment Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-05', // 6月5日
      description: 'World Environment Day is celebrated on June 5th each year and is the United Nations\' principal vehicle for encouraging awareness and action for the protection of the environment. First held in 1974, it has been a platform for raising awareness on environmental issues such as marine pollution, human overpopulation, global warming, sustainable consumption, and wildlife crime. Each year, the day is organized around a theme that focuses attention on a particularly pressing environmental concern, with different countries hosting the main celebrations.',
    ),
    SpecialDate(
      id: 'INTL_InternationalWomensDay',
      name: 'International Women\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-08', // 3月8日
      description: 'International Women\'s Day is celebrated on March 8th every year. It is a focal point in the movement for women\'s rights and gender equality. The day commemorates the social, economic, cultural, and political achievements of women, while also marking a call to action for accelerating gender parity. The first International Women\'s Day was observed in 1911, supported by over a million people. Today, it belongs to all groups collectively everywhere and is not specific to any country, group, or organization. The day is marked by rallies, conferences, networking events, marches, and various celebrations worldwide.',
    ),
    SpecialDate(
      id: 'INTL_WorldAIDSDay',
      name: 'World AIDS Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-01', // 12月1日
      description: 'World AIDS Day, observed on December 1st each year, is dedicated to raising awareness about the AIDS pandemic caused by the spread of HIV infection, and to mourning those who have died from the disease. Founded in 1988, it was the first ever global health day. The day provides an opportunity for people worldwide to unite in the fight against HIV, to show support for people living with HIV, and to commemorate those who have died from AIDS-related illnesses. Many people wear a red ribbon, the universal symbol of awareness and support for people living with HIV.',
    ),
    SpecialDate(
      id: 'INTL_WorldOceansDay',
      name: 'World Oceans Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-08', // 6月8日
      description: 'World Oceans Day is celebrated on June 8th each year. The concept was originally proposed in 1992 at the Earth Summit in Rio de Janeiro, Brazil, and was officially recognized by the United Nations in 2008. The day is an opportunity to raise global awareness of the benefits humankind derives from the ocean and our individual and collective duty to use its resources sustainably. The day is marked by a variety of events, including beach cleanups, educational programs, art contests, film festivals, and sustainable seafood events.',
    ),
    
    // --- 中国特殊纪念日 ---
    SpecialDate(
      id: 'CN_JournalistsDay',
      name: '记者节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-08', // 11月8日
      description: '中国记者节是为纪念中国新闻工作者而设立的节日，定于每年11月8日。这一天是为了表彰新闻工作者的贡献，促进新闻事业的发展。1999年8月，中国国务院批准将每年的11月8日定为记者节。选择这一天是因为1937年11月8日，中华全国新闻工作者协会在武汉成立。在记者节这一天，全国各地会举行各种活动，表彰优秀新闻工作者，研讨新闻事业的发展。',
    ),
    SpecialDate(
      id: 'CN_TeachersDay',
      name: '教师节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-10', // 9月10日
      description: '中国教师节是为了表彰教师的贡献而设立的节日，定于每年9月10日。这一天是为了提高教师的社会地位，促进教育事业的发展。1985年1月，中国第六届全国人大常委会第九次会议通过了国务院关于建立教师节的议案，决定将每年的9月10日定为教师节。在教师节这一天，学生们会向老师表达感谢和敬意，学校和社会各界也会举行各种活动，表彰优秀教师。',
    ),
    SpecialDate(
      id: 'CN_YouthDay',
      name: '青年节',
      type: SpecialDateType.memorial,
      regions: ['CN'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-04', // 5月4日
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
      description: '国际儿童节是为了保障世界各国儿童的权利和福利而设立的节日，定于每年6月1日。中国于1949年12月正式确定每年6月1日为儿童节。儿童节旨在引起人们对儿童健康、教育和福利的关注，促进儿童之间的国际友谊和相互了解。在儿童节这一天，学校和社会各界会举行各种活动，如文艺表演、游园活动、知识竞赛等，让儿童度过一个快乐的节日。',
    ),
    
    // --- 其他国家特殊纪念日 ---
    SpecialDate(
      id: 'US_IndependenceDay',
      name: 'Independence Day',
      type: SpecialDateType.statutory,
      regions: ['US'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-04', // 7月4日
      description: 'Independence Day, also known as the Fourth of July, is a federal holiday in the United States commemorating the Declaration of Independence, which was adopted on July 4, 1776. The Continental Congress declared that the thirteen American colonies were no longer subject to the monarch of Britain and were now united, free, and independent states. The day is typically celebrated with fireworks, parades, barbecues, carnivals, fairs, picnics, concerts, baseball games, family reunions, political speeches, and ceremonies. It is a day of patriotic celebration and family events throughout the United States.',
    ),
    SpecialDate(
      id: 'UK_GuyFawkesNight',
      name: 'Guy Fawkes Night',
      type: SpecialDateType.traditional,
      regions: ['UK'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-05', // 11月5日
      description: 'Guy Fawkes Night, also known as Bonfire Night, is an annual commemoration observed on November 5th in the United Kingdom. It marks the failure of the Gunpowder Plot of 1605, when a group of Catholic conspirators, including Guy Fawkes, attempted to blow up the Houses of Parliament in London. The plot was foiled when Fawkes was discovered guarding explosives placed beneath the House of Lords. The day is celebrated with bonfires, fireworks, and the burning of effigies of Guy Fawkes. Traditional foods include toffee apples, parkin (a kind of gingerbread cake), and baked potatoes cooked in the bonfire ashes.',
    ),
    SpecialDate(
      id: 'FR_BastilleDay',
      name: 'Bastille Day',
      type: SpecialDateType.statutory,
      regions: ['FR'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-14', // 7月14日
      description: 'Bastille Day, officially known as French National Day (Fête nationale), is celebrated on July 14th each year. It commemorates the Storming of the Bastille on July 14, 1789, a turning point of the French Revolution, as well as the Fête de la Fédération which celebrated the unity of the French people on July 14, 1790. The day is marked by military parades, fireworks, concerts, and balls. The largest and oldest military parade in Europe is held on the morning of July 14th on the Champs-Élysées in Paris in front of the President of the Republic, French officials, and foreign guests.',
    ),
    SpecialDate(
      id: 'AU_AustraliaDay',
      name: 'Australia Day',
      type: SpecialDateType.statutory,
      regions: ['AU'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-26', // 1月26日
      description: 'Australia Day is the official national day of Australia, celebrated annually on January 26th. It marks the anniversary of the 1788 arrival of the First Fleet of British ships at Port Jackson, New South Wales, and the raising of the Flag of Great Britain at Sydney Cove by Governor Arthur Phillip. The day is an official public holiday in every state and territory of Australia, and celebrations include citizenship ceremonies, award presentations, community festivals, concerts, and fireworks. However, the date is also controversial for some Australians, particularly Indigenous Australians, who see it as marking the beginning of colonization and dispossession.',
    ),
    SpecialDate(
      id: 'CA_CanadaDay',
      name: 'Canada Day',
      type: SpecialDateType.statutory,
      regions: ['CA'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-01', // 7月1日
      description: 'Canada Day is the national day of Canada, celebrated on July 1st each year. It commemorates the anniversary of the July 1, 1867, enactment of the British North America Act, 1867 (today called the Constitution Act, 1867), which united the three separate colonies of the Province of Canada, Nova Scotia, and New Brunswick into a single Dominion within the British Empire called Canada. Originally called Dominion Day, the holiday was renamed in 1982 when the Canada Act was passed. The day is marked by parades, concerts, fireworks, and citizenship ceremonies. Major celebrations take place in Ottawa, the national capital, as well as in provincial capitals and other cities and towns across the country.',
    ),
  ];
}

// 根据地区获取特殊纪念日列表
List<SpecialDate> getSpecialDaysForRegion(BuildContext context, String regionCode) {
  final specialDays = getSpecialDays(context);
  return specialDays.where((day) => day.regions.contains(regionCode) || day.regions.contains('ALL')).toList();
}
