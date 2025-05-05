/**
 * 备份调度服务
 * 
 * 负责调度和管理自动备份任务
 */

const cron = require('node-cron');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');
const configService = require('./configService');
const asyncTaskService = require('./asyncTaskService');
const alertService = require('./alertService');

/**
 * 备份调度服务
 */
class BackupSchedulerService {
  /**
   * 构造函数
   */
  constructor() {
    this.initialized = false;
    this.tasks = new Map();
    this.lastBackupStatus = new Map();
    this.config = {
      enabled: true,
      schedules: {
        daily: '0 1 * * *',      // 每天凌晨1点
        weekly: '0 2 * * 0',     // 每周日凌晨2点
        monthly: '0 3 1 * *'     // 每月1日凌晨3点
      },
      retention: {
        daily: 7,                // 保留7天
        weekly: 4,               // 保留4周
        monthly: 12              // 保留12个月
      },
      upload: {
        enabled: false,
        destinations: ['s3']     // 上传目标
      },
      notification: {
        success: true,           // 成功通知
        failure: true            // 失败通知
      },
      maxConcurrent: 1           // 最大并发备份任务数
    };
    
    // 注册配置模式
    this._registerConfigSchema();
  }
  
  /**
   * 注册配置模式
   * @private
   */
  _registerConfigSchema() {
    configService.configManager.registerSchema('backup', {
      type: 'object',
      properties: {
        enabled: { type: 'boolean' },
        schedules: {
          type: 'object',
          properties: {
            daily: { type: 'string', format: 'cron' },
            weekly: { type: 'string', format: 'cron' },
            monthly: { type: 'string', format: 'cron' }
          }
        },
        retention: {
          type: 'object',
          properties: {
            daily: { type: 'integer', minimum: 1 },
            weekly: { type: 'integer', minimum: 1 },
            monthly: { type: 'integer', minimum: 1 }
          }
        },
        upload: {
          type: 'object',
          properties: {
            enabled: { type: 'boolean' },
            destinations: { 
              type: 'array',
              items: { type: 'string', enum: ['s3', 'ftp', 'local'] }
            }
          }
        },
        notification: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            failure: { type: 'boolean' }
          }
        },
        maxConcurrent: { type: 'integer', minimum: 1 }
      }
    });
  }
  
  /**
   * 初始化服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化备份调度服务');
      
      // 加载配置
      const config = configService.configManager.get('backup');
      if (config) {
        this.config = { ...this.config, ...config };
      }
      
      // 确保备份目录存在
      const backupDir = this.config.backupDir || path.resolve(process.cwd(), 'backups');
      if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
      }
      
      // 如果启用，则调度备份任务
      if (this.config.enabled) {
        this._scheduleBackupTasks();
      }
      
      this.initialized = true;
      logger.info('备份调度服务初始化完成');
    } catch (error) {
      logger.error('初始化备份调度服务失败', error);
      throw error;
    }
  }
  
  /**
   * 调度备份任务
   * @private
   */
  _scheduleBackupTasks() {
    try {
      logger.info('调度备份任务');
      
      // 调度每日备份
      this._scheduleTask('daily', this.config.schedules.daily, () => {
        return this._executeBackup('daily');
      });
      
      // 调度每周备份
      this._scheduleTask('weekly', this.config.schedules.weekly, () => {
        return this._executeBackup('weekly');
      });
      
      // 调度每月备份
      this._scheduleTask('monthly', this.config.schedules.monthly, () => {
        return this._executeBackup('monthly');
      });
      
      logger.info('备份任务调度完成');
    } catch (error) {
      logger.error('调度备份任务失败', error);
      throw error;
    }
  }
  
  /**
   * 调度任务
   * @private
   * @param {string} name - 任务名称
   * @param {string} schedule - Cron表达式
   * @param {Function} callback - 回调函数
   */
  _scheduleTask(name, schedule, callback) {
    // 取消现有任务
    if (this.tasks.has(name)) {
      this.tasks.get(name).stop();
    }
    
    // 创建新任务
    const task = cron.schedule(schedule, async () => {
      try {
        logger.info(`执行${name}备份任务`);
        await callback();
      } catch (error) {
        logger.error(`执行${name}备份任务失败`, error);
        
        // 发送告警
        if (this.config.notification.failure) {
          alertService.createAlert({
            name: `backup_failure_${name}`,
            level: 'error',
            message: `${name}备份失败: ${error.message}`,
            source: 'backup_scheduler',
            data: { error: error.message, stack: error.stack }
          });
        }
      }
    });
    
    // 保存任务
    this.tasks.set(name, task);
    logger.info(`已调度${name}备份任务: ${schedule}`);
  }
  
  /**
   * 执行备份
   * @private
   * @param {string} type - 备份类型
   * @returns {Promise<boolean>} 是否成功
   */
  async _executeBackup(type) {
    try {
      // 检查是否有太多并发备份任务
      const runningTasks = asyncTaskService.getTasksByType('backup')
        .filter(task => task.status === 'running')
        .length;
      
      if (runningTasks >= this.config.maxConcurrent) {
        logger.warn(`备份任务数量已达到最大值 ${this.config.maxConcurrent}，跳过${type}备份`);
        return false;
      }
      
      // 添加异步任务
      const taskId = await asyncTaskService.addTask('backup', {
        type,
        upload: this.config.upload.enabled,
        timestamp: new Date().toISOString()
      });
      
      logger.info(`已添加${type}备份任务: ${taskId}`);
      
      // 更新最后备份状态
      this.lastBackupStatus.set(type, {
        status: 'running',
        startTime: new Date(),
        taskId
      });
      
      return true;
    } catch (error) {
      logger.error(`执行${type}备份失败`, error);
      
      // 更新最后备份状态
      this.lastBackupStatus.set(type, {
        status: 'failed',
        startTime: new Date(),
        endTime: new Date(),
        error: error.message
      });
      
      return false;
    }
  }
  
  /**
   * 手动执行备份
   * @param {string} type - 备份类型
   * @param {boolean} upload - 是否上传
   * @returns {Promise<string>} 任务ID
   */
  async executeManualBackup(type = 'full', upload = false) {
    try {
      logger.info(`手动执行${type}备份`);
      
      // 添加异步任务
      const taskId = await asyncTaskService.addTask('backup', {
        type,
        upload,
        manual: true,
        timestamp: new Date().toISOString()
      });
      
      logger.info(`已添加手动${type}备份任务: ${taskId}`);
      
      return taskId;
    } catch (error) {
      logger.error(`手动执行${type}备份失败`, error);
      throw error;
    }
  }
  
  /**
   * 获取备份状态
   * @returns {Object} 备份状态
   */
  getBackupStatus() {
    return {
      enabled: this.config.enabled,
      schedules: this.config.schedules,
      lastBackupStatus: Object.fromEntries(this.lastBackupStatus),
      runningTasks: asyncTaskService.getTasksByType('backup')
        .filter(task => task.status === 'running')
        .map(task => ({
          id: task.id,
          type: task.data.type,
          startTime: new Date(task.startTime).toISOString(),
          manual: task.data.manual || false
        }))
    };
  }
  
  /**
   * 启用备份
   * @returns {void}
   */
  enable() {
    if (!this.config.enabled) {
      this.config.enabled = true;
      this._scheduleBackupTasks();
      logger.info('已启用备份');
    }
  }
  
  /**
   * 禁用备份
   * @returns {void}
   */
  disable() {
    if (this.config.enabled) {
      this.config.enabled = false;
      
      // 停止所有任务
      for (const [name, task] of this.tasks.entries()) {
        task.stop();
        logger.info(`已停止${name}备份任务`);
      }
      
      this.tasks.clear();
      logger.info('已禁用备份');
    }
  }
  
  /**
   * 更新备份配置
   * @param {Object} config - 新配置
   * @returns {void}
   */
  updateConfig(config) {
    // 更新配置
    this.config = { ...this.config, ...config };
    
    // 如果启用，则重新调度备份任务
    if (this.config.enabled) {
      this._scheduleBackupTasks();
    } else {
      this.disable();
    }
    
    logger.info('已更新备份配置');
  }
}

// 创建单例
const backupSchedulerService = new BackupSchedulerService();

module.exports = backupSchedulerService;
