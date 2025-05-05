/**
 * 备份任务处理器
 * 
 * 处理备份异步任务
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');
const asyncTaskService = require('./asyncTaskService');
const alertService = require('./alertService');
const configService = require('./configService');

/**
 * 备份任务处理器
 */
class BackupTaskHandler {
  /**
   * 构造函数
   */
  constructor() {
    this.initialized = false;
    this.config = {
      backupScript: path.resolve(process.cwd(), 'scripts/disaster-recovery/backup.js'),
      notification: {
        success: true,
        failure: true
      }
    };
  }
  
  /**
   * 初始化处理器
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化备份任务处理器');
      
      // 加载配置
      const config = configService.configManager.get('backup');
      if (config && config.notification) {
        this.config.notification = config.notification;
      }
      
      // 注册任务处理器
      asyncTaskService.registerHandler('backup', this.handleBackupTask.bind(this));
      
      this.initialized = true;
      logger.info('备份任务处理器初始化完成');
    } catch (error) {
      logger.error('初始化备份任务处理器失败', error);
      throw error;
    }
  }
  
  /**
   * 处理备份任务
   * @param {Object} data - 任务数据
   * @param {Object} task - 任务对象
   * @returns {Promise<Object>} 任务结果
   */
  async handleBackupTask(data, task) {
    try {
      logger.info(`处理备份任务: ${task.id}`, { type: data.type, upload: data.upload });
      
      // 构建命令
      const cmd = this._buildBackupCommand(data);
      
      // 执行备份命令
      logger.info(`执行备份命令: ${cmd}`);
      const output = execSync(cmd, { encoding: 'utf8' });
      
      // 解析输出
      const result = this._parseBackupOutput(output);
      
      // 发送成功通知
      if (this.config.notification.success) {
        alertService.createAlert({
          name: `backup_success_${data.type}`,
          level: 'info',
          message: `${data.type}备份成功`,
          source: 'backup_handler',
          data: {
            type: data.type,
            files: result.files,
            upload: data.upload,
            manual: data.manual || false
          }
        });
      }
      
      logger.info(`备份任务完成: ${task.id}`, { result });
      return {
        success: true,
        files: result.files,
        output: result.output
      };
    } catch (error) {
      logger.error(`备份任务失败: ${task.id}`, error);
      
      // 发送失败通知
      if (this.config.notification.failure) {
        alertService.createAlert({
          name: `backup_failure_${data.type}`,
          level: 'error',
          message: `${data.type}备份失败: ${error.message}`,
          source: 'backup_handler',
          data: {
            type: data.type,
            error: error.message,
            stack: error.stack,
            manual: data.manual || false
          }
        });
      }
      
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  /**
   * 构建备份命令
   * @private
   * @param {Object} data - 任务数据
   * @returns {string} 备份命令
   */
  _buildBackupCommand(data) {
    const args = [];
    
    // 备份类型
    if (data.type && data.type !== 'full') {
      args.push(`--type=${data.type}`);
    }
    
    // 环境
    const env = process.env.NODE_ENV || 'development';
    args.push(`--env=${env}`);
    
    // 是否上传
    if (data.upload) {
      args.push('--upload=true');
    }
    
    // 构建命令
    return `node ${this.config.backupScript} ${args.join(' ')}`;
  }
  
  /**
   * 解析备份输出
   * @private
   * @param {string} output - 备份输出
   * @returns {Object} 解析结果
   */
  _parseBackupOutput(output) {
    try {
      // 提取备份文件
      const files = [];
      const fileRegex = /备份(文件|配置|数据库)完成: (.+)/g;
      let match;
      
      while ((match = fileRegex.exec(output)) !== null) {
        files.push(match[2]);
      }
      
      return {
        success: true,
        files,
        output
      };
    } catch (error) {
      logger.error('解析备份输出失败', error);
      return {
        success: false,
        files: [],
        output
      };
    }
  }
}

// 创建单例
const backupTaskHandler = new BackupTaskHandler();

module.exports = backupTaskHandler;
