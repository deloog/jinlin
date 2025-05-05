/**
 * 备份控制器
 *
 * 处理备份相关的API请求
 */

const path = require('path');
const fs = require('fs');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');
const backupSchedulerService = require('../services/backupSchedulerService');
const backupMonitoringService = require('../services/backupMonitoringService');
const asyncTaskService = require('../services/asyncTaskService');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * 获取备份状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 * @returns {void}
 */
exports.getBackupStatus = async (req, res, next) => {
  try {
    const status = backupSchedulerService.getBackupStatus();

    // 获取备份历史
    const backupHistory = await getBackupHistory();

    // 获取监控指标
    const monitoringMetrics = await getMonitoringMetrics();

    res.json({
      status,
      history: backupHistory,
      monitoring: monitoringMetrics
    });
  } catch (error) {
    logger.error('获取备份状态失败', error);
    next(error);
  }
};

/**
 * 获取备份历史
 * @returns {Promise<Array>} 备份历史
 */
async function getBackupHistory() {
  try {
    // 获取备份目录
    const backupDir = process.env.BACKUP_DIR || path.resolve(process.cwd(), 'backups');

    // 如果目录不存在，返回空数组
    if (!fs.existsSync(backupDir)) {
      return [];
    }

    // 获取备份文件
    const files = fs.readdirSync(backupDir)
      .filter(file => {
        // 过滤备份文件
        return file.includes('_daily_') ||
               file.includes('_weekly_') ||
               file.includes('_monthly_');
      })
      .map(file => {
        // 获取文件信息
        const filePath = path.join(backupDir, file);
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
    logger.error('获取备份历史失败', error);
    return [];
  }
}

/**
 * 执行手动备份
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 * @returns {void}
 */
exports.executeManualBackup = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new ValidationError('验证失败', errors.array());
    }

    const { type = 'full', upload = false } = req.body;

    // 执行手动备份
    const taskId = await backupSchedulerService.executeManualBackup(type, upload);

    res.json({
      message: '手动备份已启动',
      taskId
    });
  } catch (error) {
    logger.error('执行手动备份失败', error);
    next(error);
  }
};

/**
 * 获取备份任务状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 * @returns {void}
 */
exports.getBackupTaskStatus = async (req, res, next) => {
  try {
    const { taskId } = req.params;

    // 获取任务
    const task = asyncTaskService.getTask(taskId);
    if (!task) {
      throw new NotFoundError('备份任务不存在');
    }

    res.json({
      task
    });
  } catch (error) {
    logger.error('获取备份任务状态失败', error);
    next(error);
  }
};

/**
 * 获取监控指标
 * @returns {Promise<Object>} 监控指标
 */
async function getMonitoringMetrics() {
  try {
    // 从Prometheus服务获取备份相关指标
    const metrics = {
      fileCount: {},
      latestAge: {},
      latestSize: {},
      status: {}
    };

    // 获取备份文件数量
    const backupFilesGauge = backupMonitoringService.backupFilesGauge;
    if (backupFilesGauge) {
      const values = backupFilesGauge.getValues();
      for (const [labels, value] of Object.entries(values)) {
        const type = JSON.parse(labels).type;
        metrics.fileCount[type] = value;
      }
    }

    // 获取最新备份文件年龄
    const backupAgeGauge = backupMonitoringService.backupAgeGauge;
    if (backupAgeGauge) {
      const values = backupAgeGauge.getValues();
      for (const [labels, value] of Object.entries(values)) {
        const type = JSON.parse(labels).type;
        metrics.latestAge[type] = value;
      }
    }

    // 获取最新备份文件大小
    const backupSizeGauge = backupMonitoringService.backupSizeGauge;
    if (backupSizeGauge) {
      const values = backupSizeGauge.getValues();
      for (const [labels, value] of Object.entries(values)) {
        const type = JSON.parse(labels).type;
        metrics.latestSize[type] = value;
      }
    }

    // 获取备份状态
    const backupStatusGauge = backupMonitoringService.backupStatusGauge;
    if (backupStatusGauge) {
      const values = backupStatusGauge.getValues();
      for (const [labels, value] of Object.entries(values)) {
        const type = JSON.parse(labels).type;
        metrics.status[type] = value === 1;
      }
    }

    return metrics;
  } catch (error) {
    logger.error('获取监控指标失败', error);
    return {};
  }
}

/**
 * 更新备份配置
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 * @returns {void}
 */
exports.updateBackupConfig = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      throw new ValidationError('验证失败', errors.array());
    }

    const {
      enabled,
      schedules,
      retention,
      upload,
      notification,
      monitoring
    } = req.body;

    // 更新备份调度配置
    const schedulerConfig = {};

    if (enabled !== undefined) {
      schedulerConfig.enabled = enabled;
    }

    if (schedules) {
      schedulerConfig.schedules = schedules;
    }

    if (retention) {
      schedulerConfig.retention = retention;
    }

    if (upload) {
      schedulerConfig.upload = upload;
    }

    if (notification) {
      schedulerConfig.notification = notification;
    }

    backupSchedulerService.updateConfig(schedulerConfig);

    // 更新监控配置
    if (monitoring) {
      backupMonitoringService.updateConfig(monitoring);
    }

    res.json({
      message: '备份配置已更新',
      config: {
        scheduler: backupSchedulerService.config,
        monitoring: backupMonitoringService.config
      }
    });
  } catch (error) {
    logger.error('更新备份配置失败', error);
    next(error);
  }
};

/**
 * 删除备份文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 * @returns {void}
 */
exports.deleteBackupFile = async (req, res, next) => {
  try {
    const { fileName } = req.params;

    // 获取备份目录
    const backupDir = process.env.BACKUP_DIR || path.resolve(process.cwd(), 'backups');
    const filePath = path.join(backupDir, fileName);

    // 检查文件是否存在
    if (!fs.existsSync(filePath)) {
      throw new NotFoundError('备份文件不存在');
    }

    // 删除文件
    fs.unlinkSync(filePath);

    res.json({
      message: '备份文件已删除'
    });
  } catch (error) {
    logger.error('删除备份文件失败', error);
    next(error);
  }
};
