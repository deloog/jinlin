/**
 * 告警服务
 *
 * 提供增强的告警功能：
 * - 多级告警策略
 * - 告警升级和自动处理
 * - 智能告警聚合
 * - 多渠道通知
 */
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { asyncTaskService } = require('./asyncTaskService');
const { v4: uuidv4 } = require('uuid');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用告警
  enabled: process.env.ALERTS_ENABLED === 'true' || true,

  // 告警级别
  levels: {
    // 信息级别
    info: {
      color: 'blue',
      priority: 0,
      autoResolve: true,
      autoResolveTimeout: 3600000 // 1小时
    },

    // 警告级别
    warning: {
      color: 'yellow',
      priority: 1,
      autoResolve: true,
      autoResolveTimeout: 7200000 // 2小时
    },

    // 错误级别
    error: {
      color: 'red',
      priority: 2,
      autoResolve: false
    },

    // 严重级别
    critical: {
      color: 'purple',
      priority: 3,
      autoResolve: false,
      autoEscalate: true,
      escalateTimeout: 1800000 // 30分钟
    }
  },

  // 告警通知配置
  notifications: {
    // 是否启用通知
    enabled: process.env.ALERT_NOTIFICATIONS_ENABLED === 'true' || true,

    // 通知渠道
    channels: {
      // 控制台通知
      console: {
        enabled: process.env.CONSOLE_NOTIFICATIONS_ENABLED === 'true' || true,
        minLevel: process.env.CONSOLE_NOTIFICATIONS_MIN_LEVEL || 'info'
      },

      // 邮件通知
      email: {
        enabled: process.env.EMAIL_NOTIFICATIONS_ENABLED === 'true' || false,
        minLevel: process.env.EMAIL_NOTIFICATIONS_MIN_LEVEL || 'warning',
        recipients: (process.env.EMAIL_NOTIFICATIONS_RECIPIENTS || '').split(',').filter(Boolean),
        throttle: parseInt(process.env.EMAIL_NOTIFICATIONS_THROTTLE || '300000', 10) // 5分钟
      },

      // Webhook通知
      webhook: {
        enabled: process.env.WEBHOOK_NOTIFICATIONS_ENABLED === 'true' || false,
        minLevel: process.env.WEBHOOK_NOTIFICATIONS_MIN_LEVEL || 'warning',
        url: process.env.WEBHOOK_NOTIFICATIONS_URL || '',
        throttle: parseInt(process.env.WEBHOOK_NOTIFICATIONS_THROTTLE || '60000', 10) // 1分钟
      }
    }
  },

  // 告警聚合配置
  aggregation: {
    // 是否启用聚合
    enabled: process.env.ALERT_AGGREGATION_ENABLED === 'true' || true,

    // 聚合窗口（毫秒）
    window: parseInt(process.env.ALERT_AGGREGATION_WINDOW || '300000', 10), // 5分钟

    // 聚合阈值
    threshold: parseInt(process.env.ALERT_AGGREGATION_THRESHOLD || '5', 10), // 5个相似告警

    // 相似度阈值
    similarityThreshold: parseFloat(process.env.ALERT_SIMILARITY_THRESHOLD || '0.7') // 70%相似
  },

  // 告警持久化配置
  persistence: {
    // 是否启用持久化
    enabled: process.env.ALERT_PERSISTENCE_ENABLED === 'true' || true,

    // 持久化间隔（毫秒）
    interval: parseInt(process.env.ALERT_PERSISTENCE_INTERVAL || '60000', 10), // 1分钟

    // 最大保留告警数
    maxAlerts: parseInt(process.env.MAX_ALERTS || '1000', 10)
  }
};

// 告警服务类
class AlertService extends EventEmitter {
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
      levels: {
        ...DEFAULT_CONFIG.levels,
        ...(config.levels || {})
      },
      notifications: {
        ...DEFAULT_CONFIG.notifications,
        ...(config.notifications || {}),
        channels: {
          ...DEFAULT_CONFIG.notifications.channels,
          ...(config.notifications?.channels || {})
        }
      },
      aggregation: {
        ...DEFAULT_CONFIG.aggregation,
        ...(config.aggregation || {})
      },
      persistence: {
        ...DEFAULT_CONFIG.persistence,
        ...(config.persistence || {})
      }
    };

    // 活动告警
    this.activeAlerts = new Map();

    // 已解决告警
    this.resolvedAlerts = [];

    // 告警计数器
    this.alertCounters = {
      total: 0,
      byLevel: {
        info: 0,
        warning: 0,
        error: 0,
        critical: 0
      },
      byType: new Map()
    };

    // 通知计数器
    this.notificationCounters = {
      total: 0,
      byChannel: {
        console: 0,
        email: 0,
        webhook: 0
      }
    };

    // 通知时间戳
    this.lastNotificationTime = {
      email: 0,
      webhook: 0
    };

    // 告警聚合缓冲区
    this.aggregationBuffer = [];

    // 告警聚合定时器
    this.aggregationTimer = null;

    // 告警持久化定时器
    this.persistenceTimer = null;

    // 告警自动解决定时器
    this.autoResolveTimer = null;

    // 告警升级定时器
    this.escalationTimer = null;

    // 初始化状态
    this.initialized = false;

    // 注册配置架构
    this._registerConfigSchema();

    logger.info('告警服务已创建');
  }

  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');

    // 注册告警配置架构
    configManager.registerSchema('alerts.enabled', Joi.boolean().default(true));
    configManager.registerSchema('alerts.notifications.enabled', Joi.boolean().default(true));
    configManager.registerSchema('alerts.aggregation.enabled', Joi.boolean().default(true));
    configManager.registerSchema('alerts.aggregation.window', Joi.number().min(1000).default(300000));
  }

  /**
   * 初始化告警服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }

    try {
      logger.info('初始化告警服务');

      // 如果未启用告警，不执行初始化
      if (!this.config.enabled) {
        logger.info('告警服务未启用');
        return;
      }

      // 启动告警聚合
      if (this.config.aggregation.enabled) {
        this._startAggregation();
      }

      // 启动告警持久化
      if (this.config.persistence.enabled) {
        this._startPersistence();
      }

      // 启动告警自动解决
      this._startAutoResolve();

      // 启动告警升级
      this._startEscalation();

      // 注册异步任务处理器
      this._registerTaskHandlers();

      this.initialized = true;
      logger.info('告警服务初始化成功');
    } catch (error) {
      logger.error('初始化告警服务失败', { error });
      throw error;
    }
  }

  /**
   * 注册异步任务处理器
   * @private
   */
  _registerTaskHandlers() {
    try {
      // 注册邮件通知任务处理器
      asyncTaskService.registerHandler('alert-email-notification', async (data) => {
        logger.info('处理邮件通知任务', { alertId: data.alertId });
        await this._sendEmailNotification(data.alert, data.recipients);
        return { success: true };
      });

      // 注册Webhook通知任务处理器
      asyncTaskService.registerHandler('alert-webhook-notification', async (data) => {
        logger.info('处理Webhook通知任务', { alertId: data.alertId });
        await this._sendWebhookNotification(data.alert, data.url);
        return { success: true };
      });

      logger.info('告警任务处理器注册成功');
    } catch (error) {
      logger.error('注册告警任务处理器失败', { error });
    }
  }

  /**
   * 启动告警聚合
   * @private
   */
  _startAggregation() {
    // 清除现有定时器
    if (this.aggregationTimer) {
      clearInterval(this.aggregationTimer);
    }

    // 设置新定时器
    this.aggregationTimer = setInterval(() => {
      this._processAggregation();
    }, this.config.aggregation.window);

    logger.info('告警聚合定时器已启动');
  }

  /**
   * 处理告警聚合
   * @private
   */
  _processAggregation() {
    try {
      // 如果缓冲区为空，不处理
      if (this.aggregationBuffer.length === 0) {
        return;
      }

      // 按类型分组
      const alertsByType = new Map();

      for (const alert of this.aggregationBuffer) {
        if (!alertsByType.has(alert.type)) {
          alertsByType.set(alert.type, []);
        }

        alertsByType.get(alert.type).push(alert);
      }

      // 处理每个类型的告警
      for (const [type, alerts] of alertsByType.entries()) {
        // 如果告警数量超过阈值，创建聚合告警
        if (alerts.length >= this.config.aggregation.threshold) {
          const firstAlert = alerts[0];

          // 创建聚合告警
          const aggregatedAlert = {
            id: uuidv4(),
            type: `aggregated_${type}`,
            level: firstAlert.level,
            message: `收到${alerts.length}个类似的${type}告警`,
            details: {
              count: alerts.length,
              firstOccurrence: firstAlert.timestamp,
              lastOccurrence: alerts[alerts.length - 1].timestamp,
              samples: alerts.slice(0, 3)
            },
            timestamp: new Date().toISOString(),
            aggregated: true
          };

          // 添加聚合告警
          this._addAlert(aggregatedAlert);

          logger.info(`创建聚合告警: ${aggregatedAlert.message}`, { alertId: aggregatedAlert.id, count: alerts.length });
        } else {
          // 如果告警数量未超过阈值，添加每个告警
          for (const alert of alerts) {
            this._addAlert(alert);
          }
        }
      }

      // 清空缓冲区
      this.aggregationBuffer = [];
    } catch (error) {
      logger.error('处理告警聚合失败', { error });
    }
  }

  /**
   * 启动告警持久化
   * @private
   */
  _startPersistence() {
    // 清除现有定时器
    if (this.persistenceTimer) {
      clearInterval(this.persistenceTimer);
    }

    // 设置新定时器
    this.persistenceTimer = setInterval(() => {
      this._persistAlerts();
    }, this.config.persistence.interval);

    logger.info('告警持久化定时器已启动');
  }

  /**
   * 持久化告警
   * @private
   */
  _persistAlerts() {
    try {
      // TODO: 实现告警持久化逻辑
      logger.debug('持久化告警');
    } catch (error) {
      logger.error('持久化告警失败', { error });
    }
  }

  /**
   * 启动告警自动解决
   * @private
   */
  _startAutoResolve() {
    // 清除现有定时器
    if (this.autoResolveTimer) {
      clearInterval(this.autoResolveTimer);
    }

    // 设置新定时器
    this.autoResolveTimer = setInterval(() => {
      this._checkAutoResolve();
    }, 60000); // 每分钟检查一次

    logger.info('告警自动解决定时器已启动');
  }

  /**
   * 检查告警自动解决
   * @private
   */
  _checkAutoResolve() {
    try {
      const now = Date.now();

      // 检查每个活动告警
      for (const [alertId, alert] of this.activeAlerts.entries()) {
        // 获取告警级别配置
        const levelConfig = this.config.levels[alert.level];

        // 如果配置了自动解决
        if (levelConfig && levelConfig.autoResolve && levelConfig.autoResolveTimeout) {
          // 计算告警年龄
          const alertTimestamp = new Date(alert.timestamp).getTime();
          const alertAge = now - alertTimestamp;

          // 如果告警年龄超过自动解决超时
          if (alertAge >= levelConfig.autoResolveTimeout) {
            // 解决告警
            this.resolveAlert(alertId, {
              reason: 'auto_resolve',
              message: '告警已自动解决（超时）'
            });

            logger.info(`告警已自动解决: ${alert.message}`, { alertId, age: alertAge });
          }
        }
      }
    } catch (error) {
      logger.error('检查告警自动解决失败', { error });
    }
  }

  /**
   * 启动告警升级
   * @private
   */
  _startEscalation() {
    // 清除现有定时器
    if (this.escalationTimer) {
      clearInterval(this.escalationTimer);
    }

    // 设置新定时器
    this.escalationTimer = setInterval(() => {
      this._checkEscalation();
    }, 60000); // 每分钟检查一次

    logger.info('告警升级定时器已启动');
  }

  /**
   * 检查告警升级
   * @private
   */
  _checkEscalation() {
    try {
      const now = Date.now();

      // 检查每个活动告警
      for (const [alertId, alert] of this.activeAlerts.entries()) {
        // 获取告警级别配置
        const levelConfig = this.config.levels[alert.level];

        // 如果配置了自动升级
        if (levelConfig && levelConfig.autoEscalate && levelConfig.escalateTimeout) {
          // 检查是否已升级
          if (alert.escalated) {
            continue;
          }

          // 计算告警年龄
          const alertTimestamp = new Date(alert.timestamp).getTime();
          const alertAge = now - alertTimestamp;

          // 如果告警年龄超过升级超时
          if (alertAge >= levelConfig.escalateTimeout) {
            // 升级告警
            this._escalateAlert(alertId);

            logger.info(`告警已升级: ${alert.message}`, { alertId, age: alertAge });
          }
        }
      }
    } catch (error) {
      logger.error('检查告警升级失败', { error });
    }
  }

  /**
   * 升级告警
   * @private
   * @param {string} alertId - 告警ID
   */
  _escalateAlert(alertId) {
    try {
      // 获取告警
      const alert = this.activeAlerts.get(alertId);

      if (!alert) {
        return;
      }

      // 标记为已升级
      alert.escalated = true;
      alert.escalatedAt = new Date().toISOString();

      // 更新告警
      this.activeAlerts.set(alertId, alert);

      // 发送升级通知
      this._sendNotifications(alert, true);

      // 发出告警升级事件
      this.emit('alert:escalated', { alertId, alert });
    } catch (error) {
      logger.error('升级告警失败', { error, alertId });
    }
  }

  /**
   * 添加告警
   * @param {Object} alert - 告警信息
   * @returns {string} 告警ID
   */
  addAlert(alert) {
    try {
      // 检查初始化状态
      if (!this.initialized) {
        throw new Error('告警服务未初始化');
      }

      // 如果未启用告警，不执行操作
      if (!this.config.enabled) {
        return null;
      }

      // 验证告警级别
      if (!alert.level || !this.config.levels[alert.level]) {
        alert.level = 'info';
      }

      // 添加告警ID
      if (!alert.id) {
        alert.id = uuidv4();
      }

      // 添加时间戳
      if (!alert.timestamp) {
        alert.timestamp = new Date().toISOString();
      }

      // 如果启用了聚合，添加到缓冲区
      if (this.config.aggregation.enabled) {
        this.aggregationBuffer.push(alert);

        // 如果缓冲区过大，立即处理
        if (this.aggregationBuffer.length >= this.config.aggregation.threshold * 2) {
          this._processAggregation();
        }
      } else {
        // 直接添加告警
        this._addAlert(alert);
      }

      return alert.id;
    } catch (error) {
      logger.error('添加告警失败', { error, alert });
      return null;
    }
  }

  /**
   * 添加告警（内部方法）
   * @private
   * @param {Object} alert - 告警信息
   */
  _addAlert(alert) {
    try {
      // 添加到活动告警
      this.activeAlerts.set(alert.id, alert);

      // 更新告警计数器
      this.alertCounters.total++;
      this.alertCounters.byLevel[alert.level]++;

      // 按类型计数
      if (alert.type) {
        const typeCount = this.alertCounters.byType.get(alert.type) || 0;
        this.alertCounters.byType.set(alert.type, typeCount + 1);
      }

      // 发送通知
      this._sendNotifications(alert);

      // 发出告警添加事件
      this.emit('alert:added', { alertId: alert.id, alert });

      // 记录日志
      const logLevel = alert.level === 'critical' || alert.level === 'error' ? 'error' :
                      alert.level === 'warning' ? 'warn' : 'info';

      logger[logLevel](`告警: ${alert.message}`, { alertId: alert.id, level: alert.level, type: alert.type });

      return alert.id;
    } catch (error) {
      logger.error('添加告警失败', { error, alert });
      return null;
    }
  }

  /**
   * 解决告警
   * @param {string} alertId - 告警ID
   * @param {Object} resolution - 解决信息
   * @returns {boolean} 是否成功
   */
  resolveAlert(alertId, resolution = {}) {
    try {
      // 检查初始化状态
      if (!this.initialized) {
        throw new Error('告警服务未初始化');
      }

      // 如果未启用告警，不执行操作
      if (!this.config.enabled) {
        return false;
      }

      // 获取告警
      const alert = this.activeAlerts.get(alertId);

      if (!alert) {
        return false;
      }

      // 添加解决信息
      alert.resolved = true;
      alert.resolvedAt = new Date().toISOString();
      alert.resolution = {
        reason: resolution.reason || 'manual',
        message: resolution.message || '告警已手动解决',
        by: resolution.by || 'system'
      };

      // 从活动告警中移除
      this.activeAlerts.delete(alertId);

      // 添加到已解决告警
      this.resolvedAlerts.push(alert);

      // 限制已解决告警数量
      if (this.resolvedAlerts.length > this.config.persistence.maxAlerts) {
        this.resolvedAlerts = this.resolvedAlerts.slice(-this.config.persistence.maxAlerts);
      }

      // 发出告警解决事件
      this.emit('alert:resolved', { alertId, alert });

      logger.info(`告警已解决: ${alert.message}`, { alertId, resolution });

      return true;
    } catch (error) {
      logger.error('解决告警失败', { error, alertId });
      return false;
    }
  }

  /**
   * 发送通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {boolean} isEscalation - 是否是升级通知
   */
  _sendNotifications(alert, isEscalation = false) {
    try {
      // 如果未启用通知，不执行操作
      if (!this.config.notifications.enabled) {
        return;
      }

      // 控制台通知
      this._sendConsoleNotification(alert, isEscalation);

      // 邮件通知
      this._checkAndSendEmailNotification(alert, isEscalation);

      // Webhook通知
      this._checkAndSendWebhookNotification(alert, isEscalation);

      // 更新通知计数器
      this.notificationCounters.total++;
    } catch (error) {
      logger.error('发送通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 发送控制台通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {boolean} isEscalation - 是否是升级通知
   */
  _sendConsoleNotification(alert, isEscalation) {
    try {
      // 如果未启用控制台通知，不执行操作
      if (!this.config.notifications.channels.console.enabled) {
        return;
      }

      // 检查最小级别
      const minLevel = this.config.notifications.channels.console.minLevel;
      const levelPriority = this.config.levels[alert.level].priority;
      const minLevelPriority = this.config.levels[minLevel].priority;

      if (levelPriority < minLevelPriority) {
        return;
      }

      // 构建通知消息
      const prefix = isEscalation ? '[升级]' : '';
      const message = `${prefix}告警: ${alert.message}`;

      // 根据级别选择日志级别
      const logLevel = alert.level === 'critical' || alert.level === 'error' ? 'error' :
                      alert.level === 'warning' ? 'warn' : 'info';

      // 记录日志
      logger[logLevel](message, { alertId: alert.id, level: alert.level, type: alert.type });

      // 更新通知计数器
      this.notificationCounters.byChannel.console++;
    } catch (error) {
      logger.error('发送控制台通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 检查并发送邮件通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {boolean} isEscalation - 是否是升级通知
   */
  _checkAndSendEmailNotification(alert, isEscalation) {
    try {
      // 如果未启用邮件通知，不执行操作
      if (!this.config.notifications.channels.email.enabled) {
        return;
      }

      // 检查最小级别
      const minLevel = this.config.notifications.channels.email.minLevel;
      const levelPriority = this.config.levels[alert.level].priority;
      const minLevelPriority = this.config.levels[minLevel].priority;

      if (levelPriority < minLevelPriority && !isEscalation) {
        return;
      }

      // 检查节流
      const now = Date.now();
      const throttle = this.config.notifications.channels.email.throttle;

      if (now - this.lastNotificationTime.email < throttle && !isEscalation) {
        logger.debug('邮件通知被节流', { alertId: alert.id });
        return;
      }

      // 更新最后通知时间
      this.lastNotificationTime.email = now;

      // 获取收件人
      const recipients = this.config.notifications.channels.email.recipients;

      if (!recipients || recipients.length === 0) {
        logger.warn('邮件通知没有收件人', { alertId: alert.id });
        return;
      }

      // 提交异步任务
      asyncTaskService.addTask('alert-email-notification', {
        alertId: alert.id,
        alert,
        recipients,
        isEscalation
      });

      // 更新通知计数器
      this.notificationCounters.byChannel.email++;
    } catch (error) {
      logger.error('检查并发送邮件通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 发送邮件通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {Array<string>} recipients - 收件人列表
   * @returns {Promise<void>}
   */
  async _sendEmailNotification(alert, recipients) {
    try {
      // TODO: 实现邮件发送逻辑
      logger.info('发送邮件通知', { alertId: alert.id, recipients });
    } catch (error) {
      logger.error('发送邮件通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 检查并发送Webhook通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {boolean} isEscalation - 是否是升级通知
   */
  _checkAndSendWebhookNotification(alert, isEscalation) {
    try {
      // 如果未启用Webhook通知，不执行操作
      if (!this.config.notifications.channels.webhook.enabled) {
        return;
      }

      // 检查最小级别
      const minLevel = this.config.notifications.channels.webhook.minLevel;
      const levelPriority = this.config.levels[alert.level].priority;
      const minLevelPriority = this.config.levels[minLevel].priority;

      if (levelPriority < minLevelPriority && !isEscalation) {
        return;
      }

      // 检查节流
      const now = Date.now();
      const throttle = this.config.notifications.channels.webhook.throttle;

      if (now - this.lastNotificationTime.webhook < throttle && !isEscalation) {
        logger.debug('Webhook通知被节流', { alertId: alert.id });
        return;
      }

      // 更新最后通知时间
      this.lastNotificationTime.webhook = now;

      // 获取URL
      const url = this.config.notifications.channels.webhook.url;

      if (!url) {
        logger.warn('Webhook通知没有URL', { alertId: alert.id });
        return;
      }

      // 提交异步任务
      asyncTaskService.addTask('alert-webhook-notification', {
        alertId: alert.id,
        alert,
        url,
        isEscalation
      });

      // 更新通知计数器
      this.notificationCounters.byChannel.webhook++;
    } catch (error) {
      logger.error('检查并发送Webhook通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 发送Webhook通知
   * @private
   * @param {Object} alert - 告警信息
   * @param {string} url - Webhook URL
   * @returns {Promise<void>}
   */
  async _sendWebhookNotification(alert, url) {
    try {
      // TODO: 实现Webhook发送逻辑
      logger.info('发送Webhook通知', { alertId: alert.id, url });
    } catch (error) {
      logger.error('发送Webhook通知失败', { error, alertId: alert.id });
    }
  }

  /**
   * 获取活动告警
   * @returns {Array<Object>} 活动告警列表
   */
  getActiveAlerts() {
    return Array.from(this.activeAlerts.values());
  }

  /**
   * 获取已解决告警
   * @param {number} limit - 限制数量
   * @returns {Array<Object>} 已解决告警列表
   */
  getResolvedAlerts(limit = 100) {
    return this.resolvedAlerts.slice(-limit);
  }

  /**
   * 获取告警
   * @param {string} alertId - 告警ID
   * @returns {Object|null} 告警
   */
  getAlert(alertId) {
    // 先从活动告警中查找
    if (this.activeAlerts.has(alertId)) {
      return this.activeAlerts.get(alertId);
    }

    // 再从已解决告警中查找
    return this.resolvedAlerts.find(alert => alert.id === alertId) || null;
  }

  /**
   * 获取告警统计
   * @returns {Object} 告警统计
   */
  getAlertStats() {
    return {
      active: this.activeAlerts.size,
      resolved: this.resolvedAlerts.length,
      total: this.alertCounters.total,
      byLevel: { ...this.alertCounters.byLevel },
      byType: Object.fromEntries(this.alertCounters.byType),
      notifications: {
        total: this.notificationCounters.total,
        byChannel: { ...this.notificationCounters.byChannel }
      }
    };
  }

  /**
   * 清理已解决告警
   * @param {number} maxAge - 最大年龄（毫秒）
   * @returns {number} 清理的告警数
   */
  cleanupResolvedAlerts(maxAge = 30 * 24 * 60 * 60 * 1000) { // 默认30天
    try {
      const now = Date.now();
      const initialCount = this.resolvedAlerts.length;

      // 过滤掉超过最大年龄的告警
      this.resolvedAlerts = this.resolvedAlerts.filter(alert => {
        const resolvedAt = new Date(alert.resolvedAt).getTime();
        return now - resolvedAt < maxAge;
      });

      const cleanedCount = initialCount - this.resolvedAlerts.length;

      if (cleanedCount > 0) {
        logger.info(`清理了${cleanedCount}个已解决告警`);
      }

      return cleanedCount;
    } catch (error) {
      logger.error('清理已解决告警失败', { error });
      return 0;
    }
  }

  /**
   * 关闭告警服务
   * @returns {Promise<void>}
   */
  async close() {
    try {
      logger.info('关闭告警服务');

      // 清除定时器
      if (this.aggregationTimer) {
        clearInterval(this.aggregationTimer);
        this.aggregationTimer = null;
      }

      if (this.persistenceTimer) {
        clearInterval(this.persistenceTimer);
        this.persistenceTimer = null;
      }

      if (this.autoResolveTimer) {
        clearInterval(this.autoResolveTimer);
        this.autoResolveTimer = null;
      }

      if (this.escalationTimer) {
        clearInterval(this.escalationTimer);
        this.escalationTimer = null;
      }

      // 持久化告警
      if (this.config.persistence.enabled) {
        await this._persistAlerts();
      }

      // 重置状态
      this.initialized = false;

      logger.info('告警服务已关闭');
    } catch (error) {
      logger.error('关闭告警服务失败', { error });
      throw error;
    }
  }
}

// 创建单例
const alertService = new AlertService();

// 导出
module.exports = {
  alertService,
  AlertService
};
