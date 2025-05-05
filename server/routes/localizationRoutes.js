/**
 * 多语言路由
 */
const express = require('express');
const { body } = require('express-validator');
const localizationController = require('../controllers/localizationController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 获取支持的语言列表
router.get('/languages', localizationController.getSupportedLanguages);

// 获取翻译
router.get('/translations', localizationController.getTranslation);

// 获取所有翻译
router.get('/translations/all', localizationController.getAllTranslations);

// 设置翻译（仅管理员）
router.post('/translations',
  authMiddleware.isAdmin,
  [
    body('key').notEmpty().withMessage('key不能为空'),
    body('translations').notEmpty().withMessage('translations不能为空')
  ],
  localizationController.setTranslation
);

// 删除翻译（仅管理员）
router.delete('/translations',
  authMiddleware.isAdmin,
  localizationController.deleteTranslation
);

module.exports = router;
