/**
 * 服务降级策略服务
 * 
 * 实现服务降级策略，确保核心功能在系统压力大时仍能正常运行
 * 服务降级策略包括：
 * - 服务优先级：区分核心服务和非核心服务
 * - 降级策略：在系统压力大时自动降级非核心服务
 * - 降级回退：为关键服务提供降级回退方案
 */
const logger = require('../utils/logger');
const monitoringService = require('./monitoringService');
const { EventEmitter } = require('events');

// 服务优先级
const ServicePriority = {
  CRITICAL: 'CRITICAL',   // 关键服务，不可降级
  HIGH: 'HIGH',           // 高优先级服务，最后降级
  MEDIUM: 'MEDIUM',       // 中优先级服务，次优先降级
  LOW: 'LOW'              // 低优先级服务，优先降级
};

// 系统状态
const SystemState = {
  NORMAL: 'NORMAL',       // 正常状态，所有服务正常运行
  UNDER_LOAD: 'UNDER_LOAD', // 负载状态，部分非核心服务降级
  OVERLOADED: 'OVERLOADED', // 过载状态，大部分非核心服务降级
  CRITICAL: 'CRITICAL'    // 危急状态，只保留关键服务
};

// 默认配置
const DEFAULT_OPTIONS = {
  checkInterval: 10000,   // 检查间隔，多久检查一次系统状态（毫秒）
  cpuThreshold: {         // CPU使用率阈值
    underLoad: 70,        // 负载状态阈值
    overloaded: 85,       // 过载状态阈值
    critical: 95          // 危急状态阈值
  },
  memoryThreshold: {      // 内存使用率阈值
    underLoad: 70,        // 负载状态阈值
    overloaded: 85,       // 过载状态阈值
    critical: 95          // 危急状态阈值
  },
  responseTimeThreshold: { // 响应时间阈值（毫秒）
    underLoad: 500,       // 负载状态阈值
    overloaded: 1000,     // 过载状态阈值
    critical: 2000        // 危急状态阈值
  },
  errorRateThreshold: {   // 错误率阈值（百分比）
    underLoad: 5,         // 负载状态阈值
    overloaded: 10,       // 过载状态阈值
    critical: 20          // 危急状态阈值
  },
  recoveryThreshold: 3,   // 恢复阈值，连续多少次检查正常后恢复服务
  degradationDelay: 5000  // 降级延迟，检测到系统状态变化后多久开始降级（毫秒）
};

/**
 * 服务降级管理器
 */
class FallbackManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} options - 配置选项
   */
  constructor(options = {}) {
    super();
    this.options = { ...DEFAULT_OPTIONS, ...options };
    
    // 系统状态
    this.systemState = SystemState.NORMAL;
    
    // 注册的服务
    this.services = new Map();
    
    // 降级状态
    this.degradedServices = new Set();
    
    // 恢复计数器
    this.recoveryCounter = 0;
    
    // 上次状态变更时间
    this.lastStateChange = Date.now();
    
    // 启动监控
    this._startMonitoring();
    
    logger.info(`服务降级管理器已创建，初始系统状态: ${this.systemState}`);
  }
  
  /**
   * 注册服务
   * @param {string} serviceName - 服务名称
   * @param {Function} normalFunction - 正常功能函数
   * @param {Function} fallbackFunction - 降级功能函数
   * @param {string} priority - 服务优先级
   * @returns {Object} 服务对象
   */
  registerService(serviceName, normalFunction, fallbackFunction, priority = ServicePriority.MEDIUM) {
    if (this.services.has(serviceName)) {
      logger.warn(`服务 [${serviceName}] 已注册，将被覆盖`);
    }
    
    const service = {
      name: serviceName,
      normalFunction,
      fallbackFunction,
      priority,
      isDegraded: false
    };
    
    this.services.set(serviceName, service);
    logger.info(`服务 [${serviceName}] 已注册，优先级: ${priority}`);
    
    return service;
  }
  
  /**
   * 执行服务
   * @param {string} serviceName - 服务名称
   * @param {...any} args - 传递给服务函数的参数
   * @returns {Promise<any>} 服务执行结果
   */
  async executeService(serviceName, ...args) {
    const service = this.services.get(serviceName);
    
    if (!service) {
      throw new Error(`服务 [${serviceName}] 未注册`);
    }
    
    // 检查服务是否降级
    if (service.isDegraded || this.degradedServices.has(serviceName)) {
      logger.debug(`服务 [${serviceName}] 已降级，使用降级功能`);
      return service.fallbackFunction(...args);
    }
    
    // 根据系统状态和服务优先级决定是否降级
    if (this._shouldDegrade(service)) {
      logger.debug(`服务 [${serviceName}] 根据系统状态降级，使用降级功能`);
      return service.fallbackFunction(...args);
    }
    
    // 使用正常功能
    return service.normalFunction(...args);
  }
  
  /**
   * 手动降级服务
   * @param {string} serviceName - 服务名称
   * @returns {boolean} 是否成功
   */
  degradeService(serviceName) {
    const service = this.services.get(serviceName);
    
    if (!service) {
      logger.warn(`尝试降级未注册的服务 [${serviceName}]`);
      return false;
    }
    
    if (service.isDegraded) {
      return true; // 已经是降级状态
    }
    
    service.isDegraded = true;
    this.degradedServices.add(serviceName);
    
    logger.info(`服务 [${serviceName}] 已手动降级`);
    this._emitEvent('service-degraded', { serviceName });
    
    return true;
  }
  
  /**
   * 手动恢复服务
   * @param {string} serviceName - 服务名称
   * @returns {boolean} 是否成功
   */
  restoreService(serviceName) {
    const service = this.services.get(serviceName);
    
    if (!service) {
      logger.warn(`尝试恢复未注册的服务 [${serviceName}]`);
      return false;
    }
    
    if (!service.isDegraded) {
      return true; // 已经是正常状态
    }
    
    service.isDegraded = false;
    this.degradedServices.delete(serviceName);
    
    logger.info(`服务 [${serviceName}] 已手动恢复`);
    this._emitEvent('service-restored', { serviceName });
    
    return true;
  }
  
  /**
   * 判断服务是否应该降级
   * @param {Object} service - 服务对象
   * @returns {boolean} 是否应该降级
   * @private
   */
  _shouldDegrade(service) {
    // 关键服务不降级
    if (service.priority === ServicePriority.CRITICAL) {
      return false;
    }
    
    // 根据系统状态和服务优先级决定
    switch (this.systemState) {
      case SystemState.NORMAL:
        return false;
      
      case SystemState.UNDER_LOAD:
        // 只降级低优先级服务
        return service.priority === ServicePriority.LOW;
      
      case SystemState.OVERLOADED:
        // 降级低优先级和中优先级服务
        return service.priority === ServicePriority.LOW || 
               service.priority === ServicePriority.MEDIUM;
      
      case SystemState.CRITICAL:
        // 降级所有非关键服务
        return service.priority !== ServicePriority.CRITICAL;
      
      default:
        return false;
    }
  }
  
  /**
   * 启动监控
   * @private
   */
  _startMonitoring() {
    this.monitorInterval = setInterval(() => {
      this._checkSystemState();
    }, this.options.checkInterval);
  }
  
  /**
   * 检查系统状态
   * @private
   */
  _checkSystemState() {
    try {
      // 获取系统指标
      const metrics = monitoringService.getSystemMetrics();
      
      // 计算新的系统状态
      const newState = this._calculateSystemState(metrics);
      
      // 如果状态变化，更新系统状态
      if (newState !== this.systemState) {
        this._updateSystemState(newState);
      } else if (newState === SystemState.NORMAL && this.systemState === SystemState.NORMAL) {
        // 如果连续多次检查都是正常状态，增加恢复计数器
        this.recoveryCounter++;
        
        // 如果恢复计数器达到阈值，恢复所有服务
        if (this.recoveryCounter >= this.options.recoveryThreshold) {
          this._restoreAllServices();
        }
      }
    } catch (error) {
      logger.error('检查系统状态失败:', error);
    }
  }
  
  /**
   * 计算系统状态
   * @param {Object} metrics - 系统指标
   * @returns {string} 系统状态
   * @private
   */
  _calculateSystemState(metrics) {
    // 获取CPU使用率
    const cpuUsage = metrics.server.cpu.usage;
    
    // 获取内存使用率
    const memoryUsage = (metrics.server.memory.used / metrics.server.memory.total) * 100;
    
    // 获取平均响应时间
    const responseTime = metrics.application.response_time.avg;
    
    // 获取错误率
    const errorRate = metrics.application.error_rate;
    
    // 判断系统状态
    if (cpuUsage >= this.options.cpuThreshold.critical ||
        memoryUsage >= this.options.memoryThreshold.critical ||
        responseTime >= this.options.responseTimeThreshold.critical ||
        errorRate >= this.options.errorRateThreshold.critical) {
      return SystemState.CRITICAL;
    } else if (cpuUsage >= this.options.cpuThreshold.overloaded ||
               memoryUsage >= this.options.memoryThreshold.overloaded ||
               responseTime >= this.options.responseTimeThreshold.overloaded ||
               errorRate >= this.options.errorRateThreshold.overloaded) {
      return SystemState.OVERLOADED;
    } else if (cpuUsage >= this.options.cpuThreshold.underLoad ||
               memoryUsage >= this.options.memoryThreshold.underLoad ||
               responseTime >= this.options.responseTimeThreshold.underLoad ||
               errorRate >= this.options.errorRateThreshold.underLoad) {
      return SystemState.UNDER_LOAD;
    } else {
      return SystemState.NORMAL;
    }
  }
  
  /**
   * 更新系统状态
   * @param {string} newState - 新的系统状态
   * @private
   */
  _updateSystemState(newState) {
    const oldState = this.systemState;
    this.systemState = newState;
    this.lastStateChange = Date.now();
    this.recoveryCounter = 0;
    
    logger.info(`系统状态变更: ${oldState} -> ${newState}`);
    this._emitEvent('state-change', { oldState, newState });
    
    // 根据新状态调整服务
    setTimeout(() => {
      this._adjustServices();
    }, this.options.degradationDelay);
  }
  
  /**
   * 调整服务
   * @private
   */
  _adjustServices() {
    // 遍历所有服务，根据系统状态和服务优先级调整
    for (const [serviceName, service] of this.services.entries()) {
      const shouldDegrade = this._shouldDegrade(service);
      
      if (shouldDegrade && !service.isDegraded) {
        // 降级服务
        service.isDegraded = true;
        this.degradedServices.add(serviceName);
        logger.info(`服务 [${serviceName}] 已自动降级（系统状态: ${this.systemState}）`);
        this._emitEvent('service-degraded', { serviceName, reason: 'system-state' });
      } else if (!shouldDegrade && service.isDegraded && 
                 this.systemState === SystemState.NORMAL) {
        // 恢复服务（只在系统状态正常时）
        service.isDegraded = false;
        this.degradedServices.delete(serviceName);
        logger.info(`服务 [${serviceName}] 已自动恢复（系统状态: ${this.systemState}）`);
        this._emitEvent('service-restored', { serviceName, reason: 'system-state' });
      }
    }
  }
  
  /**
   * 恢复所有服务
   * @private
   */
  _restoreAllServices() {
    for (const [serviceName, service] of this.services.entries()) {
      if (service.isDegraded) {
        service.isDegraded = false;
        this.degradedServices.delete(serviceName);
        logger.info(`服务 [${serviceName}] 已自动恢复（系统恢复正常）`);
        this._emitEvent('service-restored', { serviceName, reason: 'system-recovery' });
      }
    }
    
    this.recoveryCounter = 0;
  }
  
  /**
   * 发送事件
   * @param {string} eventName - 事件名称
   * @param {Object} data - 事件数据
   * @private
   */
  _emitEvent(eventName, data = {}) {
    this.emit(eventName, {
      systemState: this.systemState,
      timestamp: Date.now(),
      ...data
    });
  }
  
  /**
   * 获取系统状态
   * @returns {Object} 系统状态
   */
  getSystemState() {
    return {
      state: this.systemState,
      lastStateChange: this.lastStateChange,
      upTime: Date.now() - this.lastStateChange,
      degradedServices: Array.from(this.degradedServices),
      totalServices: this.services.size,
      recoveryCounter: this.recoveryCounter
    };
  }
  
  /**
   * 获取所有服务状态
   * @returns {Array<Object>} 服务状态数组
   */
  getAllServiceStates() {
    return Array.from(this.services.entries()).map(([name, service]) => ({
      name,
      priority: service.priority,
      isDegraded: service.isDegraded
    }));
  }
}

// 创建单例
const fallbackManager = new FallbackManager();

module.exports = {
  ServicePriority,
  SystemState,
  fallbackManager,
  FallbackManager
};
