/**
 * 备份路由
 *
 * 提供备份相关的API：
 * - 获取备份状态
 * - 执行手动备份
 * - 获取备份任务状态
 * - 更新备份配置
 * - 删除备份文件
 */

const express = require('express');
const { body, param } = require('express-validator');
const backupController = require('../controllers/backupController');
const authMiddleware = require('../middleware/auth');
const { adminLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用管理员速率限制
router.use(adminLimiter);

// 获取备份状态
router.get('/status',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  backupController.getBackupStatus
);

// 执行手动备份
router.post('/execute',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    body('type')
      .optional()
      .isIn(['full', 'db', 'files', 'config'])
      .withMessage('备份类型必须是 full、db、files 或 config'),
    body('upload')
      .optional()
      .isBoolean()
      .withMessage('upload 必须是布尔值')
  ],
  backupController.executeManualBackup
);

// 获取备份任务状态
router.get('/task/:taskId',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    param('taskId')
      .isString()
      .withMessage('任务ID必须是字符串')
  ],
  backupController.getBackupTaskStatus
);

// 更新备份配置
router.put('/config',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    body('enabled')
      .optional()
      .isBoolean()
      .withMessage('enabled 必须是布尔值'),
    body('schedules.daily')
      .optional()
      .isString()
      .withMessage('daily 必须是字符串'),
    body('schedules.weekly')
      .optional()
      .isString()
      .withMessage('weekly 必须是字符串'),
    body('schedules.monthly')
      .optional()
      .isString()
      .withMessage('monthly 必须是字符串'),
    body('retention.daily')
      .optional()
      .isInt({ min: 1 })
      .withMessage('daily 必须是大于0的整数'),
    body('retention.weekly')
      .optional()
      .isInt({ min: 1 })
      .withMessage('weekly 必须是大于0的整数'),
    body('retention.monthly')
      .optional()
      .isInt({ min: 1 })
      .withMessage('monthly 必须是大于0的整数'),
    body('upload.enabled')
      .optional()
      .isBoolean()
      .withMessage('enabled 必须是布尔值'),
    body('upload.destinations')
      .optional()
      .isArray()
      .withMessage('destinations 必须是数组'),
    body('notification.success')
      .optional()
      .isBoolean()
      .withMessage('success 必须是布尔值'),
    body('notification.failure')
      .optional()
      .isBoolean()
      .withMessage('failure 必须是布尔值'),
    body('monitoring.enabled')
      .optional()
      .isBoolean()
      .withMessage('enabled 必须是布尔值'),
    body('monitoring.interval')
      .optional()
      .isInt({ min: 60000 })
      .withMessage('interval 必须是大于60000的整数'),
    body('monitoring.thresholds.age.daily')
      .optional()
      .isInt({ min: 3600000 })
      .withMessage('daily 必须是大于3600000的整数'),
    body('monitoring.thresholds.age.weekly')
      .optional()
      .isInt({ min: 3600000 })
      .withMessage('weekly 必须是大于3600000的整数'),
    body('monitoring.thresholds.age.monthly')
      .optional()
      .isInt({ min: 3600000 })
      .withMessage('monthly 必须是大于3600000的整数'),
    body('monitoring.thresholds.size.min')
      .optional()
      .isInt({ min: 1 })
      .withMessage('min 必须是大于0的整数'),
    body('monitoring.thresholds.size.warning')
      .optional()
      .isInt({ min: 1024 })
      .withMessage('warning 必须是大于1024的整数'),
    body('monitoring.alertLevels.missing')
      .optional()
      .isIn(['info', 'warning', 'error', 'critical'])
      .withMessage('missing 必须是 info、warning、error 或 critical'),
    body('monitoring.alertLevels.tooOld')
      .optional()
      .isIn(['info', 'warning', 'error', 'critical'])
      .withMessage('tooOld 必须是 info、warning、error 或 critical'),
    body('monitoring.alertLevels.tooSmall')
      .optional()
      .isIn(['info', 'warning', 'error', 'critical'])
      .withMessage('tooSmall 必须是 info、warning、error 或 critical'),
    body('monitoring.alertLevels.tooLarge')
      .optional()
      .isIn(['info', 'warning', 'error', 'critical'])
      .withMessage('tooLarge 必须是 info、warning、error 或 critical')
  ],
  backupController.updateBackupConfig
);

// 删除备份文件
router.delete('/file/:fileName',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    param('fileName')
      .isString()
      .withMessage('文件名必须是字符串')
  ],
  backupController.deleteBackupFile
);

module.exports = router;
