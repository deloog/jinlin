/**
 * 农历控制器
 */
const holidayService = require('../services/holidayService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取农历节日
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getLunarHolidays = async (req, res) => {
  try {
    const { year, language } = req.query;
    
    // 验证年份
    const yearNum = parseInt(year);
    if (isNaN(yearNum) || yearNum < 1900 || yearNum > 2100) {
      return res.status(400).json({ error: '无效的年份，应为1900-2100之间的整数' });
    }
    
    // 获取农历节日
    const lunarHolidays = await holidayService.getLunarHolidays(yearNum, language);
    
    res.json({ data: lunarHolidays });
  } catch (error) {
    logger.error('获取农历节日失败:', error);
    res.status(500).json({ error: '获取农历节日失败' });
  }
};

/**
 * 获取当前日期的农历信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getLunarDateInfo = async (req, res) => {
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
    
    // 获取农历信息
    const lunarInfo = holidayService.getLunarDateInfo(targetDate, language);
    
    res.json({ data: lunarInfo });
  } catch (error) {
    logger.error('获取农历信息失败:', error);
    res.status(500).json({ error: '获取农历信息失败' });
  }
};
