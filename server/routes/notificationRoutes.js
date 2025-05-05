/**
 * 通知路由
 */
const express = require('express');
const { body, param, query } = require('express-validator');
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/auth');
const { globalLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用全局速率限制
router.use(globalLimiter);

// 保存设备令牌
router.post('/tokens',
  authMiddleware.isAuthenticated,
  [
    body('device_id').notEmpty().withMessage('device_id不能为空'),
    body('token').notEmpty().withMessage('token不能为空'),
    body('platform').notEmpty().withMessage('platform不能为空')
      .isIn(['ios', 'android', 'web']).withMessage('platform必须是ios、android或web')
  ],
  notificationController.saveDeviceToken
);

// 删除设备令牌
router.delete('/tokens',
  authMiddleware.isAuthenticated,
  [
    body('device_id').notEmpty().withMessage('device_id不能为空')
  ],
  notificationController.removeDeviceToken
);

// 获取用户的通知
router.get('/',
  authMiddleware.isAuthenticated,
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit必须是1-100之间的整数'),
    query('offset').optional().isInt({ min: 0 }).withMessage('offset必须是非负整数'),
    query('unread_only').optional().isBoolean().withMessage('unread_only必须是布尔值')
  ],
  notificationController.getUserNotifications
);

// 标记通知为已读
router.put('/:notification_id/read',
  authMiddleware.isAuthenticated,
  [
    param('notification_id').notEmpty().withMessage('notification_id不能为空')
  ],
  notificationController.markNotificationAsRead
);

// 标记所有通知为已读
router.put('/read-all',
  authMiddleware.isAuthenticated,
  notificationController.markAllNotificationsAsRead
);

// 删除通知
router.delete('/:notification_id',
  authMiddleware.isAuthenticated,
  [
    param('notification_id').notEmpty().withMessage('notification_id不能为空')
  ],
  notificationController.deleteNotification
);

// 发送测试通知
router.post('/test',
  authMiddleware.isAuthenticated,
  [
    body('title').notEmpty().withMessage('title不能为空'),
    body('body').notEmpty().withMessage('body不能为空')
  ],
  notificationController.sendTestNotification
);

module.exports = router;
