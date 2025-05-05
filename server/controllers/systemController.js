/**
 * 系统控制器
 *
 * 提供系统状态信息，包括：
 * - 熔断器状态
 * - 服务降级状态
 * - 缓存状态
 * - 资源使用情况
 * - 令牌黑名单状态
 */
const logger = require('../utils/logger');
const { getAllCircuitBreakerStates } = require('../utils/circuitBreaker');
const { fallbackManager } = require('../utils/fallbackStrategy');
const cacheService = require('../services/cacheService');
const { tokenBlacklistManager } = require('../services/tokenBlacklistService');
const monitoringService = require('../services/monitoringService');
const os = require('os');
const v8 = require('v8');

/**
 * 获取系统状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSystemStatus = async (req, res) => {
  try {
    // 获取系统指标
    const metrics = monitoringService.getSystemMetrics();

    // 获取熔断器状态
    const circuitBreakerStates = getAllCircuitBreakerStates();

    // 获取服务降级状态
    const fallbackState = fallbackManager.getSystemState();

    // 获取缓存状态
    const cacheStats = await cacheService.getStats();

    // 获取令牌黑名单状态
    const tokenBlacklistStats = tokenBlacklistManager.getStats();

    // 获取资源使用情况
    const resourceUsage = {
      cpu: {
        usage: process.cpuUsage(),
        cores: os.cpus().length
      },
      memory: {
        total: os.totalmem(),
        free: os.freemem(),
        usage: process.memoryUsage()
      },
      disk: {
        // 简单实现，实际应该使用fs.statfs或其他方法获取磁盘使用情况
        available: true
      }
    };

    // 获取系统信息
    const systemInfo = {
      platform: os.platform(),
      arch: os.arch(),
      release: os.release(),
      uptime: os.uptime(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      cpus: os.cpus().length,
      loadAvg: os.loadavg()
    };

    // 获取Node.js信息
    const nodeInfo = {
      version: process.version,
      pid: process.pid,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      heapStatistics: v8.getHeapStatistics()
    };

    res.json({
      timestamp: Date.now(),
      system: systemInfo,
      node: nodeInfo,
      metrics,
      circuitBreakers: circuitBreakerStates,
      fallback: fallbackState,
      cache: cacheStats,
      tokenBlacklist: tokenBlacklistStats,
      resources: resourceUsage
    });
  } catch (error) {
    logger.error('获取系统状态失败:', error);
    res.status(500).json({ error: '获取系统状态失败' });
  }
};

/**
 * 获取熔断器状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getCircuitBreakerStatus = async (req, res) => {
  try {
    const circuitBreakerStates = getAllCircuitBreakerStates();

    res.json({
      timestamp: Date.now(),
      circuitBreakers: circuitBreakerStates
    });
  } catch (error) {
    logger.error('获取熔断器状态失败:', error);
    res.status(500).json({ error: '获取熔断器状态失败' });
  }
};

/**
 * 获取服务降级状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getFallbackStatus = async (req, res) => {
  try {
    const fallbackState = fallbackManager.getSystemState();
    const serviceStates = fallbackManager.getAllServiceStates();

    res.json({
      timestamp: Date.now(),
      system: fallbackState,
      services: serviceStates
    });
  } catch (error) {
    logger.error('获取服务降级状态失败:', error);
    res.status(500).json({ error: '获取服务降级状态失败' });
  }
};

/**
 * 获取缓存状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getCacheStatus = async (req, res) => {
  try {
    const cacheStats = await cacheService.getStats();

    res.json({
      timestamp: Date.now(),
      cache: cacheStats
    });
  } catch (error) {
    logger.error('获取缓存状态失败:', error);
    res.status(500).json({ error: '获取缓存状态失败' });
  }
};

/**
 * 获取令牌黑名单状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTokenBlacklistStatus = async (req, res) => {
  try {
    const tokenBlacklistStats = tokenBlacklistManager.getStats();

    res.json({
      timestamp: Date.now(),
      tokenBlacklist: tokenBlacklistStats
    });
  } catch (error) {
    logger.error('获取令牌黑名单状态失败:', error);
    res.status(500).json({ error: '获取令牌黑名单状态失败' });
  }
};

/**
 * 获取资源使用情况
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getResourceUsage = async (req, res) => {
  try {
    const resourceUsage = {
      cpu: {
        usage: process.cpuUsage(),
        cores: os.cpus().length
      },
      memory: {
        total: os.totalmem(),
        free: os.freemem(),
        usage: process.memoryUsage()
      },
      disk: {
        // 简单实现，实际应该使用fs.statfs或其他方法获取磁盘使用情况
        available: true
      }
    };

    res.json({
      timestamp: Date.now(),
      resources: resourceUsage
    });
  } catch (error) {
    logger.error('获取资源使用情况失败:', error);
    res.status(500).json({ error: '获取资源使用情况失败' });
  }
};

/**
 * 强制执行垃圾回收
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.forceGarbageCollection = async (req, res) => {
  try {
    // 获取垃圾回收前的内存使用情况
    const memoryBefore = process.memoryUsage();

    // 强制执行垃圾回收
    if (global.gc) {
      global.gc();

      // 获取垃圾回收后的内存使用情况
      const memoryAfter = process.memoryUsage();

      res.json({
        timestamp: Date.now(),
        message: '垃圾回收成功',
        memoryBefore,
        memoryAfter,
        freed: {
          rss: memoryBefore.rss - memoryAfter.rss,
          heapTotal: memoryBefore.heapTotal - memoryAfter.heapTotal,
          heapUsed: memoryBefore.heapUsed - memoryAfter.heapUsed,
          external: memoryBefore.external - memoryAfter.external
        }
      });
    } else {
      res.status(400).json({
        error: '无法强制执行垃圾回收，请使用--expose-gc参数启动Node.js'
      });
    }
  } catch (error) {
    logger.error('强制执行垃圾回收失败:', error);
    res.status(500).json({ error: '强制执行垃圾回收失败' });
  }
};

/**
 * 清空缓存
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.clearCache = async (req, res) => {
  try {
    const { namespace } = req.query;

    if (namespace) {
      // 清空指定命名空间的缓存
      const count = await cacheService.clearNamespace(namespace);

      res.json({
        timestamp: Date.now(),
        message: `命名空间 ${namespace} 的缓存已清空`,
        count
      });
    } else {
      // 清空所有缓存
      const count = await cacheService.clearAll();

      res.json({
        timestamp: Date.now(),
        message: '所有缓存已清空',
        count
      });
    }
  } catch (error) {
    logger.error('清空缓存失败:', error);
    res.status(500).json({ error: '清空缓存失败' });
  }
};

/**
 * 重置熔断器
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.resetCircuitBreaker = async (req, res) => {
  try {
    const { name } = req.params;

    const circuitBreaker = require('../utils/circuitBreaker').getCircuitBreaker(name);

    if (!circuitBreaker) {
      return res.status(404).json({
        error: `熔断器 ${name} 不存在`
      });
    }

    // 重置熔断器
    circuitBreaker.reset();

    res.json({
      timestamp: Date.now(),
      message: `熔断器 ${name} 已重置`,
      state: circuitBreaker.getState()
    });
  } catch (error) {
    logger.error('重置熔断器失败:', error);
    res.status(500).json({ error: '重置熔断器失败' });
  }
};
