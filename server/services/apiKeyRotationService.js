/**
 * API密钥轮换服务
 * 
 * 提供API密钥自动轮换功能：
 * - 定期轮换API密钥
 * - 支持旧密钥的优雅过渡期
 * - 支持密钥版本管理
 */
const crypto = require('crypto');
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { dbPoolManager } = require('../config/database');
const { cacheService } = require('./cacheService');

// 缓存命名空间
const CACHE_NAMESPACE = 'api:keys';

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用API密钥轮换
  enabled: process.env.API_KEY_ROTATION_ENABLED === 'true' || false,
  
  // 轮换间隔（天）
  interval: parseInt(process.env.API_KEY_ROTATION_INTERVAL || '90', 10), // 默认90天
  
  // 过渡期（天）
  gracePeriod: parseInt(process.env.API_KEY_ROTATION_GRACE_PERIOD || '30', 10), // 默认30天
  
  // 密钥长度（字节）
  keyLength: parseInt(process.env.API_KEY_LENGTH || '32', 10), // 默认32字节（64个十六进制字符）
  
  // 通知配置
  notification: {
    // 是否启用通知
    enabled: process.env.API_KEY_ROTATION_NOTIFICATION_ENABLED === 'true' || true,
    
    // 提前通知天数
    advanceDays: parseInt(process.env.API_KEY_ROTATION_NOTIFICATION_ADVANCE_DAYS || '14', 10) // 默认14天
  }
};

// API密钥轮换服务类
class ApiKeyRotationService extends EventEmitter {
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
      notification: {
        ...DEFAULT_CONFIG.notification,
        ...(config.notification || {})
      }
    };
    
    // 轮换定时器
    this.rotationTimer = null;
    
    // 通知定时器
    this.notificationTimer = null;
    
    // 初始化状态
    this.initialized = false;
    
    // 注册配置架构
    this._registerConfigSchema();
    
    logger.info('API密钥轮换服务已创建');
  }
  
  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');
    
    // 注册API密钥轮换配置架构
    configManager.registerSchema('apiKey.rotation.enabled', Joi.boolean().default(false));
    configManager.registerSchema('apiKey.rotation.interval', Joi.number().min(1).default(90));
    configManager.registerSchema('apiKey.rotation.gracePeriod', Joi.number().min(1).default(30));
    configManager.registerSchema('apiKey.rotation.notification.enabled', Joi.boolean().default(true));
    configManager.registerSchema('apiKey.rotation.notification.advanceDays', Joi.number().min(1).default(14));
  }
  
  /**
   * 初始化API密钥轮换服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化API密钥轮换服务');
      
      // 确保API客户端表存在
      await this._ensureApiClientTable();
      
      // 如果启用了轮换，启动定时器
      if (this.config.enabled) {
        this._startRotationTimer();
        this._startNotificationTimer();
      }
      
      this.initialized = true;
      logger.info('API密钥轮换服务初始化成功');
    } catch (error) {
      logger.error('初始化API密钥轮换服务失败:', error);
      throw error;
    }
  }
  
  /**
   * 确保API客户端表存在
   * @private
   * @returns {Promise<void>}
   */
  async _ensureApiClientTable() {
    try {
      // 检查表是否存在
      const [tables] = await dbPoolManager.query(`
        SHOW TABLES LIKE 'api_clients'
      `);
      
      // 如果表不存在，创建表
      if (tables.length === 0) {
        await dbPoolManager.query(`
          CREATE TABLE api_clients (
            id VARCHAR(36) PRIMARY KEY,
            app_id VARCHAR(50) NOT NULL UNIQUE,
            app_name VARCHAR(100) NOT NULL,
            app_secret VARCHAR(255) NOT NULL,
            previous_secret VARCHAR(255),
            secret_version INT NOT NULL DEFAULT 1,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            last_rotated_at DATETIME,
            next_rotation_at DATETIME,
            revoked_at DATETIME,
            INDEX idx_app_id (app_id),
            INDEX idx_is_active (is_active)
          )
        `);
        
        logger.info('API客户端表已创建');
      }
    } catch (error) {
      logger.error('确保API客户端表存在失败:', error);
      throw error;
    }
  }
  
  /**
   * 启动轮换定时器
   * @private
   */
  _startRotationTimer() {
    // 清除现有定时器
    if (this.rotationTimer) {
      clearInterval(this.rotationTimer);
    }
    
    // 设置新定时器
    this.rotationTimer = setInterval(() => {
      this._checkAndRotateKeys().catch(error => {
        logger.error('检查和轮换API密钥失败:', error);
      });
    }, 24 * 60 * 60 * 1000); // 每天检查一次
    
    logger.info('API密钥轮换定时器已启动');
  }
  
  /**
   * 启动通知定时器
   * @private
   */
  _startNotificationTimer() {
    // 如果未启用通知，不启动定时器
    if (!this.config.notification.enabled) {
      return;
    }
    
    // 清除现有定时器
    if (this.notificationTimer) {
      clearInterval(this.notificationTimer);
    }
    
    // 设置新定时器
    this.notificationTimer = setInterval(() => {
      this._checkAndSendNotifications().catch(error => {
        logger.error('检查和发送API密钥轮换通知失败:', error);
      });
    }, 24 * 60 * 60 * 1000); // 每天检查一次
    
    logger.info('API密钥轮换通知定时器已启动');
  }
  
  /**
   * 检查和轮换API密钥
   * @private
   * @returns {Promise<void>}
   */
  async _checkAndRotateKeys() {
    try {
      // 查询需要轮换的API客户端
      const now = new Date();
      const clients = await dbPoolManager.query(`
        SELECT * FROM api_clients
        WHERE is_active = TRUE
        AND (
          next_rotation_at IS NOT NULL
          AND next_rotation_at <= ?
        )
      `, [now.toISOString().slice(0, 19).replace('T', ' ')]);
      
      // 轮换每个客户端的密钥
      for (const client of clients) {
        await this._rotateClientKey(client);
      }
      
      logger.info(`已检查API密钥轮换，处理了 ${clients.length} 个客户端`);
    } catch (error) {
      logger.error('检查和轮换API密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 检查和发送API密钥轮换通知
   * @private
   * @returns {Promise<void>}
   */
  async _checkAndSendNotifications() {
    try {
      // 如果未启用通知，不发送通知
      if (!this.config.notification.enabled) {
        return;
      }
      
      // 计算通知日期
      const now = new Date();
      const notificationDate = new Date(now);
      notificationDate.setDate(now.getDate() + this.config.notification.advanceDays);
      
      // 查询需要通知的API客户端
      const clients = await dbPoolManager.query(`
        SELECT * FROM api_clients
        WHERE is_active = TRUE
        AND (
          next_rotation_at IS NOT NULL
          AND next_rotation_at <= ?
          AND next_rotation_at > ?
        )
      `, [
        notificationDate.toISOString().slice(0, 19).replace('T', ' '),
        now.toISOString().slice(0, 19).replace('T', ' ')
      ]);
      
      // 发送通知
      for (const client of clients) {
        await this._sendRotationNotification(client);
      }
      
      logger.info(`已检查API密钥轮换通知，发送了 ${clients.length} 个通知`);
    } catch (error) {
      logger.error('检查和发送API密钥轮换通知失败:', error);
      throw error;
    }
  }
  
  /**
   * 轮换客户端密钥
   * @private
   * @param {Object} client - API客户端
   * @returns {Promise<void>}
   */
  async _rotateClientKey(client) {
    try {
      // 生成新密钥
      const newSecret = crypto.randomBytes(this.config.keyLength).toString('hex');
      
      // 更新客户端
      const now = new Date();
      const nextRotation = new Date(now);
      nextRotation.setDate(now.getDate() + this.config.interval);
      
      // 更新数据库
      await dbPoolManager.query(`
        UPDATE api_clients
        SET 
          previous_secret = app_secret,
          app_secret = ?,
          secret_version = secret_version + 1,
          updated_at = ?,
          last_rotated_at = ?,
          next_rotation_at = ?
        WHERE id = ?
      `, [
        newSecret,
        now.toISOString().slice(0, 19).replace('T', ' '),
        now.toISOString().slice(0, 19).replace('T', ' '),
        nextRotation.toISOString().slice(0, 19).replace('T', ' '),
        client.id
      ]);
      
      // 清除缓存
      await cacheService.del(CACHE_NAMESPACE, `secret:${client.app_id}`);
      
      // 发出密钥轮换事件
      this.emit('key-rotated', {
        clientId: client.id,
        appId: client.app_id,
        appName: client.app_name,
        secretVersion: client.secret_version + 1,
        rotatedAt: now
      });
      
      logger.info(`已轮换API客户端密钥: ${client.app_name} (${client.app_id})`);
    } catch (error) {
      logger.error(`轮换API客户端密钥失败: ${client.app_name} (${client.app_id})`, error);
      throw error;
    }
  }
  
  /**
   * 发送轮换通知
   * @private
   * @param {Object} client - API客户端
   * @returns {Promise<void>}
   */
  async _sendRotationNotification(client) {
    try {
      // 计算剩余天数
      const now = new Date();
      const rotationDate = new Date(client.next_rotation_at);
      const daysRemaining = Math.ceil((rotationDate - now) / (24 * 60 * 60 * 1000));
      
      // 发出通知事件
      this.emit('rotation-notification', {
        clientId: client.id,
        appId: client.app_id,
        appName: client.app_name,
        rotationDate,
        daysRemaining
      });
      
      logger.info(`已发送API密钥轮换通知: ${client.app_name} (${client.app_id}), ${daysRemaining}天后轮换`);
    } catch (error) {
      logger.error(`发送API密钥轮换通知失败: ${client.app_name} (${client.app_id})`, error);
      throw error;
    }
  }
  
  /**
   * 创建API客户端
   * @param {Object} clientData - 客户端数据
   * @returns {Promise<Object>} 创建的客户端
   */
  async createClient(clientData) {
    try {
      // 生成ID和密钥
      const id = crypto.randomUUID();
      const appId = clientData.appId || crypto.randomBytes(8).toString('hex');
      const appSecret = crypto.randomBytes(this.config.keyLength).toString('hex');
      
      // 计算下次轮换日期
      const now = new Date();
      const nextRotation = new Date(now);
      nextRotation.setDate(now.getDate() + this.config.interval);
      
      // 插入数据库
      await dbPoolManager.query(`
        INSERT INTO api_clients (
          id, app_id, app_name, app_secret, secret_version,
          is_active, created_at, updated_at, next_rotation_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        id,
        appId,
        clientData.appName,
        appSecret,
        1,
        true,
        now.toISOString().slice(0, 19).replace('T', ' '),
        now.toISOString().slice(0, 19).replace('T', ' '),
        nextRotation.toISOString().slice(0, 19).replace('T', ' ')
      ]);
      
      // 返回创建的客户端
      return {
        id,
        appId,
        appName: clientData.appName,
        appSecret,
        secretVersion: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        nextRotationAt: nextRotation
      };
    } catch (error) {
      logger.error('创建API客户端失败:', error);
      throw error;
    }
  }
  
  /**
   * 获取API客户端
   * @param {string} appId - 应用ID
   * @returns {Promise<Object|null>} 客户端
   */
  async getClient(appId) {
    try {
      // 查询数据库
      const clients = await dbPoolManager.query(`
        SELECT * FROM api_clients
        WHERE app_id = ?
      `, [appId]);
      
      // 如果找不到客户端，返回null
      if (clients.length === 0) {
        return null;
      }
      
      // 返回客户端
      return clients[0];
    } catch (error) {
      logger.error('获取API客户端失败:', error);
      throw error;
    }
  }
  
  /**
   * 验证API密钥
   * @param {string} appId - 应用ID
   * @param {string} appSecret - 应用密钥
   * @returns {Promise<boolean>} 是否有效
   */
  async validateKey(appId, appSecret) {
    try {
      // 获取客户端
      const client = await this.getClient(appId);
      
      // 如果找不到客户端或客户端未激活，返回false
      if (!client || !client.is_active) {
        return false;
      }
      
      // 检查当前密钥
      if (client.app_secret === appSecret) {
        return true;
      }
      
      // 检查上一个密钥（如果在宽限期内）
      if (client.previous_secret === appSecret) {
        // 检查是否在宽限期内
        const now = new Date();
        const lastRotated = new Date(client.last_rotated_at);
        const gracePeriodEnd = new Date(lastRotated);
        gracePeriodEnd.setDate(lastRotated.getDate() + this.config.gracePeriod);
        
        // 如果在宽限期内，返回true
        if (now <= gracePeriodEnd) {
          return true;
        }
      }
      
      // 密钥无效
      return false;
    } catch (error) {
      logger.error('验证API密钥失败:', error);
      throw error;
    }
  }
  
  /**
   * 撤销API客户端
   * @param {string} appId - 应用ID
   * @returns {Promise<boolean>} 是否成功
   */
  async revokeClient(appId) {
    try {
      // 更新数据库
      const now = new Date();
      const result = await dbPoolManager.query(`
        UPDATE api_clients
        SET 
          is_active = FALSE,
          updated_at = ?,
          revoked_at = ?
        WHERE app_id = ?
      `, [
        now.toISOString().slice(0, 19).replace('T', ' '),
        now.toISOString().slice(0, 19).replace('T', ' '),
        appId
      ]);
      
      // 清除缓存
      await cacheService.del(CACHE_NAMESPACE, `secret:${appId}`);
      
      // 发出客户端撤销事件
      this.emit('client-revoked', {
        appId,
        revokedAt: now
      });
      
      // 返回是否成功
      return result.affectedRows > 0;
    } catch (error) {
      logger.error('撤销API客户端失败:', error);
      throw error;
    }
  }
}

// 创建单例
const apiKeyRotationService = new ApiKeyRotationService();

// 导出
module.exports = {
  apiKeyRotationService,
  ApiKeyRotationService
};
