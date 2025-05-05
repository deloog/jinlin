/**
 * 配置管理路由
 */
const express = require('express');
const router = express.Router();
const { configManager } = require('../services/configService');
const { requireRole } = require('../middleware/permissionMiddleware');
const { validate, validators } = require('../middleware/validationMiddleware');
const logger = require('../utils/enhancedLogger');

// 获取配置
router.get('/', requireRole('admin'), async (req, res) => {
  try {
    // 获取查询参数
    const { key } = req.query;
    
    // 如果指定了key，获取单个配置
    if (key) {
      const value = await configManager.get(key);
      
      if (value === null) {
        return res.status(404).json({
          error: 'Not Found',
          message: `配置 ${key} 不存在`,
          code: 'CONFIG_NOT_FOUND'
        });
      }
      
      return res.json({
        key,
        value
      });
    }
    
    // 否则获取所有配置
    const configs = {};
    
    for (const [key, value] of configManager.configCache.entries()) {
      configs[key] = value;
    }
    
    return res.json(configs);
  } catch (error) {
    logger.error('获取配置失败', { error });
    
    return res.status(500).json({
      error: 'Internal Server Error',
      message: '获取配置失败',
      code: 'CONFIG_GET_ERROR'
    });
  }
});

// 设置配置
router.post('/', requireRole('admin'), validate([
  validators.string.notEmpty().withMessage('配置键不能为空').bail()
    .isLength({ min: 1, max: 100 }).withMessage('配置键长度必须在1到100个字符之间')
    .custom(value => {
      if (!/^[a-zA-Z0-9_.]+$/.test(value)) {
        throw new Error('配置键只能包含字母、数字、下划线和点');
      }
      return true;
    }),
]), async (req, res) => {
  try {
    // 获取请求体
    const { key, value, source = 'database', persist = true, valueType = typeof value } = req.body;
    
    // 设置配置
    const success = await configManager.set(key, value, {
      source,
      persist,
      valueType
    });
    
    if (!success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '设置配置失败',
        code: 'CONFIG_SET_ERROR'
      });
    }
    
    return res.json({
      key,
      value,
      message: '配置已更新'
    });
  } catch (error) {
    logger.error('设置配置失败', { error });
    
    return res.status(500).json({
      error: 'Internal Server Error',
      message: '设置配置失败',
      code: 'CONFIG_SET_ERROR'
    });
  }
});

// 删除配置
router.delete('/:key', requireRole('admin'), async (req, res) => {
  try {
    // 获取路径参数
    const { key } = req.params;
    
    // 获取查询参数
    const { source = 'database', persist = true } = req.query;
    
    // 删除配置
    const success = await configManager.delete(key, {
      source,
      persist
    });
    
    if (!success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '删除配置失败',
        code: 'CONFIG_DELETE_ERROR'
      });
    }
    
    return res.json({
      key,
      message: '配置已删除'
    });
  } catch (error) {
    logger.error('删除配置失败', { error });
    
    return res.status(500).json({
      error: 'Internal Server Error',
      message: '删除配置失败',
      code: 'CONFIG_DELETE_ERROR'
    });
  }
});

// 清除配置缓存
router.post('/clear-cache', requireRole('admin'), async (req, res) => {
  try {
    // 清除配置缓存
    await configManager.clearCache();
    
    return res.json({
      message: '配置缓存已清除'
    });
  } catch (error) {
    logger.error('清除配置缓存失败', { error });
    
    return res.status(500).json({
      error: 'Internal Server Error',
      message: '清除配置缓存失败',
      code: 'CONFIG_CLEAR_CACHE_ERROR'
    });
  }
});

// 注册配置架构
router.post('/schema', requireRole('admin'), async (req, res) => {
  try {
    // 获取请求体
    const { key, schema } = req.body;
    
    // 验证架构
    if (!key || !schema) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '配置键和架构不能为空',
        code: 'INVALID_SCHEMA'
      });
    }
    
    // 尝试解析架构
    try {
      const Joi = require('joi');
      const parsedSchema = eval(`(${schema})`);
      
      // 注册架构
      configManager.registerSchema(key, parsedSchema);
      
      return res.json({
        key,
        message: '配置架构已注册'
      });
    } catch (error) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '无效的架构定义',
        code: 'INVALID_SCHEMA',
        details: error.message
      });
    }
  } catch (error) {
    logger.error('注册配置架构失败', { error });
    
    return res.status(500).json({
      error: 'Internal Server Error',
      message: '注册配置架构失败',
      code: 'SCHEMA_REGISTER_ERROR'
    });
  }
});

// 导出路由
module.exports = router;
