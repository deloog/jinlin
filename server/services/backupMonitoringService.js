/**
 * 备份监控服务
 * 
 * 负责监控备份状态和发送告警
 */

const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');
const alertService = require('./alertService');
const configService = require('./configService');
const prometheusService = require('./prometheusService');

/**
 * 备份监控服务
 */
class BackupMonitoringService {
  /**
   * 构造函数
   */
  constructor() {
    this.initialized = false;
    this.monitoringTimer = null;
    this.config = {
      enabled: true,
      interval: 15 * 60 * 1000, // 15分钟
      backupDir: process.env.BACKUP_DIR || path.resolve(process.cwd(), 'backups'),
      thresholds: {
        age: {
          daily: 24 * 60 * 60 * 1000, // 1天
          weekly: 7 * 24 * 60 * 60 * 1000, // 7天
          monthly: 31 * 24 * 60 * 60 * 1000 // 31天
        },
        size: {
          min: 1024, // 1KB
          warning: 1024 * 1024 * 100 // 100MB
        }
      },
      alertLevels: {
        missing: 'error',
        tooOld: 'warning',
        tooSmall: 'warning',
        tooLarge: 'info'
      }
    };
    
    // 注册配置模式
    this._registerConfigSchema();
    
    // 注册Prometheus指标
    this._registerPrometheusMetrics();
  }
  
  /**
   * 注册配置模式
   * @private
   */
  _registerConfigSchema() {
    configService.configManager.registerSchema('backupMonitoring', {
      type: 'object',
      properties: {
        enabled: { type: 'boolean' },
        interval: { type: 'integer', minimum: 60000 },
        thresholds: {
          type: 'object',
          properties: {
            age: {
              type: 'object',
              properties: {
                daily: { type: 'integer', minimum: 3600000 },
                weekly: { type: 'integer', minimum: 3600000 },
                monthly: { type: 'integer', minimum: 3600000 }
              }
            },
            size: {
              type: 'object',
              properties: {
                min: { type: 'integer', minimum: 1 },
                warning: { type: 'integer', minimum: 1024 }
              }
            }
          }
        },
        alertLevels: {
          type: 'object',
          properties: {
            missing: { type: 'string', enum: ['info', 'warning', 'error', 'critical'] },
            tooOld: { type: 'string', enum: ['info', 'warning', 'error', 'critical'] },
            tooSmall: { type: 'string', enum: ['info', 'warning', 'error', 'critical'] },
            tooLarge: { type: 'string', enum: ['info', 'warning', 'error', 'critical'] }
          }
        }
      }
    });
  }
  
  /**
   * 注册Prometheus指标
   * @private
   */
  _registerPrometheusMetrics() {
    // 备份文件数量
    this.backupFilesGauge = prometheusService.registerGauge(
      'backup_files_total',
      'Total number of backup files',
      ['type']
    );
    
    // 最新备份文件年龄
    this.backupAgeGauge = prometheusService.registerGauge(
      'backup_latest_age_seconds',
      'Age of the latest backup file in seconds',
      ['type']
    );
    
    // 最新备份文件大小
    this.backupSizeGauge = prometheusService.registerGauge(
      'backup_latest_size_bytes',
      'Size of the latest backup file in bytes',
      ['type']
    );
    
    // 备份状态
    this.backupStatusGauge = prometheusService.registerGauge(
      'backup_status',
      'Status of backups (1=OK, 0=Error)',
      ['type']
    );
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
      logger.info('初始化备份监控服务');
      
      // 加载配置
      const config = configService.configManager.get('backupMonitoring');
      if (config) {
        this.config = { ...this.config, ...config };
      }
      
      // 确保备份目录存在
      if (!fs.existsSync(this.config.backupDir)) {
        fs.mkdirSync(this.config.backupDir, { recursive: true });
      }
      
      // 启动监控
      if (this.config.enabled) {
        this._startMonitoring();
      }
      
      this.initialized = true;
      logger.info('备份监控服务初始化完成');
    } catch (error) {
      logger.error('初始化备份监控服务失败', error);
      throw error;
    }
  }
  
  /**
   * 启动监控
   * @private
   */
  _startMonitoring() {
    // 清除现有定时器
    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
    }
    
    // 立即执行一次监控
    this._monitorBackups();
    
    // 设置定时器
    this.monitoringTimer = setInterval(() => {
      this._monitorBackups();
    }, this.config.interval);
    
    logger.info(`备份监控已启动，间隔: ${this.config.interval / 1000}秒`);
  }
  
  /**
   * 监控备份
   * @private
   */
  async _monitorBackups() {
    try {
      logger.info('开始监控备份');
      
      // 获取备份文件
      const backupFiles = this._getBackupFiles();
      
      // 按类型分组
      const filesByType = this._groupFilesByType(backupFiles);
      
      // 更新指标
      this._updateMetrics(filesByType);
      
      // 检查备份状态
      this._checkBackupStatus(filesByType);
      
      logger.info('备份监控完成');
    } catch (error) {
      logger.error('监控备份失败', error);
    }
  }
  
  /**
   * 获取备份文件
   * @private
   * @returns {Array<Object>} 备份文件列表
   */
  _getBackupFiles() {
    try {
      // 如果目录不存在，返回空数组
      if (!fs.existsSync(this.config.backupDir)) {
        return [];
      }
      
      // 获取备份文件
      const files = fs.readdirSync(this.config.backupDir)
        .filter(file => {
          // 过滤备份文件
          return file.includes('_daily_') || 
                 file.includes('_weekly_') || 
                 file.includes('_monthly_');
        })
        .map(file => {
          // 获取文件信息
          const filePath = path.join(this.config.backupDir, file);
          const stats = fs.statSync(filePath);
          
          // 解析文件名
          const parts = file.split('_');
          const type = parts[0]; // 数据库、文件或配置
          
          // 确定备份类型
          let backupType = 'unknown';
          if (file.includes('_daily_')) {
            backupType = 'daily';
          } else if (file.includes('_weekly_')) {
            backupType = 'weekly';
          } else if (file.includes('_monthly_')) {
            backupType = 'monthly';
          }
          
          return {
            name: file,
            path: filePath,
            type,
            backupType,
            size: stats.size,
            createdAt: stats.birthtime,
            modifiedAt: stats.mtime
          };
        });
      
      // 按修改时间排序
      files.sort((a, b) => b.modifiedAt - a.modifiedAt);
      
      return files;
    } catch (error) {
      logger.error('获取备份文件失败', error);
      return [];
    }
  }
  
  /**
   * 按类型分组文件
   * @private
   * @param {Array<Object>} files - 文件列表
   * @returns {Object} 分组后的文件
   */
  _groupFilesByType(files) {
    const result = {
      daily: {
        db: [],
        files: [],
        config: []
      },
      weekly: {
        db: [],
        files: [],
        config: []
      },
      monthly: {
        db: [],
        files: [],
        config: []
      }
    };
    
    // 分组文件
    for (const file of files) {
      if (result[file.backupType] && result[file.backupType][file.type]) {
        result[file.backupType][file.type].push(file);
      }
    }
    
    return result;
  }
  
  /**
   * 更新指标
   * @private
   * @param {Object} filesByType - 分组后的文件
   */
  _updateMetrics(filesByType) {
    const now = Date.now();
    
    // 更新每种类型的指标
    for (const [backupType, typeFiles] of Object.entries(filesByType)) {
      for (const [fileType, files] of Object.entries(typeFiles)) {
        // 更新文件数量
        this.backupFilesGauge.set({ type: `${backupType}_${fileType}` }, files.length);
        
        // 如果有文件，更新最新文件的年龄和大小
        if (files.length > 0) {
          const latestFile = files[0];
          const ageSeconds = (now - latestFile.modifiedAt.getTime()) / 1000;
          
          this.backupAgeGauge.set({ type: `${backupType}_${fileType}` }, ageSeconds);
          this.backupSizeGauge.set({ type: `${backupType}_${fileType}` }, latestFile.size);
          
          // 更新状态
          const maxAge = this.config.thresholds.age[backupType];
          const isOk = latestFile.size >= this.config.thresholds.size.min && 
                      (now - latestFile.modifiedAt.getTime()) <= maxAge;
          
          this.backupStatusGauge.set({ type: `${backupType}_${fileType}` }, isOk ? 1 : 0);
        } else {
          // 没有文件，状态为错误
          this.backupStatusGauge.set({ type: `${backupType}_${fileType}` }, 0);
        }
      }
    }
  }
  
  /**
   * 检查备份状态
   * @private
   * @param {Object} filesByType - 分组后的文件
   */
  _checkBackupStatus(filesByType) {
    const now = Date.now();
    
    // 检查每种类型的备份
    for (const [backupType, typeFiles] of Object.entries(filesByType)) {
      for (const [fileType, files] of Object.entries(typeFiles)) {
        // 检查是否有文件
        if (files.length === 0) {
          // 发送缺失告警
          this._sendAlert(
            'missing',
            `缺少${backupType}${fileType}备份`,
            {
              backupType,
              fileType
            }
          );
          continue;
        }
        
        // 获取最新文件
        const latestFile = files[0];
        
        // 检查文件年龄
        const age = now - latestFile.modifiedAt.getTime();
        const maxAge = this.config.thresholds.age[backupType];
        
        if (age > maxAge) {
          // 发送过期告警
          this._sendAlert(
            'tooOld',
            `${backupType}${fileType}备份过期`,
            {
              backupType,
              fileType,
              file: latestFile.name,
              age: Math.floor(age / (60 * 60 * 1000)), // 小时
              maxAge: Math.floor(maxAge / (60 * 60 * 1000)) // 小时
            }
          );
        }
        
        // 检查文件大小
        if (latestFile.size < this.config.thresholds.size.min) {
          // 发送文件过小告警
          this._sendAlert(
            'tooSmall',
            `${backupType}${fileType}备份文件过小`,
            {
              backupType,
              fileType,
              file: latestFile.name,
              size: latestFile.size,
              minSize: this.config.thresholds.size.min
            }
          );
        } else if (latestFile.size > this.config.thresholds.size.warning) {
          // 发送文件过大告警
          this._sendAlert(
            'tooLarge',
            `${backupType}${fileType}备份文件过大`,
            {
              backupType,
              fileType,
              file: latestFile.name,
              size: latestFile.size,
              warningSize: this.config.thresholds.size.warning
            }
          );
        }
      }
    }
  }
  
  /**
   * 发送告警
   * @private
   * @param {string} type - 告警类型
   * @param {string} message - 告警消息
   * @param {Object} data - 告警数据
   */
  _sendAlert(type, message, data) {
    const level = this.config.alertLevels[type] || 'warning';
    
    alertService.createAlert({
      name: `backup_${type}_${data.backupType}_${data.fileType}`,
      level,
      message,
      source: 'backup_monitoring',
      data
    });
  }
  
  /**
   * 停止监控
   */
  stop() {
    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
      this.monitoringTimer = null;
      logger.info('备份监控已停止');
    }
  }
  
  /**
   * 手动执行监控
   * @returns {Promise<void>}
   */
  async runNow() {
    await this._monitorBackups();
  }
  
  /**
   * 更新配置
   * @param {Object} config - 新配置
   */
  updateConfig(config) {
    // 更新配置
    this.config = { ...this.config, ...config };
    
    // 重启监控
    if (this.config.enabled) {
      this._startMonitoring();
    } else {
      this.stop();
    }
    
    logger.info('备份监控配置已更新');
  }
}

// 创建单例
const backupMonitoringService = new BackupMonitoringService();

module.exports = backupMonitoringService;
