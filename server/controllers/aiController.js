/**
 * AI控制器
 */
const aiService = require('../services/aiService');
const holidayService = require('../services/holidayService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 生成提醒事项描述
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.generateReminderDescription = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { input, language, model, temperature } = req.body;
    
    if (!input) {
      return res.status(400).json({ error: '缺少input参数' });
    }
    
    // 生成描述
    const description = await aiService.generateReminderDescription(input, language, {
      model,
      temperature
    });
    
    res.json({ data: description });
  } catch (error) {
    logger.error('生成提醒事项描述失败:', error);
    res.status(500).json({ error: '生成提醒事项描述失败' });
  }
};

/**
 * 生成节日描述
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.generateHolidayDescription = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { holidayId, language, model, temperature } = req.body;
    
    if (!holidayId) {
      return res.status(400).json({ error: '缺少holidayId参数' });
    }
    
    // 获取节日
    try {
      const holiday = await holidayService.getHoliday(holidayId);
      
      // 生成描述
      const description = await aiService.generateHolidayDescription(holiday, language, {
        model,
        temperature
      });
      
      res.json({ data: description });
    } catch (error) {
      if (error.message === '节日不存在') {
        return res.status(404).json({ error: '节日不存在' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('生成节日描述失败:', error);
    res.status(500).json({ error: '生成节日描述失败' });
  }
};

/**
 * 生成多语言翻译
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.generateTranslation = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { text, sourceLanguage, targetLanguage, model, temperature } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: '缺少text参数' });
    }
    
    if (!targetLanguage) {
      return res.status(400).json({ error: '缺少targetLanguage参数' });
    }
    
    // 生成翻译
    const translation = await aiService.generateTranslation(text, sourceLanguage, targetLanguage, {
      model,
      temperature
    });
    
    res.json({ data: translation });
  } catch (error) {
    logger.error('生成翻译失败:', error);
    res.status(500).json({ error: '生成翻译失败' });
  }
};

/**
 * 解析一句话提醒
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.parseOneSentenceReminder = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { input, language, model, temperature } = req.body;
    
    if (!input) {
      return res.status(400).json({ error: '缺少input参数' });
    }
    
    // 解析一句话提醒
    const reminderData = await aiService.parseOneSentenceReminder(input, language, {
      model,
      temperature
    });
    
    res.json({ data: reminderData });
  } catch (error) {
    logger.error('解析一句话提醒失败:', error);
    res.status(500).json({ error: '解析一句话提醒失败' });
  }
};

/**
 * 获取支持的AI模型
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSupportedModels = async (req, res) => {
  try {
    const models = aiService.getSupportedModels();
    res.json({ data: models });
  } catch (error) {
    logger.error('获取支持的AI模型失败:', error);
    res.status(500).json({ error: '获取支持的AI模型失败' });
  }
};
