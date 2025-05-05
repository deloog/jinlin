/**
 * 异步任务处理服务
 * 
 * 提供异步任务处理功能：
 * - 基于内存队列的异步任务处理
 * - 支持任务优先级
 * - 支持任务重试
 * - 支持任务超时
 * - 支持任务并发控制
 */
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { v4: uuidv4 } = require('uuid');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用异步任务处理
  enabled: process.env.ASYNC_TASK_ENABLED === 'true' || true,
  
  // 队列配置
  queue: {
    // 最大队列长度
    maxLength: parseInt(process.env.ASYNC_TASK_QUEUE_MAX_LENGTH || '1000', 10),
    
    // 最大并发任务数
    concurrency: parseInt(process.env.ASYNC_TASK_CONCURRENCY || '5', 10),
    
    // 任务超时（毫秒）
    timeout: parseInt(process.env.ASYNC_TASK_TIMEOUT || '30000', 10),
    
    // 任务重试配置
    retry: {
      // 最大重试次数
      maxRetries: parseInt(process.env.ASYNC_TASK_MAX_RETRIES || '3', 10),
      
      // 重试延迟（毫秒）
      delay: parseInt(process.env.ASYNC_TASK_RETRY_DELAY || '1000', 10),
      
      // 重试延迟因子
      factor: parseFloat(process.env.ASYNC_TASK_RETRY_FACTOR || '2.0')
    }
  },
  
  // 持久化配置
  persistence: {
    // 是否启用持久化
    enabled: process.env.ASYNC_TASK_PERSISTENCE_ENABLED === 'true' || false,
    
    // 持久化间隔（毫秒）
    interval: parseInt(process.env.ASYNC_TASK_PERSISTENCE_INTERVAL || '60000', 10),
    
    // 持久化文件路径
    filePath: process.env.ASYNC_TASK_PERSISTENCE_FILE_PATH || './tasks.json'
  },
  
  // 监控配置
  monitoring: {
    // 是否启用监控
    enabled: process.env.ASYNC_TASK_MONITORING_ENABLED === 'true' || true,
    
    // 监控间隔（毫秒）
    interval: parseInt(process.env.ASYNC_TASK_MONITORING_INTERVAL || '5000', 10)
  }
};

// 任务状态
const TASK_STATUS = {
  PENDING: 'pending',
  RUNNING: 'running',
  COMPLETED: 'completed',
  FAILED: 'failed',
  RETRYING: 'retrying',
  CANCELLED: 'cancelled',
  TIMEOUT: 'timeout'
};

// 任务优先级
const TASK_PRIORITY = {
  LOW: 0,
  NORMAL: 1,
  HIGH: 2,
  CRITICAL: 3
};

// 异步任务处理服务类
class AsyncTaskService extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} config - 配置
   */
  constructor(config = {}) {
    super();
    
    // 合并配置
    this.config = {
      ...DEFAULT_CONFIG,
      ...config,
      queue: {
        ...DEFAULT_CONFIG.queue,
        ...(config.queue || {}),
        retry: {
          ...DEFAULT_CONFIG.queue.retry,
          ...(config.queue?.retry || {})
        }
      },
      persistence: {
        ...DEFAULT_CONFIG.persistence,
        ...(config.persistence || {})
      },
      monitoring: {
        ...DEFAULT_CONFIG.monitoring,
        ...(config.monitoring || {})
      }
    };
    
    // 任务队列
    this.queue = [];
    
    // 任务映射
    this.tasks = new Map();
    
    // 任务处理器映射
    this.handlers = new Map();
    
    // 运行中的任务数
    this.runningTasks = 0;
    
    // 持久化定时器
    this.persistenceTimer = null;
    
    // 监控定时器
    this.monitoringTimer = null;
    
    // 初始化状态
    this.initialized = false;
    
    // 暂停状态
    this.paused = false;
    
    // 注册配置架构
    this._registerConfigSchema();
    
    logger.info('异步任务处理服务已创建');
  }
  
  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');
    
    // 注册异步任务配置架构
    configManager.registerSchema('asyncTask.enabled', Joi.boolean().default(true));
    configManager.registerSchema('asyncTask.queue.concurrency', Joi.number().min(1).default(5));
    configManager.registerSchema('asyncTask.queue.timeout', Joi.number().min(1000).default(30000));
    configManager.registerSchema('asyncTask.queue.retry.maxRetries', Joi.number().min(0).default(3));
  }
  
  /**
   * 初始化异步任务处理服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化异步任务处理服务');
      
      // 加载持久化任务
      if (this.config.persistence.enabled) {
        await this._loadPersistedTasks();
        
        // 启动持久化定时器
        this._startPersistenceTimer();
      }
      
      // 启动监控定时器
      if (this.config.monitoring.enabled) {
        this._startMonitoringTimer();
      }
      
      // 启动任务处理
      this._processQueue();
      
      this.initialized = true;
      logger.info('异步任务处理服务初始化成功');
    } catch (error) {
      logger.error('初始化异步任务处理服务失败', { error });
      throw error;
    }
  }
  
  /**
   * 加载持久化任务
   * @private
   * @returns {Promise<void>}
   */
  async _loadPersistedTasks() {
    try {
      const fs = require('fs').promises;
      const path = require('path');
      
      // 检查文件是否存在
      try {
        await fs.access(this.config.persistence.filePath);
      } catch (e) {
        // 文件不存在，创建空文件
        await fs.writeFile(this.config.persistence.filePath, JSON.stringify({ tasks: [] }));
        return;
      }
      
      // 读取文件
      const data = await fs.readFile(this.config.persistence.filePath, 'utf8');
      const { tasks } = JSON.parse(data);
      
      // 加载任务
      for (const task of tasks) {
        // 只加载未完成的任务
        if (task.status === TASK_STATUS.PENDING || task.status === TASK_STATUS.RETRYING) {
          // 重置任务状态
          task.status = TASK_STATUS.PENDING;
          task.retries = 0;
          
          // 添加到队列
          this.queue.push(task);
          this.tasks.set(task.id, task);
        }
      }
      
      logger.info(`已加载 ${this.queue.length} 个持久化任务`);
    } catch (error) {
      logger.error('加载持久化任务失败', { error });
    }
  }
  
  /**
   * 启动持久化定时器
   * @private
   */
  _startPersistenceTimer() {
    // 清除现有定时器
    if (this.persistenceTimer) {
      clearInterval(this.persistenceTimer);
    }
    
    // 设置新定时器
    this.persistenceTimer = setInterval(() => {
      this._persistTasks().catch(error => {
        logger.error('持久化任务失败', { error });
      });
    }, this.config.persistence.interval);
    
    logger.info('持久化定时器已启动');
  }
  
  /**
   * 持久化任务
   * @private
   * @returns {Promise<void>}
   */
  async _persistTasks() {
    try {
      const fs = require('fs').promises;
      
      // 获取所有任务
      const tasks = Array.from(this.tasks.values());
      
      // 写入文件
      await fs.writeFile(
        this.config.persistence.filePath,
        JSON.stringify({ tasks }, null, 2)
      );
      
      logger.debug(`已持久化 ${tasks.length} 个任务`);
    } catch (error) {
      logger.error('持久化任务失败', { error });
    }
  }
  
  /**
   * 启动监控定时器
   * @private
   */
  _startMonitoringTimer() {
    // 清除现有定时器
    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
    }
    
    // 设置新定时器
    this.monitoringTimer = setInterval(() => {
      this._monitorQueue();
    }, this.config.monitoring.interval);
    
    logger.info('监控定时器已启动');
  }
  
  /**
   * 监控队列
   * @private
   */
  _monitorQueue() {
    try {
      // 计算队列统计
      const stats = {
        queueLength: this.queue.length,
        runningTasks: this.runningTasks,
        completedTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.COMPLETED).length,
        failedTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.FAILED).length,
        pendingTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.PENDING).length,
        retryingTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.RETRYING).length,
        cancelledTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.CANCELLED).length,
        timeoutTasks: Array.from(this.tasks.values()).filter(t => t.status === TASK_STATUS.TIMEOUT).length,
        totalTasks: this.tasks.size,
        handlers: this.handlers.size
      };
      
      // 发出监控事件
      this.emit('monitor', stats);
      
      // 检查队列健康
      if (stats.queueLength >= this.config.queue.maxLength * 0.8) {
        logger.warn('队列接近最大长度', { queueLength: stats.queueLength, maxLength: this.config.queue.maxLength });
      }
      
      // 检查超时任务
      const now = Date.now();
      for (const [id, task] of this.tasks.entries()) {
        if (task.status === TASK_STATUS.RUNNING && task.startTime && (now - task.startTime > this.config.queue.timeout)) {
          // 标记任务超时
          task.status = TASK_STATUS.TIMEOUT;
          task.endTime = now;
          task.error = 'Task timed out';
          
          // 减少运行中的任务数
          this.runningTasks--;
          
          // 发出任务超时事件
          this.emit('task:timeout', { taskId: id, task });
          
          logger.warn('任务超时', { taskId: id, type: task.type, timeout: this.config.queue.timeout });
        }
      }
    } catch (error) {
      logger.error('监控队列失败', { error });
    }
  }
  
  /**
   * 处理队列
   * @private
   */
  _processQueue() {
    // 如果服务未启用或已暂停，不处理队列
    if (!this.config.enabled || this.paused) {
      return;
    }
    
    // 检查是否有可用的并发槽
    if (this.runningTasks >= this.config.queue.concurrency) {
      return;
    }
    
    // 检查队列是否为空
    if (this.queue.length === 0) {
      return;
    }
    
    // 按优先级排序队列
    this.queue.sort((a, b) => b.priority - a.priority);
    
    // 获取下一个任务
    const task = this.queue.shift();
    
    // 检查任务是否存在
    if (!task) {
      return;
    }
    
    // 检查任务处理器是否存在
    if (!this.handlers.has(task.type)) {
      logger.error('任务处理器不存在', { taskId: task.id, type: task.type });
      
      // 标记任务失败
      task.status = TASK_STATUS.FAILED;
      task.endTime = Date.now();
      task.error = `No handler registered for task type: ${task.type}`;
      
      // 发出任务失败事件
      this.emit('task:failed', { taskId: task.id, task, error: task.error });
      
      // 继续处理队列
      setImmediate(() => this._processQueue());
      
      return;
    }
    
    // 增加运行中的任务数
    this.runningTasks++;
    
    // 更新任务状态
    task.status = TASK_STATUS.RUNNING;
    task.startTime = Date.now();
    
    // 发出任务开始事件
    this.emit('task:running', { taskId: task.id, task });
    
    // 设置任务超时
    const timeoutId = setTimeout(() => {
      // 检查任务是否仍在运行
      if (task.status === TASK_STATUS.RUNNING) {
        // 标记任务超时
        task.status = TASK_STATUS.TIMEOUT;
        task.endTime = Date.now();
        task.error = 'Task timed out';
        
        // 减少运行中的任务数
        this.runningTasks--;
        
        // 发出任务超时事件
        this.emit('task:timeout', { taskId: task.id, task });
        
        logger.warn('任务超时', { taskId: task.id, type: task.type, timeout: this.config.queue.timeout });
        
        // 继续处理队列
        setImmediate(() => this._processQueue());
      }
    }, this.config.queue.timeout);
    
    // 执行任务
    Promise.resolve()
      .then(() => {
        // 获取任务处理器
        const handler = this.handlers.get(task.type);
        
        // 执行任务处理器
        return handler(task.data);
      })
      .then(result => {
        // 清除超时定时器
        clearTimeout(timeoutId);
        
        // 标记任务完成
        task.status = TASK_STATUS.COMPLETED;
        task.endTime = Date.now();
        task.result = result;
        
        // 减少运行中的任务数
        this.runningTasks--;
        
        // 发出任务完成事件
        this.emit('task:completed', { taskId: task.id, task, result });
        
        logger.debug('任务完成', { taskId: task.id, type: task.type });
      })
      .catch(error => {
        // 清除超时定时器
        clearTimeout(timeoutId);
        
        // 检查是否需要重试
        if (task.retries < this.config.queue.retry.maxRetries) {
          // 增加重试次数
          task.retries++;
          
          // 计算重试延迟
          const delay = this.config.queue.retry.delay * Math.pow(this.config.queue.retry.factor, task.retries - 1);
          
          // 更新任务状态
          task.status = TASK_STATUS.RETRYING;
          task.error = error.message || String(error);
          
          // 减少运行中的任务数
          this.runningTasks--;
          
          // 发出任务重试事件
          this.emit('task:retrying', { taskId: task.id, task, error, retries: task.retries, delay });
          
          logger.warn('任务重试', { taskId: task.id, type: task.type, retries: task.retries, delay });
          
          // 延迟重试
          setTimeout(() => {
            // 将任务重新加入队列
            this.queue.push(task);
            
            // 继续处理队列
            this._processQueue();
          }, delay);
        } else {
          // 标记任务失败
          task.status = TASK_STATUS.FAILED;
          task.endTime = Date.now();
          task.error = error.message || String(error);
          
          // 减少运行中的任务数
          this.runningTasks--;
          
          // 发出任务失败事件
          this.emit('task:failed', { taskId: task.id, task, error });
          
          logger.error('任务失败', { taskId: task.id, type: task.type, error });
        }
      })
      .finally(() => {
        // 继续处理队列
        setImmediate(() => this._processQueue());
      });
    
    // 继续处理队列（并发）
    setImmediate(() => this._processQueue());
  }
  
  /**
   * 注册任务处理器
   * @param {string} type - 任务类型
   * @param {Function} handler - 任务处理器
   * @returns {void}
   */
  registerHandler(type, handler) {
    if (typeof handler !== 'function') {
      throw new Error('任务处理器必须是函数');
    }
    
    this.handlers.set(type, handler);
    logger.info('注册任务处理器', { type });
  }
  
  /**
   * 取消注册任务处理器
   * @param {string} type - 任务类型
   * @returns {boolean} 是否成功
   */
  unregisterHandler(type) {
    const result = this.handlers.delete(type);
    
    if (result) {
      logger.info('取消注册任务处理器', { type });
    }
    
    return result;
  }
  
  /**
   * 添加任务
   * @param {string} type - 任务类型
   * @param {any} data - 任务数据
   * @param {Object} options - 任务选项
   * @returns {Promise<string>} 任务ID
   */
  async addTask(type, data, options = {}) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('异步任务处理服务未初始化');
    }
    
    // 如果服务未启用，直接执行任务
    if (!this.config.enabled) {
      // 检查任务处理器是否存在
      if (!this.handlers.has(type)) {
        throw new Error(`No handler registered for task type: ${type}`);
      }
      
      // 获取任务处理器
      const handler = this.handlers.get(type);
      
      // 执行任务处理器
      return handler(data);
    }
    
    // 检查队列是否已满
    if (this.queue.length >= this.config.queue.maxLength) {
      throw new Error('任务队列已满');
    }
    
    // 创建任务
    const task = {
      id: options.id || uuidv4(),
      type,
      data,
      priority: options.priority || TASK_PRIORITY.NORMAL,
      status: TASK_STATUS.PENDING,
      createdAt: Date.now(),
      retries: 0,
      ...options
    };
    
    // 添加到队列
    this.queue.push(task);
    
    // 添加到任务映射
    this.tasks.set(task.id, task);
    
    // 发出任务添加事件
    this.emit('task:added', { taskId: task.id, task });
    
    logger.debug('添加任务', { taskId: task.id, type });
    
    // 启动任务处理
    setImmediate(() => this._processQueue());
    
    return task.id;
  }
  
  /**
   * 取消任务
   * @param {string} taskId - 任务ID
   * @returns {boolean} 是否成功
   */
  cancelTask(taskId) {
    // 检查任务是否存在
    if (!this.tasks.has(taskId)) {
      return false;
    }
    
    // 获取任务
    const task = this.tasks.get(taskId);
    
    // 检查任务是否可取消
    if (task.status !== TASK_STATUS.PENDING && task.status !== TASK_STATUS.RETRYING) {
      return false;
    }
    
    // 从队列中移除任务
    const index = this.queue.findIndex(t => t.id === taskId);
    
    if (index !== -1) {
      this.queue.splice(index, 1);
    }
    
    // 更新任务状态
    task.status = TASK_STATUS.CANCELLED;
    task.endTime = Date.now();
    
    // 发出任务取消事件
    this.emit('task:cancelled', { taskId, task });
    
    logger.debug('取消任务', { taskId, type: task.type });
    
    return true;
  }
  
  /**
   * 获取任务
   * @param {string} taskId - 任务ID
   * @returns {Object|null} 任务
   */
  getTask(taskId) {
    return this.tasks.get(taskId) || null;
  }
  
  /**
   * 获取所有任务
   * @returns {Array<Object>} 任务列表
   */
  getAllTasks() {
    return Array.from(this.tasks.values());
  }
  
  /**
   * 获取任务状态
   * @param {string} taskId - 任务ID
   * @returns {string|null} 任务状态
   */
  getTaskStatus(taskId) {
    const task = this.tasks.get(taskId);
    return task ? task.status : null;
  }
  
  /**
   * 获取任务结果
   * @param {string} taskId - 任务ID
   * @returns {any|null} 任务结果
   */
  getTaskResult(taskId) {
    const task = this.tasks.get(taskId);
    return task && task.status === TASK_STATUS.COMPLETED ? task.result : null;
  }
  
  /**
   * 清理已完成的任务
   * @param {number} maxAge - 最大年龄（毫秒）
   * @returns {number} 清理的任务数
   */
  cleanupTasks(maxAge = 24 * 60 * 60 * 1000) {
    const now = Date.now();
    let count = 0;
    
    // 遍历所有任务
    for (const [id, task] of this.tasks.entries()) {
      // 检查任务是否已完成、失败、取消或超时
      if (
        (task.status === TASK_STATUS.COMPLETED || 
         task.status === TASK_STATUS.FAILED || 
         task.status === TASK_STATUS.CANCELLED || 
         task.status === TASK_STATUS.TIMEOUT) && 
        task.endTime && 
        (now - task.endTime > maxAge)
      ) {
        // 删除任务
        this.tasks.delete(id);
        count++;
      }
    }
    
    logger.info('清理任务', { count });
    
    return count;
  }
  
  /**
   * 暂停任务处理
   * @returns {void}
   */
  pause() {
    this.paused = true;
    logger.info('暂停任务处理');
  }
  
  /**
   * 恢复任务处理
   * @returns {void}
   */
  resume() {
    this.paused = false;
    logger.info('恢复任务处理');
    
    // 启动任务处理
    setImmediate(() => this._processQueue());
  }
  
  /**
   * 关闭异步任务处理服务
   * @returns {Promise<void>}
   */
  async close() {
    try {
      logger.info('关闭异步任务处理服务');
      
      // 暂停任务处理
      this.pause();
      
      // 清除持久化定时器
      if (this.persistenceTimer) {
        clearInterval(this.persistenceTimer);
        this.persistenceTimer = null;
      }
      
      // 清除监控定时器
      if (this.monitoringTimer) {
        clearInterval(this.monitoringTimer);
        this.monitoringTimer = null;
      }
      
      // 持久化任务
      if (this.config.persistence.enabled) {
        await this._persistTasks();
      }
      
      // 重置状态
      this.initialized = false;
      
      logger.info('异步任务处理服务已关闭');
    } catch (error) {
      logger.error('关闭异步任务处理服务失败', { error });
      throw error;
    }
  }
}

// 创建单例
const asyncTaskService = new AsyncTaskService();

// 导出
module.exports = {
  asyncTaskService,
  AsyncTaskService,
  TASK_STATUS,
  TASK_PRIORITY
};
