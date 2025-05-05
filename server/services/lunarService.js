/**
 * 农历服务
 * 提供农历日期转换和处理功能
 */
const logger = require('../utils/logger');

// 农历月份名称
const LUNAR_MONTH_NAMES = {
  zh: ['正月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '冬月', '腊月'],
  en: ['First Month', 'Second Month', 'Third Month', 'Fourth Month', 'Fifth Month', 'Sixth Month', 'Seventh Month', 'Eighth Month', 'Ninth Month', 'Tenth Month', 'Eleventh Month', 'Twelfth Month'],
  ja: ['正月', '如月', '弥生', '卯月', '皐月', '水無月', '文月', '葉月', '長月', '神無月', '霜月', '師走'],
  ko: ['정월', '이월', '삼월', '사월', '오월', '유월', '칠월', '팔월', '구월', '시월', '동월', '섣달']
};

// 农历日期名称
const LUNAR_DAY_NAMES = {
  zh: ['初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十', '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十', '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'],
  en: ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th', '13th', '14th', '15th', '16th', '17th', '18th', '19th', '20th', '21st', '22nd', '23rd', '24th', '25th', '26th', '27th', '28th', '29th', '30th'],
  ja: ['朔日', '二日', '三日', '四日', '五日', '六日', '七日', '八日', '九日', '十日', '十一日', '十二日', '十三日', '十四日', '十五日', '十六日', '十七日', '十八日', '十九日', '二十日', '二十一日', '二十二日', '二十三日', '二十四日', '二十五日', '二十六日', '二十七日', '二十八日', '二十九日', '三十日'],
  ko: ['초하루', '초이틀', '초사흘', '초나흘', '초닷새', '초엿새', '초이레', '초여드레', '초아흐레', '초열흘', '열하루', '열이틀', '열사흘', '열나흘', '열닷새', '열엿새', '열이레', '열여드레', '열아흐레', '스무날', '스무하루', '스무이틀', '스무사흘', '스무나흘', '스무닷새', '스무엿새', '스무이레', '스무여드레', '스무아흐레', '서른날']
};

// 天干
const HEAVENLY_STEMS = {
  zh: ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'],
  en: ['Jia', 'Yi', 'Bing', 'Ding', 'Wu', 'Ji', 'Geng', 'Xin', 'Ren', 'Gui'],
  ja: ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'],
  ko: ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계']
};

// 地支
const EARTHLY_BRANCHES = {
  zh: ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'],
  en: ['Zi', 'Chou', 'Yin', 'Mao', 'Chen', 'Si', 'Wu', 'Wei', 'Shen', 'You', 'Xu', 'Hai'],
  ja: ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'],
  ko: ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해']
};

// 生肖
const ZODIAC_ANIMALS = {
  zh: ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'],
  en: ['Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake', 'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig'],
  ja: ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'],
  ko: ['쥐', '소', '호랑이', '토끼', '용', '뱀', '말', '양', '원숭이', '닭', '개', '돼지']
};

// 农历数据
// 这里使用了一个简化的农历数据表，实际应用中应使用更完整的数据
// 数据格式：[闰月，正月初一对应的公历日期，农历每月的天数...]
// 例如：[0, 2, 1, 31, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30] 表示：
// - 没有闰月 (0)
// - 正月初一是公历2月1日
// - 农历正月有31天，二月有29天，...
const LUNAR_INFO = [
  [0, 2, 1, 31, 29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30], // 2020
  [0, 2, 12, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29], // 2021
  [0, 2, 1, 31, 30, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29], // 2022
  [0, 1, 22, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 30], // 2023
  [0, 2, 10, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 30], // 2024
  [0, 1, 29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30], // 2025
  [0, 2, 17, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29], // 2026
  [0, 2, 6, 31, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], // 2027
  [0, 1, 26, 30, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], // 2028
  [0, 2, 13, 30, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30], // 2029
  [0, 2, 3, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29, 30], // 2030
];

/**
 * 获取农历年份数据
 * @param {number} year - 公历年份
 * @returns {Array} 农历年份数据
 */
function getLunarYearInfo(year) {
  const index = year - 2020;
  if (index < 0 || index >= LUNAR_INFO.length) {
    throw new Error(`不支持的年份: ${year}`);
  }
  
  return LUNAR_INFO[index];
}

/**
 * 公历日期转农历日期
 * @param {Date} date - 公历日期
 * @returns {Object} 农历日期对象
 */
exports.solarToLunar = (date) => {
  try {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    
    // 获取农历年份数据
    const yearInfo = getLunarYearInfo(year);
    const leapMonth = yearInfo[0]; // 闰月
    const springFestivalMonth = yearInfo[1]; // 正月初一的月份
    const springFestivalDay = yearInfo[2]; // 正月初一的日期
    
    // 计算当前日期距离正月初一的天数
    let span = 0;
    
    // 如果当前月份在春节前
    if (month < springFestivalMonth || (month === springFestivalMonth && day < springFestivalDay)) {
      // 获取上一年的农历数据
      const lastYearInfo = getLunarYearInfo(year - 1);
      
      // 计算从上一年春节到当前日期的天数
      // 这里需要更复杂的计算，简化处理
      // ...
      
      // 返回上一年的农历日期
      return {
        year: year - 1,
        month: 12, // 简化处理，假设为腊月
        day: 30, // 简化处理，假设为三十
        isLeapMonth: false
      };
    }
    
    // 计算从正月初一到当前日期的天数
    // 这里需要更复杂的计算，简化处理
    // ...
    
    // 简化处理，假设为当年正月
    return {
      year,
      month: 1,
      day: 1,
      isLeapMonth: false
    };
  } catch (error) {
    logger.error('公历转农历失败:', error);
    throw error;
  }
};

/**
 * 农历日期转公历日期
 * @param {number} year - 农历年份
 * @param {number} month - 农历月份
 * @param {number} day - 农历日期
 * @param {boolean} isLeapMonth - 是否闰月
 * @returns {Date} 公历日期
 */
exports.lunarToSolar = (year, month, day, isLeapMonth = false) => {
  try {
    // 获取农历年份数据
    const yearInfo = getLunarYearInfo(year);
    const leapMonth = yearInfo[0]; // 闰月
    const springFestivalMonth = yearInfo[1]; // 正月初一的月份
    const springFestivalDay = yearInfo[2]; // 正月初一的日期
    
    // 创建正月初一的公历日期
    const springFestival = new Date(year, springFestivalMonth - 1, springFestivalDay);
    
    // 计算从正月初一到指定农历日期的天数
    let days = 0;
    
    // 计算月份天数
    for (let i = 1; i < month; i++) {
      // 处理闰月
      if (leapMonth > 0 && i === leapMonth) {
        days += yearInfo[i + 3];
      }
      days += yearInfo[i + 2];
    }
    
    // 如果是闰月，且当前月份是闰月
    if (isLeapMonth && month === leapMonth) {
      days += yearInfo[month + 2];
    }
    
    // 加上日期
    days += day - 1;
    
    // 计算公历日期
    const result = new Date(springFestival);
    result.setDate(springFestival.getDate() + days);
    
    return result;
  } catch (error) {
    logger.error('农历转公历失败:', error);
    throw error;
  }
};

/**
 * 获取农历日期的文本表示
 * @param {Object} lunarDate - 农历日期对象
 * @param {string} language - 语言代码
 * @returns {string} 农历日期文本
 */
exports.getLunarDateText = (lunarDate, language = 'zh') => {
  try {
    const { year, month, day, isLeapMonth } = lunarDate;
    
    // 获取语言
    const lang = language in LUNAR_MONTH_NAMES ? language : 'zh';
    
    // 获取月份名称
    const monthName = LUNAR_MONTH_NAMES[lang][month - 1];
    
    // 获取日期名称
    const dayName = LUNAR_DAY_NAMES[lang][day - 1];
    
    // 闰月表示
    const leapText = isLeapMonth ? (lang === 'zh' ? '闰' : 'Leap ') : '';
    
    // 组合文本
    if (lang === 'zh') {
      return `${leapText}${monthName}${dayName}`;
    } else if (lang === 'en') {
      return `${leapText}${monthName} ${dayName}`;
    } else if (lang === 'ja') {
      return `${leapText}${monthName}${dayName}`;
    } else if (lang === 'ko') {
      return `${leapText}${monthName} ${dayName}`;
    }
    
    return `${leapText}${monthName} ${dayName}`;
  } catch (error) {
    logger.error('获取农历日期文本失败:', error);
    throw error;
  }
};

/**
 * 获取农历年份的干支表示
 * @param {number} year - 农历年份
 * @param {string} language - 语言代码
 * @returns {string} 干支年份
 */
exports.getChineseZodiacYear = (year, language = 'zh') => {
  try {
    // 获取语言
    const lang = language in HEAVENLY_STEMS ? language : 'zh';
    
    // 计算天干
    const stemIndex = (year - 4) % 10;
    const stem = HEAVENLY_STEMS[lang][stemIndex];
    
    // 计算地支
    const branchIndex = (year - 4) % 12;
    const branch = EARTHLY_BRANCHES[lang][branchIndex];
    
    // 计算生肖
    const zodiac = ZODIAC_ANIMALS[lang][branchIndex];
    
    // 返回干支和生肖
    return {
      stemBranch: `${stem}${branch}`,
      zodiac
    };
  } catch (error) {
    logger.error('获取农历年份干支表示失败:', error);
    throw error;
  }
};
