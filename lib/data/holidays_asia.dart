import '../special_date.dart';
import 'package:flutter/material.dart';

// 亚洲地区节日列表（日本、韩国、印度等）
List<SpecialDate> getAsianHolidays(BuildContext context) {
  return [
    // --- 日本节日 ---
    SpecialDate(
      id: 'JP_NewYear',
      name: '正月',
      type: SpecialDateType.statutory,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '01-01', // MM-DD
      description: '正月（Shōgatsu）是日本最重要的节日，庆祝新年的到来。庆祝活动通常从1月1日持续到1月3日，这段时间被称为"三が日"（San ga nichi）。传统习俗包括参拜神社（初詣/Hatsumōde）、吃特殊的新年料理（おせち/Osechi）、给孩子发压岁钱（お年玉/Otoshidama）等。日本人通常会在新年前大扫除（大掃除/Ōsōji），以干净的状态迎接新年。新年期间，人们会互相问候"明けましておめでとうございます"（Akemashite omedetō gozaimasu），意为"新年快乐"。',
    ),
    SpecialDate(
      id: 'JP_SetuBun',
      name: '節分',
      type: SpecialDateType.traditional,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '02-03', // MM-DD
      description: '節分（Setsubun）字面意思是"季节分隔"，传统上标志着冬季结束和春季开始。在日本传统历法中，它是立春前一天。最著名的习俗是"豆まき"（Mamemaki），即撒豆驱鬼，人们会一边撒豆子一边喊"鬼は外、福は内"（Oni wa soto, fuku wa uchi），意为"鬼出去，福进来"。另一个现代习俗是吃"恵方巻"（Ehōmaki），一种特殊的寿司卷，人们面朝当年的吉祥方向（恵方/Ehō）一口气吃完，不说话，以求好运。',
    ),
    SpecialDate(
      id: 'JP_Hinamatsuri',
      name: 'ひな祭り',
      type: SpecialDateType.traditional,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '03-03', // MM-DD
      description: 'ひな祭り（Hinamatsuri），又称女儿节或人偶节，是日本的传统节日，在每年3月3日庆祝。这一天，家中有女孩的家庭会摆放精美的人偶（雛人形/Hina-ningyō），代表传统的皇室婚礼。这些人偶通常摆放在红色的阶梯状展示台上。传统食物包括有色的菱形糯米糕（菱餅/Hishimochi）、白酒（甘酒/Amazake）和蛤蜊汤（はまぐりのお吸い物/Hamaguri no osuimono）。这个节日的目的是祈求女孩们健康成长和幸福。',
    ),
    SpecialDate(
      id: 'JP_GoldenWeek',
      name: 'ゴールデンウィーク',
      type: SpecialDateType.statutory,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '04-29', // MM-DD (开始日期)
      description: 'ゴールデンウィーク（Golden Week）是日本的黄金周，从4月29日持续到5月5日，包含多个连续的法定假日：昭和之日（4月29日）、宪法纪念日（5月3日）、绿色之日（5月4日）和儿童节（5月5日）。这是日本最长的假期之一，许多人会利用这段时间旅行、探亲或休闲。由于是旅游旺季，交通和住宿通常会非常拥挤和昂贵。许多企业和学校在这段时间会完全关闭。',
    ),
    SpecialDate(
      id: 'JP_Tanabata',
      name: '七夕',
      type: SpecialDateType.traditional,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '07-07', // MM-DD
      description: '七夕（Tanabata）是日本的星节，源自中国的七夕节，庆祝牛郎（彦星/Hikoboshi）和织女（織姫/Orihime）一年一度的相会。根据传说，这对恋人被银河分隔，只有在每年七月七日才能相见。人们会在竹子上挂彩色纸条（短冊/Tanzaku），写下愿望。各地会举办七夕节庆活动，最著名的是宫城县仙台市的仙台七夕祭（仙台七夕まつり/Sendai Tanabata Matsuri），街道上装饰着精美的纸饰。在一些地区，七夕按农历计算，在8月左右庆祝。',
    ),
    SpecialDate(
      id: 'JP_Obon',
      name: 'お盆',
      type: SpecialDateType.traditional,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '08-13', // MM-DD (开始日期，持续三天)
      description: 'お盆（Obon）是日本的重要传统节日，人们相信祖先的灵魂会在这段时间回到家中。虽然不是法定假日，但许多日本人会休假回家与家人团聚。传统上，人们会在家门口点迎火（迎え火/Mukaebi）引导祖先回家，节日结束时点送火（送り火/Okuribi）送祖先回去。其他习俗包括扫墓、盂兰盆舞（盆踊り/Bon Odori）和供奉祭品。日期因地区而异，东京等地区在7月中旬庆祝，而其他地区如关西地区则在8月中旬庆祝。京都著名的五山送り火（Gozan no Okuribi）是Obon期间的重要活动，山上点燃形成各种形状的篝火。',
    ),
    SpecialDate(
      id: 'JP_Shichigosan',
      name: '七五三',
      type: SpecialDateType.traditional,
      regions: ['JP'],
      calculationType: DateCalculationType.fixedGregorian,
      calculationRule: '11-15', // MM-DD
      description: '七五三（Shichi-go-san，意为"七、五、三"）是日本的传统节日，庆祝3岁和7岁的女孩以及3岁和5岁的男孩的成长。在11月15日或附近的周末，父母会带着盛装打扮的孩子去神社祈福，祈求健康成长。孩子们通常会穿传统和服，女孩可能会第一次穿正式的和服（被称为"晴れ着/Haregi"）。参拜后，孩子们会收到"千歳飴"（Chitose Ame），一种长条形的红白糖果，象征长寿和健康成长。这个节日的起源可以追溯到江户时代（1603-1868）。',
    ),
    
    // --- 韩国节日 ---
    SpecialDate(
      id: 'KR_Seollal',
      name: '설날',
      type: SpecialDateType.statutory,
      regions: ['KR'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '01-01L', // LMM-LDD (农历正月初一)
      description: '설날（Seollal）是韩国的农历新年，是韩国最重要的传统节日之一。庆祝活动通常持续三天（新年前一天、新年当天和新年后一天）。这是家庭团聚的重要时刻，人们会穿传统服装韩服（한복/Hanbok），进行祭祖仪式（차례/Charye），向长辈行大礼（세배/Sebae）并收到压岁钱（세뱃돈/Sebaetdon）。传统食物包括年糕汤（떡국/Tteokguk），据说吃了这种汤就长了一岁。其他活动包括玩传统游戏如投掷棋子游戏（윷놀이/Yunnori）。',
    ),
    SpecialDate(
      id: 'KR_Chuseok',
      name: '추석',
      type: SpecialDateType.statutory,
      regions: ['KR'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '08-15L', // LMM-LDD (农历八月十五)
      description: '추석（Chuseok），又称韩国感恩节或中秋节，是韩国三大传统节日之一（与설날/Seollal和端午节并列）。它在农历八月十五举行，是庆祝丰收和感谢祖先的节日。庆祝活动通常持续三天，人们会回家与家人团聚，扫墓（성묘/Seongmyo），进行祭祖仪式（차례/Charye）。传统食物包括松糕（송편/Songpyeon），一种半月形的糯米糕。其他活动包括民间舞蹈和游戏，如江陵地区的强罗假面舞（강릉 관노 가면극/Gangneung Gwanno Gamyeongeuk）。',
    ),
    SpecialDate(
      id: 'KR_BuddhasBirthday',
      name: '부처님 오신 날',
      type: SpecialDateType.statutory,
      regions: ['KR'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '04-08L', // LMM-LDD (农历四月初八)
      description: '부처님 오신 날（Buddha\'s Birthday），又称燃灯节（연등회/Yeondeunghoe），是韩国的重要佛教节日，庆祝佛陀诞生。在农历四月初八庆祝，是韩国的法定假日。庆祝活动包括寺庙举行特别仪式，以及首尔举行的盛大灯笼游行（연등행렬/Yeondeung Haengnyeol）。人们会在寺庙挂彩色灯笼，象征佛陀的智慧照亮世界。许多非佛教徒也会参与庆祝活动。2020年，韩国的灯笼节被联合国教科文组织列入人类非物质文化遗产名录。',
    ),
    
    // --- 印度节日 ---
    SpecialDate(
      id: 'IN_Diwali',
      name: 'दीवाली',
      type: SpecialDateType.statutory,
      regions: ['IN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '10-15L', // 简化，实际日期根据印度历法计算
      description: 'दीवाली（Diwali）或排灯节是印度最重要的节日之一，象征光明战胜黑暗、善良战胜邪恶。庆祝活动通常持续五天，高潮在第三天。人们会装饰家居，点亮油灯（दीया/Diya）和蜡烛，放烟花，交换礼物和甜食。这是印度教、耆那教、锡克教等多个宗教的重要节日。在印度教传统中，排灯节庆祝罗摩神（Lord Rama）从流放中回归，也与财富女神拉克希米（Goddess Lakshmi）有关。商家视这一天为财政新年的开始。',
    ),
    SpecialDate(
      id: 'IN_Holi',
      name: 'होली',
      type: SpecialDateType.statutory,
      regions: ['IN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '03-15L', // 简化，实际日期根据印度历法计算
      description: 'होली（Holi）是印度的色彩节或春节，庆祝春天的到来和冬天的结束。节日通常持续两天，前一天晚上点篝火（होलिका दहन/Holika Dahan），象征邪恶的消亡；第二天是रंगवाली होली（Rangwali Holi），人们互相泼洒彩色粉末（गुलाल/Gulal）和彩色水，欢庆节日。这个节日打破了社会阶层和性别的界限，人们一起庆祝，互道"Holi Hai!"（"今天是Holi！"）。传统饮料包括一种含大麻的饮料（भांग/Bhang）。Holi源于印度教传说，特别是与毗湿奴神的化身黑天（Krishna）有关的故事。',
    ),
    SpecialDate(
      id: 'IN_Dussehra',
      name: 'दशहरा',
      type: SpecialDateType.statutory,
      regions: ['IN'],
      calculationType: DateCalculationType.fixedLunar,
      calculationRule: '09-25L', // 简化，实际日期根据印度历法计算
      description: 'दशहरा（Dussehra）或विजयादशमी（Vijayadashami）是印度的重要节日，庆祝善良战胜邪恶。在北印度，它庆祝罗摩神（Lord Rama）战胜恶魔国王拉瓦纳（Ravana）；在东印度和孟加拉，它庆祝女神杜尔加（Goddess Durga）战胜恶魔马希沙（Mahishasura）。庆祝活动包括演出《罗摩衍那》史诗的拉姆利拉（Ramlila）戏剧，以及焚烧拉瓦纳的巨大雕像。在迈索尔等地，会举行盛大的游行。这个节日标志着九夜节（Navaratri）的结束，也是为期五天的排灯节（Diwali）的前奏。',
    ),
  ];
}

// 根据地区获取节日列表
List<SpecialDate> getHolidaysForRegion(BuildContext context, String regionCode) {
  final holidays = getAsianHolidays(context);
  return holidays.where((h) => h.regions.contains(regionCode) || h.regions.contains('ALL')).toList();
}
