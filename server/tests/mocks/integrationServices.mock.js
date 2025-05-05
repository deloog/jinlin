/**
 * 集成测试服务模拟
 */
const { EventEmitter } = require('events');

// 异步任务服务模拟
class AsyncTaskService extends EventEmitter {
  constructor() {
    super();
    this.initialized = false;
    this.tasks = new Map();
    this.queue = [];
    this.handlers = new Map();
    this.paused = false;
    this.processing = false;
  }
  
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    this.initialized = true;
    return true;
  }
  
  async close() {
    this.initialized = false;
    return true;
  }
  
  registerHandler(taskType, handler) {
    this.handlers.set(taskType, handler);
    return true;
  }
  
  unregisterHandler(taskType) {
    return this.handlers.delete(taskType);
  }
  
  async addTask(taskType, data, options = {}) {
    if (!this.initialized) {
      throw new Error('异步任务处理服务未初始化');
    }
    
    const taskId = options.id || `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    const task = {
      id: taskId,
      type: taskType,
      data,
      status: 'pending',
      createdAt: new Date().toISOString(),
      priority: options.priority || 1,
      attempts: 0,
      maxAttempts: options.maxAttempts || 3,
      result: null,
      error: null
    };
    
    this.tasks.set(taskId, task);
    this.queue.push(taskId);
    
    // 按优先级排序
    this.queue.sort((a, b) => {
      const taskA = this.tasks.get(a);
      const taskB = this.tasks.get(b);
      return taskB.priority - taskA.priority;
    });
    
    // 如果未暂停，则处理任务
    if (!this.paused && !this.processing) {
      this._processQueue();
    }
    
    return taskId;
  }
  
  getTask(taskId) {
    return this.tasks.get(taskId) || null;
  }
  
  getTaskResult(taskId) {
    const task = this.tasks.get(taskId);
    return task ? task.result : null;
  }
  
  async _processQueue() {
    if (this.paused || this.processing || this.queue.length === 0) {
      return;
    }
    
    this.processing = true;
    
    while (this.queue.length > 0 && !this.paused) {
      const taskId = this.queue.shift();
      const task = this.tasks.get(taskId);
      
      if (!task) {
        continue;
      }
      
      // 更新任务状态
      task.status = 'processing';
      task.attempts++;
      task.startedAt = new Date().toISOString();
      
      try {
        // 获取处理器
        const handler = this.handlers.get(task.type);
        
        if (!handler) {
          throw new Error(`未找到任务类型 ${task.type} 的处理器`);
        }
        
        // 执行处理器
        const result = await handler(task.data, task);
        
        // 更新任务状态
        task.status = 'completed';
        task.result = result;
        task.completedAt = new Date().toISOString();
        
        // 发出任务完成事件
        this.emit('task:completed', { taskId, task });
      } catch (error) {
        // 更新任务状态
        task.error = {
          message: error.message,
          stack: error.stack
        };
        
        // 检查是否需要重试
        if (task.attempts < task.maxAttempts) {
          task.status = 'pending';
          this.queue.push(taskId);
        } else {
          task.status = 'failed';
          task.failedAt = new Date().toISOString();
          
          // 发出任务失败事件
          this.emit('task:failed', { taskId, task, error });
        }
      }
    }
    
    this.processing = false;
  }
  
  pause() {
    this.paused = true;
    return true;
  }
  
  resume() {
    this.paused = false;
    
    // 恢复处理队列
    if (this.queue.length > 0 && !this.processing) {
      this._processQueue();
    }
    
    return true;
  }
  
  cancelTask(taskId) {
    const task = this.tasks.get(taskId);
    
    if (!task) {
      return false;
    }
    
    // 如果任务已完成或失败，不能取消
    if (task.status === 'completed' || task.status === 'failed') {
      return false;
    }
    
    // 从队列中移除
    const index = this.queue.indexOf(taskId);
    if (index !== -1) {
      this.queue.splice(index, 1);
    }
    
    // 更新任务状态
    task.status = 'cancelled';
    task.cancelledAt = new Date().toISOString();
    
    // 发出任务取消事件
    this.emit('task:cancelled', { taskId, task });
    
    return true;
  }
  
  clearCompletedTasks(maxAge = 24 * 60 * 60 * 1000) {
    const now = Date.now();
    let count = 0;
    
    for (const [taskId, task] of this.tasks.entries()) {
      if (task.status === 'completed' || task.status === 'failed' || task.status === 'cancelled') {
        const completedAt = new Date(task.completedAt || task.failedAt || task.cancelledAt).getTime();
        
        if (now - completedAt > maxAge) {
          this.tasks.delete(taskId);
          count++;
        }
      }
    }
    
    return count;
  }
}

// 多级缓存服务模拟
class MultiLevelCacheService extends EventEmitter {
  constructor() {
    super();
    this.initialized = false;
    this.cache = new Map();
    this.stats = {
      hits: 0,
      misses: 0,
      total: 0
    };
  }
  
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    this.initialized = true;
    return true;
  }
  
  async close() {
    this.initialized = false;
    return true;
  }
  
  async get(namespace, key) {
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    const cacheKey = `${namespace}:${key}`;
    const item = this.cache.get(cacheKey);
    
    this.stats.total++;
    
    if (item && (!item.expires || item.expires > Date.now())) {
      this.stats.hits++;
      return item.value;
    }
    
    this.stats.misses++;
    return null;
  }
  
  async set(namespace, key, value, ttl = 0) {
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    const cacheKey = `${namespace}:${key}`;
    const expires = ttl > 0 ? Date.now() + (ttl * 1000) : null;
    
    this.cache.set(cacheKey, { value, expires });
    return true;
  }
  
  async del(namespace, key) {
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    const cacheKey = `${namespace}:${key}`;
    return this.cache.delete(cacheKey);
  }
  
  async clear(namespace) {
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    if (!namespace) {
      this.cache.clear();
      return true;
    }
    
    const prefix = `${namespace}:`;
    
    for (const key of this.cache.keys()) {
      if (key.startsWith(prefix)) {
        this.cache.delete(key);
      }
    }
    
    return true;
  }
  
  getHitRate() {
    if (this.stats.total === 0) {
      return 0;
    }
    
    return this.stats.hits / this.stats.total;
  }
  
  getMissRate() {
    if (this.stats.total === 0) {
      return 0;
    }
    
    return this.stats.misses / this.stats.total;
  }
}

// 创建实例
const asyncTaskService = new AsyncTaskService();
const multiLevelCacheService = new MultiLevelCacheService();

// 导出
module.exports = {
  AsyncTaskService,
  MultiLevelCacheService,
  asyncTaskService,
  multiLevelCacheService
};
