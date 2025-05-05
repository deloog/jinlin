/**
 * 24节气控制器
 */
const holidayService = require('../services/holidayService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取指定年份的24节气
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSolarTerms = async (req, res) => {
  try {
    const { year, language } = req.query;
    
    // 验证年份
    const yearNum = parseInt(year);
    if (isNaN(yearNum) || yearNum < 1900 || yearNum > 2100) {
      return res.status(400).json({ error: '无效的年份，应为1900-2100之间的整数' });
    }
    
    // 获取24节气
    const solarTerms = await holidayService.getSolarTerms(yearNum, language);
    
    res.json({ data: solarTerms });
  } catch (error) {
    logger.error('获取24节气失败:', error);
    res.status(500).json({ error: '获取24节气失败' });
  }
};

/**
 * 获取当天的节气
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getCurrentSolarTerm = async (req, res) => {
  try {
    const { date, language } = req.query;
    
    // 解析日期
    let targetDate;
    if (date) {
      targetDate = new Date(date);
      if (isNaN(targetDate.getTime())) {
        return res.status(400).json({ error: '无效的日期格式' });
      }
    } else {
      targetDate = new Date();
    }
    
    // 获取当天节气
    const solarTerm = await holidayService.getSolarTermForDate(targetDate, language);
    
    if (!solarTerm) {
      return res.json({ data: null, message: '当天没有节气' });
    }
    
    res.json({ data: solarTerm });
  } catch (error) {
    logger.error('获取当天节气失败:', error);
    res.status(500).json({ error: '获取当天节气失败' });
  }
};

/**
 * 获取下一个节气
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getNextSolarTerm = async (req, res) => {
  try {
    const { date, language } = req.query;
    
    // 解析日期
    let targetDate;
    if (date) {
      targetDate = new Date(date);
      if (isNaN(targetDate.getTime())) {
        return res.status(400).json({ error: '无效的日期格式' });
      }
    } else {
      targetDate = new Date();
    }
    
    // 获取下一个节气
    const nextSolarTerm = await holidayService.getNextSolarTerm(targetDate, language);
    
    res.json({ data: nextSolarTerm });
  } catch (error) {
    logger.error('获取下一个节气失败:', error);
    res.status(500).json({ error: '获取下一个节气失败' });
  }
};

/**
 * 更新24节气数据
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.updateSolarTerms = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { years } = req.body;
    
    // 验证年数
    const yearsNum = parseInt(years || 5);
    if (isNaN(yearsNum) || yearsNum < 1 || yearsNum > 10) {
      return res.status(400).json({ error: '无效的年数，应为1-10之间的整数' });
    }
    
    // 更新24节气数据
    const success = await holidayService.updateSolarTerms(yearsNum);
    
    if (success) {
      res.json({ message: '24节气数据更新成功' });
    } else {
      res.status(500).json({ error: '24节气数据更新失败' });
    }
  } catch (error) {
    logger.error('更新24节气数据失败:', error);
    res.status(500).json({ error: '更新24节气数据失败' });
  }
};
