/**
 * 监控控制器
 *
 * 提供监控和告警相关的API：
 * - 获取系统健康状态
 * - 获取系统指标
 * - 获取告警信息
 * - 获取追踪信息
 */
const { validationResult } = require('express-validator');
const monitoringService = require('../services/monitoringService');
const logger = require('../utils/enhancedLogger');
const { alertService } = require('../services/alertService');
const { tracingService } = require('../services/tracingService');
const { asyncTaskService } = require('../services/asyncTaskService');
const { multiLevelCacheService } = require('../services/multiLevelCacheService');
const { loadBalancerService } = require('../services/loadBalancerService');
const os = require('os');

/**
 * 获取系统指标
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSystemMetrics = (req, res, next) => {
  try {
    const metrics = monitoringService.getSystemMetrics();
    res.json({ data: metrics });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取请求计数器
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getRequestCounters = (req, res, next) => {
  try {
    const counters = monitoringService.getRequestCounters();
    res.json({ data: counters });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取响应时间统计
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getResponseTimeStats = (req, res, next) => {
  try {
    const stats = monitoringService.getResponseTimeStats();
    res.json({ data: stats });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取告警
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getAlerts = (req, res, next) => {
  try {
    // 如果使用新的告警服务
    if (alertService && alertService.initialized) {
      // 获取查询参数
      const { status, level, limit } = req.query;

      // 获取活动告警
      let activeAlerts = alertService.getActiveAlerts();

      // 获取已解决告警
      let resolvedAlerts = alertService.getResolvedAlerts(parseInt(limit || '100', 10));

      // 根据状态过滤
      if (status === 'active') {
        resolvedAlerts = [];
      } else if (status === 'resolved') {
        activeAlerts = [];
      }

      // 根据级别过滤
      if (level) {
        activeAlerts = activeAlerts.filter(alert => alert.level === level);
        resolvedAlerts = resolvedAlerts.filter(alert => alert.level === level);
      }

      // 获取告警统计
      const alertStats = alertService.getAlertStats();

      // 返回告警信息
      res.json({
        timestamp: Date.now(),
        active: activeAlerts,
        resolved: resolvedAlerts,
        stats: alertStats
      });
    } else {
      // 使用旧的监控服务
      const alerts = monitoringService.getAlerts();
      res.json({ data: alerts });
    }
  } catch (error) {
    logger.error('获取告警信息失败', { error });
    next(error);
  }
};

/**
 * 设置告警阈值
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.setAlertThresholds = (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { cpu_usage, memory_usage, error_rate, response_time } = req.body;

    monitoringService.setAlertThresholds({
      cpu_usage,
      memory_usage,
      error_rate,
      response_time
    });

    res.json({ message: '告警阈值已更新' });
  } catch (error) {
    next(error);
  }
};

/**
 * 解决告警
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.resolveAlert = async (req, res, next) => {
  try {
    // 获取告警ID
    const { alertId } = req.params;

    if (!alertId) {
      return res.status(400).json({ error: '缺少告警ID' });
    }

    // 获取解决信息
    const { reason, message } = req.body;

    // 解决告警
    const result = alertService.resolveAlert(alertId, {
      reason: reason || 'manual',
      message: message || '告警已手动解决',
      by: req.user ? req.user.username : 'admin'
    });

    if (!result) {
      return res.status(404).json({ error: '告警不存在或已解决', alertId });
    }

    // 返回成功消息
    res.json({
      timestamp: Date.now(),
      alertId,
      message: '告警已解决',
      success: true
    });
  } catch (error) {
    logger.error('解决告警失败', { error });
    next(error);
  }
};

/**
 * 获取系统健康状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getHealth = async (req, res, next) => {
  try {
    // 获取系统信息
    const systemInfo = {
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      release: os.release(),
      uptime: os.uptime(),
      loadavg: os.loadavg(),
      totalmem: os.totalmem(),
      freemem: os.freemem(),
      cpus: os.cpus().length
    };

    // 获取进程信息
    const processInfo = {
      pid: process.pid,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      version: process.version,
      env: process.env.NODE_ENV || 'development'
    };

    // 获取服务状态
    const servicesStatus = {
      monitoring: monitoringService.isInitialized ? 'healthy' : 'initializing',
      alert: alertService.initialized ? 'healthy' : 'initializing',
      tracing: tracingService.initialized ? 'healthy' : 'initializing',
      asyncTask: asyncTaskService.initialized ? 'healthy' : 'initializing',
      cache: multiLevelCacheService.initialized ? 'healthy' : 'initializing',
      loadBalancer: loadBalancerService.initialized ? 'healthy' : 'initializing'
    };

    // 计算整体状态
    const overallStatus = Object.values(servicesStatus).every(status => status === 'healthy') ? 'healthy' : 'degraded';

    // 返回健康状态
    res.json({
      timestamp: Date.now(),
      status: overallStatus,
      system: systemInfo,
      process: processInfo,
      services: servicesStatus
    });
  } catch (error) {
    logger.error('获取系统健康状态失败', { error });
    next(error);
  }
};

/**
 * 获取追踪信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTraces = async (req, res, next) => {
  try {
    // 获取追踪统计
    const tracingStats = tracingService.getTracingStats();

    // 返回追踪信息
    res.json({
      timestamp: Date.now(),
      stats: tracingStats
    });
  } catch (error) {
    logger.error('获取追踪信息失败', { error });
    next(error);
  }
};

/**
 * 获取追踪详情
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTraceDetails = async (req, res, next) => {
  try {
    // 获取追踪ID
    const { traceId } = req.params;

    if (!traceId) {
      return res.status(400).json({ error: '缺少追踪ID' });
    }

    // 获取追踪
    const trace = tracingService.getTrace(traceId);

    if (!trace) {
      return res.status(404).json({ error: '追踪不存在', traceId });
    }

    // 返回追踪详情
    res.json({
      timestamp: Date.now(),
      traceId,
      trace: trace.getData()
    });
  } catch (error) {
    logger.error('获取追踪详情失败', { error });
    next(error);
  }
};

/**
 * 获取服务状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getServiceStatus = async (req, res, next) => {
  try {
    // 获取异步任务服务状态
    const asyncTaskStatus = {
      initialized: asyncTaskService.initialized,
      queueLength: asyncTaskService.queue.length,
      runningTasks: asyncTaskService.runningTasks,
      handlers: asyncTaskService.handlers.size,
      tasks: asyncTaskService.tasks.size
    };

    // 获取缓存服务状态
    const cacheStatus = {
      initialized: multiLevelCacheService.initialized,
      size: multiLevelCacheService.getSize(),
      hitRate: multiLevelCacheService.getHitRate(),
      missRate: multiLevelCacheService.getMissRate()
    };

    // 获取负载均衡服务状态
    const loadBalancerStatus = {
      initialized: loadBalancerService.initialized,
      enabled: loadBalancerService.config.enabled,
      nodes: loadBalancerService.nodes.size,
      healthyNodes: Array.from(loadBalancerService.nodeHealth.values()).filter(health => health.status === 'healthy').length
    };

    // 返回服务状态
    res.json({
      timestamp: Date.now(),
      asyncTask: asyncTaskStatus,
      cache: cacheStatus,
      loadBalancer: loadBalancerStatus
    });
  } catch (error) {
    logger.error('获取服务状态失败', { error });
    next(error);
  }
};
