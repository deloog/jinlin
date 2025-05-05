/**
 * Deepseek路由
 */
const express = require('express');
const { body } = require('express-validator');
const deepseekController = require('../controllers/deepseekController');
const authMiddleware = require('../middleware/auth');
const { aiLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 生成提醒事项描述
router.post('/reminder-description',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  [
    body('input').notEmpty().withMessage('input不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  deepseekController.generateReminderDescription
);

// 解析自然语言输入
router.post('/extract-events',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  [
    body('input').notEmpty().withMessage('input不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  deepseekController.extractEventsFromText
);

// 生成自定义响应
router.post('/custom-response',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  [
    body('prompt').notEmpty().withMessage('prompt不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数'),
    body('max_tokens').optional().isInt({ min: 1, max: 4000 }).withMessage('max_tokens应为1-4000之间的整数')
  ],
  deepseekController.generateCustomResponse
);

// 批量生成描述
router.post('/batch-descriptions',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  [
    body('titles').isArray().withMessage('titles必须是数组'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  deepseekController.batchGenerateDescriptions
);

module.exports = router;
