/**
 * 熔断器服务
 * 
 * 实现熔断器模式，防止级联故障，提高系统稳定性
 * 熔断器有三种状态：
 * - 关闭（CLOSED）：正常状态，请求正常通过
 * - 开启（OPEN）：故障状态，请求直接失败，不会调用实际服务
 * - 半开（HALF_OPEN）：恢复状态，允许部分请求通过，测试服务是否恢复
 */
const logger = require('../utils/logger');
const { EventEmitter } = require('events');

// 熔断器状态
const CircuitState = {
  CLOSED: 'CLOSED',   // 关闭状态（正常）
  OPEN: 'OPEN',       // 开启状态（故障）
  HALF_OPEN: 'HALF_OPEN' // 半开状态（恢复中）
};

// 默认配置
const DEFAULT_OPTIONS = {
  failureThreshold: 5,     // 故障阈值，连续失败多少次后打开熔断器
  resetTimeout: 30000,     // 重置超时，熔断器打开后多久进入半开状态（毫秒）
  halfOpenSuccessThreshold: 2, // 半开状态下，连续成功多少次后关闭熔断器
  monitorInterval: 10000,  // 监控间隔，多久检查一次熔断器状态（毫秒）
  timeout: 10000,          // 操作超时时间（毫秒）
  volumeThreshold: 10,     // 请求量阈值，至少处理多少请求后才开始计算错误率
  errorThresholdPercentage: 50 // 错误率阈值，错误率超过多少后打开熔断器
};

/**
 * 熔断器类
 */
class CircuitBreaker extends EventEmitter {
  /**
   * 构造函数
   * @param {string} name - 熔断器名称
   * @param {Function} action - 要保护的操作函数
   * @param {Object} options - 配置选项
   */
  constructor(name, action, options = {}) {
    super();
    this.name = name;
    this.action = action;
    this.options = { ...DEFAULT_OPTIONS, ...options };
    
    // 熔断器状态
    this.state = CircuitState.CLOSED;
    
    // 统计数据
    this.stats = {
      successes: 0,
      failures: 0,
      rejects: 0,
      lastFailure: null,
      lastSuccess: null,
      consecutiveFailures: 0,
      consecutiveSuccesses: 0,
      totalRequests: 0
    };
    
    // 上次状态变更时间
    this.lastStateChange = Date.now();
    
    // 启动监控
    this._startMonitoring();
    
    logger.info(`熔断器 [${this.name}] 已创建，初始状态: ${this.state}`);
  }
  
  /**
   * 执行受保护的操作
   * @param {...any} args - 传递给操作函数的参数
   * @returns {Promise<any>} 操作结果
   */
  async execute(...args) {
    this.stats.totalRequests++;
    
    // 检查熔断器状态
    if (this.state === CircuitState.OPEN) {
      // 熔断器开启，直接拒绝请求
      this.stats.rejects++;
      this._emitEvent('reject', { reason: 'Circuit is OPEN' });
      throw new Error(`熔断器 [${this.name}] 开启，请求被拒绝`);
    }
    
    if (this.state === CircuitState.HALF_OPEN && 
        this.stats.consecutiveSuccesses >= this.options.halfOpenSuccessThreshold) {
      // 半开状态下连续成功次数达到阈值，关闭熔断器
      this._close();
    }
    
    try {
      // 设置超时
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error(`操作超时（${this.options.timeout}ms）`)), this.options.timeout);
      });
      
      // 执行操作
      const result = await Promise.race([
        this.action(...args),
        timeoutPromise
      ]);
      
      // 操作成功
      this._onSuccess();
      return result;
    } catch (error) {
      // 操作失败
      this._onFailure(error);
      throw error;
    }
  }
  
  /**
   * 处理操作成功
   * @private
   */
  _onSuccess() {
    this.stats.successes++;
    this.stats.lastSuccess = Date.now();
    this.stats.consecutiveSuccesses++;
    this.stats.consecutiveFailures = 0;
    
    this._emitEvent('success');
    
    // 如果是半开状态，检查是否需要关闭熔断器
    if (this.state === CircuitState.HALF_OPEN && 
        this.stats.consecutiveSuccesses >= this.options.halfOpenSuccessThreshold) {
      this._close();
    }
  }
  
  /**
   * 处理操作失败
   * @param {Error} error - 错误对象
   * @private
   */
  _onFailure(error) {
    this.stats.failures++;
    this.stats.lastFailure = Date.now();
    this.stats.consecutiveFailures++;
    this.stats.consecutiveSuccesses = 0;
    
    this._emitEvent('failure', { error });
    
    // 检查是否需要打开熔断器
    if (this.state === CircuitState.CLOSED && 
        this.stats.consecutiveFailures >= this.options.failureThreshold) {
      this._open();
    } else if (this.state === CircuitState.HALF_OPEN) {
      // 半开状态下任何失败都会重新打开熔断器
      this._open();
    }
  }
  
  /**
   * 打开熔断器
   * @private
   */
  _open() {
    if (this.state !== CircuitState.OPEN) {
      logger.warn(`熔断器 [${this.name}] 状态变更: ${this.state} -> ${CircuitState.OPEN}`);
      this.state = CircuitState.OPEN;
      this.lastStateChange = Date.now();
      
      // 设置定时器，在resetTimeout后进入半开状态
      this.resetTimer = setTimeout(() => {
        this._halfOpen();
      }, this.options.resetTimeout);
      
      this._emitEvent('open');
    }
  }
  
  /**
   * 半开熔断器
   * @private
   */
  _halfOpen() {
    if (this.state === CircuitState.OPEN) {
      logger.info(`熔断器 [${this.name}] 状态变更: ${this.state} -> ${CircuitState.HALF_OPEN}`);
      this.state = CircuitState.HALF_OPEN;
      this.lastStateChange = Date.now();
      this.stats.consecutiveSuccesses = 0;
      this.stats.consecutiveFailures = 0;
      
      this._emitEvent('half-open');
    }
  }
  
  /**
   * 关闭熔断器
   * @private
   */
  _close() {
    if (this.state !== CircuitState.CLOSED) {
      logger.info(`熔断器 [${this.name}] 状态变更: ${this.state} -> ${CircuitState.CLOSED}`);
      this.state = CircuitState.CLOSED;
      this.lastStateChange = Date.now();
      this.stats.consecutiveSuccesses = 0;
      this.stats.consecutiveFailures = 0;
      
      this._emitEvent('close');
    }
  }
  
  /**
   * 发送事件
   * @param {string} eventName - 事件名称
   * @param {Object} data - 事件数据
   * @private
   */
  _emitEvent(eventName, data = {}) {
    this.emit(eventName, {
      name: this.name,
      state: this.state,
      stats: { ...this.stats },
      timestamp: Date.now(),
      ...data
    });
  }
  
  /**
   * 启动监控
   * @private
   */
  _startMonitoring() {
    this.monitorInterval = setInterval(() => {
      // 计算错误率
      const totalCalls = this.stats.successes + this.stats.failures;
      const errorRate = totalCalls > 0 ? (this.stats.failures / totalCalls) * 100 : 0;
      
      // 发送状态事件
      this._emitEvent('status', {
        errorRate,
        upTime: Date.now() - this.lastStateChange
      });
      
      // 如果请求量达到阈值且错误率超过阈值，打开熔断器
      if (this.state === CircuitState.CLOSED && 
          totalCalls >= this.options.volumeThreshold && 
          errorRate >= this.options.errorThresholdPercentage) {
        logger.warn(`熔断器 [${this.name}] 错误率 ${errorRate.toFixed(2)}% 超过阈值 ${this.options.errorThresholdPercentage}%`);
        this._open();
      }
    }, this.options.monitorInterval);
  }
  
  /**
   * 重置熔断器
   */
  reset() {
    logger.info(`熔断器 [${this.name}] 重置`);
    this.state = CircuitState.CLOSED;
    this.lastStateChange = Date.now();
    this.stats = {
      successes: 0,
      failures: 0,
      rejects: 0,
      lastFailure: null,
      lastSuccess: null,
      consecutiveFailures: 0,
      consecutiveSuccesses: 0,
      totalRequests: 0
    };
    
    if (this.resetTimer) {
      clearTimeout(this.resetTimer);
      this.resetTimer = null;
    }
    
    this._emitEvent('reset');
  }
  
  /**
   * 获取熔断器状态
   * @returns {Object} 熔断器状态
   */
  getState() {
    return {
      name: this.name,
      state: this.state,
      stats: { ...this.stats },
      lastStateChange: this.lastStateChange,
      upTime: Date.now() - this.lastStateChange
    };
  }
}

// 熔断器注册表
const circuitBreakers = new Map();

/**
 * 创建熔断器
 * @param {string} name - 熔断器名称
 * @param {Function} action - 要保护的操作函数
 * @param {Object} options - 配置选项
 * @returns {CircuitBreaker} 熔断器实例
 */
function createCircuitBreaker(name, action, options = {}) {
  if (circuitBreakers.has(name)) {
    return circuitBreakers.get(name);
  }
  
  const circuitBreaker = new CircuitBreaker(name, action, options);
  circuitBreakers.set(name, circuitBreaker);
  
  return circuitBreaker;
}

/**
 * 获取熔断器
 * @param {string} name - 熔断器名称
 * @returns {CircuitBreaker|null} 熔断器实例，如果不存在则返回null
 */
function getCircuitBreaker(name) {
  return circuitBreakers.get(name) || null;
}

/**
 * 获取所有熔断器
 * @returns {Array<CircuitBreaker>} 熔断器实例数组
 */
function getAllCircuitBreakers() {
  return Array.from(circuitBreakers.values());
}

/**
 * 获取所有熔断器状态
 * @returns {Array<Object>} 熔断器状态数组
 */
function getAllCircuitBreakerStates() {
  return Array.from(circuitBreakers.values()).map(cb => cb.getState());
}

module.exports = {
  CircuitState,
  CircuitBreaker,
  createCircuitBreaker,
  getCircuitBreaker,
  getAllCircuitBreakers,
  getAllCircuitBreakerStates
};
