/**
 * 多语言控制器
 */
const localizationService = require('../services/localizationService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取支持的语言列表
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSupportedLanguages = async (req, res) => {
  try {
    const { language } = req.query;
    
    const supportedLanguages = localizationService.getSupportedLanguages();
    
    // 如果指定了语言，则返回该语言的语言名称
    if (language) {
      const languageNames = supportedLanguages.map(lang => ({
        code: lang,
        name: localizationService.getLanguageName(lang, language)
      }));
      
      res.json({ data: languageNames });
    } else {
      res.json({ data: supportedLanguages });
    }
  } catch (error) {
    logger.error('获取支持的语言列表失败:', error);
    res.status(500).json({ error: '获取支持的语言列表失败' });
  }
};

/**
 * 获取翻译
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTranslation = async (req, res) => {
  try {
    const { key, context, language } = req.query;
    
    if (!key) {
      return res.status(400).json({ error: '缺少key参数' });
    }
    
    const translation = await localizationService.getTranslation(key, context, language);
    
    res.json({ data: translation });
  } catch (error) {
    logger.error('获取翻译失败:', error);
    res.status(500).json({ error: '获取翻译失败' });
  }
};

/**
 * 设置翻译
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.setTranslation = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { key, translations, context } = req.body;
    
    if (!key) {
      return res.status(400).json({ error: '缺少key参数' });
    }
    
    if (!translations || Object.keys(translations).length === 0) {
      return res.status(400).json({ error: '缺少translations参数' });
    }
    
    const result = await localizationService.setTranslation(key, translations, context);
    
    res.json({ data: result });
  } catch (error) {
    logger.error('设置翻译失败:', error);
    res.status(500).json({ error: '设置翻译失败' });
  }
};

/**
 * 获取所有翻译
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getAllTranslations = async (req, res) => {
  try {
    const { language } = req.query;
    
    const translations = await localizationService.getAllTranslations(language);
    
    res.json({ data: translations });
  } catch (error) {
    logger.error('获取所有翻译失败:', error);
    res.status(500).json({ error: '获取所有翻译失败' });
  }
};

/**
 * 删除翻译
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.deleteTranslation = async (req, res) => {
  try {
    const { key, context } = req.query;
    
    if (!key) {
      return res.status(400).json({ error: '缺少key参数' });
    }
    
    const success = await localizationService.deleteTranslation(key, context);
    
    if (success) {
      res.json({ message: '翻译删除成功' });
    } else {
      res.status(404).json({ error: '翻译不存在' });
    }
  } catch (error) {
    logger.error('删除翻译失败:', error);
    res.status(500).json({ error: '删除翻译失败' });
  }
};
