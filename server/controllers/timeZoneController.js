/**
 * 时区控制器
 */
const { validationResult } = require('express-validator');
const timeZoneUtils = require('../utils/timeZoneUtils');
const logger = require('../utils/logger');

/**
 * 获取所有时区
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getAllTimeZones = (req, res, next) => {
  try {
    const timeZones = timeZoneUtils.getAllTimeZones();
    res.json({ data: timeZones });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取时区信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTimeZoneInfo = (req, res, next) => {
  try {
    const { time_zone } = req.params;
    
    const timeZoneInfo = timeZoneUtils.getTimeZoneInfo(time_zone);
    
    if (!timeZoneInfo) {
      return res.status(404).json({ error: '时区不存在' });
    }
    
    res.json({ data: timeZoneInfo });
  } catch (error) {
    next(error);
  }
};

/**
 * 转换时间到指定时区
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.convertToTimeZone = (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { date, target_time_zone, source_time_zone } = req.body;
    
    const convertedTime = timeZoneUtils.convertToTimeZone(date, target_time_zone, source_time_zone);
    
    if (!convertedTime) {
      return res.status(400).json({ error: '时间转换失败' });
    }
    
    res.json({
      data: {
        original_date: date,
        converted_date: convertedTime,
        source_time_zone: source_time_zone || 'UTC',
        target_time_zone
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 格式化日期时间
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.formatDateTime = (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { date, format, time_zone } = req.body;
    
    const formattedDateTime = timeZoneUtils.formatDateTime(date, format, time_zone);
    
    if (!formattedDateTime) {
      return res.status(400).json({ error: '日期时间格式化失败' });
    }
    
    res.json({
      data: {
        original_date: date,
        formatted_date: formattedDateTime,
        format: format || 'YYYY-MM-DD HH:mm:ss',
        time_zone: time_zone || timeZoneUtils.DEFAULT_TIMEZONE
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取当前时间
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getCurrentTime = (req, res, next) => {
  try {
    const { time_zone, format } = req.query;
    
    const currentTime = timeZoneUtils.getCurrentTime(time_zone, format);
    
    if (!currentTime) {
      return res.status(400).json({ error: '获取当前时间失败' });
    }
    
    res.json({
      data: {
        current_time: currentTime,
        time_zone: time_zone || timeZoneUtils.DEFAULT_TIMEZONE,
        format: format || 'YYYY-MM-DD HH:mm:ss'
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 计算两个日期之间的差异
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getDateDiff = (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { date1, date2, unit } = req.body;
    
    const diff = timeZoneUtils.getDateDiff(date1, date2, unit);
    
    if (diff === null) {
      return res.status(400).json({ error: '计算日期差异失败' });
    }
    
    res.json({
      data: {
        date1,
        date2,
        diff,
        unit: unit || 'days'
      }
    });
  } catch (error) {
    next(error);
  }
};
