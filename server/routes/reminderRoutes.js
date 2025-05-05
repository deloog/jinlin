/**
 * 提醒事项路由
 */
const express = require('express');
const { body } = require('express-validator');
const reminderController = require('../controllers/reminderController');
// const authMiddleware = require('../middleware/auth'); // 如果需要认证

const router = express.Router();

// 获取提醒事项列表
router.get('/', 
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.getReminders
);

// 获取单个提醒事项
router.get('/:id', 
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.getReminder
);

// 创建提醒事项
router.post('/',
  [
    // 验证请求体
    body('title').notEmpty().withMessage('提醒事项标题不能为空'),
    body('date').notEmpty().withMessage('日期不能为空')
      .matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('日期格式应为YYYY-MM-DD'),
    body('time').optional()
      .matches(/^\d{2}:\d{2}(:\d{2})?$/).withMessage('时间格式应为HH:MM或HH:MM:SS'),
    body('priority').optional()
      .isIn(['low', 'medium', 'high']).withMessage('优先级必须是low、medium或high'),
    body('is_completed').optional().isBoolean().withMessage('is_completed必须是布尔值'),
    body('is_recurring').optional().isBoolean().withMessage('is_recurring必须是布尔值'),
  ],
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.createReminder
);

// 更新提醒事项
router.put('/:id',
  [
    // 验证请求体
    body('title').optional(),
    body('date').optional()
      .matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('日期格式应为YYYY-MM-DD'),
    body('time').optional()
      .matches(/^\d{2}:\d{2}(:\d{2})?$/).withMessage('时间格式应为HH:MM或HH:MM:SS'),
    body('priority').optional()
      .isIn(['low', 'medium', 'high']).withMessage('优先级必须是low、medium或high'),
    body('is_completed').optional().isBoolean().withMessage('is_completed必须是布尔值'),
    body('is_recurring').optional().isBoolean().withMessage('is_recurring必须是布尔值'),
  ],
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.updateReminder
);

// 删除提醒事项
router.delete('/:id',
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.deleteReminder
);

// 标记提醒事项为已完成/未完成
router.put('/:id/complete',
  [
    // 验证请求体
    body('completed').isBoolean().withMessage('completed必须是布尔值'),
  ],
  // authMiddleware.isAuthenticated, // 如果需要认证
  reminderController.markComplete
);

module.exports = router;
