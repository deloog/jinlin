/**
 * 节日服务
 */
const Holiday = require('../models/Holiday');
const solarTermService = require('./solarTermService');
const lunarService = require('./lunarService');
const logger = require('../utils/logger');

/**
 * 获取节日列表
 * @param {Object} filters - 过滤条件
 * @returns {Array} 节日列表
 */
exports.getHolidays = async (filters = {}) => {
  try {
    return await Holiday.getAll(filters);
  } catch (error) {
    logger.error('获取节日列表失败:', error);
    throw error;
  }
};

/**
 * 获取单个节日
 * @param {string} id - 节日ID
 * @returns {Object} 节日对象
 */
exports.getHoliday = async (id) => {
  try {
    const holiday = await Holiday.getById(id);

    if (!holiday) {
      throw new Error('节日不存在');
    }

    return holiday;
  } catch (error) {
    logger.error('获取节日失败:', error);
    throw error;
  }
};

/**
 * 创建节日
 * @param {Object} holidayData - 节日数据
 * @returns {Object} 创建的节日
 */
exports.createHoliday = async (holidayData) => {
  try {
    return await Holiday.create(holidayData);
  } catch (error) {
    logger.error('创建节日失败:', error);
    throw error;
  }
};

/**
 * 更新节日
 * @param {string} id - 节日ID
 * @param {Object} holidayData - 节日数据
 * @returns {Object} 更新的节日
 */
exports.updateHoliday = async (id, holidayData) => {
  try {
    const holiday = await Holiday.getById(id);

    if (!holiday) {
      throw new Error('节日不存在');
    }

    return await Holiday.update(id, holidayData);
  } catch (error) {
    logger.error('更新节日失败:', error);
    throw error;
  }
};

/**
 * 删除节日
 * @param {string} id - 节日ID
 * @returns {boolean} 是否成功
 */
exports.deleteHoliday = async (id) => {
  try {
    const holiday = await Holiday.getById(id);

    if (!holiday) {
      throw new Error('节日不存在');
    }

    return await Holiday.delete(id);
  } catch (error) {
    logger.error('删除节日失败:', error);
    throw error;
  }
};

/**
 * 批量创建节日
 * @param {Array} holidays - 节日数据数组
 * @returns {Array} 创建的节日数组
 */
exports.batchCreateHolidays = async (holidays) => {
  try {
    return await Holiday.batchCreate(holidays);
  } catch (error) {
    logger.error('批量创建节日失败:', error);
    throw error;
  }
};

/**
 * 根据地区获取节日
 * @param {string} region - 地区代码
 * @param {string} language - 语言代码
 * @returns {Array} 节日列表
 */
exports.getHolidaysByRegion = async (region, language) => {
  try {
    const filters = { region };
    const holidays = await Holiday.getAll(filters);

    // 处理多语言
    if (language) {
      return holidays.map(holiday => {
        const result = { ...holiday };

        // 解析JSON字段
        result.name = JSON.parse(holiday.name);
        if (holiday.description) result.description = JSON.parse(holiday.description);
        if (holiday.regions) result.regions = JSON.parse(holiday.regions);
        if (holiday.customs) result.customs = JSON.parse(holiday.customs);
        if (holiday.taboos) result.taboos = JSON.parse(holiday.taboos);
        if (holiday.foods) result.foods = JSON.parse(holiday.foods);
        if (holiday.greetings) result.greetings = JSON.parse(holiday.greetings);
        if (holiday.activities) result.activities = JSON.parse(holiday.activities);
        if (holiday.history) result.history = JSON.parse(holiday.history);

        // 获取指定语言的名称和描述
        result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
        if (result.description) {
          result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
        }

        return result;
      });
    }

    return holidays;
  } catch (error) {
    logger.error('根据地区获取节日失败:', error);
    throw error;
  }
};

/**
 * 根据类型获取节日
 * @param {string} type - 节日类型
 * @param {string} language - 语言代码
 * @returns {Array} 节日列表
 */
exports.getHolidaysByType = async (type, language) => {
  try {
    const filters = { type };
    const holidays = await Holiday.getAll(filters);

    // 处理多语言
    if (language) {
      return holidays.map(holiday => {
        const result = { ...holiday };

        // 解析JSON字段
        result.name = JSON.parse(holiday.name);
        if (holiday.description) result.description = JSON.parse(holiday.description);
        if (holiday.regions) result.regions = JSON.parse(holiday.regions);
        if (holiday.customs) result.customs = JSON.parse(holiday.customs);
        if (holiday.taboos) result.taboos = JSON.parse(holiday.taboos);
        if (holiday.foods) result.foods = JSON.parse(holiday.foods);
        if (holiday.greetings) result.greetings = JSON.parse(holiday.greetings);
        if (holiday.activities) result.activities = JSON.parse(holiday.activities);
        if (holiday.history) result.history = JSON.parse(holiday.history);

        // 获取指定语言的名称和描述
        result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
        if (result.description) {
          result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
        }

        return result;
      });
    }

    return holidays;
  } catch (error) {
    logger.error('根据类型获取节日失败:', error);
    throw error;
  }
};

/**
 * 获取24节气
 * @param {number} year - 年份
 * @param {string} language - 语言代码
 * @returns {Array} 24节气列表
 */
exports.getSolarTerms = async (year, language) => {
  try {
    // 使用专门的24节气服务获取数据
    const solarTerms = await solarTermService.getSolarTermsForYear(year);

    // 处理多语言
    if (language) {
      return solarTerms.map(solarTerm => {
        const result = { ...solarTerm };

        // 解析JSON字段
        result.name = JSON.parse(solarTerm.name);
        if (solarTerm.description) result.description = JSON.parse(solarTerm.description);
        if (solarTerm.regions) result.regions = JSON.parse(solarTerm.regions);

        // 获取指定语言的名称和描述
        result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
        if (result.description) {
          result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
        }

        return result;
      });
    }

    return solarTerms;
  } catch (error) {
    logger.error('获取24节气失败:', error);
    throw error;
  }
};

/**
 * 获取当天的节气
 * @param {Date} date - 日期
 * @param {string} language - 语言代码
 * @returns {Object} 节气对象
 */
exports.getSolarTermForDate = async (date, language) => {
  try {
    // 使用专门的24节气服务获取数据
    const solarTerm = await solarTermService.getSolarTermForDate(date);

    if (!solarTerm) {
      return null;
    }

    // 处理多语言
    if (language) {
      const result = { ...solarTerm };

      // 解析JSON字段
      result.name = JSON.parse(solarTerm.name);
      if (solarTerm.description) result.description = JSON.parse(solarTerm.description);
      if (solarTerm.regions) result.regions = JSON.parse(solarTerm.regions);

      // 获取指定语言的名称和描述
      result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
      if (result.description) {
        result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
      }

      return result;
    }

    return solarTerm;
  } catch (error) {
    logger.error('获取当天节气失败:', error);
    throw error;
  }
};

/**
 * 获取下一个节气
 * @param {Date} date - 日期
 * @param {string} language - 语言代码
 * @returns {Object} 下一个节气对象
 */
exports.getNextSolarTerm = async (date, language) => {
  try {
    // 使用专门的24节气服务获取数据
    const nextSolarTerm = await solarTermService.getNextSolarTerm(date);

    // 处理多语言
    if (language) {
      const result = { ...nextSolarTerm };

      // 解析JSON字段
      result.name = JSON.parse(nextSolarTerm.name);
      if (nextSolarTerm.description) result.description = JSON.parse(nextSolarTerm.description);
      if (nextSolarTerm.regions) result.regions = JSON.parse(nextSolarTerm.regions);

      // 获取指定语言的名称和描述
      result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
      if (result.description) {
        result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
      }

      return result;
    }

    return nextSolarTerm;
  } catch (error) {
    logger.error('获取下一个节气失败:', error);
    throw error;
  }
};

/**
 * 更新24节气数据
 * @param {number} years - 更新未来几年的数据
 * @returns {boolean} 是否成功
 */
exports.updateSolarTerms = async (years = 5) => {
  try {
    return await solarTermService.updateSolarTermService(years);
  } catch (error) {
    logger.error('更新24节气数据失败:', error);
    throw error;
  }
};

/**
 * 获取农历节日
 * @param {number} year - 年份
 * @param {string} language - 语言代码
 * @returns {Array} 农历节日列表
 */
exports.getLunarHolidays = async (year, language) => {
  try {
    // 构建过滤条件
    const filters = {
      type: 'traditional',
      calculation_type: 'lunar'
    };

    // 获取所有农历节日
    const holidays = await Holiday.getAll(filters);

    // 处理每个节日，计算公历日期
    const result = [];

    for (const holiday of holidays) {
      try {
        // 解析计算规则
        const calculationRule = JSON.parse(holiday.calculation_rule);

        // 只处理农历节日
        if (calculationRule.type !== 'lunar') {
          continue;
        }

        // 获取农历月份和日期
        const lunarMonth = calculationRule.month;
        const lunarDay = calculationRule.day;
        const isLeapMonth = calculationRule.isLeapMonth || false;

        // 转换为公历日期
        const solarDate = lunarService.lunarToSolar(year, lunarMonth, lunarDay, isLeapMonth);

        // 创建节日对象
        const holidayObj = { ...holiday };

        // 设置公历日期
        holidayObj.date = solarDate.toISOString().split('T')[0];

        // 处理多语言
        if (language) {
          // 解析JSON字段
          holidayObj.name = JSON.parse(holiday.name);
          if (holiday.description) holidayObj.description = JSON.parse(holiday.description);
          if (holiday.regions) holidayObj.regions = JSON.parse(holiday.regions);
          if (holiday.customs) holidayObj.customs = JSON.parse(holiday.customs);
          if (holiday.taboos) holidayObj.taboos = JSON.parse(holiday.taboos);
          if (holiday.foods) holidayObj.foods = JSON.parse(holiday.foods);
          if (holiday.greetings) holidayObj.greetings = JSON.parse(holiday.greetings);
          if (holiday.activities) holidayObj.activities = JSON.parse(holiday.activities);
          if (holiday.history) holidayObj.history = JSON.parse(holiday.history);

          // 获取指定语言的名称和描述
          holidayObj.name = holidayObj.name[language] || holidayObj.name.default || Object.values(holidayObj.name)[0];
          if (holidayObj.description) {
            holidayObj.description = holidayObj.description[language] || holidayObj.description.default || Object.values(holidayObj.description)[0];
          }
        }

        // 添加农历日期文本
        const lunarDate = {
          year,
          month: lunarMonth,
          day: lunarDay,
          isLeapMonth
        };

        holidayObj.lunar_date_text = lunarService.getLunarDateText(lunarDate, language);

        result.push(holidayObj);
      } catch (error) {
        logger.error(`处理农历节日失败: ${holiday.id}`, error);
        // 继续处理下一个节日
      }
    }

    return result;
  } catch (error) {
    logger.error('获取农历节日失败:', error);
    throw error;
  }
};

/**
 * 获取当前日期的农历信息
 * @param {Date} date - 日期
 * @param {string} language - 语言代码
 * @returns {Object} 农历信息
 */
exports.getLunarDateInfo = (date, language = 'zh') => {
  try {
    // 公历转农历
    const lunarDate = lunarService.solarToLunar(date);

    // 获取农历日期文本
    const lunarDateText = lunarService.getLunarDateText(lunarDate, language);

    // 获取干支年份
    const chineseZodiac = lunarService.getChineseZodiacYear(lunarDate.year, language);

    return {
      lunar_date: lunarDate,
      lunar_date_text: lunarDateText,
      stem_branch: chineseZodiac.stemBranch,
      zodiac: chineseZodiac.zodiac
    };
  } catch (error) {
    logger.error('获取农历信息失败:', error);
    throw error;
  }
};
