/**
 * 配置管理服务
 * 
 * 提供动态配置管理功能：
 * - 动态配置更新
 * - 配置验证
 * - 环境特定配置
 * - 配置缓存
 * - 配置变更通知
 */
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');
const Joi = require('joi');
const dotenv = require('dotenv');
const { cacheService } = require('./cacheService');
const logger = require('../utils/enhancedLogger');

// 缓存命名空间
const CACHE_NAMESPACE = 'config';

// 默认配置
const DEFAULT_CONFIG = {
  // 配置源
  sources: {
    // 环境变量
    env: {
      enabled: true,
      priority: 3
    },
    
    // 配置文件
    file: {
      enabled: true,
      priority: 2,
      path: process.env.CONFIG_FILE_PATH || path.join(__dirname, '../../config.json')
    },
    
    // 数据库
    database: {
      enabled: process.env.CONFIG_DB_ENABLED === 'true' || false,
      priority: 1,
      table: process.env.CONFIG_DB_TABLE || 'app_config',
      refreshInterval: parseInt(process.env.CONFIG_DB_REFRESH_INTERVAL || '60000', 10) // 默认1分钟
    }
  },
  
  // 缓存配置
  cache: {
    enabled: true,
    ttl: parseInt(process.env.CONFIG_CACHE_TTL || '300000', 10) // 默认5分钟
  },
  
  // 验证配置
  validation: {
    enabled: true,
    strictMode: process.env.CONFIG_VALIDATION_STRICT === 'true' || false
  }
};

/**
 * 配置管理器
 */
class ConfigManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} options - 选项
   */
  constructor(options = {}) {
    super();
    
    // 合并配置
    this.options = {
      ...DEFAULT_CONFIG,
      ...options
    };
    
    // 配置缓存
    this.configCache = new Map();
    
    // 配置架构
    this.schemas = new Map();
    
    // 初始化
    this._init();
    
    logger.info('配置管理器已初始化');
  }
  
  /**
   * 初始化
   * @private
   */
  _init() {
    // 加载环境变量
    this._loadEnvVariables();
    
    // 如果启用了数据库配置，设置定时刷新
    if (this.options.sources.database.enabled) {
      this._setupDatabaseRefresh();
    }
  }
  
  /**
   * 加载环境变量
   * @private
   */
  _loadEnvVariables() {
    try {
      // 获取当前环境
      const env = process.env.NODE_ENV || 'development';
      
      // 加载对应环境的配置文件
      const envPath = path.join(process.cwd(), `.env.${env}`);
      if (fs.existsSync(envPath)) {
        dotenv.config({ path: envPath });
      }
      
      // 加载默认配置文件
      const defaultEnvPath = path.join(process.cwd(), '.env');
      if (fs.existsSync(defaultEnvPath)) {
        dotenv.config({ path: defaultEnvPath });
      }
    } catch (error) {
      logger.error('加载环境变量失败', { error });
    }
  }
  
  /**
   * 设置数据库配置刷新
   * @private
   */
  _setupDatabaseRefresh() {
    // 设置定时器
    this.refreshInterval = setInterval(() => {
      this._refreshDatabaseConfig();
    }, this.options.sources.database.refreshInterval);
    
    // 立即刷新一次
    this._refreshDatabaseConfig();
  }
  
  /**
   * 刷新数据库配置
   * @private
   */
  async _refreshDatabaseConfig() {
    try {
      // 从数据库加载配置
      const configs = await this._loadConfigFromDatabase();
      
      // 更新配置缓存
      for (const [key, value] of Object.entries(configs)) {
        this.configCache.set(key, value);
      }
      
      // 触发刷新事件
      this.emit('refresh', configs);
      
      logger.debug('数据库配置已刷新');
    } catch (error) {
      logger.error('刷新数据库配置失败', { error });
    }
  }
  
  /**
   * 从数据库加载配置
   * @returns {Promise<Object>} 配置对象
   * @private
   */
  async _loadConfigFromDatabase() {
    try {
      // 从缓存获取
      if (this.options.cache.enabled) {
        const cachedConfig = await cacheService.get(CACHE_NAMESPACE, 'db_config');
        
        if (cachedConfig) {
          return cachedConfig;
        }
      }
      
      // 从数据库获取
      const { dbPoolManager } = require('../config/database');
      
      const results = await dbPoolManager.query(
        `SELECT key_name, value, value_type FROM ${this.options.sources.database.table} WHERE is_active = 1`
      );
      
      // 解析配置
      const configs = {};
      
      for (const row of results) {
        try {
          // 根据类型解析值
          let value;
          
          switch (row.value_type) {
            case 'number':
              value = parseFloat(row.value);
              break;
              
            case 'boolean':
              value = row.value === 'true';
              break;
              
            case 'json':
              value = JSON.parse(row.value);
              break;
              
            case 'string':
            default:
              value = row.value;
              break;
          }
          
          configs[row.key_name] = value;
        } catch (error) {
          logger.error('解析配置值失败', { error, key: row.key_name, value: row.value, type: row.value_type });
        }
      }
      
      // 缓存配置
      if (this.options.cache.enabled) {
        await cacheService.set(CACHE_NAMESPACE, 'db_config', configs, this.options.cache.ttl);
      }
      
      return configs;
    } catch (error) {
      logger.error('从数据库加载配置失败', { error });
      return {};
    }
  }
  
  /**
   * 从文件加载配置
   * @returns {Promise<Object>} 配置对象
   * @private
   */
  async _loadConfigFromFile() {
    try {
      // 从缓存获取
      if (this.options.cache.enabled) {
        const cachedConfig = await cacheService.get(CACHE_NAMESPACE, 'file_config');
        
        if (cachedConfig) {
          return cachedConfig;
        }
      }
      
      // 检查文件是否存在
      const filePath = this.options.sources.file.path;
      
      if (!fs.existsSync(filePath)) {
        logger.warn('配置文件不存在', { path: filePath });
        return {};
      }
      
      // 读取文件
      const fileContent = fs.readFileSync(filePath, 'utf8');
      
      // 解析JSON
      const configs = JSON.parse(fileContent);
      
      // 缓存配置
      if (this.options.cache.enabled) {
        await cacheService.set(CACHE_NAMESPACE, 'file_config', configs, this.options.cache.ttl);
      }
      
      return configs;
    } catch (error) {
      logger.error('从文件加载配置失败', { error });
      return {};
    }
  }
  
  /**
   * 从环境变量加载配置
   * @param {string} prefix - 环境变量前缀
   * @returns {Object} 配置对象
   * @private
   */
  _loadConfigFromEnv(prefix = 'APP_CONFIG_') {
    try {
      const configs = {};
      
      // 遍历环境变量
      for (const [key, value] of Object.entries(process.env)) {
        // 检查前缀
        if (key.startsWith(prefix)) {
          // 移除前缀
          const configKey = key.substring(prefix.length).toLowerCase();
          
          // 解析值
          let parsedValue = value;
          
          // 尝试解析为数字
          if (/^-?\d+(\.\d+)?$/.test(value)) {
            parsedValue = parseFloat(value);
          }
          // 尝试解析为布尔值
          else if (value === 'true' || value === 'false') {
            parsedValue = value === 'true';
          }
          // 尝试解析为JSON
          else if (value.startsWith('{') || value.startsWith('[')) {
            try {
              parsedValue = JSON.parse(value);
            } catch (e) {
              // 如果解析失败，保持原始值
              parsedValue = value;
            }
          }
          
          configs[configKey] = parsedValue;
        }
      }
      
      return configs;
    } catch (error) {
      logger.error('从环境变量加载配置失败', { error });
      return {};
    }
  }
  
  /**
   * 注册配置架构
   * @param {string} key - 配置键
   * @param {Object} schema - Joi架构
   */
  registerSchema(key, schema) {
    this.schemas.set(key, schema);
    logger.debug(`已注册配置架构: ${key}`);
  }
  
  /**
   * 验证配置
   * @param {string} key - 配置键
   * @param {*} value - 配置值
   * @returns {Object} 验证结果
   * @private
   */
  _validateConfig(key, value) {
    // 如果未启用验证，返回原始值
    if (!this.options.validation.enabled) {
      return { value, valid: true };
    }
    
    // 获取架构
    const schema = this.schemas.get(key);
    
    // 如果没有架构，返回原始值
    if (!schema) {
      return { value, valid: true };
    }
    
    // 验证值
    const { error, value: validatedValue } = schema.validate(value, {
      abortEarly: false,
      stripUnknown: true
    });
    
    // 如果有错误
    if (error) {
      const errorDetails = error.details.map(detail => detail.message).join(', ');
      
      logger.warn(`配置验证失败: ${key}`, { error: errorDetails, value });
      
      // 如果启用了严格模式，返回错误
      if (this.options.validation.strictMode) {
        return { valid: false, error: errorDetails };
      }
    }
    
    // 返回验证后的值
    return { value: validatedValue || value, valid: !error };
  }
  
  /**
   * 获取配置
   * @param {string} key - 配置键
   * @param {*} defaultValue - 默认值
   * @returns {Promise<*>} 配置值
   */
  async get(key, defaultValue = null) {
    try {
      // 从缓存获取
      if (this.configCache.has(key)) {
        return this.configCache.get(key);
      }
      
      // 按优先级获取配置
      const sources = Object.entries(this.options.sources)
        .filter(([, config]) => config.enabled)
        .sort((a, b) => a[1].priority - b[1].priority);
      
      let value = defaultValue;
      
      for (const [sourceName, sourceConfig] of sources) {
        let sourceValue;
        
        // 从不同源获取配置
        switch (sourceName) {
          case 'env':
            sourceValue = this._loadConfigFromEnv()[key];
            break;
            
          case 'file':
            const fileConfig = await this._loadConfigFromFile();
            sourceValue = fileConfig[key];
            break;
            
          case 'database':
            const dbConfig = await this._loadConfigFromDatabase();
            sourceValue = dbConfig[key];
            break;
        }
        
        // 如果找到值，更新
        if (sourceValue !== undefined) {
          value = sourceValue;
        }
      }
      
      // 验证配置
      const { value: validatedValue, valid } = this._validateConfig(key, value);
      
      // 如果验证失败且启用了严格模式，返回默认值
      if (!valid && this.options.validation.strictMode) {
        return defaultValue;
      }
      
      // 缓存配置
      this.configCache.set(key, validatedValue);
      
      return validatedValue;
    } catch (error) {
      logger.error(`获取配置失败: ${key}`, { error });
      return defaultValue;
    }
  }
  
  /**
   * 设置配置
   * @param {string} key - 配置键
   * @param {*} value - 配置值
   * @param {Object} options - 选项
   * @returns {Promise<boolean>} 是否成功
   */
  async set(key, value, options = {}) {
    try {
      // 默认选项
      const defaultOptions = {
        source: 'database', // 配置源
        persist: true, // 是否持久化
        valueType: typeof value // 值类型
      };
      
      // 合并选项
      const setOptions = { ...defaultOptions, ...options };
      
      // 验证配置
      const { value: validatedValue, valid } = this._validateConfig(key, value);
      
      // 如果验证失败且启用了严格模式，返回失败
      if (!valid && this.options.validation.strictMode) {
        return false;
      }
      
      // 更新缓存
      this.configCache.set(key, validatedValue);
      
      // 如果需要持久化
      if (setOptions.persist) {
        switch (setOptions.source) {
          case 'file':
            await this._saveConfigToFile(key, validatedValue);
            break;
            
          case 'database':
            await this._saveConfigToDatabase(key, validatedValue, setOptions.valueType);
            break;
            
          default:
            logger.warn(`不支持的配置源: ${setOptions.source}`);
            return false;
        }
      }
      
      // 触发更新事件
      this.emit('update', { key, value: validatedValue });
      
      return true;
    } catch (error) {
      logger.error(`设置配置失败: ${key}`, { error, value });
      return false;
    }
  }
  
  /**
   * 将配置保存到文件
   * @param {string} key - 配置键
   * @param {*} value - 配置值
   * @returns {Promise<boolean>} 是否成功
   * @private
   */
  async _saveConfigToFile(key, value) {
    try {
      // 获取文件路径
      const filePath = this.options.sources.file.path;
      
      // 读取现有配置
      let config = {};
      
      if (fs.existsSync(filePath)) {
        const fileContent = fs.readFileSync(filePath, 'utf8');
        config = JSON.parse(fileContent);
      }
      
      // 更新配置
      config[key] = value;
      
      // 写入文件
      fs.writeFileSync(filePath, JSON.stringify(config, null, 2), 'utf8');
      
      // 清除缓存
      if (this.options.cache.enabled) {
        await cacheService.del(CACHE_NAMESPACE, 'file_config');
      }
      
      return true;
    } catch (error) {
      logger.error(`将配置保存到文件失败: ${key}`, { error, value });
      return false;
    }
  }
  
  /**
   * 将配置保存到数据库
   * @param {string} key - 配置键
   * @param {*} value - 配置值
   * @param {string} valueType - 值类型
   * @returns {Promise<boolean>} 是否成功
   * @private
   */
  async _saveConfigToDatabase(key, value, valueType) {
    try {
      // 获取数据库连接
      const { dbPoolManager } = require('../config/database');
      
      // 准备值
      let stringValue;
      
      if (typeof value === 'object') {
        stringValue = JSON.stringify(value);
        valueType = 'json';
      } else {
        stringValue = String(value);
      }
      
      // 更新或插入配置
      await dbPoolManager.query(`
        INSERT INTO ${this.options.sources.database.table}
        (key_name, value, value_type, updated_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
        value = VALUES(value),
        value_type = VALUES(value_type),
        updated_at = NOW()
      `, [key, stringValue, valueType]);
      
      // 清除缓存
      if (this.options.cache.enabled) {
        await cacheService.del(CACHE_NAMESPACE, 'db_config');
      }
      
      return true;
    } catch (error) {
      logger.error(`将配置保存到数据库失败: ${key}`, { error, value });
      return false;
    }
  }
  
  /**
   * 删除配置
   * @param {string} key - 配置键
   * @param {Object} options - 选项
   * @returns {Promise<boolean>} 是否成功
   */
  async delete(key, options = {}) {
    try {
      // 默认选项
      const defaultOptions = {
        source: 'database', // 配置源
        persist: true // 是否持久化
      };
      
      // 合并选项
      const deleteOptions = { ...defaultOptions, ...options };
      
      // 从缓存中删除
      this.configCache.delete(key);
      
      // 如果需要持久化
      if (deleteOptions.persist) {
        switch (deleteOptions.source) {
          case 'file':
            await this._deleteConfigFromFile(key);
            break;
            
          case 'database':
            await this._deleteConfigFromDatabase(key);
            break;
            
          default:
            logger.warn(`不支持的配置源: ${deleteOptions.source}`);
            return false;
        }
      }
      
      // 触发删除事件
      this.emit('delete', { key });
      
      return true;
    } catch (error) {
      logger.error(`删除配置失败: ${key}`, { error });
      return false;
    }
  }
  
  /**
   * 从文件中删除配置
   * @param {string} key - 配置键
   * @returns {Promise<boolean>} 是否成功
   * @private
   */
  async _deleteConfigFromFile(key) {
    try {
      // 获取文件路径
      const filePath = this.options.sources.file.path;
      
      // 检查文件是否存在
      if (!fs.existsSync(filePath)) {
        return true;
      }
      
      // 读取现有配置
      const fileContent = fs.readFileSync(filePath, 'utf8');
      const config = JSON.parse(fileContent);
      
      // 删除配置
      delete config[key];
      
      // 写入文件
      fs.writeFileSync(filePath, JSON.stringify(config, null, 2), 'utf8');
      
      // 清除缓存
      if (this.options.cache.enabled) {
        await cacheService.del(CACHE_NAMESPACE, 'file_config');
      }
      
      return true;
    } catch (error) {
      logger.error(`从文件中删除配置失败: ${key}`, { error });
      return false;
    }
  }
  
  /**
   * 从数据库中删除配置
   * @param {string} key - 配置键
   * @returns {Promise<boolean>} 是否成功
   * @private
   */
  async _deleteConfigFromDatabase(key) {
    try {
      // 获取数据库连接
      const { dbPoolManager } = require('../config/database');
      
      // 删除配置
      await dbPoolManager.query(`
        UPDATE ${this.options.sources.database.table}
        SET is_active = 0, updated_at = NOW()
        WHERE key_name = ?
      `, [key]);
      
      // 清除缓存
      if (this.options.cache.enabled) {
        await cacheService.del(CACHE_NAMESPACE, 'db_config');
      }
      
      return true;
    } catch (error) {
      logger.error(`从数据库中删除配置失败: ${key}`, { error });
      return false;
    }
  }
  
  /**
   * 清除配置缓存
   * @returns {Promise<void>}
   */
  async clearCache() {
    // 清除内存缓存
    this.configCache.clear();
    
    // 清除分布式缓存
    if (this.options.cache.enabled) {
      await cacheService.del(CACHE_NAMESPACE, 'db_config');
      await cacheService.del(CACHE_NAMESPACE, 'file_config');
    }
    
    logger.debug('配置缓存已清除');
  }
  
  /**
   * 关闭配置管理器
   */
  close() {
    // 清除定时器
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
      this.refreshInterval = null;
    }
    
    logger.info('配置管理器已关闭');
  }
}

// 创建单例
const configManager = new ConfigManager();

// 注册常用配置架构
configManager.registerSchema('app.port', Joi.number().port().default(3000));
configManager.registerSchema('app.env', Joi.string().valid('development', 'test', 'production').default('development'));
configManager.registerSchema('app.logLevel', Joi.string().valid('error', 'warn', 'info', 'http', 'debug').default('info'));
configManager.registerSchema('app.cors.origin', Joi.alternatives().try(Joi.string(), Joi.array().items(Joi.string())).default('*'));
configManager.registerSchema('app.cors.methods', Joi.alternatives().try(Joi.string(), Joi.array().items(Joi.string())).default('GET,HEAD,PUT,PATCH,POST,DELETE'));

// 导出配置管理器
module.exports = {
  configManager,
  ConfigManager
};
