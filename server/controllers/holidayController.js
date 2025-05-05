/**
 * 节日控制器
 */
const holidayService = require('../services/holidayService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取节日列表
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getHolidays = async (req, res) => {
  try {
    const { language, region, startDate, endDate, type } = req.query;

    // 构建过滤条件
    const filters = {};
    if (region) filters.region = region;
    if (type) filters.type = type;
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;

    let holidays;

    if (region && language) {
      // 使用专门的服务方法获取特定地区和语言的节日
      holidays = await holidayService.getHolidaysByRegion(region, language);
    } else if (type && language) {
      // 使用专门的服务方法获取特定类型和语言的节日
      holidays = await holidayService.getHolidaysByType(type, language);
    } else {
      // 获取所有节日并处理
      const allHolidays = await holidayService.getHolidays(filters);

      // 如果指定了语言，过滤返回的节日名称和描述
      holidays = allHolidays.map(holiday => {
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

        // 如果指定了语言，只返回该语言的名称和描述
        if (language) {
          result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
          if (result.description) {
            result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
          }
          // 处理其他多语言字段...
        }

        return result;
      });
    }

    res.json({ data: holidays });
  } catch (error) {
    logger.error('获取节日列表失败:', error);
    res.status(500).json({ error: '获取节日列表失败' });
  }
};

/**
 * 获取单个节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getHoliday = async (req, res) => {
  try {
    const { id } = req.params;
    const { language } = req.query;

    try {
      const holiday = await holidayService.getHoliday(id);

      // 解析JSON字段
      const result = { ...holiday };
      result.name = JSON.parse(holiday.name);
      if (holiday.description) result.description = JSON.parse(holiday.description);
      if (holiday.regions) result.regions = JSON.parse(holiday.regions);
      if (holiday.customs) result.customs = JSON.parse(holiday.customs);
      if (holiday.taboos) result.taboos = JSON.parse(holiday.taboos);
      if (holiday.foods) result.foods = JSON.parse(holiday.foods);
      if (holiday.greetings) result.greetings = JSON.parse(holiday.greetings);
      if (holiday.activities) result.activities = JSON.parse(holiday.activities);
      if (holiday.history) result.history = JSON.parse(holiday.history);

      // 如果指定了语言，只返回该语言的名称和描述
      if (language) {
        result.name = result.name[language] || result.name.default || Object.values(result.name)[0];
        if (result.description) {
          result.description = result.description[language] || result.description.default || Object.values(result.description)[0];
        }
        // 处理其他多语言字段...
      }

      res.json({ data: result });
    } catch (error) {
      if (error.message === '节日不存在') {
        return res.status(404).json({ error: '节日不存在' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('获取节日失败:', error);
    res.status(500).json({ error: '获取节日失败' });
  }
};

/**
 * 创建节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.createHoliday = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const holidayData = req.body;

    // 创建节日
    const holiday = await holidayService.createHoliday(holidayData);

    res.status(201).json({ data: holiday });
  } catch (error) {
    logger.error('创建节日失败:', error);
    res.status(500).json({ error: '创建节日失败' });
  }
};

/**
 * 更新节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.updateHoliday = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const holidayData = req.body;

    try {
      // 更新节日
      const updatedHoliday = await holidayService.updateHoliday(id, holidayData);
      res.json({ data: updatedHoliday });
    } catch (error) {
      if (error.message === '节日不存在') {
        return res.status(404).json({ error: '节日不存在' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('更新节日失败:', error);
    res.status(500).json({ error: '更新节日失败' });
  }
};

/**
 * 删除节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.deleteHoliday = async (req, res) => {
  try {
    const { id } = req.params;

    try {
      // 删除节日
      const success = await holidayService.deleteHoliday(id);

      if (success) {
        res.json({ message: '节日删除成功' });
      } else {
        res.status(500).json({ error: '节日删除失败' });
      }
    } catch (error) {
      if (error.message === '节日不存在') {
        return res.status(404).json({ error: '节日不存在' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('删除节日失败:', error);
    res.status(500).json({ error: '删除节日失败' });
  }
};

/**
 * 批量创建节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.batchCreateHolidays = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { holidays } = req.body;

    if (!Array.isArray(holidays) || holidays.length === 0) {
      return res.status(400).json({ error: '无效的节日数据' });
    }

    // 批量创建节日
    const createdHolidays = await holidayService.batchCreateHolidays(holidays);

    res.status(201).json({ data: createdHolidays });
  } catch (error) {
    logger.error('批量创建节日失败:', error);
    res.status(500).json({ error: '批量创建节日失败' });
  }
};
