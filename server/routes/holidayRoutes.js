/**
 * 节日路由
 */
const express = require('express');
const { body } = require('express-validator');
const holidayController = require('../controllers/holidayController');
// const authMiddleware = require('../middleware/auth'); // 如果需要认证

const router = express.Router();

// 获取节日列表
router.get('/', holidayController.getHolidays);

// 获取单个节日
router.get('/:id', holidayController.getHoliday);

// 创建节日
router.post('/',
  [
    // 验证请求体
    body('name').notEmpty().withMessage('节日名称不能为空'),
    body('type').notEmpty().withMessage('节日类型不能为空'),
    body('regions').notEmpty().withMessage('适用地区不能为空'),
    body('calculation_type').notEmpty().withMessage('计算类型不能为空'),
    body('calculation_rule').notEmpty().withMessage('计算规则不能为空'),
  ],
  // authMiddleware.isAdmin, // 如果需要管理员权限
  holidayController.createHoliday
);

// 更新节日
router.put('/:id',
  [
    // 验证请求体
    body('name').optional(),
    body('type').optional(),
    body('regions').optional(),
    body('calculation_type').optional(),
    body('calculation_rule').optional(),
  ],
  // authMiddleware.isAdmin, // 如果需要管理员权限
  holidayController.updateHoliday
);

// 删除节日
router.delete('/:id',
  // authMiddleware.isAdmin, // 如果需要管理员权限
  holidayController.deleteHoliday
);

// 批量创建节日
router.post('/batch',
  [
    // 验证请求体
    body('holidays').isArray().withMessage('holidays必须是数组'),
    body('holidays.*.name').notEmpty().withMessage('节日名称不能为空'),
    body('holidays.*.type').notEmpty().withMessage('节日类型不能为空'),
    body('holidays.*.regions').notEmpty().withMessage('适用地区不能为空'),
    body('holidays.*.calculation_type').notEmpty().withMessage('计算类型不能为空'),
    body('holidays.*.calculation_rule').notEmpty().withMessage('计算规则不能为空'),
  ],
  // authMiddleware.isAdmin, // 如果需要管理员权限
  holidayController.batchCreateHolidays
);

module.exports = router;
