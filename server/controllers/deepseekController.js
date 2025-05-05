/**
 * Deepseek控制器
 */
const deepseekService = require('../services/deepseekService');
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
    const description = await deepseekService.processText(input, language, {
      model,
      temperature
    });
    
    res.json({ data: description });
  } catch (error) {
    logger.error('生成提醒事项描述失败:', error);
    res.status(500).json({ error: '生成提醒事项描述失败: ' + error.message });
  }
};

/**
 * 解析自然语言输入
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.extractEventsFromText = async (req, res) => {
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
    
    // 解析自然语言输入
    const events = await deepseekService.extractEventsFromText(input, language, {
      model,
      temperature
    });
    
    res.json({ data: events });
  } catch (error) {
    logger.error('解析自然语言输入失败:', error);
    res.status(500).json({ error: '解析自然语言输入失败: ' + error.message });
  }
};

/**
 * 生成自定义响应
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.generateCustomResponse = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { prompt, language, model, temperature, max_tokens } = req.body;
    
    if (!prompt) {
      return res.status(400).json({ error: '缺少prompt参数' });
    }
    
    // 生成自定义响应
    // 这里我们复用processText方法，但可以根据需要创建新的方法
    const response = await deepseekService.processText(prompt, language, {
      model,
      temperature,
      max_tokens: max_tokens || 300
    });
    
    res.json({ data: response });
  } catch (error) {
    logger.error('生成自定义响应失败:', error);
    res.status(500).json({ error: '生成自定义响应失败: ' + error.message });
  }
};

/**
 * 批量生成描述
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.batchGenerateDescriptions = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { titles, language, model, temperature } = req.body;
    
    if (!titles || !Array.isArray(titles) || titles.length === 0) {
      return res.status(400).json({ error: '缺少titles参数或格式无效' });
    }
    
    // 批量生成描述
    const descriptions = [];
    
    for (const title of titles) {
      try {
        const description = await deepseekService.processText(title, language, {
          model,
          temperature
        });
        
        descriptions.push({
          title,
          description
        });
      } catch (error) {
        descriptions.push({
          title,
          error: error.message
        });
      }
    }
    
    res.json({ data: descriptions });
  } catch (error) {
    logger.error('批量生成描述失败:', error);
    res.status(500).json({ error: '批量生成描述失败: ' + error.message });
  }
};
