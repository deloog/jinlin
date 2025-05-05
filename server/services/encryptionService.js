/**
 * 加密服务
 * 
 * 提供数据加密和解密功能：
 * - 敏感数据字段加密
 * - 密钥管理
 * - 密钥轮换
 * - 加密算法可配置
 */
const crypto = require('crypto');
const { promisify } = require('util');
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { dbPoolManager } = require('../config/database');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用加密
  enabled: process.env.ENCRYPTION_ENABLED === 'true' || true,
  
  // 加密算法
  algorithm: process.env.ENCRYPTION_ALGORITHM || 'aes-256-gcm',
  
  // 密钥配置
  keys: {
    // 密钥存储方式: 'file', 'database', 'env'
    storage: process.env.ENCRYPTION_KEY_STORAGE || 'database',
    
    // 文件存储配置
    file: {
      path: process.env.ENCRYPTION_KEY_FILE_PATH || path.join(__dirname, '../../keys'),
      namePrefix: process.env.ENCRYPTION_KEY_FILE_PREFIX || 'encryption_key_'
    },
    
    // 数据库存储配置
    database: {
      table: process.env.ENCRYPTION_KEY_DB_TABLE || 'encryption_keys'
    },
    
    // 环境变量存储配置
    env: {
      prefix: process.env.ENCRYPTION_KEY_ENV_PREFIX || 'ENCRYPTION_KEY_'
    },
    
    // 密钥轮换配置
    rotation: {
      enabled: process.env.ENCRYPTION_KEY_ROTATION_ENABLED === 'true' || false,
      interval: parseInt(process.env.ENCRYPTION_KEY_ROTATION_INTERVAL || '30', 10), // 默认30天
      gracePeriod: parseInt(process.env.ENCRYPTION_KEY_ROTATION_GRACE_PERIOD || '7', 10) // 默认7天
    }
  },
  
  // 敏感字段配置
  sensitiveFields: {
    // 用户表敏感字段
    users: ['email', 'display_name'],
    
    // 提醒事项表敏感字段
    reminders: ['title', 'description', 'location'],
    
    // 联系人表敏感字段
    contacts: ['name', 'phone_number', 'email', 'address'],
    
    // 自定义表敏感字段
    custom: {}
  }
};

// 加密服务类
class EncryptionService extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} config - 配置
   */
  constructor(config = {}) {
    super();
    
    // 合并配置
    this.config = {
      ...DEFAULT_CONFIG,
      ...config,
      sensitiveFields: {
        ...DEFAULT_CONFIG.sensitiveFields,
        ...(config.sensitiveFields || {})
      }
    };
    
    // 当前活动密钥
    this.activeKey = null;
    
    // 所有密钥
    this.keys = new Map();
    
    // 密钥轮换定时器
    this.rotationTimer = null;
    
    // 初始化状态
    this.initialized = false;
    
    // 注册配置架构
    this._registerConfigSchema();
    
    logger.info('加密服务已创建');
  }
  
  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');
    
    // 注册加密配置架构
    configManager.registerSchema('encryption.enabled', Joi.boolean().default(true));
    configManager.registerSchema('encryption.algorithm', Joi.string().default('aes-256-gcm'));
    configManager.registerSchema('encryption.keys.storage', Joi.string().valid('file', 'database', 'env').default('database'));
    configManager.registerSchema('encryption.keys.rotation.enabled', Joi.boolean().default(false));
    configManager.registerSchema('encryption.keys.rotation.interval', Joi.number().min(1).default(30));
    configManager.registerSchema('encryption.keys.rotation.gracePeriod', Joi.number().min(1).default(7));
  }
  
  /**
   * 初始化加密服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化加密服务');
      
      // 确保密钥表存在
      await this._ensureKeyTable();
      
      // 加载所有密钥
      await this._loadKeys();
      
      // 设置活动密钥
      await this._setActiveKey();
      
      // 如果启用了密钥轮换，启动定时器
      if (this.config.keys.rotation.enabled) {
        this._startKeyRotation();
      }
      
      this.initialized = true;
      logger.info('加密服务初始化成功');
    } catch (error) {
      logger.error('初始化加密服务失败:', error);
      throw error;
    }
  }
  
  /**
   * 确保密钥表存在
   * @private
   * @returns {Promise<void>}
   */
  async _ensureKeyTable() {
    if (this.config.keys.storage !== 'database') {
      return;
    }
    
    try {
      // 创建密钥表
      await dbPoolManager.query(`
        CREATE TABLE IF NOT EXISTS ${this.config.keys.database.table} (
          id VARCHAR(36) PRIMARY KEY,
          version INT NOT NULL,
          key_data TEXT NOT NULL,
          iv TEXT NOT NULL,
          is_active BOOLEAN DEFAULT FALSE,
          created_at DATETIME NOT NULL,
          activated_at DATETIME,
          deactivated_at DATETIME,
          INDEX idx_version (version),
          INDEX idx_is_active (is_active)
        )
      `);
      
      logger.info('密钥表已确保存在');
    } catch (error) {
      logger.error('确保密钥表存在失败:', error);
      throw error;
    }
  }
  
  /**
   * 加载所有密钥
   * @private
   * @returns {Promise<void>}
   */
  async _loadKeys() {
    try {
      // 清空密钥
      this.keys.clear();
      
      // 根据存储方式加载密钥
      switch (this.config.keys.storage) {
        case 'file':
          await this._loadKeysFromFile();
          break;
          
        case 'database':
          await this._loadKeysFromDatabase();
          break;
          
        case 'env':
          this._loadKeysFromEnv();
          break;
          
        default:
          throw new Error(`不支持的密钥存储方式: ${this.config.keys.storage}`);
      }
      
      logger.info(`已加载 ${this.keys.size} 个密钥`);
    } catch (error) {
      logger.error('加载密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 从文件加载密钥
   * @private
   * @returns {Promise<void>}
   */
  async _loadKeysFromFile() {
    try {
      const { file } = this.config.keys;
      const readdir = promisify(fs.readdir);
      const readFile = promisify(fs.readFile);
      
      // 确保目录存在
      if (!fs.existsSync(file.path)) {
        fs.mkdirSync(file.path, { recursive: true });
      }
      
      // 读取目录
      const files = await readdir(file.path);
      
      // 过滤密钥文件
      const keyFiles = files.filter(f => f.startsWith(file.namePrefix) && f.endsWith('.json'));
      
      // 加载每个密钥
      for (const keyFile of keyFiles) {
        const filePath = path.join(file.path, keyFile);
        const content = await readFile(filePath, 'utf8');
        const keyData = JSON.parse(content);
        
        this.keys.set(keyData.id, keyData);
      }
    } catch (error) {
      logger.error('从文件加载密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 从数据库加载密钥
   * @private
   * @returns {Promise<void>}
   */
  async _loadKeysFromDatabase() {
    try {
      // 查询所有密钥
      const keys = await dbPoolManager.query(`
        SELECT * FROM ${this.config.keys.database.table}
        ORDER BY version ASC
      `);
      
      // 加载每个密钥
      for (const key of keys) {
        this.keys.set(key.id, {
          id: key.id,
          version: key.version,
          keyData: key.key_data,
          iv: key.iv,
          isActive: key.is_active === 1,
          createdAt: key.created_at,
          activatedAt: key.activated_at,
          deactivatedAt: key.deactivated_at
        });
      }
    } catch (error) {
      logger.error('从数据库加载密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 从环境变量加载密钥
   * @private
   */
  _loadKeysFromEnv() {
    try {
      const { prefix } = this.config.keys.env;
      
      // 查找所有密钥环境变量
      const keyVars = Object.keys(process.env)
        .filter(key => key.startsWith(prefix))
        .sort();
      
      // 加载每个密钥
      for (const keyVar of keyVars) {
        const keyData = JSON.parse(process.env[keyVar]);
        this.keys.set(keyData.id, keyData);
      }
    } catch (error) {
      logger.error('从环境变量加载密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 设置活动密钥
   * @private
   * @returns {Promise<void>}
   */
  async _setActiveKey() {
    try {
      // 查找活动密钥
      let activeKey = null;
      
      for (const [id, key] of this.keys.entries()) {
        if (key.isActive) {
          activeKey = key;
          break;
        }
      }
      
      // 如果没有活动密钥，创建一个
      if (!activeKey) {
        activeKey = await this._createNewKey();
      }
      
      this.activeKey = activeKey;
      logger.info(`活动密钥已设置: 版本 ${activeKey.version}`);
    } catch (error) {
      logger.error('设置活动密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 创建新密钥
   * @private
   * @returns {Promise<Object>} 新密钥
   */
  async _createNewKey() {
    try {
      // 生成新密钥
      const id = crypto.randomUUID();
      const keyBuffer = crypto.randomBytes(32); // 256位密钥
      const ivBuffer = crypto.randomBytes(16); // 128位IV
      const keyData = keyBuffer.toString('hex');
      const iv = ivBuffer.toString('hex');
      const version = this.keys.size + 1;
      const now = new Date();
      
      // 创建密钥对象
      const newKey = {
        id,
        version,
        keyData,
        iv,
        isActive: true,
        createdAt: now,
        activatedAt: now,
        deactivatedAt: null
      };
      
      // 保存密钥
      await this._saveKey(newKey);
      
      // 添加到密钥集合
      this.keys.set(id, newKey);
      
      logger.info(`创建新密钥: 版本 ${version}`);
      return newKey;
    } catch (error) {
      logger.error('创建新密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 保存密钥
   * @private
   * @param {Object} key - 密钥对象
   * @returns {Promise<void>}
   */
  async _saveKey(key) {
    try {
      // 根据存储方式保存密钥
      switch (this.config.keys.storage) {
        case 'file':
          await this._saveKeyToFile(key);
          break;
          
        case 'database':
          await this._saveKeyToDatabase(key);
          break;
          
        case 'env':
          // 环境变量不支持动态保存
          logger.warn('环境变量存储不支持动态保存密钥');
          break;
          
        default:
          throw new Error(`不支持的密钥存储方式: ${this.config.keys.storage}`);
      }
    } catch (error) {
      logger.error('保存密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 将密钥保存到文件
   * @private
   * @param {Object} key - 密钥对象
   * @returns {Promise<void>}
   */
  async _saveKeyToFile(key) {
    try {
      const { file } = this.config.keys;
      const writeFile = promisify(fs.writeFile);
      
      // 确保目录存在
      if (!fs.existsSync(file.path)) {
        fs.mkdirSync(file.path, { recursive: true });
      }
      
      // 构建文件路径
      const filePath = path.join(file.path, `${file.namePrefix}${key.version}.json`);
      
      // 写入文件
      await writeFile(filePath, JSON.stringify(key, null, 2), 'utf8');
    } catch (error) {
      logger.error('将密钥保存到文件失败:', error);
      throw error;
    }
  }
  
  /**
   * 将密钥保存到数据库
   * @private
   * @param {Object} key - 密钥对象
   * @returns {Promise<void>}
   */
  async _saveKeyToDatabase(key) {
    try {
      // 格式化日期
      const createdAt = key.createdAt.toISOString().slice(0, 19).replace('T', ' ');
      const activatedAt = key.activatedAt ? key.activatedAt.toISOString().slice(0, 19).replace('T', ' ') : null;
      const deactivatedAt = key.deactivatedAt ? key.deactivatedAt.toISOString().slice(0, 19).replace('T', ' ') : null;
      
      // 插入或更新密钥
      await dbPoolManager.query(`
        INSERT INTO ${this.config.keys.database.table}
        (id, version, key_data, iv, is_active, created_at, activated_at, deactivated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        key_data = VALUES(key_data),
        iv = VALUES(iv),
        is_active = VALUES(is_active),
        activated_at = VALUES(activated_at),
        deactivated_at = VALUES(deactivated_at)
      `, [
        key.id,
        key.version,
        key.keyData,
        key.iv,
        key.isActive ? 1 : 0,
        createdAt,
        activatedAt,
        deactivatedAt
      ]);
    } catch (error) {
      logger.error('将密钥保存到数据库失败:', error);
      throw error;
    }
  }
  
  /**
   * 启动密钥轮换
   * @private
   */
  _startKeyRotation() {
    // 清除现有定时器
    if (this.rotationTimer) {
      clearInterval(this.rotationTimer);
    }
    
    // 设置新定时器
    this.rotationTimer = setInterval(() => {
      this._checkKeyRotation().catch(error => {
        logger.error('检查密钥轮换失败:', error);
      });
    }, 24 * 60 * 60 * 1000); // 每天检查一次
    
    logger.info('密钥轮换定时器已启动');
  }
  
  /**
   * 检查密钥轮换
   * @private
   * @returns {Promise<void>}
   */
  async _checkKeyRotation() {
    try {
      // 如果没有活动密钥，不执行轮换
      if (!this.activeKey) {
        return;
      }
      
      // 计算密钥年龄（天）
      const now = new Date();
      const keyAge = Math.floor((now - new Date(this.activeKey.activatedAt)) / (24 * 60 * 60 * 1000));
      
      // 如果密钥年龄超过轮换间隔，执行轮换
      if (keyAge >= this.config.keys.rotation.interval) {
        logger.info(`密钥已使用 ${keyAge} 天，执行轮换`);
        await this._rotateKey();
      }
    } catch (error) {
      logger.error('检查密钥轮换失败:', error);
      throw error;
    }
  }
  
  /**
   * 轮换密钥
   * @private
   * @returns {Promise<void>}
   */
  async _rotateKey() {
    try {
      // 创建新密钥
      const newKey = await this._createNewKey();
      
      // 将当前活动密钥标记为非活动
      if (this.activeKey) {
        this.activeKey.isActive = false;
        this.activeKey.deactivatedAt = new Date();
        
        // 保存旧密钥
        await this._saveKey(this.activeKey);
      }
      
      // 设置新的活动密钥
      this.activeKey = newKey;
      
      // 发出密钥轮换事件
      this.emit('key-rotated', {
        oldKeyVersion: this.activeKey ? this.activeKey.version : null,
        newKeyVersion: newKey.version
      });
      
      logger.info(`密钥已轮换: 版本 ${newKey.version}`);
    } catch (error) {
      logger.error('轮换密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 加密数据
   * @param {string} plaintext - 明文
   * @param {Object} options - 选项
   * @returns {string} 密文
   */
  encrypt(plaintext, options = {}) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('加密服务未初始化');
    }
    
    // 检查活动密钥
    if (!this.activeKey) {
      throw new Error('没有活动密钥');
    }
    
    try {
      // 获取密钥和IV
      const key = Buffer.from(this.activeKey.keyData, 'hex');
      const iv = Buffer.from(this.activeKey.iv, 'hex');
      
      // 创建加密器
      const cipher = crypto.createCipheriv(this.config.algorithm, key, iv);
      
      // 加密数据
      let encrypted = cipher.update(plaintext, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // 获取认证标签（仅适用于GCM模式）
      let authTag = '';
      if (this.config.algorithm.includes('gcm')) {
        authTag = cipher.getAuthTag().toString('hex');
      }
      
      // 构建结果
      const result = {
        v: this.activeKey.version,
        d: encrypted,
        t: authTag
      };
      
      // 返回JSON字符串
      return JSON.stringify(result);
    } catch (error) {
      logger.error('加密数据失败:', error);
      throw error;
    }
  }
  
  /**
   * 解密数据
   * @param {string} ciphertext - 密文
   * @param {Object} options - 选项
   * @returns {string} 明文
   */
  decrypt(ciphertext, options = {}) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('加密服务未初始化');
    }
    
    try {
      // 解析密文
      const { v, d, t } = JSON.parse(ciphertext);
      
      // 查找对应版本的密钥
      let keyData = null;
      for (const [id, key] of this.keys.entries()) {
        if (key.version === v) {
          keyData = key;
          break;
        }
      }
      
      // 如果找不到密钥，抛出错误
      if (!keyData) {
        throw new Error(`找不到版本 ${v} 的密钥`);
      }
      
      // 获取密钥和IV
      const key = Buffer.from(keyData.keyData, 'hex');
      const iv = Buffer.from(keyData.iv, 'hex');
      
      // 创建解密器
      const decipher = crypto.createDecipheriv(this.config.algorithm, key, iv);
      
      // 设置认证标签（仅适用于GCM模式）
      if (this.config.algorithm.includes('gcm') && t) {
        decipher.setAuthTag(Buffer.from(t, 'hex'));
      }
      
      // 解密数据
      let decrypted = decipher.update(d, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      logger.error('解密数据失败:', error);
      throw error;
    }
  }
  
  /**
   * 加密对象
   * @param {Object} data - 数据对象
   * @param {string} tableName - 表名
   * @returns {Object} 加密后的对象
   */
  encryptObject(data, tableName) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('加密服务未初始化');
    }
    
    // 如果未启用加密，直接返回原始数据
    if (!this.config.enabled) {
      return data;
    }
    
    try {
      // 克隆数据对象
      const encryptedData = { ...data };
      
      // 获取敏感字段
      const sensitiveFields = this.config.sensitiveFields[tableName] || [];
      
      // 加密敏感字段
      for (const field of sensitiveFields) {
        if (encryptedData[field] !== undefined && encryptedData[field] !== null) {
          // 将对象和数组转换为JSON字符串
          const value = typeof encryptedData[field] === 'object'
            ? JSON.stringify(encryptedData[field])
            : String(encryptedData[field]);
          
          // 加密字段
          encryptedData[field] = this.encrypt(value);
        }
      }
      
      return encryptedData;
    } catch (error) {
      logger.error('加密对象失败:', error);
      throw error;
    }
  }
  
  /**
   * 解密对象
   * @param {Object} data - 加密的数据对象
   * @param {string} tableName - 表名
   * @returns {Object} 解密后的对象
   */
  decryptObject(data, tableName) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('加密服务未初始化');
    }
    
    // 如果未启用加密，直接返回原始数据
    if (!this.config.enabled) {
      return data;
    }
    
    try {
      // 克隆数据对象
      const decryptedData = { ...data };
      
      // 获取敏感字段
      const sensitiveFields = this.config.sensitiveFields[tableName] || [];
      
      // 解密敏感字段
      for (const field of sensitiveFields) {
        if (decryptedData[field] !== undefined && decryptedData[field] !== null) {
          try {
            // 解密字段
            const decrypted = this.decrypt(decryptedData[field]);
            
            // 尝试解析JSON
            try {
              decryptedData[field] = JSON.parse(decrypted);
            } catch (e) {
              // 不是JSON，保持为字符串
              decryptedData[field] = decrypted;
            }
          } catch (e) {
            // 解密失败，保持原样
            logger.warn(`解密字段失败: ${field}`, e);
          }
        }
      }
      
      return decryptedData;
    } catch (error) {
      logger.error('解密对象失败:', error);
      throw error;
    }
  }
}

// 创建单例
const encryptionService = new EncryptionService();

// 导出
module.exports = {
  encryptionService,
  EncryptionService
};
