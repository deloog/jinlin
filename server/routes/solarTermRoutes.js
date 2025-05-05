/**
 * 24节气路由
 */
const express = require('express');
const { body } = require('express-validator');
const solarTermController = require('../controllers/solarTermController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 获取指定年份的24节气
router.get('/', solarTermController.getSolarTerms);

// 获取当天的节气
router.get('/current', solarTermController.getCurrentSolarTerm);

// 获取下一个节气
router.get('/next', solarTermController.getNextSolarTerm);

// 更新24节气数据（仅管理员）
router.post('/update',
  authMiddleware.isAdmin,
  [
    body('years').optional().isInt({ min: 1, max: 10 }).withMessage('年数应为1-10之间的整数')
  ],
  solarTermController.updateSolarTerms
);

module.exports = router;
