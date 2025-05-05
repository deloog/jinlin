/**
 * 监控服务
 * 提供应用程序监控和告警功能
 */
const os = require('os');
const { pool } = require('../config/database');
const logger = require('../utils/logger');
const { createError } = require('../utils/errorHandler');

// 系统指标
let systemMetrics = {
  // 服务器指标
  server: {
    uptime: 0,
    memory: {
      total: 0,
      free: 0,
      used: 0,
      usage: 0
    },
    cpu: {
      load: [0, 0, 0],
      usage: 0
    },
    process: {
      memory: {
        rss: 0,
        heapTotal: 0,
        heapUsed: 0,
        external: 0
      },
      cpu: {
        user: 0,
        system: 0
      }
    }
  },

  // 应用指标
  application: {
    requests: {
      total: 0,
      success: 0,
      error: 0,
      pending: 0
    },
    response_time: {
      avg: 0,
      min: 0,
      max: 0,
      p95: 0,
      p99: 0
    },
    error_rate: 0
  },

  // 数据库指标
  database: {
    connections: {
      active: 0,
      idle: 0,
      total: 0
    },
    queries: {
      total: 0,
      select: 0,
      insert: 0,
      update: 0,
      delete: 0
    },
    response_time: {
      avg: 0
    }
  },

  // 缓存指标
  cache: {
    hits: 0,
    misses: 0,
    hit_rate: 0,
    size: 0
  },

  // 熔断器指标
  circuit_breakers: {
    total: 0,
    open: 0,
    half_open: 0,
    closed: 0,
    instances: {}
  },

  // 服务降级指标
  fallback: {
    system_state: 'NORMAL',
    degraded_services: 0,
    total_services: 0
  },

  // 告警
  alerts: []
};

// 请求计数器
const requestCounters = {
  total: 0,
  success: 0,
  error: 0,
  pending: 0,
  byPath: new Map(),
  byMethod: new Map(),
  byStatusCode: new Map()
};

// 速率限制计数器
const rateLimitCounters = {
  total: 0,
  byType: new Map(),
  byResource: new Map(),
  byClientKey: new Map(),
  byPath: new Map()
};

// 响应时间统计
const responseTimeStats = {
  values: [],
  avg: 0,
  min: Number.MAX_SAFE_INTEGER,
  max: 0,
  p95: 0,
  p99: 0
};

// 告警阈值
const alertThresholds = {
  cpu_usage: 80, // CPU使用率超过80%
  memory_usage: 80, // 内存使用率超过80%
  error_rate: 5, // 错误率超过5%
  response_time: 1000 // 响应时间超过1000ms
};

// 告警状态
const alertStatus = {
  cpu_usage: false,
  memory_usage: false,
  error_rate: false,
  response_time: false
};

/**
 * 初始化监控服务
 */
function initialize() {
  // 每10秒收集一次系统指标
  setInterval(collectSystemMetrics, 10000);

  // 每分钟检查一次告警
  setInterval(checkAlerts, 60000);

  // 每小时重置一次响应时间统计
  setInterval(() => {
    responseTimeStats.values = [];
    responseTimeStats.avg = 0;
    responseTimeStats.min = Number.MAX_SAFE_INTEGER;
    responseTimeStats.max = 0;
    responseTimeStats.p95 = 0;
    responseTimeStats.p99 = 0;
  }, 60 * 60 * 1000);

  logger.info('监控服务已初始化');
}

/**
 * 收集系统指标
 */
async function collectSystemMetrics() {
  try {
    // 收集服务器指标
    const totalMemory = os.totalmem();
    const freeMemory = os.freemem();
    const usedMemory = totalMemory - freeMemory;
    const memoryUsage = (usedMemory / totalMemory) * 100;

    const loadAvg = os.loadavg();
    const cpuUsage = process.cpuUsage();
    const processMemory = process.memoryUsage();

    systemMetrics.server.uptime = process.uptime();
    systemMetrics.server.memory.total = totalMemory;
    systemMetrics.server.memory.free = freeMemory;
    systemMetrics.server.memory.used = usedMemory;
    systemMetrics.server.memory.usage = memoryUsage;

    systemMetrics.server.cpu.load = loadAvg;
    systemMetrics.server.cpu.usage = (loadAvg[0] / os.cpus().length) * 100;

    systemMetrics.server.process.memory = {
      rss: processMemory.rss,
      heapTotal: processMemory.heapTotal,
      heapUsed: processMemory.heapUsed,
      external: processMemory.external
    };

    systemMetrics.server.process.cpu = {
      user: cpuUsage.user,
      system: cpuUsage.system
    };

    // 收集应用指标
    systemMetrics.application.requests = {
      total: requestCounters.total,
      success: requestCounters.success,
      error: requestCounters.error,
      pending: requestCounters.pending
    };

    systemMetrics.application.response_time = {
      avg: responseTimeStats.avg,
      min: responseTimeStats.min === Number.MAX_SAFE_INTEGER ? 0 : responseTimeStats.min,
      max: responseTimeStats.max,
      p95: responseTimeStats.p95,
      p99: responseTimeStats.p99
    };

    systemMetrics.application.error_rate = requestCounters.total > 0
      ? (requestCounters.error / requestCounters.total) * 100
      : 0;

    // 收集数据库指标
    try {
      const [dbStatus] = await pool.query('SHOW STATUS');

      const dbStatusMap = {};
      for (const row of dbStatus) {
        dbStatusMap[row.Variable_name] = row.Value;
      }

      systemMetrics.database.connections.active = parseInt(dbStatusMap.Threads_connected || 0);
      systemMetrics.database.connections.idle = parseInt(dbStatusMap.Threads_cached || 0);
      systemMetrics.database.connections.total = parseInt(dbStatusMap.Connections || 0);

      systemMetrics.database.queries.total = parseInt(dbStatusMap.Questions || 0);
      systemMetrics.database.queries.select = parseInt(dbStatusMap.Com_select || 0);
      systemMetrics.database.queries.insert = parseInt(dbStatusMap.Com_insert || 0);
      systemMetrics.database.queries.update = parseInt(dbStatusMap.Com_update || 0);
      systemMetrics.database.queries.delete = parseInt(dbStatusMap.Com_delete || 0);

      systemMetrics.database.response_time.avg = parseFloat(dbStatusMap.Slow_queries || 0);
    } catch (error) {
      logger.error('收集数据库指标失败:', error);
    }

    // 收集缓存指标
    try {
      const cacheService = require('./cacheService');
      const cacheStats = cacheService.getStats();

      systemMetrics.cache = {
        hits: cacheStats.hits,
        misses: cacheStats.misses,
        hit_rate: cacheStats.hitRate * 100,
        size: cacheStats.size
      };
    } catch (error) {
      logger.error('收集缓存指标失败:', error);
    }
  } catch (error) {
    logger.error('收集系统指标失败:', error);
  }
}

/**
 * 检查告警
 */
function checkAlerts() {
  try {
    const alerts = [];

    // 检查CPU使用率
    if (systemMetrics.server.cpu.usage > alertThresholds.cpu_usage) {
      if (!alertStatus.cpu_usage) {
        alertStatus.cpu_usage = true;
        const alert = {
          type: 'cpu_usage',
          level: 'warning',
          message: `CPU使用率过高: ${systemMetrics.server.cpu.usage.toFixed(2)}%`,
          timestamp: new Date().toISOString()
        };
        alerts.push(alert);
        systemMetrics.alerts.push(alert);
        logger.warn(alert.message);
      }
    } else {
      alertStatus.cpu_usage = false;
    }

    // 检查内存使用率
    if (systemMetrics.server.memory.usage > alertThresholds.memory_usage) {
      if (!alertStatus.memory_usage) {
        alertStatus.memory_usage = true;
        const alert = {
          type: 'memory_usage',
          level: 'warning',
          message: `内存使用率过高: ${systemMetrics.server.memory.usage.toFixed(2)}%`,
          timestamp: new Date().toISOString()
        };
        alerts.push(alert);
        systemMetrics.alerts.push(alert);
        logger.warn(alert.message);
      }
    } else {
      alertStatus.memory_usage = false;
    }

    // 检查错误率
    if (systemMetrics.application.error_rate > alertThresholds.error_rate) {
      if (!alertStatus.error_rate) {
        alertStatus.error_rate = true;
        const alert = {
          type: 'error_rate',
          level: 'error',
          message: `错误率过高: ${systemMetrics.application.error_rate.toFixed(2)}%`,
          timestamp: new Date().toISOString()
        };
        alerts.push(alert);
        systemMetrics.alerts.push(alert);
        logger.error(alert.message);
      }
    } else {
      alertStatus.error_rate = false;
    }

    // 检查响应时间
    if (systemMetrics.application.response_time.avg > alertThresholds.response_time) {
      if (!alertStatus.response_time) {
        alertStatus.response_time = true;
        const alert = {
          type: 'response_time',
          level: 'warning',
          message: `平均响应时间过高: ${systemMetrics.application.response_time.avg.toFixed(2)}ms`,
          timestamp: new Date().toISOString()
        };
        alerts.push(alert);
        systemMetrics.alerts.push(alert);
        logger.warn(alert.message);
      }
    } else {
      alertStatus.response_time = false;
    }

    // 限制告警数量
    if (systemMetrics.alerts.length > 100) {
      systemMetrics.alerts = systemMetrics.alerts.slice(-100);
    }

    // 发送告警
    if (alerts.length > 0) {
      sendAlerts(alerts);
    }
  } catch (error) {
    logger.error('检查告警失败:', error);
  }
}

/**
 * 发送告警
 * @param {Array} alerts - 告警列表
 */
function sendAlerts(alerts) {
  // 这里可以实现发送告警的逻辑，如发送邮件、短信、钉钉等
  logger.info(`发送${alerts.length}个告警`);
}

/**
 * 记录请求
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 */
function requestLogger(req, res, next) {
  // 记录请求开始时间
  req._startTime = Date.now();

  // 增加请求计数
  requestCounters.total++;
  requestCounters.pending++;

  // 按路径统计
  const path = req.path;
  if (!requestCounters.byPath.has(path)) {
    requestCounters.byPath.set(path, { total: 0, success: 0, error: 0 });
  }
  requestCounters.byPath.get(path).total++;

  // 按方法统计
  const method = req.method;
  if (!requestCounters.byMethod.has(method)) {
    requestCounters.byMethod.set(method, { total: 0, success: 0, error: 0 });
  }
  requestCounters.byMethod.get(method).total++;

  // 监听响应完成事件
  res.on('finish', () => {
    // 计算响应时间
    const responseTime = Date.now() - req._startTime;

    // 更新响应时间统计
    responseTimeStats.values.push(responseTime);
    responseTimeStats.avg = responseTimeStats.values.reduce((a, b) => a + b, 0) / responseTimeStats.values.length;
    responseTimeStats.min = Math.min(responseTimeStats.min, responseTime);
    responseTimeStats.max = Math.max(responseTimeStats.max, responseTime);

    // 计算百分位数
    if (responseTimeStats.values.length > 0) {
      const sortedValues = [...responseTimeStats.values].sort((a, b) => a - b);
      const p95Index = Math.floor(sortedValues.length * 0.95);
      const p99Index = Math.floor(sortedValues.length * 0.99);
      responseTimeStats.p95 = sortedValues[p95Index] || 0;
      responseTimeStats.p99 = sortedValues[p99Index] || 0;
    }

    // 减少待处理请求计数
    requestCounters.pending--;

    // 按状态码统计
    const statusCode = res.statusCode;
    if (!requestCounters.byStatusCode.has(statusCode)) {
      requestCounters.byStatusCode.set(statusCode, 0);
    }
    requestCounters.byStatusCode.set(statusCode, requestCounters.byStatusCode.get(statusCode) + 1);

    // 更新成功/错误计数
    if (statusCode >= 200 && statusCode < 400) {
      requestCounters.success++;
      requestCounters.byPath.get(path).success++;
      requestCounters.byMethod.get(method).success++;
    } else {
      requestCounters.error++;
      requestCounters.byPath.get(path).error++;
      requestCounters.byMethod.get(method).error++;
    }
  });

  next();
}

/**
 * 更新熔断器指标
 * @param {string} name - 熔断器名称
 * @param {Object} metrics - 熔断器指标
 */
function updateCircuitBreakerMetrics(name, metrics) {
  // 更新熔断器实例指标
  systemMetrics.circuit_breakers.instances[name] = metrics;

  // 更新熔断器总数
  systemMetrics.circuit_breakers.total = Object.keys(systemMetrics.circuit_breakers.instances).length;

  // 更新各状态熔断器数量
  systemMetrics.circuit_breakers.open = Object.values(systemMetrics.circuit_breakers.instances)
    .filter(cb => cb.state === 'OPEN').length;

  systemMetrics.circuit_breakers.half_open = Object.values(systemMetrics.circuit_breakers.instances)
    .filter(cb => cb.state === 'HALF_OPEN').length;

  systemMetrics.circuit_breakers.closed = Object.values(systemMetrics.circuit_breakers.instances)
    .filter(cb => cb.state === 'CLOSED').length;
}

/**
 * 更新服务降级指标
 * @param {Object} metrics - 服务降级指标
 */
function updateFallbackMetrics(metrics) {
  systemMetrics.fallback = {
    ...systemMetrics.fallback,
    ...metrics
  };
}

/**
 * 添加告警
 * @param {Object} alert - 告警信息
 */
function addAlert(alert) {
  // 添加时间戳
  if (!alert.timestamp) {
    alert.timestamp = new Date().toISOString();
  }

  // 添加到告警列表
  systemMetrics.alerts.push(alert);

  // 限制告警数量
  if (systemMetrics.alerts.length > 100) {
    systemMetrics.alerts = systemMetrics.alerts.slice(-100);
  }

  // 记录告警日志
  const logLevel = alert.level === 'critical' ? 'error' :
                  alert.level === 'warning' ? 'warn' : 'info';

  logger[logLevel](`告警: ${alert.message}`, alert);

  // 发送告警（如果需要）
  if (alert.level === 'critical' || alert.level === 'warning') {
    sendAlert(alert);
  }
}

/**
 * 获取系统指标
 * @returns {Object} 系统指标
 */
function getSystemMetrics() {
  return systemMetrics;
}

/**
 * 获取请求计数器
 * @returns {Object} 请求计数器
 */
function getRequestCounters() {
  return {
    total: requestCounters.total,
    success: requestCounters.success,
    error: requestCounters.error,
    pending: requestCounters.pending,
    byPath: Object.fromEntries(requestCounters.byPath),
    byMethod: Object.fromEntries(requestCounters.byMethod),
    byStatusCode: Object.fromEntries(requestCounters.byStatusCode)
  };
}

/**
 * 获取响应时间统计
 * @returns {Object} 响应时间统计
 */
function getResponseTimeStats() {
  return {
    avg: responseTimeStats.avg,
    min: responseTimeStats.min === Number.MAX_SAFE_INTEGER ? 0 : responseTimeStats.min,
    max: responseTimeStats.max,
    p95: responseTimeStats.p95,
    p99: responseTimeStats.p99
  };
}

/**
 * 获取告警
 * @returns {Array} 告警列表
 */
function getAlerts() {
  return systemMetrics.alerts;
}

/**
 * 设置告警阈值
 * @param {Object} thresholds - 告警阈值
 */
function setAlertThresholds(thresholds) {
  if (thresholds.cpu_usage !== undefined) {
    alertThresholds.cpu_usage = thresholds.cpu_usage;
  }

  if (thresholds.memory_usage !== undefined) {
    alertThresholds.memory_usage = thresholds.memory_usage;
  }

  if (thresholds.error_rate !== undefined) {
    alertThresholds.error_rate = thresholds.error_rate;
  }

  if (thresholds.response_time !== undefined) {
    alertThresholds.response_time = thresholds.response_time;
  }
}

/**
 * 记录速率限制事件
 * @param {Object} event - 速率限制事件
 */
function recordRateLimitEvent(event) {
  try {
    // 增加总计数
    rateLimitCounters.total++;

    // 按类型计数
    if (event.type) {
      const typeCount = rateLimitCounters.byType.get(event.type) || 0;
      rateLimitCounters.byType.set(event.type, typeCount + 1);
    }

    // 按资源计数
    if (event.resource) {
      const resourceCount = rateLimitCounters.byResource.get(event.resource) || 0;
      rateLimitCounters.byResource.set(event.resource, resourceCount + 1);
    }

    // 按客户端计数
    if (event.clientKey) {
      const clientCount = rateLimitCounters.byClientKey.get(event.clientKey) || 0;
      rateLimitCounters.byClientKey.set(event.clientKey, clientCount + 1);
    }

    // 按路径计数
    if (event.path) {
      const pathCount = rateLimitCounters.byPath.get(event.path) || 0;
      rateLimitCounters.byPath.set(event.path, pathCount + 1);
    }

    // 添加告警（如果客户端被频繁限制）
    if (event.clientKey) {
      const clientCount = rateLimitCounters.byClientKey.get(event.clientKey) || 0;

      if (clientCount >= 10) {
        addAlert({
          type: 'rate_limit',
          level: 'warning',
          message: `客户端 ${event.clientKey} 频繁触发速率限制`,
          details: {
            clientKey: event.clientKey,
            count: clientCount,
            path: event.path,
            method: event.method,
            type: event.type
          }
        });
      }
    }

    // 更新系统指标
    systemMetrics.application.rate_limits = {
      total: rateLimitCounters.total,
      byType: Object.fromEntries(rateLimitCounters.byType),
      topResources: Array.from(rateLimitCounters.byResource.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5),
      topPaths: Array.from(rateLimitCounters.byPath.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
    };
  } catch (error) {
    logger.error('记录速率限制事件失败:', error);
  }
}

module.exports = {
  initialize,
  requestLogger,
  getSystemMetrics,
  getRequestCounters,
  getResponseTimeStats,
  getAlerts,
  setAlertThresholds,
  updateCircuitBreakerMetrics,
  updateFallbackMetrics,
  addAlert,
  recordDatabaseQuery,
  recordCacheOperation,
  recordRateLimitEvent
};
