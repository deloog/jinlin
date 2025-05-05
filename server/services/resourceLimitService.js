/**
 * 资源限制服务
 * 
 * 实现更细粒度的资源限制和并发控制，防止资源耗尽
 * 支持：
 * - API资源限制：限制API请求频率和并发数
 * - 数据库连接限制：监控和管理数据库连接池
 * - 文件上传限制：限制文件上传大小和数量
 * - 内存使用限制：监控和限制内存使用
 */
const logger = require('../utils/logger');
const { EventEmitter } = require('events');
const os = require('os');
const v8 = require('v8');

// 默认配置
const DEFAULT_OPTIONS = {
  checkInterval: 5000,      // 检查间隔（毫秒）
  memoryThreshold: {        // 内存使用阈值
    warning: 70,            // 警告阈值（百分比）
    critical: 85,           // 危急阈值（百分比）
    action: 95              // 操作阈值（百分比）
  },
  cpuThreshold: {           // CPU使用阈值
    warning: 70,            // 警告阈值（百分比）
    critical: 85,           // 危急阈值（百分比）
    action: 95              // 操作阈值（百分比）
  },
  dbConnectionThreshold: {  // 数据库连接阈值
    warning: 70,            // 警告阈值（百分比）
    critical: 85,           // 危急阈值（百分比）
    action: 95              // 操作阈值（百分比）
  },
  fileUploadLimits: {       // 文件上传限制
    maxSize: 10 * 1024 * 1024, // 最大文件大小（字节）
    maxFiles: 5,            // 最大文件数
    allowedTypes: [         // 允许的文件类型
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
      'text/plain',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
  },
  apiRateLimits: {          // API速率限制
    default: {              // 默认限制
      windowMs: 60000,      // 时间窗口（毫秒）
      max: 100,             // 最大请求数
      message: '请求过于频繁，请稍后再试'
    },
    auth: {                 // 认证API限制
      windowMs: 3600000,    // 时间窗口（毫秒）
      max: 20,              // 最大请求数
      message: '认证请求过于频繁，请稍后再试'
    },
    ai: {                   // AI API限制
      windowMs: 3600000,    // 时间窗口（毫秒）
      max: 10,              // 最大请求数
      message: 'AI请求过于频繁，请稍后再试'
    }
  },
  concurrencyLimits: {      // 并发限制
    default: 100,           // 默认并发限制
    fileUpload: 10,         // 文件上传并发限制
    aiProcessing: 5,        // AI处理并发限制
    dbQuery: 50             // 数据库查询并发限制
  },
  enableGC: true,           // 是否启用垃圾回收
  gcThreshold: 85,          // 垃圾回收阈值（百分比）
  enableLogging: true,      // 是否启用日志
  enableAlerts: true,       // 是否启用告警
  enableActions: true       // 是否启用自动操作
};

/**
 * 资源限制管理器
 */
class ResourceLimitManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} options - 配置选项
   */
  constructor(options = {}) {
    super();
    this.options = { ...DEFAULT_OPTIONS, ...options };
    
    // 资源使用情况
    this.resourceUsage = {
      memory: {
        total: 0,
        used: 0,
        free: 0,
        percentage: 0
      },
      cpu: {
        usage: 0,
        cores: os.cpus().length
      },
      dbConnections: {
        total: 0,
        used: 0,
        free: 0,
        percentage: 0
      },
      concurrency: {
        current: {
          default: 0,
          fileUpload: 0,
          aiProcessing: 0,
          dbQuery: 0
        },
        max: this.options.concurrencyLimits
      },
      heapStatistics: {}
    };
    
    // 并发计数器
    this.concurrencyCounters = new Map();
    
    // 启动资源监控
    this._startResourceMonitoring();
    
    logger.info('资源限制管理器已创建');
  }
  
  /**
   * 启动资源监控
   * @private
   */
  _startResourceMonitoring() {
    this.monitorInterval = setInterval(() => {
      this._checkResourceUsage();
    }, this.options.checkInterval);
  }
  
  /**
   * 检查资源使用情况
   * @private
   */
  _checkResourceUsage() {
    try {
      // 更新内存使用情况
      this._updateMemoryUsage();
      
      // 更新CPU使用情况
      this._updateCpuUsage();
      
      // 更新数据库连接情况
      this._updateDbConnectionUsage();
      
      // 检查是否需要执行操作
      this._checkActions();
      
      // 发送资源使用情况事件
      this._emitEvent('resource-usage-updated', {
        resourceUsage: { ...this.resourceUsage }
      });
    } catch (error) {
      logger.error('检查资源使用情况失败:', error);
    }
  }
  
  /**
   * 更新内存使用情况
   * @private
   */
  _updateMemoryUsage() {
    // 系统内存
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;
    const memPercentage = (usedMem / totalMem) * 100;
    
    this.resourceUsage.memory = {
      total: totalMem,
      used: usedMem,
      free: freeMem,
      percentage: memPercentage
    };
    
    // 堆内存
    const heapStats = v8.getHeapStatistics();
    this.resourceUsage.heapStatistics = {
      totalHeapSize: heapStats.total_heap_size,
      usedHeapSize: heapStats.used_heap_size,
      heapSizeLimit: heapStats.heap_size_limit,
      percentage: (heapStats.used_heap_size / heapStats.heap_size_limit) * 100
    };
    
    // 检查内存使用情况
    if (memPercentage >= this.options.memoryThreshold.action) {
      logger.error(`内存使用率过高: ${memPercentage.toFixed(2)}%，已达到操作阈值`);
      this._emitEvent('memory-critical', {
        percentage: memPercentage,
        threshold: this.options.memoryThreshold.action
      });
    } else if (memPercentage >= this.options.memoryThreshold.critical) {
      logger.warn(`内存使用率过高: ${memPercentage.toFixed(2)}%，已达到危急阈值`);
      this._emitEvent('memory-warning', {
        percentage: memPercentage,
        threshold: this.options.memoryThreshold.critical
      });
    } else if (memPercentage >= this.options.memoryThreshold.warning) {
      logger.info(`内存使用率较高: ${memPercentage.toFixed(2)}%，已达到警告阈值`);
    }
  }
  
  /**
   * 更新CPU使用情况
   * @private
   */
  _updateCpuUsage() {
    // 这里简单实现，实际应该使用更准确的方式计算CPU使用率
    // 例如，使用node-os-utils库
    
    // 获取CPU信息
    const cpus = os.cpus();
    let totalIdle = 0;
    let totalTick = 0;
    
    // 计算CPU使用率
    for (const cpu of cpus) {
      for (const type in cpu.times) {
        totalTick += cpu.times[type];
      }
      totalIdle += cpu.times.idle;
    }
    
    // 计算CPU使用百分比
    const cpuPercentage = 100 - (totalIdle / totalTick) * 100;
    
    this.resourceUsage.cpu = {
      usage: cpuPercentage,
      cores: cpus.length
    };
    
    // 检查CPU使用情况
    if (cpuPercentage >= this.options.cpuThreshold.action) {
      logger.error(`CPU使用率过高: ${cpuPercentage.toFixed(2)}%，已达到操作阈值`);
      this._emitEvent('cpu-critical', {
        percentage: cpuPercentage,
        threshold: this.options.cpuThreshold.action
      });
    } else if (cpuPercentage >= this.options.cpuThreshold.critical) {
      logger.warn(`CPU使用率过高: ${cpuPercentage.toFixed(2)}%，已达到危急阈值`);
      this._emitEvent('cpu-warning', {
        percentage: cpuPercentage,
        threshold: this.options.cpuThreshold.critical
      });
    } else if (cpuPercentage >= this.options.cpuThreshold.warning) {
      logger.info(`CPU使用率较高: ${cpuPercentage.toFixed(2)}%，已达到警告阈值`);
    }
  }
  
  /**
   * 更新数据库连接使用情况
   * @private
   */
  _updateDbConnectionUsage() {
    try {
      // 获取数据库连接池信息
      // 这里简单实现，实际应该从数据库连接池获取
      const { pool } = require('../config/database');
      
      if (pool && typeof pool.getConnection === 'function') {
        // 获取连接池状态
        pool.query('SHOW STATUS LIKE "Threads_connected"', (err, results) => {
          if (err) {
            logger.error('获取数据库连接状态失败:', err);
            return;
          }
          
          // 解析结果
          const threadsConnected = results[0] ? parseInt(results[0].Value, 10) : 0;
          
          // 更新连接使用情况
          const connectionLimit = pool.config.connectionLimit || 10;
          const usedConnections = threadsConnected;
          const freeConnections = connectionLimit - usedConnections;
          const connectionPercentage = (usedConnections / connectionLimit) * 100;
          
          this.resourceUsage.dbConnections = {
            total: connectionLimit,
            used: usedConnections,
            free: freeConnections,
            percentage: connectionPercentage
          };
          
          // 检查数据库连接使用情况
          if (connectionPercentage >= this.options.dbConnectionThreshold.action) {
            logger.error(`数据库连接使用率过高: ${connectionPercentage.toFixed(2)}%，已达到操作阈值`);
            this._emitEvent('db-connection-critical', {
              percentage: connectionPercentage,
              threshold: this.options.dbConnectionThreshold.action
            });
          } else if (connectionPercentage >= this.options.dbConnectionThreshold.critical) {
            logger.warn(`数据库连接使用率过高: ${connectionPercentage.toFixed(2)}%，已达到危急阈值`);
            this._emitEvent('db-connection-warning', {
              percentage: connectionPercentage,
              threshold: this.options.dbConnectionThreshold.critical
            });
          } else if (connectionPercentage >= this.options.dbConnectionThreshold.warning) {
            logger.info(`数据库连接使用率较高: ${connectionPercentage.toFixed(2)}%，已达到警告阈值`);
          }
        });
      }
    } catch (error) {
      logger.error('更新数据库连接使用情况失败:', error);
    }
  }
  
  /**
   * 检查是否需要执行操作
   * @private
   */
  _checkActions() {
    // 如果未启用自动操作，直接返回
    if (!this.options.enableActions) {
      return;
    }
    
    // 检查是否需要执行垃圾回收
    if (this.options.enableGC && 
        this.resourceUsage.heapStatistics.percentage >= this.options.gcThreshold) {
      this._forceGarbageCollection();
    }
  }
  
  /**
   * 强制执行垃圾回收
   * @private
   */
  _forceGarbageCollection() {
    try {
      logger.info('强制执行垃圾回收');
      
      // 在Node.js中，可以使用global.gc()强制执行垃圾回收
      // 但需要使用--expose-gc参数启动Node.js
      if (global.gc) {
        global.gc();
        logger.info('垃圾回收完成');
        
        // 更新内存使用情况
        this._updateMemoryUsage();
        
        this._emitEvent('garbage-collection-completed', {
          memoryBefore: this.resourceUsage.memory,
          memoryAfter: this.resourceUsage.memory
        });
      } else {
        logger.warn('无法强制执行垃圾回收，请使用--expose-gc参数启动Node.js');
      }
    } catch (error) {
      logger.error('强制执行垃圾回收失败:', error);
    }
  }
  
  /**
   * 验证文件上传
   * @param {Object} file - 文件对象
   * @returns {Object} 验证结果
   */
  validateFileUpload(file) {
    // 检查文件大小
    if (file.size > this.options.fileUploadLimits.maxSize) {
      return {
        valid: false,
        error: `文件大小超过限制: ${file.size} > ${this.options.fileUploadLimits.maxSize}`
      };
    }
    
    // 检查文件类型
    if (!this.options.fileUploadLimits.allowedTypes.includes(file.mimetype)) {
      return {
        valid: false,
        error: `不支持的文件类型: ${file.mimetype}`
      };
    }
    
    return {
      valid: true
    };
  }
  
  /**
   * 获取API速率限制配置
   * @param {string} type - API类型
   * @returns {Object} 速率限制配置
   */
  getApiRateLimit(type) {
    return this.options.apiRateLimits[type] || this.options.apiRateLimits.default;
  }
  
  /**
   * 获取并发限制
   * @param {string} type - 并发类型
   * @returns {number} 并发限制
   */
  getConcurrencyLimit(type) {
    return this.options.concurrencyLimits[type] || this.options.concurrencyLimits.default;
  }
  
  /**
   * 增加并发计数
   * @param {string} type - 并发类型
   * @returns {boolean} 是否成功
   */
  incrementConcurrency(type) {
    const limit = this.getConcurrencyLimit(type);
    const current = this.resourceUsage.concurrency.current[type] || 0;
    
    // 检查是否超过限制
    if (current >= limit) {
      logger.warn(`并发请求超过限制: ${type}, ${current} >= ${limit}`);
      return false;
    }
    
    // 增加计数
    this.resourceUsage.concurrency.current[type] = current + 1;
    
    // 更新并发计数器
    const key = `${type}:${Date.now()}`;
    this.concurrencyCounters.set(key, true);
    
    return true;
  }
  
  /**
   * 减少并发计数
   * @param {string} type - 并发类型
   */
  decrementConcurrency(type) {
    const current = this.resourceUsage.concurrency.current[type] || 0;
    
    // 减少计数
    this.resourceUsage.concurrency.current[type] = Math.max(0, current - 1);
  }
  
  /**
   * 创建并发控制中间件
   * @param {string} type - 并发类型
   * @returns {Function} 中间件函数
   */
  createConcurrencyMiddleware(type) {
    return (req, res, next) => {
      // 增加并发计数
      if (!this.incrementConcurrency(type)) {
        // 如果超过限制，返回错误
        return res.status(429).json({
          error: `并发请求过多，请稍后再试`,
          status: 429
        });
      }
      
      // 在请求结束时减少并发计数
      res.on('finish', () => {
        this.decrementConcurrency(type);
      });
      
      next();
    };
  }
  
  /**
   * 发送事件
   * @param {string} eventName - 事件名称
   * @param {Object} data - 事件数据
   * @private
   */
  _emitEvent(eventName, data = {}) {
    if (this.options.enableLogging) {
      this.emit(eventName, {
        timestamp: Date.now(),
        ...data
      });
    }
  }
  
  /**
   * 获取资源使用情况
   * @returns {Object} 资源使用情况
   */
  getResourceUsage() {
    return { ...this.resourceUsage };
  }
  
  /**
   * 关闭资源限制管理器
   */
  close() {
    // 清除监控定时器
    if (this.monitorInterval) {
      clearInterval(this.monitorInterval);
    }
    
    logger.info('资源限制管理器已关闭');
  }
}

// 创建单例
const resourceLimitManager = new ResourceLimitManager();

module.exports = {
  resourceLimitManager,
  ResourceLimitManager
};
