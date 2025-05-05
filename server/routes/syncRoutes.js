/**
 * 同步路由
 */
const express = require('express');
const { body } = require('express-validator');
const syncController = require('../controllers/syncController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 获取同步记录
router.get('/records',
  authMiddleware.isAuthenticated,
  syncController.getSyncRecords
);

// 获取最后同步时间
router.get('/last-sync-time',
  authMiddleware.isAuthenticated,
  syncController.getLastSyncTime
);

// 同步数据
router.post('/',
  authMiddleware.isAuthenticated,
  [
    // 验证请求体
    body('device_id').notEmpty().withMessage('设备ID不能为空'),
    body('operations').isArray().withMessage('operations必须是数组'),
    body('operations.*.entity_type').notEmpty().withMessage('实体类型不能为空'),
    body('operations.*.operation_type').notEmpty().withMessage('操作类型不能为空'),
    body('operations.*.entity_id').notEmpty().withMessage('实体ID不能为空')
  ],
  syncController.syncData
);

// 解决同步冲突
router.post('/resolve-conflict',
  authMiddleware.isAuthenticated,
  [
    // 验证请求体
    body('sync_record_id').notEmpty().withMessage('同步记录ID不能为空'),
    body('resolution').notEmpty().withMessage('解决方式不能为空')
      .isIn(['client', 'server', 'merge']).withMessage('解决方式必须是client、server或merge')
  ],
  syncController.resolveSyncConflict
);

module.exports = router;
