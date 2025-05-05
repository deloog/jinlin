/**
 * 时区路由
 */
const express = require('express');
const { body, param, query } = require('express-validator');
const timeZoneController = require('../controllers/timeZoneController');
const { globalLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用全局速率限制
router.use(globalLimiter);

// 获取所有时区
router.get('/', timeZoneController.getAllTimeZones);

// 获取时区信息
router.get('/:time_zone',
  [
    param('time_zone').notEmpty().withMessage('time_zone不能为空')
  ],
  timeZoneController.getTimeZoneInfo
);

// 转换时间到指定时区
router.post('/convert',
  [
    body('date').optional(),
    body('target_time_zone').notEmpty().withMessage('target_time_zone不能为空'),
    body('source_time_zone').optional()
  ],
  timeZoneController.convertToTimeZone
);

// 格式化日期时间
router.post('/format',
  [
    body('date').optional(),
    body('format').optional(),
    body('time_zone').optional()
  ],
  timeZoneController.formatDateTime
);

// 获取当前时间
router.get('/current/time',
  [
    query('time_zone').optional(),
    query('format').optional()
  ],
  timeZoneController.getCurrentTime
);

// 计算两个日期之间的差异
router.post('/diff',
  [
    body('date1').notEmpty().withMessage('date1不能为空'),
    body('date2').notEmpty().withMessage('date2不能为空'),
    body('unit').optional().isIn(['years', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds']).withMessage('unit必须是有效的时间单位')
  ],
  timeZoneController.getDateDiff
);

module.exports = router;
