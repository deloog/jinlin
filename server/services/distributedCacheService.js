/**
 * 分布式缓存服务
 * 
 * 实现分布式缓存和缓存穿透保护，提高系统性能和稳定性
 * 支持多种缓存策略：
 * - 本地内存缓存：快速但不共享
 * - Redis缓存：分布式共享缓存
 * - 多级缓存：结合本地缓存和Redis缓存
 * 
 * 防护措施：
 * - 缓存穿透保护：使用布隆过滤器或空值缓存
 * - 缓存击穿保护：使用互斥锁或热点数据永不过期
 * - 缓存雪崩保护：使用随机过期时间
 */
const logger = require('../utils/logger');
const cacheService = require('./cacheService');
const { promisify } = require('util');
const crypto = require('crypto');
const { EventEmitter } = require('events');
const Redis = require('ioredis');

// 缓存类型
const CacheType = {
  MEMORY: 'MEMORY',     // 内存缓存
  REDIS: 'REDIS',       // Redis缓存
  MULTI_LEVEL: 'MULTI_LEVEL' // 多级缓存
};

// 默认配置
const DEFAULT_OPTIONS = {
  cacheType: CacheType.MULTI_LEVEL, // 默认使用多级缓存
  redisOptions: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    db: process.env.REDIS_DB || 0,
    keyPrefix: 'cache:',
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    }
  },
  defaultTTL: 3600,     // 默认缓存过期时间（秒）
  nullValueTTL: 60,     // 空值缓存过期时间（秒）
  bloomFilterSize: 10000, // 布隆过滤器大小
  bloomFilterErrorRate: 0.01, // 布隆过滤器错误率
  lockTimeout: 5000,    // 互斥锁超时时间（毫秒）
  lockRetryDelay: 100,  // 互斥锁重试延迟（毫秒）
  lockRetryTimes: 10,   // 互斥锁重试次数
  randomizeTTL: true,   // 是否使用随机过期时间
  randomizeTTLFactor: 0.2, // 随机过期时间因子
  enableCompression: false, // 是否启用压缩
  compressionThreshold: 1024, // 压缩阈值（字节）
  enableBloomFilter: true, // 是否启用布隆过滤器
  enableNullCache: true, // 是否启用空值缓存
  statsInterval: 60000, // 统计信息收集间隔（毫秒）
  maxMemorySize: 100 * 1024 * 1024, // 最大内存缓存大小（字节）
  maxMemoryPolicy: 'lru', // 内存淘汰策略
  maxKeys: 10000,       // 最大缓存键数
};

/**
 * 分布式缓存管理器
 */
class DistributedCacheManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} options - 配置选项
   */
  constructor(options = {}) {
    super();
    this.options = { ...DEFAULT_OPTIONS, ...options };
    
    // 统计信息
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      errors: 0,
      lockTimeouts: 0,
      bloomFilterRejections: 0,
      compressions: 0,
      nullCacheHits: 0,
      memoryUsage: 0,
      keyCount: 0
    };
    
    // 锁映射
    this.locks = new Map();
    
    // 初始化缓存
    this._initializeCache();
    
    // 启动统计信息收集
    this._startStatsCollection();
    
    logger.info(`分布式缓存管理器已创建，类型: ${this.options.cacheType}`);
  }
  
  /**
   * 初始化缓存
   * @private
   */
  _initializeCache() {
    // 初始化内存缓存
    this.memoryCache = cacheService;
    
    // 初始化Redis缓存（如果需要）
    if (this.options.cacheType === CacheType.REDIS || 
        this.options.cacheType === CacheType.MULTI_LEVEL) {
      try {
        this.redisClient = new Redis(this.options.redisOptions);
        
        // 监听Redis事件
        this.redisClient.on('connect', () => {
          logger.info('Redis连接成功');
        });
        
        this.redisClient.on('error', (error) => {
          logger.error('Redis错误:', error);
          this.stats.errors++;
        });
        
        this.redisClient.on('close', () => {
          logger.warn('Redis连接关闭');
        });
        
        // 将Redis命令转换为Promise
        this.redisGet = promisify(this.redisClient.get).bind(this.redisClient);
        this.redisSet = promisify(this.redisClient.set).bind(this.redisClient);
        this.redisDel = promisify(this.redisClient.del).bind(this.redisClient);
        this.redisExists = promisify(this.redisClient.exists).bind(this.redisClient);
        this.redisExpire = promisify(this.redisClient.expire).bind(this.redisClient);
        this.redisSetNX = promisify(this.redisClient.setnx).bind(this.redisClient);
        this.redisPExpire = promisify(this.redisClient.pexpire).bind(this.redisClient);
      } catch (error) {
        logger.error('初始化Redis缓存失败:', error);
        this.stats.errors++;
        
        // 如果Redis初始化失败，降级为内存缓存
        if (this.options.cacheType === CacheType.REDIS) {
          logger.warn('Redis初始化失败，降级为内存缓存');
          this.options.cacheType = CacheType.MEMORY;
        }
      }
    }
    
    // 初始化布隆过滤器（如果启用）
    if (this.options.enableBloomFilter) {
      try {
        // 这里使用简单的布隆过滤器实现
        // 在实际生产环境中，应该使用更高效的布隆过滤器库
        this.bloomFilter = new Set();
      } catch (error) {
        logger.error('初始化布隆过滤器失败:', error);
        this.stats.errors++;
        this.options.enableBloomFilter = false;
      }
    }
  }
  
  /**
   * 启动统计信息收集
   * @private
   */
  _startStatsCollection() {
    this.statsInterval = setInterval(() => {
      // 收集内存使用情况
      if (this.options.cacheType === CacheType.MEMORY || 
          this.options.cacheType === CacheType.MULTI_LEVEL) {
        const memoryStats = this.memoryCache.getStats();
        this.stats.memoryUsage = memoryStats.size;
        this.stats.keyCount = memoryStats.keys;
      }
      
      // 发送统计事件
      this._emitEvent('stats', { stats: { ...this.stats } });
      
      // 检查内存使用情况，如果超过限制，清理部分缓存
      if (this.stats.memoryUsage > this.options.maxMemorySize) {
        this._cleanupMemoryCache();
      }
    }, this.options.statsInterval);
  }
  
  /**
   * 清理内存缓存
   * @private
   */
  _cleanupMemoryCache() {
    logger.warn(`内存缓存超过限制 (${this.stats.memoryUsage} > ${this.options.maxMemorySize})，开始清理`);
    
    // 根据淘汰策略清理缓存
    // 这里简单实现，实际应该根据策略进行更复杂的清理
    this.memoryCache.clearAll();
    
    logger.info('内存缓存清理完成');
  }
  
  /**
   * 生成缓存键
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @returns {string} 缓存键
   * @private
   */
  _generateCacheKey(namespace, key) {
    return `${namespace}:${key}`;
  }
  
  /**
   * 计算随机过期时间
   * @param {number} ttl - 过期时间（秒）
   * @returns {number} 随机过期时间（秒）
   * @private
   */
  _randomizeTTL(ttl) {
    if (!this.options.randomizeTTL) {
      return ttl;
    }
    
    const factor = this.options.randomizeTTLFactor;
    const min = Math.floor(ttl * (1 - factor));
    const max = Math.ceil(ttl * (1 + factor));
    
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }
  
  /**
   * 压缩数据
   * @param {*} data - 要压缩的数据
   * @returns {Buffer} 压缩后的数据
   * @private
   */
  _compressData(data) {
    // 这里简单实现，实际应该使用更高效的压缩算法
    const jsonData = JSON.stringify(data);
    
    // 如果数据小于阈值，不压缩
    if (!this.options.enableCompression || 
        jsonData.length < this.options.compressionThreshold) {
      return jsonData;
    }
    
    try {
      const compressed = require('zlib').deflateSync(jsonData);
      this.stats.compressions++;
      return compressed;
    } catch (error) {
      logger.error('压缩数据失败:', error);
      this.stats.errors++;
      return jsonData;
    }
  }
  
  /**
   * 解压数据
   * @param {Buffer|string} data - 要解压的数据
   * @returns {*} 解压后的数据
   * @private
   */
  _decompressData(data) {
    if (!this.options.enableCompression || typeof data === 'string') {
      return JSON.parse(data);
    }
    
    try {
      const decompressed = require('zlib').inflateSync(data).toString();
      return JSON.parse(decompressed);
    } catch (error) {
      logger.error('解压数据失败:', error);
      this.stats.errors++;
      
      // 尝试直接解析
      try {
        return JSON.parse(data);
      } catch (e) {
        throw new Error('无法解析缓存数据');
      }
    }
  }
  
  /**
   * 获取分布式锁
   * @param {string} lockKey - 锁键
   * @param {number} timeout - 超时时间（毫秒）
   * @returns {Promise<boolean>} 是否获取成功
   * @private
   */
  async _acquireLock(lockKey, timeout = this.options.lockTimeout) {
    const lockValue = Date.now().toString();
    let acquired = false;
    
    // 如果使用Redis，使用Redis实现分布式锁
    if (this.redisClient) {
      try {
        acquired = await this.redisSetNX(`lock:${lockKey}`, lockValue);
        
        if (acquired) {
          // 设置锁过期时间，防止死锁
          await this.redisPExpire(`lock:${lockKey}`, timeout);
          this.locks.set(lockKey, lockValue);
        }
      } catch (error) {
        logger.error('获取Redis锁失败:', error);
        this.stats.errors++;
        acquired = false;
      }
    } else {
      // 否则使用内存锁
      if (!this.locks.has(lockKey)) {
        this.locks.set(lockKey, lockValue);
        acquired = true;
        
        // 设置锁过期时间
        setTimeout(() => {
          if (this.locks.get(lockKey) === lockValue) {
            this.locks.delete(lockKey);
          }
        }, timeout);
      }
    }
    
    return acquired;
  }
  
  /**
   * 释放分布式锁
   * @param {string} lockKey - 锁键
   * @returns {Promise<boolean>} 是否释放成功
   * @private
   */
  async _releaseLock(lockKey) {
    const lockValue = this.locks.get(lockKey);
    
    if (!lockValue) {
      return false;
    }
    
    // 如果使用Redis，使用Redis释放锁
    if (this.redisClient) {
      try {
        // 确保只释放自己的锁
        const currentValue = await this.redisGet(`lock:${lockKey}`);
        
        if (currentValue === lockValue) {
          await this.redisDel(`lock:${lockKey}`);
          this.locks.delete(lockKey);
          return true;
        }
      } catch (error) {
        logger.error('释放Redis锁失败:', error);
        this.stats.errors++;
        return false;
      }
    } else {
      // 否则释放内存锁
      if (this.locks.get(lockKey) === lockValue) {
        this.locks.delete(lockKey);
        return true;
      }
    }
    
    return false;
  }
  
  /**
   * 设置缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @param {*} value - 值
   * @param {number} ttl - 过期时间（秒），默认使用配置中的默认值
   * @returns {Promise<boolean>} 是否成功
   */
  async set(namespace, key, value, ttl = this.options.defaultTTL) {
    try {
      const cacheKey = this._generateCacheKey(namespace, key);
      
      // 如果启用布隆过滤器，将键添加到布隆过滤器
      if (this.options.enableBloomFilter) {
        this.bloomFilter.add(cacheKey);
      }
      
      // 计算随机过期时间
      const finalTTL = this._randomizeTTL(ttl);
      
      // 压缩数据
      const data = this._compressData(value);
      
      // 根据缓存类型存储数据
      if (this.options.cacheType === CacheType.MEMORY) {
        // 存储到内存缓存
        this.memoryCache.set(namespace, key, data, finalTTL);
      } else if (this.options.cacheType === CacheType.REDIS) {
        // 存储到Redis缓存
        if (this.redisClient) {
          await this.redisSet(cacheKey, data, 'EX', finalTTL);
        } else {
          throw new Error('Redis客户端未初始化');
        }
      } else if (this.options.cacheType === CacheType.MULTI_LEVEL) {
        // 存储到内存缓存和Redis缓存
        this.memoryCache.set(namespace, key, data, finalTTL);
        
        if (this.redisClient) {
          await this.redisSet(cacheKey, data, 'EX', finalTTL);
        }
      }
      
      this.stats.sets++;
      return true;
    } catch (error) {
      logger.error('设置缓存失败:', error);
      this.stats.errors++;
      return false;
    }
  }
  
  /**
   * 获取缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @param {Function} [fallbackFn] - 回退函数，当缓存未命中时调用
   * @returns {Promise<*>} 缓存值，如果不存在则返回null
   */
  async get(namespace, key, fallbackFn = null) {
    try {
      const cacheKey = this._generateCacheKey(namespace, key);
      
      // 如果启用布隆过滤器，检查键是否可能存在
      if (this.options.enableBloomFilter && !this.bloomFilter.has(cacheKey)) {
        this.stats.bloomFilterRejections++;
        this.stats.misses++;
        
        // 如果提供了回退函数，调用回退函数
        if (fallbackFn) {
          return this._handleCacheMiss(namespace, key, fallbackFn);
        }
        
        return null;
      }
      
      let data = null;
      
      // 根据缓存类型获取数据
      if (this.options.cacheType === CacheType.MEMORY) {
        // 从内存缓存获取
        data = this.memoryCache.get(namespace, key);
      } else if (this.options.cacheType === CacheType.REDIS) {
        // 从Redis缓存获取
        if (this.redisClient) {
          data = await this.redisGet(cacheKey);
        } else {
          throw new Error('Redis客户端未初始化');
        }
      } else if (this.options.cacheType === CacheType.MULTI_LEVEL) {
        // 先从内存缓存获取
        data = this.memoryCache.get(namespace, key);
        
        // 如果内存缓存未命中，从Redis缓存获取
        if (data === null && this.redisClient) {
          data = await this.redisGet(cacheKey);
          
          // 如果Redis缓存命中，更新内存缓存
          if (data !== null) {
            // 获取TTL
            const ttl = await this.redisClient.ttl(cacheKey);
            if (ttl > 0) {
              this.memoryCache.set(namespace, key, data, ttl);
            }
          }
        }
      }
      
      // 如果缓存命中
      if (data !== null) {
        // 检查是否是空值缓存
        if (data === 'NULL' && this.options.enableNullCache) {
          this.stats.nullCacheHits++;
          this.stats.hits++;
          return null;
        }
        
        // 解压数据
        const value = this._decompressData(data);
        this.stats.hits++;
        return value;
      }
      
      // 缓存未命中
      this.stats.misses++;
      
      // 如果提供了回退函数，调用回退函数
      if (fallbackFn) {
        return this._handleCacheMiss(namespace, key, fallbackFn);
      }
      
      return null;
    } catch (error) {
      logger.error('获取缓存失败:', error);
      this.stats.errors++;
      
      // 如果提供了回退函数，调用回退函数
      if (fallbackFn) {
        return fallbackFn();
      }
      
      return null;
    }
  }
  
  /**
   * 处理缓存未命中
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @param {Function} fallbackFn - 回退函数
   * @returns {Promise<*>} 回退函数的结果
   * @private
   */
  async _handleCacheMiss(namespace, key, fallbackFn) {
    const lockKey = this._generateCacheKey(namespace, key);
    
    // 尝试获取锁，防止缓存击穿
    let locked = false;
    let retryCount = 0;
    
    while (!locked && retryCount < this.options.lockRetryTimes) {
      locked = await this._acquireLock(lockKey);
      
      if (!locked) {
        retryCount++;
        await new Promise(resolve => setTimeout(resolve, this.options.lockRetryDelay));
      }
    }
    
    if (!locked) {
      // 无法获取锁，可能是并发请求过多
      this.stats.lockTimeouts++;
      logger.warn(`无法获取缓存锁: ${lockKey}`);
      return fallbackFn();
    }
    
    try {
      // 再次检查缓存，可能在等待锁的过程中已经被其他请求填充
      const cachedValue = await this.get(namespace, key);
      if (cachedValue !== null) {
        return cachedValue;
      }
      
      // 调用回退函数获取数据
      const value = await fallbackFn();
      
      // 将数据存入缓存
      if (value === null && this.options.enableNullCache) {
        // 存储空值，防止缓存穿透
        await this.set(namespace, key, 'NULL', this.options.nullValueTTL);
      } else if (value !== null) {
        await this.set(namespace, key, value);
      }
      
      return value;
    } finally {
      // 释放锁
      await this._releaseLock(lockKey);
    }
  }
  
  /**
   * 删除缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @returns {Promise<boolean>} 是否成功
   */
  async del(namespace, key) {
    try {
      const cacheKey = this._generateCacheKey(namespace, key);
      
      // 根据缓存类型删除数据
      if (this.options.cacheType === CacheType.MEMORY) {
        // 从内存缓存删除
        this.memoryCache.del(namespace, key);
      } else if (this.options.cacheType === CacheType.REDIS) {
        // 从Redis缓存删除
        if (this.redisClient) {
          await this.redisDel(cacheKey);
        } else {
          throw new Error('Redis客户端未初始化');
        }
      } else if (this.options.cacheType === CacheType.MULTI_LEVEL) {
        // 从内存缓存和Redis缓存删除
        this.memoryCache.del(namespace, key);
        
        if (this.redisClient) {
          await this.redisDel(cacheKey);
        }
      }
      
      return true;
    } catch (error) {
      logger.error('删除缓存失败:', error);
      this.stats.errors++;
      return false;
    }
  }
  
  /**
   * 清空命名空间
   * @param {string} namespace - 命名空间
   * @returns {Promise<boolean>} 是否成功
   */
  async clearNamespace(namespace) {
    try {
      // 从内存缓存清空
      if (this.options.cacheType === CacheType.MEMORY || 
          this.options.cacheType === CacheType.MULTI_LEVEL) {
        this.memoryCache.clearNamespace(namespace);
      }
      
      // 从Redis缓存清空
      if ((this.options.cacheType === CacheType.REDIS || 
           this.options.cacheType === CacheType.MULTI_LEVEL) && 
          this.redisClient) {
        // 获取所有匹配的键
        const keys = await this.redisClient.keys(`${namespace}:*`);
        
        if (keys.length > 0) {
          await this.redisClient.del(...keys);
        }
      }
      
      return true;
    } catch (error) {
      logger.error('清空命名空间失败:', error);
      this.stats.errors++;
      return false;
    }
  }
  
  /**
   * 清空所有缓存
   * @returns {Promise<boolean>} 是否成功
   */
  async clearAll() {
    try {
      // 从内存缓存清空
      if (this.options.cacheType === CacheType.MEMORY || 
          this.options.cacheType === CacheType.MULTI_LEVEL) {
        this.memoryCache.clearAll();
      }
      
      // 从Redis缓存清空
      if ((this.options.cacheType === CacheType.REDIS || 
           this.options.cacheType === CacheType.MULTI_LEVEL) && 
          this.redisClient) {
        await this.redisClient.flushdb();
      }
      
      // 重置布隆过滤器
      if (this.options.enableBloomFilter) {
        this.bloomFilter = new Set();
      }
      
      return true;
    } catch (error) {
      logger.error('清空所有缓存失败:', error);
      this.stats.errors++;
      return false;
    }
  }
  
  /**
   * 获取统计信息
   * @returns {Object} 统计信息
   */
  getStats() {
    const hitRate = this.stats.hits + this.stats.misses > 0 
      ? (this.stats.hits / (this.stats.hits + this.stats.misses)) * 100 
      : 0;
    
    return {
      ...this.stats,
      hitRate: hitRate.toFixed(2),
      cacheType: this.options.cacheType
    };
  }
  
  /**
   * 发送事件
   * @param {string} eventName - 事件名称
   * @param {Object} data - 事件数据
   * @private
   */
  _emitEvent(eventName, data = {}) {
    this.emit(eventName, {
      timestamp: Date.now(),
      ...data
    });
  }
  
  /**
   * 关闭缓存管理器
   */
  async close() {
    // 清除统计信息收集定时器
    if (this.statsInterval) {
      clearInterval(this.statsInterval);
    }
    
    // 关闭Redis连接
    if (this.redisClient) {
      await this.redisClient.quit();
    }
    
    logger.info('分布式缓存管理器已关闭');
  }
}

// 创建单例
const distributedCacheManager = new DistributedCacheManager();

module.exports = {
  CacheType,
  distributedCacheManager,
  DistributedCacheManager
};
