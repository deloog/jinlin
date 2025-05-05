/**
 * 文件路由
 */
const express = require('express');
const { body, param, query } = require('express-validator');
const fileController = require('../controllers/fileController');
const fileService = require('../services/fileService');
const authMiddleware = require('../middleware/auth');
const { globalLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用全局速率限制
router.use(globalLimiter);

// 上传单个文件
router.post('/',
  authMiddleware.isAuthenticated,
  fileService.upload.single('file'),
  fileController.uploadFile
);

// 上传多个文件
router.post('/multiple',
  authMiddleware.isAuthenticated,
  fileService.upload.array('files', 5),
  fileController.uploadMultipleFiles
);

// 获取文件
router.get('/:file_id',
  fileController.getFile
);

// 获取文件信息
router.get('/:file_id/info',
  authMiddleware.isAuthenticated,
  [
    param('file_id').notEmpty().withMessage('file_id不能为空')
  ],
  fileController.getFileInfo
);

// 获取用户的文件
router.get('/',
  authMiddleware.isAuthenticated,
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit必须是1-100之间的整数'),
    query('offset').optional().isInt({ min: 0 }).withMessage('offset必须是非负整数'),
    query('entity_type').optional(),
    query('entity_id').optional()
  ],
  fileController.getUserFiles
);

// 删除文件
router.delete('/:file_id',
  authMiddleware.isAuthenticated,
  [
    param('file_id').notEmpty().withMessage('file_id不能为空')
  ],
  fileController.deleteFile
);

// 关联文件到实体
router.put('/:file_id/associate',
  authMiddleware.isAuthenticated,
  [
    param('file_id').notEmpty().withMessage('file_id不能为空'),
    body('entity_type').notEmpty().withMessage('entity_type不能为空'),
    body('entity_id').notEmpty().withMessage('entity_id不能为空')
  ],
  fileController.associateFileWithEntity
);

module.exports = router;
