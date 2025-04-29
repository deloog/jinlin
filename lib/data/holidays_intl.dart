import '../special_date.dart';
import 'package:flutter/material.dart';

// 国际节日和西方传统节日列表
List<SpecialDate> getInternationalHolidays(BuildContext context) {
  return [
    // --- 国际性节日 ---
    SpecialDate(
      id: 'INTL_NewYearDay',
      name: 'New Year\'s Day',
      type: SpecialDateType.statutory,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-01', // MM-DD
      description: 'New Year\'s Day marks the beginning of the new year in the Gregorian calendar. It is celebrated worldwide with various customs and traditions. Many cultures feature fireworks, parties, and special foods believed to bring luck in the coming year. In Scotland, the celebration is called "Hogmanay" with the tradition of "first-footing." In Spain, people eat 12 grapes at midnight - one for each stroke of the clock. The celebration of New Year\'s Day dates back over 4,000 years to ancient Babylon, making it one of the oldest holidays still observed today.',
    ),
    SpecialDate(
      id: 'INTL_ValentinesDay',
      name: 'Valentine\'s Day',
      type: SpecialDateType.traditional,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '02-14', // MM-DD
      description: 'Valentine\'s Day is celebrated on February 14th as a day dedicated to love and romance. Its origins are linked to several Christian martyrs named Valentine and was established as a feast day by Pope Gelasius I in 496 CE. The day became associated with romantic love in the 14th century, within the circle of Geoffrey Chaucer. Modern traditions include exchanging greeting cards (valentines), flowers (particularly roses), chocolates, and gifts between loved ones. It\'s also a popular day for marriage proposals. While primarily observed in Western countries, Valentine\'s Day has spread globally and is now celebrated in many parts of the world.',
    ),
    SpecialDate(
      id: 'INTL_EarthDay',
      name: 'Earth Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-22', // MM-DD
      description: 'Earth Day is an annual event celebrated on April 22nd to demonstrate support for environmental protection. It was first celebrated in 1970, and is now coordinated globally by the Earth Day Network and celebrated in more than 193 countries. The event was founded by U.S. Senator Gaylord Nelson after witnessing the devastating 1969 Santa Barbara oil spill. Earth Day aims to raise awareness about issues such as pollution, climate change, biodiversity loss, and other environmental concerns. Activities often include community clean-ups, tree planting, educational workshops, and advocacy campaigns. The 1990 Earth Day event helped boost recycling efforts globally, and the 2020 event marked its 50th anniversary with digital mobilizations due to the COVID-19 pandemic.',
    ),
    SpecialDate(
      id: 'INTL_LabourDay',
      name: 'Labour Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '05-01', // MM-DD
      description: 'A celebration of laborers and the working classes',
    ),
    SpecialDate(
      id: 'INTL_ChildrensDay',
      name: 'Children\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-01', // MM-DD
      description: 'A day to honor children',
    ),
    SpecialDate(
      id: 'INTL_WorldEnvironmentDay',
      name: 'World Environment Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-05', // MM-DD
      description: 'A day for encouraging awareness and action for the environment',
    ),
    SpecialDate(
      id: 'INTL_UNDay',
      name: 'United Nations Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-24', // MM-DD
      description: 'Anniversary of the UN Charter coming into force',
    ),
    SpecialDate(
      id: 'INTL_HumanRightsDay',
      name: 'Human Rights Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-10', // MM-DD
      description: 'Anniversary of the Universal Declaration of Human Rights',
    ),

    // --- 西方传统节日 ---
    SpecialDate(
      id: 'WEST_Easter',
      name: 'Easter',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '4,1,0', // 复活节计算比较复杂，这里简化为4月第一个周日
      description: 'Easter is one of the most important Christian festivals, celebrating the resurrection of Jesus Christ. The date varies each year, falling on the first Sunday after the full moon following the spring equinox (between March 22 and April 25). The holiday has both religious and secular traditions. Religious observances include special church services, while secular customs include Easter eggs (symbolizing new life), the Easter Bunny (a folklore figure who brings eggs to children), and Easter parades. Many of these traditions have roots in pre-Christian spring fertility celebrations. Easter is preceded by Lent, a 40-day period of fasting and reflection, and Holy Week, which includes Maundy Thursday, Good Friday, and Holy Saturday.',
    ),
    SpecialDate(
      id: 'WEST_GoodFriday',
      name: 'Good Friday',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.relativeTo,
      calculationRule: 'WEST_Easter,-2', // 复活节前两天
      description: 'Good Friday is a Christian observance commemorating the crucifixion of Jesus Christ and his death at Calvary. It is observed during Holy Week as part of the Paschal Triduum (the three days before Easter). The date varies each year, falling on the Friday before Easter. In many countries, it is a public holiday with solemn religious services. Traditional practices include fasting, prayer, and veneration of the cross. In some cultures, there are processions reenacting the Stations of the Cross. The name "Good Friday" may seem contradictory given the somber events it commemorates; the term "good" likely comes from an older meaning of the word as "holy" or from "God\'s Friday."',
    ),
    SpecialDate(
      id: 'WEST_StPatricksDay',
      name: 'St. Patrick\'s Day',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'IE', 'US'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-17', // MM-DD
      description: 'St. Patrick\'s Day is celebrated on March 17th, the traditional death date of Saint Patrick, the foremost patron saint of Ireland. Originally a religious feast day, it has evolved into a celebration of Irish culture and heritage. Saint Patrick lived in the 5th century and is credited with bringing Christianity to Ireland. Traditions include wearing green clothing (the color associated with Irish Catholics), displaying shamrocks (which Saint Patrick allegedly used to explain the Holy Trinity), and attending parades. The holiday is officially observed in Ireland, Northern Ireland, and the Canadian province of Newfoundland and Labrador, but is widely celebrated around the world, especially in countries with large Irish diaspora populations like the United States, Canada, and Australia.',
    ),
    SpecialDate(
      id: 'WEST_Halloween',
      name: 'Halloween',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-31', // MM-DD
      description: 'Halloween is celebrated on October 31st, the eve of the Western Christian feast of All Hallows\' Day (All Saints\' Day). Its roots date back to the ancient Celtic festival of Samhain, when people would light bonfires and wear costumes to ward off ghosts. In the 8th century, Pope Gregory III designated November 1 as a time to honor all saints, and the evening before became known as All Hallows\' Eve, later Halloween. Modern Halloween traditions include trick-or-treating (children in costumes going from house to house collecting candy), carving jack-o\'-lanterns from pumpkins, festive gatherings, wearing costumes, and telling scary stories. While most popular in North America and the British Isles, Halloween is now celebrated in many countries around the world.',
    ),
    SpecialDate(
      id: 'WEST_Thanksgiving',
      name: 'Thanksgiving',
      type: SpecialDateType.traditional,
      regions: ['US', 'WEST'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '11,4,4', // 11月第4个周四
      description: 'Thanksgiving is a national holiday celebrated primarily in the United States and Canada. In the U.S., it is observed on the fourth Thursday of November, while in Canada it falls on the second Monday of October. The holiday originated as a harvest festival, with the American tradition tracing back to a 1621 celebration at Plymouth, where the Pilgrims held a feast to thank Native Americans for helping them survive their first harsh winter. It became an official federal holiday in 1863 when President Abraham Lincoln proclaimed a national day of thanksgiving. Traditional Thanksgiving meals feature turkey, stuffing, cranberry sauce, and pumpkin pie. The holiday is also associated with family gatherings, parades (notably the Macy\'s Thanksgiving Day Parade in New York City), and American football games. The day after Thanksgiving, known as "Black Friday," marks the beginning of the Christmas shopping season.',
    ),
    SpecialDate(
      id: 'WEST_Christmas',
      name: 'Christmas',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-25', // MM-DD
      description: 'Christmas is celebrated on December 25th and commemorates the birth of Jesus Christ. While primarily a Christian festival, it is widely observed by many non-Christians as well. The date was chosen in the 4th century, possibly to coincide with the Roman winter solstice celebrations. Christmas traditions vary around the world but often include decorating Christmas trees, exchanging gifts, attending church services, sharing meals with family, and waiting for Santa Claus (derived from the historical figure of St. Nicholas) to bring presents. Other common symbols include nativity scenes, holly, mistletoe, and Christmas carols. The holiday season often extends from late November to early January and includes other celebrations like Advent and the Twelve Days of Christmas. In many countries, Christmas Eve (December 24th) is as important as Christmas Day itself.',
    ),
    SpecialDate(
      id: 'WEST_NewYearsEve',
      name: 'New Year\'s Eve',
      type: SpecialDateType.traditional,
      regions: ['WEST', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '12-31', // MM-DD
      description: 'New Year\'s Eve is celebrated on December 31st, the last day of the year in the Gregorian calendar. It marks the transition from one year to the next and is one of the most universally celebrated holidays. Traditions vary worldwide but typically include parties, fireworks, countdowns to midnight, and singing "Auld Lang Syne" (a Scottish poem set to music). Notable celebrations include the ball drop in New York\'s Times Square, fireworks at Sydney Harbour Bridge, and the chiming of Big Ben in London. Many cultures have specific New Year\'s Eve traditions believed to bring luck: in Spain, eating 12 grapes at midnight; in Denmark, breaking dishes on friends\' doorsteps; in Brazil, wearing white clothes and jumping seven waves. The holiday is often a time for reflection on the past year and making resolutions for the coming one.',
    ),

    // --- 家庭相关节日 ---
    SpecialDate(
      id: 'INTL_MothersDay',
      name: 'Mother\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '5,2,0', // 5月第2个周日
      description: 'A celebration honoring mothers',
    ),
    SpecialDate(
      id: 'INTL_FathersDay',
      name: 'Father\'s Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.nthWeekdayOfMonth,
      calculationRule: '6,3,0', // 6月第3个周日
      description: 'A celebration honoring fathers',
    ),

    // --- 国际纪念日 ---
    SpecialDate(
      id: 'INTL_WorldHealthDay',
      name: 'World Health Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-07', // MM-DD
      description: 'A global health awareness day celebrated every year on April 7',
    ),
    SpecialDate(
      id: 'INTL_WorldOceansDay',
      name: 'World Oceans Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '06-08', // MM-DD
      description: 'A day to celebrate the ocean and take action to protect it',
    ),
    SpecialDate(
      id: 'INTL_InternationalPeaceDay',
      name: 'International Day of Peace',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '09-21', // MM-DD
      description: 'A day devoted to strengthening the ideals of peace',
    ),
    SpecialDate(
      id: 'INTL_WorldTeachersDay',
      name: 'World Teachers\' Day',
      type: SpecialDateType.memorial,
      regions: ['INTL', 'ALL'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '10-05', // MM-DD
      description: 'A day celebrating teachers around the world',
    ),
  ];
}

// 根据地区获取节日列表
List<SpecialDate> getHolidaysForRegion(BuildContext context, String regionCode) {
  final holidays = getInternationalHolidays(context);
  return holidays.where((h) =>
    h.regions.contains(regionCode) ||
    h.regions.contains('ALL') ||
    (regionCode == 'INTL' && h.regions.contains('WEST'))
  ).toList();
}
