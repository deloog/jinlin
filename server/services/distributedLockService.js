/**
 * 分布式锁服务
 * 
 * 实现基于Redis的分布式锁，支持：
 * - Redlock算法（多Redis实例支持）
 * - 锁获取重试机制
 * - 锁自动续期
 * - 锁超时自动释放
 * - 优雅降级到内存锁
 */
const Redis = require('ioredis');
const { promisify } = require('util');
const crypto = require('crypto');
const logger = require('../utils/logger');
const { EventEmitter } = require('events');

// 默认配置
const DEFAULT_CONFIG = {
  // Redis配置
  redis: {
    instances: [
      {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD || '',
        db: process.env.REDIS_DB || 0
      }
    ],
    keyPrefix: 'lock:',
    connectionTimeout: 1000 // 连接超时（毫秒）
  },
  
  // 锁配置
  lock: {
    retryCount: 3, // 重试次数
    retryDelay: 200, // 重试延迟（毫秒）
    retryJitter: 100, // 重试抖动（毫秒）
    lockTimeout: 10000, // 锁超时（毫秒）
    autoRenewal: true, // 自动续期
    renewalInterval: 5000, // 续期间隔（毫秒）
    driftFactor: 0.01, // 漂移因子（用于计算锁有效期）
    quorum: 1, // 法定人数（需要成功获取锁的Redis实例数量）
    retryOnFailure: true, // 在Redis失败时重试
    fallbackToMemory: true // 在Redis全部失败时降级到内存锁
  }
};

// 内存锁存储
const memoryLocks = new Map();

// 锁续期定时器
const renewalTimers = new Map();

/**
 * 分布式锁管理器
 */
class DistributedLockManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} config - 配置
   */
  constructor(config = {}) {
    super();
    
    // 合并配置
    this.config = {
      redis: { ...DEFAULT_CONFIG.redis, ...config.redis },
      lock: { ...DEFAULT_CONFIG.lock, ...config.lock }
    };
    
    // 设置法定人数
    if (!config.lock || !config.lock.quorum) {
      this.config.lock.quorum = Math.floor(this.config.redis.instances.length / 2) + 1;
    }
    
    // Redis客户端
    this.redisClients = [];
    
    // 初始化Redis客户端
    this._initRedisClients();
    
    logger.info('分布式锁管理器已初始化');
  }
  
  /**
   * 初始化Redis客户端
   * @private
   */
  _initRedisClients() {
    // 清理现有客户端
    this.redisClients.forEach(client => {
      if (client && client.disconnect) {
        client.disconnect();
      }
    });
    
    this.redisClients = [];
    
    // 创建新客户端
    for (const instance of this.config.redis.instances) {
      try {
        const client = new Redis({
          host: instance.host,
          port: instance.port,
          password: instance.password,
          db: instance.db,
          connectionTimeout: this.config.redis.connectionTimeout,
          retryStrategy: (times) => {
            const delay = Math.min(times * 50, 2000);
            return delay;
          }
        });
        
        // 监听事件
        client.on('error', (error) => {
          logger.error(`Redis客户端错误 (${instance.host}:${instance.port}):`, error);
          this.emit('redis-error', { instance, error });
        });
        
        client.on('connect', () => {
          logger.info(`Redis客户端已连接 (${instance.host}:${instance.port})`);
          this.emit('redis-connect', { instance });
        });
        
        this.redisClients.push(client);
      } catch (error) {
        logger.error(`初始化Redis客户端失败 (${instance.host}:${instance.port}):`, error);
        this.emit('redis-init-error', { instance, error });
      }
    }
    
    logger.info(`已初始化 ${this.redisClients.length} 个Redis客户端`);
  }
  
  /**
   * 生成锁值
   * @returns {string} 锁值
   * @private
   */
  _generateLockValue() {
    return crypto.randomBytes(16).toString('hex');
  }
  
  /**
   * 获取锁
   * @param {string} resource - 资源名称
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 锁对象
   */
  async acquireLock(resource, options = {}) {
    const lockOptions = { ...this.config.lock, ...options };
    const lockValue = this._generateLockValue();
    const lockKey = `${this.config.redis.keyPrefix}${resource}`;
    
    // 锁对象
    const lock = {
      resource,
      value: lockValue,
      validityTime: lockOptions.lockTimeout,
      acquired: false,
      usingMemoryLock: false,
      instances: []
    };
    
    // 如果没有Redis客户端，直接使用内存锁
    if (this.redisClients.length === 0) {
      if (lockOptions.fallbackToMemory) {
        return this._acquireMemoryLock(resource, lockValue, lockOptions);
      } else {
        throw new Error('没有可用的Redis客户端');
      }
    }
    
    // 尝试获取锁
    let retries = 0;
    let success = false;
    
    while (!success && retries <= lockOptions.retryCount) {
      try {
        // 尝试在所有Redis实例上获取锁
        const startTime = Date.now();
        
        // 并行获取锁
        const results = await Promise.all(
          this.redisClients.map(async (client, index) => {
            try {
              const result = await client.set(
                lockKey,
                lockValue,
                'PX',
                lockOptions.lockTimeout,
                'NX'
              );
              
              return { 
                success: result === 'OK', 
                error: null, 
                instance: index 
              };
            } catch (error) {
              logger.error(`在Redis实例 ${index} 上获取锁失败:`, error);
              return { 
                success: false, 
                error, 
                instance: index 
              };
            }
          })
        );
        
        // 计算成功获取锁的实例数量
        const successCount = results.filter(r => r.success).length;
        
        // 计算漂移时间
        const drift = Math.floor(lockOptions.lockTimeout * lockOptions.driftFactor) + 2;
        
        // 计算有效期
        const validityTime = lockOptions.lockTimeout - (Date.now() - startTime) - drift;
        
        // 检查是否满足法定人数
        if (successCount >= lockOptions.quorum && validityTime > 0) {
          lock.acquired = true;
          lock.validityTime = validityTime;
          lock.instances = results.filter(r => r.success).map(r => r.instance);
          
          // 设置自动续期
          if (lockOptions.autoRenewal) {
            this._setupAutoRenewal(lock, lockKey, lockOptions);
          }
          
          this.emit('lock-acquired', { 
            resource, 
            value: lockValue, 
            validityTime,
            instances: lock.instances
          });
          
          success = true;
          break;
        } else {
          // 释放已获取的锁
          await this._unlockInstances(lockKey, lockValue, results.filter(r => r.success).map(r => r.instance));
          
          // 如果有效期小于等于0，不再重试
          if (validityTime <= 0) {
            throw new Error('锁获取超时');
          }
        }
      } catch (error) {
        logger.error(`获取锁失败 (${resource}):`, error);
      }
      
      // 如果需要重试
      if (!success && retries < lockOptions.retryCount) {
        retries++;
        
        // 计算重试延迟
        const delay = lockOptions.retryDelay + Math.floor(Math.random() * lockOptions.retryJitter);
        
        // 等待重试
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    // 如果所有Redis实例都失败，尝试使用内存锁
    if (!success && lockOptions.fallbackToMemory) {
      logger.warn(`所有Redis实例获取锁失败，降级到内存锁 (${resource})`);
      return this._acquireMemoryLock(resource, lockValue, lockOptions);
    }
    
    return lock;
  }
  
  /**
   * 获取内存锁
   * @param {string} resource - 资源名称
   * @param {string} value - 锁值
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 锁对象
   * @private
   */
  async _acquireMemoryLock(resource, value, options) {
    const lockKey = `${this.config.redis.keyPrefix}${resource}`;
    
    // 检查锁是否已存在
    if (memoryLocks.has(lockKey)) {
      const existingLock = memoryLocks.get(lockKey);
      
      // 检查锁是否已过期
      if (existingLock.expireAt > Date.now()) {
        // 锁未过期，获取失败
        return {
          resource,
          value,
          validityTime: 0,
          acquired: false,
          usingMemoryLock: true,
          instances: []
        };
      }
      
      // 锁已过期，删除
      memoryLocks.delete(lockKey);
    }
    
    // 创建新锁
    const expireAt = Date.now() + options.lockTimeout;
    
    memoryLocks.set(lockKey, {
      value,
      expireAt
    });
    
    // 设置自动过期
    setTimeout(() => {
      const lock = memoryLocks.get(lockKey);
      if (lock && lock.value === value) {
        memoryLocks.delete(lockKey);
      }
    }, options.lockTimeout);
    
    logger.debug(`已获取内存锁 (${resource})`);
    
    return {
      resource,
      value,
      validityTime: options.lockTimeout,
      acquired: true,
      usingMemoryLock: true,
      instances: []
    };
  }
  
  /**
   * 设置自动续期
   * @param {Object} lock - 锁对象
   * @param {string} lockKey - 锁键
   * @param {Object} options - 选项
   * @private
   */
  _setupAutoRenewal(lock, lockKey, options) {
    // 清理现有定时器
    if (renewalTimers.has(lockKey)) {
      clearInterval(renewalTimers.get(lockKey));
      renewalTimers.delete(lockKey);
    }
    
    // 设置新定时器
    const timer = setInterval(async () => {
      try {
        // 续期锁
        const results = await Promise.all(
          lock.instances.map(async (instance) => {
            try {
              const client = this.redisClients[instance];
              if (!client) return { success: false, instance };
              
              // 使用PEXPIRE续期
              const result = await client.eval(
                `if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('pexpire', KEYS[1], ARGV[2]) else return 0 end`,
                1,
                lockKey,
                lock.value,
                options.lockTimeout
              );
              
              return { 
                success: result === 1, 
                instance 
              };
            } catch (error) {
              logger.error(`续期锁失败 (${lock.resource}, 实例 ${instance}):`, error);
              return { 
                success: false, 
                instance 
              };
            }
          })
        );
        
        // 计算成功续期的实例数量
        const successCount = results.filter(r => r.success).length;
        
        // 检查是否满足法定人数
        if (successCount < options.quorum) {
          logger.warn(`锁续期失败，未满足法定人数 (${lock.resource})`);
          
          // 清理定时器
          clearInterval(timer);
          renewalTimers.delete(lockKey);
          
          this.emit('lock-renewal-failed', { 
            resource: lock.resource, 
            value: lock.value
          });
        } else {
          this.emit('lock-renewed', { 
            resource: lock.resource, 
            value: lock.value,
            instances: results.filter(r => r.success).map(r => r.instance)
          });
        }
      } catch (error) {
        logger.error(`锁续期失败 (${lock.resource}):`, error);
      }
    }, options.renewalInterval);
    
    // 存储定时器
    renewalTimers.set(lockKey, timer);
  }
  
  /**
   * 释放锁
   * @param {Object} lock - 锁对象
   * @returns {Promise<boolean>} 是否成功
   */
  async releaseLock(lock) {
    if (!lock || !lock.acquired) {
      return false;
    }
    
    const lockKey = `${this.config.redis.keyPrefix}${lock.resource}`;
    
    // 清理续期定时器
    if (renewalTimers.has(lockKey)) {
      clearInterval(renewalTimers.get(lockKey));
      renewalTimers.delete(lockKey);
    }
    
    // 如果是内存锁
    if (lock.usingMemoryLock) {
      return this._releaseMemoryLock(lock.resource, lock.value);
    }
    
    // 释放Redis锁
    try {
      await this._unlockInstances(lockKey, lock.value, lock.instances);
      
      this.emit('lock-released', { 
        resource: lock.resource, 
        value: lock.value,
        instances: lock.instances
      });
      
      return true;
    } catch (error) {
      logger.error(`释放锁失败 (${lock.resource}):`, error);
      return false;
    }
  }
  
  /**
   * 释放内存锁
   * @param {string} resource - 资源名称
   * @param {string} value - 锁值
   * @returns {Promise<boolean>} 是否成功
   * @private
   */
  async _releaseMemoryLock(resource, value) {
    const lockKey = `${this.config.redis.keyPrefix}${resource}`;
    
    // 检查锁是否存在
    if (!memoryLocks.has(lockKey)) {
      return false;
    }
    
    // 检查锁值是否匹配
    const lock = memoryLocks.get(lockKey);
    if (lock.value !== value) {
      return false;
    }
    
    // 删除锁
    memoryLocks.delete(lockKey);
    
    logger.debug(`已释放内存锁 (${resource})`);
    
    return true;
  }
  
  /**
   * 在指定实例上释放锁
   * @param {string} lockKey - 锁键
   * @param {string} lockValue - 锁值
   * @param {Array<number>} instances - 实例索引数组
   * @returns {Promise<void>}
   * @private
   */
  async _unlockInstances(lockKey, lockValue, instances) {
    await Promise.all(
      instances.map(async (instance) => {
        try {
          const client = this.redisClients[instance];
          if (!client) return;
          
          // 使用Lua脚本确保只删除自己的锁
          await client.eval(
            `if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end`,
            1,
            lockKey,
            lockValue
          );
        } catch (error) {
          logger.error(`在Redis实例 ${instance} 上释放锁失败:`, error);
        }
      })
    );
  }
  
  /**
   * 关闭管理器
   */
  close() {
    // 清理所有续期定时器
    for (const timer of renewalTimers.values()) {
      clearInterval(timer);
    }
    renewalTimers.clear();
    
    // 关闭所有Redis客户端
    for (const client of this.redisClients) {
      if (client && client.disconnect) {
        client.disconnect();
      }
    }
    
    this.redisClients = [];
    
    logger.info('分布式锁管理器已关闭');
  }
}

// 创建单例
const lockManager = new DistributedLockManager();

module.exports = {
  lockManager,
  DistributedLockManager
};
