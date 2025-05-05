/**
 * AI路由
 */
const express = require('express');
const { body } = require('express-validator');
const aiController = require('../controllers/aiController');
const authMiddleware = require('../middleware/auth');
const { aiLimiter, createResourceRateLimiter } = require('../middleware/rateLimitMiddleware');

// 创建AI生成资源限制器
const aiGenerateRateLimiter = createResourceRateLimiter({
  resource: 'ai-generate',
  windowMs: 60 * 60 * 1000, // 1小时
  max: 20 // 每个IP每小时最多20个请求
});

const router = express.Router();

// 获取支持的AI模型
router.get('/models', aiController.getSupportedModels);

// 生成提醒事项描述
router.post('/reminder-description',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  aiGenerateRateLimiter, // 应用AI生成资源限制
  [
    body('input').notEmpty().withMessage('input不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  aiController.generateReminderDescription
);

// 生成节日描述
router.post('/holiday-description',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  aiGenerateRateLimiter, // 应用AI生成资源限制
  [
    body('holidayId').notEmpty().withMessage('holidayId不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  aiController.generateHolidayDescription
);

// 生成多语言翻译
router.post('/translation',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  aiGenerateRateLimiter, // 应用AI生成资源限制
  [
    body('text').notEmpty().withMessage('text不能为空'),
    body('sourceLanguage').optional(),
    body('targetLanguage').notEmpty().withMessage('targetLanguage不能为空'),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  aiController.generateTranslation
);

// 解析一句话提醒
router.post('/parse-reminder',
  authMiddleware.isAuthenticated,
  aiLimiter, // 应用AI速率限制
  aiGenerateRateLimiter, // 应用AI生成资源限制
  [
    body('input').notEmpty().withMessage('input不能为空'),
    body('language').optional(),
    body('model').optional(),
    body('temperature').optional().isFloat({ min: 0, max: 2 }).withMessage('temperature应为0-2之间的浮点数')
  ],
  aiController.parseOneSentenceReminder
);

module.exports = router;
