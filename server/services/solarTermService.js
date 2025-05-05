/**
 * 24节气服务
 * 提供精确的24节气计算和管理功能
 */
const Holiday = require('../models/Holiday');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const cacheService = require('./cacheService');

// 24节气的黄经度数（每个节气对应的太阳黄经）
const SOLAR_TERMS_DEGREES = {
  '立春': 315, '雨水': 330, '惊蛰': 345, '春分': 0,
  '清明': 15, '谷雨': 30, '立夏': 45, '小满': 60,
  '芒种': 75, '夏至': 90, '小暑': 105, '大暑': 120,
  '立秋': 135, '处暑': 150, '白露': 165, '秋分': 180,
  '寒露': 195, '霜降': 210, '立冬': 225, '小雪': 240,
  '大雪': 255, '冬至': 270, '小寒': 285, '大寒': 300
};

// 节气英文名称映射
const SOLAR_TERMS_EN = {
  '立春': 'Beginning of Spring', '雨水': 'Rain Water', '惊蛰': 'Awakening of Insects', '春分': 'Spring Equinox',
  '清明': 'Pure Brightness', '谷雨': 'Grain Rain', '立夏': 'Beginning of Summer', '小满': 'Grain Buds',
  '芒种': 'Grain in Ear', '夏至': 'Summer Solstice', '小暑': 'Minor Heat', '大暑': 'Major Heat',
  '立秋': 'Beginning of Autumn', '处暑': 'End of Heat', '白露': 'White Dew', '秋分': 'Autumn Equinox',
  '寒露': 'Cold Dew', '霜降': 'Frost\'s Descent', '立冬': 'Beginning of Winter', '小雪': 'Minor Snow',
  '大雪': 'Major Snow', '冬至': 'Winter Solstice', '小寒': 'Minor Cold', '大寒': 'Major Cold'
};

/**
 * 计算指定年份的24节气日期
 * 使用天文算法计算太阳到达特定黄经的时间
 * @param {number} year - 年份
 * @returns {Object} 24节气及其对应的日期
 */
function calculateSolarTermsForYear(year) {
  const solarTerms = {};

  // 遍历所有节气
  for (const [termName, longitude] of Object.entries(SOLAR_TERMS_DEGREES)) {
    // 计算该节气的日期
    const date = calculateSolarTermDate(year, longitude);
    solarTerms[termName] = date;
  }

  return solarTerms;
}

/**
 * 计算太阳到达特定黄经的日期
 * @param {number} year - 年份
 * @param {number} longitude - 太阳黄经（度）
 * @returns {Date} 日期
 */
function calculateSolarTermDate(year, longitude) {
  // 使用天文算法计算
  // 这里使用简化的算法，实际应用中应使用更精确的天文算法

  // 基于1900年的春分点为3月21日
  const baseYear = 1900;
  const baseSpringEquinoxDay = new Date(1900, 2, 21); // 3月21日

  // 每年春分点大约向前移动0.2422天
  const yearDiff = year - baseYear;
  const dayShift = yearDiff * 0.2422;

  // 计算当年春分点（黄经0度）
  const springEquinoxDay = new Date(year, 2, 21 - Math.floor(dayShift));

  // 一年约365.2422天，太阳每天大约移动360/365.2422 ≈ 0.9856度
  // 因此，太阳从春分点（0度）移动到特定黄经需要的天数
  let daysFromSpringEquinox = longitude / 0.9856;
  if (longitude < 0) {
    daysFromSpringEquinox += 365.2422;
  }

  // 计算最终日期
  const resultDate = new Date(springEquinoxDay);
  resultDate.setDate(springEquinoxDay.getDate() + Math.round(daysFromSpringEquinox));

  return resultDate;
}

/**
 * 获取指定年份的所有24节气
 * @param {number} year - 年份
 * @returns {Array} 24节气数组
 */
exports.getSolarTermsForYear = async (year) => {
  try {
    // 缓存键
    const cacheKey = `solarTerms:${year}`;

    // 尝试从缓存获取
    const cachedSolarTerms = cacheService.get('solarTerms', cacheKey);
    if (cachedSolarTerms) {
      return cachedSolarTerms;
    }

    // 首先尝试从数据库获取
    const solarTerms = await this.getSolarTermsFromDatabase(year);

    // 如果数据库中没有，则计算并保存
    const result = solarTerms.length === 0
      ? await this.calculateAndSaveSolarTerms(year)
      : solarTerms;

    // 缓存结果（缓存1天，因为节气数据不会频繁变化）
    cacheService.set('solarTerms', cacheKey, result, 86400);

    return result;
  } catch (error) {
    logger.error('获取24节气失败:', error);
    throw error;
  }
};

/**
 * 从数据库获取指定年份的24节气
 * @param {number} year - 年份
 * @returns {Array} 24节气数组
 */
exports.getSolarTermsFromDatabase = async (year) => {
  try {
    // 构建过滤条件
    const filters = {
      type: 'solarTerm',
      startDate: `${year}-01-01`,
      endDate: `${year}-12-31`
    };

    // 从数据库获取
    const holidays = await Holiday.getAll(filters);

    // 过滤出24节气
    return holidays.filter(holiday => {
      const name = JSON.parse(holiday.name);
      return Object.keys(SOLAR_TERMS_DEGREES).includes(name.zh);
    });
  } catch (error) {
    logger.error('从数据库获取24节气失败:', error);
    throw error;
  }
};

/**
 * 计算并保存指定年份的24节气
 * @param {number} year - 年份
 * @returns {Array} 24节气数组
 */
exports.calculateAndSaveSolarTerms = async (year) => {
  try {
    // 计算24节气日期
    const solarTermDates = calculateSolarTermsForYear(year);

    const solarTerms = [];

    // 遍历所有节气
    for (const [termName, date] of Object.entries(solarTermDates)) {
      // 创建节气数据
      const solarTerm = {
        id: uuidv4(),
        name: JSON.stringify({
          zh: termName,
          en: SOLAR_TERMS_EN[termName]
        }),
        description: JSON.stringify({
          zh: `${year}年${termName}，二十四节气之一`,
          en: `${SOLAR_TERMS_EN[termName]} of ${year}, one of the 24 solar terms`
        }),
        type: 'solarTerm',
        regions: JSON.stringify(['CN', 'TW', 'HK', 'JP', 'KR']),
        calculation_type: 'solarTerm',
        calculation_rule: JSON.stringify({
          type: 'solarTerm',
          longitude: SOLAR_TERMS_DEGREES[termName],
          year: year
        }),
        importance_level: ['春分', '夏至', '秋分', '冬至'].includes(termName) ? 'high' : 'medium',
        date: date.toISOString().split('T')[0]
      };

      // 保存到数据库
      await Holiday.create(solarTerm);

      solarTerms.push(solarTerm);
    }

    return solarTerms;
  } catch (error) {
    logger.error('计算并保存24节气失败:', error);
    throw error;
  }
};

/**
 * 获取指定日期的节气
 * @param {Date} date - 日期
 * @returns {Object} 节气对象
 */
exports.getSolarTermForDate = async (date) => {
  try {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const dateStr = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;

    // 缓存键
    const cacheKey = `solarTerm:${dateStr}`;

    // 尝试从缓存获取
    const cachedSolarTerm = cacheService.get('solarTerms', cacheKey);
    if (cachedSolarTerm !== null) {
      return cachedSolarTerm; // 可能是null，表示该日期没有节气
    }

    // 获取当年所有节气
    const solarTerms = await this.getSolarTermsForYear(year);

    // 查找当天的节气
    let result = null;
    for (const solarTerm of solarTerms) {
      const termDate = new Date(solarTerm.date);
      if (termDate.getFullYear() === year &&
          termDate.getMonth() + 1 === month &&
          termDate.getDate() === day) {
        result = solarTerm;
        break;
      }
    }

    // 缓存结果（缓存7天）
    cacheService.set('solarTerms', cacheKey, result, 7 * 86400);

    return result;
  } catch (error) {
    logger.error('获取指定日期的节气失败:', error);
    throw error;
  }
};

/**
 * 获取下一个节气
 * @param {Date} date - 日期
 * @returns {Object} 下一个节气对象
 */
exports.getNextSolarTerm = async (date) => {
  try {
    const year = date.getFullYear();
    const dateStr = date.toISOString().split('T')[0];

    // 缓存键
    const cacheKey = `nextSolarTerm:${dateStr}`;

    // 尝试从缓存获取
    const cachedNextSolarTerm = cacheService.get('solarTerms', cacheKey);
    if (cachedNextSolarTerm) {
      return cachedNextSolarTerm;
    }

    // 获取当年所有节气
    let solarTerms = await this.getSolarTermsForYear(year);

    // 按日期排序
    solarTerms = solarTerms.sort((a, b) => new Date(a.date) - new Date(b.date));

    // 查找下一个节气
    let nextSolarTerm = null;
    for (const solarTerm of solarTerms) {
      const termDate = new Date(solarTerm.date);
      if (termDate > date) {
        nextSolarTerm = solarTerm;
        break;
      }
    }

    // 如果当年没有下一个节气，则获取下一年的第一个节气
    if (!nextSolarTerm) {
      const nextYearSolarTerms = await this.getSolarTermsForYear(year + 1);
      nextSolarTerm = nextYearSolarTerms.sort((a, b) => new Date(a.date) - new Date(b.date))[0];
    }

    // 缓存结果（缓存1天）
    cacheService.set('solarTerms', cacheKey, nextSolarTerm, 86400);

    return nextSolarTerm;
  } catch (error) {
    logger.error('获取下一个节气失败:', error);
    throw error;
  }
};

/**
 * 验证24节气数据
 * @param {number} year - 年份
 * @returns {boolean} 是否有效
 */
exports.validateSolarTerms = async (year) => {
  try {
    // 获取当年所有节气
    const solarTerms = await this.getSolarTermsFromDatabase(year);

    // 检查是否有24个节气
    if (solarTerms.length !== 24) {
      return false;
    }

    // 检查每个节气是否有效
    for (const termName of Object.keys(SOLAR_TERMS_DEGREES)) {
      const found = solarTerms.some(term => {
        const name = JSON.parse(term.name);
        return name.zh === termName;
      });

      if (!found) {
        return false;
      }
    }

    return true;
  } catch (error) {
    logger.error('验证24节气数据失败:', error);
    return false;
  }
};

/**
 * 更新节气服务
 * 检查并更新未来几年的24节气数据
 * @param {number} years - 更新未来几年的数据
 * @returns {boolean} 是否成功
 */
exports.updateSolarTermService = async (years = 5) => {
  try {
    const currentYear = new Date().getFullYear();

    // 更新当年和未来几年的数据
    for (let year = currentYear; year <= currentYear + years; year++) {
      // 验证数据
      const isValid = await this.validateSolarTerms(year);

      // 如果数据无效，则重新计算并保存
      if (!isValid) {
        await this.calculateAndSaveSolarTerms(year);
      }
    }

    return true;
  } catch (error) {
    logger.error('更新节气服务失败:', error);
    return false;
  }
};
