/**
 * 多级缓存服务
 * 
 * 提供分层缓存架构：
 * - 内存缓存（一级缓存）
 * - Redis缓存（二级缓存）
 * - 文件缓存（三级缓存）
 * - 智能缓存策略
 * - 缓存预热
 */
const NodeCache = require('node-cache');
const Redis = require('ioredis');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用缓存
  enabled: process.env.CACHE_ENABLED === 'true' || true,
  
  // 内存缓存配置
  memory: {
    enabled: process.env.MEMORY_CACHE_ENABLED === 'true' || true,
    ttl: parseInt(process.env.MEMORY_CACHE_TTL || '60', 10), // 默认60秒
    checkperiod: parseInt(process.env.MEMORY_CACHE_CHECK_PERIOD || '120', 10), // 默认120秒
    maxKeys: parseInt(process.env.MEMORY_CACHE_MAX_KEYS || '1000', 10) // 默认1000个键
  },
  
  // Redis缓存配置
  redis: {
    enabled: process.env.REDIS_CACHE_ENABLED === 'true' || false,
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || '',
    db: parseInt(process.env.REDIS_DB || '0', 10),
    ttl: parseInt(process.env.REDIS_CACHE_TTL || '300', 10), // 默认300秒
    keyPrefix: process.env.REDIS_KEY_PREFIX || 'cache:'
  },
  
  // 文件缓存配置
  file: {
    enabled: process.env.FILE_CACHE_ENABLED === 'true' || false,
    dir: process.env.FILE_CACHE_DIR || path.join(__dirname, '../../cache'),
    ttl: parseInt(process.env.FILE_CACHE_TTL || '3600', 10), // 默认3600秒
    maxSize: parseInt(process.env.FILE_CACHE_MAX_SIZE || '104857600', 10) // 默认100MB
  },
  
  // 缓存策略配置
  strategy: {
    // 缓存预热
    preload: {
      enabled: process.env.CACHE_PRELOAD_ENABLED === 'true' || false,
      interval: parseInt(process.env.CACHE_PRELOAD_INTERVAL || '3600', 10), // 默认1小时
      keys: (process.env.CACHE_PRELOAD_KEYS || '').split(',').filter(Boolean)
    },
    
    // 缓存统计
    stats: {
      enabled: process.env.CACHE_STATS_ENABLED === 'true' || true,
      sampleRate: parseFloat(process.env.CACHE_STATS_SAMPLE_RATE || '0.1') // 默认10%
    }
  }
};

// 缓存级别
const CACHE_LEVELS = {
  MEMORY: 'memory',
  REDIS: 'redis',
  FILE: 'file'
};

// 多级缓存服务类
class MultiLevelCacheService extends EventEmitter {
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
      memory: {
        ...DEFAULT_CONFIG.memory,
        ...(config.memory || {})
      },
      redis: {
        ...DEFAULT_CONFIG.redis,
        ...(config.redis || {})
      },
      file: {
        ...DEFAULT_CONFIG.file,
        ...(config.file || {})
      },
      strategy: {
        ...DEFAULT_CONFIG.strategy,
        preload: {
          ...DEFAULT_CONFIG.strategy.preload,
          ...(config.strategy?.preload || {})
        },
        stats: {
          ...DEFAULT_CONFIG.strategy.stats,
          ...(config.strategy?.stats || {})
        }
      }
    };
    
    // 缓存实例
    this.caches = {};
    
    // 缓存统计
    this.stats = {
      hits: {
        [CACHE_LEVELS.MEMORY]: 0,
        [CACHE_LEVELS.REDIS]: 0,
        [CACHE_LEVELS.FILE]: 0
      },
      misses: {
        [CACHE_LEVELS.MEMORY]: 0,
        [CACHE_LEVELS.REDIS]: 0,
        [CACHE_LEVELS.FILE]: 0
      },
      sets: {
        [CACHE_LEVELS.MEMORY]: 0,
        [CACHE_LEVELS.REDIS]: 0,
        [CACHE_LEVELS.FILE]: 0
      }
    };
    
    // 预热定时器
    this.preloadTimer = null;
    
    // 初始化状态
    this.initialized = false;
    
    // 注册配置架构
    this._registerConfigSchema();
    
    logger.info('多级缓存服务已创建');
  }
  
  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');
    
    // 注册缓存配置架构
    configManager.registerSchema('cache.enabled', Joi.boolean().default(true));
    configManager.registerSchema('cache.memory.enabled', Joi.boolean().default(true));
    configManager.registerSchema('cache.memory.ttl', Joi.number().min(1).default(60));
    configManager.registerSchema('cache.redis.enabled', Joi.boolean().default(false));
    configManager.registerSchema('cache.redis.ttl', Joi.number().min(1).default(300));
    configManager.registerSchema('cache.file.enabled', Joi.boolean().default(false));
    configManager.registerSchema('cache.file.ttl', Joi.number().min(1).default(3600));
  }
  
  /**
   * 初始化多级缓存服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }
    
    try {
      logger.info('初始化多级缓存服务');
      
      // 初始化内存缓存
      if (this.config.memory.enabled) {
        this.caches[CACHE_LEVELS.MEMORY] = new NodeCache({
          stdTTL: this.config.memory.ttl,
          checkperiod: this.config.memory.checkperiod,
          maxKeys: this.config.memory.maxKeys
        });
        
        logger.info('内存缓存已初始化');
      }
      
      // 初始化Redis缓存
      if (this.config.redis.enabled) {
        this.caches[CACHE_LEVELS.REDIS] = new Redis({
          host: this.config.redis.host,
          port: this.config.redis.port,
          password: this.config.redis.password || undefined,
          db: this.config.redis.db,
          keyPrefix: this.config.redis.keyPrefix
        });
        
        // 监听Redis连接事件
        this.caches[CACHE_LEVELS.REDIS].on('connect', () => {
          logger.info('Redis缓存已连接');
        });
        
        this.caches[CACHE_LEVELS.REDIS].on('error', (error) => {
          logger.error('Redis缓存错误', { error });
        });
        
        logger.info('Redis缓存已初始化');
      }
      
      // 初始化文件缓存
      if (this.config.file.enabled) {
        // 确保缓存目录存在
        await fs.mkdir(this.config.file.dir, { recursive: true });
        
        logger.info('文件缓存已初始化');
      }
      
      // 启动缓存预热
      if (this.config.strategy.preload.enabled) {
        this._startPreload();
      }
      
      this.initialized = true;
      logger.info('多级缓存服务初始化成功');
    } catch (error) {
      logger.error('初始化多级缓存服务失败', { error });
      throw error;
    }
  }
  
  /**
   * 启动缓存预热
   * @private
   */
  _startPreload() {
    // 清除现有定时器
    if (this.preloadTimer) {
      clearInterval(this.preloadTimer);
    }
    
    // 设置新定时器
    this.preloadTimer = setInterval(() => {
      this._preloadCache().catch(error => {
        logger.error('缓存预热失败', { error });
      });
    }, this.config.strategy.preload.interval * 1000);
    
    logger.info('缓存预热定时器已启动');
  }
  
  /**
   * 预热缓存
   * @private
   * @returns {Promise<void>}
   */
  async _preloadCache() {
    try {
      // 获取预热键
      const keys = this.config.strategy.preload.keys;
      
      if (!keys || keys.length === 0) {
        return;
      }
      
      logger.info(`开始预热缓存，${keys.length}个键`);
      
      // 触发预热事件
      this.emit('preload', { keys });
      
      logger.info('缓存预热完成');
    } catch (error) {
      logger.error('预热缓存失败', { error });
      throw error;
    }
  }
  
  /**
   * 获取缓存键
   * @private
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @returns {string} 缓存键
   */
  _getCacheKey(namespace, key) {
    return `${namespace}:${key}`;
  }
  
  /**
   * 获取文件缓存路径
   * @private
   * @param {string} cacheKey - 缓存键
   * @returns {string} 文件路径
   */
  _getFilePath(cacheKey) {
    // 使用MD5哈希作为文件名
    const hash = crypto.createHash('md5').update(cacheKey).digest('hex');
    return path.join(this.config.file.dir, `${hash}.cache`);
  }
  
  /**
   * 更新缓存统计
   * @private
   * @param {string} type - 统计类型
   * @param {string} level - 缓存级别
   */
  _updateStats(type, level) {
    if (this.config.strategy.stats.enabled) {
      // 使用采样率减少统计开销
      if (Math.random() < this.config.strategy.stats.sampleRate) {
        this.stats[type][level]++;
      }
    }
  }
  
  /**
   * 从内存缓存获取
   * @private
   * @param {string} cacheKey - 缓存键
   * @returns {Promise<any>} 缓存值
   */
  async _getFromMemory(cacheKey) {
    if (!this.config.memory.enabled) {
      return null;
    }
    
    try {
      const value = this.caches[CACHE_LEVELS.MEMORY].get(cacheKey);
      
      if (value !== undefined) {
        this._updateStats('hits', CACHE_LEVELS.MEMORY);
        return value;
      }
      
      this._updateStats('misses', CACHE_LEVELS.MEMORY);
      return null;
    } catch (error) {
      logger.error('从内存缓存获取失败', { error, cacheKey });
      return null;
    }
  }
  
  /**
   * 从Redis缓存获取
   * @private
   * @param {string} cacheKey - 缓存键
   * @returns {Promise<any>} 缓存值
   */
  async _getFromRedis(cacheKey) {
    if (!this.config.redis.enabled) {
      return null;
    }
    
    try {
      const value = await this.caches[CACHE_LEVELS.REDIS].get(cacheKey);
      
      if (value !== null) {
        this._updateStats('hits', CACHE_LEVELS.REDIS);
        
        // 尝试解析JSON
        try {
          return JSON.parse(value);
        } catch (e) {
          return value;
        }
      }
      
      this._updateStats('misses', CACHE_LEVELS.REDIS);
      return null;
    } catch (error) {
      logger.error('从Redis缓存获取失败', { error, cacheKey });
      return null;
    }
  }
  
  /**
   * 从文件缓存获取
   * @private
   * @param {string} cacheKey - 缓存键
   * @returns {Promise<any>} 缓存值
   */
  async _getFromFile(cacheKey) {
    if (!this.config.file.enabled) {
      return null;
    }
    
    try {
      const filePath = this._getFilePath(cacheKey);
      
      // 检查文件是否存在
      try {
        await fs.access(filePath);
      } catch (e) {
        this._updateStats('misses', CACHE_LEVELS.FILE);
        return null;
      }
      
      // 读取文件
      const data = await fs.readFile(filePath, 'utf8');
      
      // 解析数据
      const { value, expires } = JSON.parse(data);
      
      // 检查是否过期
      if (expires && expires < Date.now()) {
        // 删除过期文件
        await fs.unlink(filePath).catch(() => {});
        
        this._updateStats('misses', CACHE_LEVELS.FILE);
        return null;
      }
      
      this._updateStats('hits', CACHE_LEVELS.FILE);
      return value;
    } catch (error) {
      logger.error('从文件缓存获取失败', { error, cacheKey });
      return null;
    }
  }
  
  /**
   * 设置内存缓存
   * @private
   * @param {string} cacheKey - 缓存键
   * @param {any} value - 缓存值
   * @param {number} ttl - 过期时间（秒）
   * @returns {Promise<void>}
   */
  async _setToMemory(cacheKey, value, ttl) {
    if (!this.config.memory.enabled) {
      return;
    }
    
    try {
      this.caches[CACHE_LEVELS.MEMORY].set(cacheKey, value, ttl);
      this._updateStats('sets', CACHE_LEVELS.MEMORY);
    } catch (error) {
      logger.error('设置内存缓存失败', { error, cacheKey });
    }
  }
  
  /**
   * 设置Redis缓存
   * @private
   * @param {string} cacheKey - 缓存键
   * @param {any} value - 缓存值
   * @param {number} ttl - 过期时间（秒）
   * @returns {Promise<void>}
   */
  async _setToRedis(cacheKey, value, ttl) {
    if (!this.config.redis.enabled) {
      return;
    }
    
    try {
      // 序列化值
      const serialized = typeof value === 'string' ? value : JSON.stringify(value);
      
      // 设置缓存
      await this.caches[CACHE_LEVELS.REDIS].set(cacheKey, serialized, 'EX', ttl);
      
      this._updateStats('sets', CACHE_LEVELS.REDIS);
    } catch (error) {
      logger.error('设置Redis缓存失败', { error, cacheKey });
    }
  }
  
  /**
   * 设置文件缓存
   * @private
   * @param {string} cacheKey - 缓存键
   * @param {any} value - 缓存值
   * @param {number} ttl - 过期时间（秒）
   * @returns {Promise<void>}
   */
  async _setToFile(cacheKey, value, ttl) {
    if (!this.config.file.enabled) {
      return;
    }
    
    try {
      const filePath = this._getFilePath(cacheKey);
      
      // 计算过期时间
      const expires = ttl > 0 ? Date.now() + (ttl * 1000) : null;
      
      // 序列化数据
      const data = JSON.stringify({
        value,
        expires,
        created: Date.now()
      });
      
      // 写入文件
      await fs.writeFile(filePath, data, 'utf8');
      
      this._updateStats('sets', CACHE_LEVELS.FILE);
    } catch (error) {
      logger.error('设置文件缓存失败', { error, cacheKey });
    }
  }
  
  /**
   * 获取缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @returns {Promise<any>} 缓存值
   */
  async get(namespace, key) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    // 如果未启用缓存，返回null
    if (!this.config.enabled) {
      return null;
    }
    
    // 获取缓存键
    const cacheKey = this._getCacheKey(namespace, key);
    
    try {
      // 从内存缓存获取
      let value = await this._getFromMemory(cacheKey);
      
      if (value !== null) {
        return value;
      }
      
      // 从Redis缓存获取
      value = await this._getFromRedis(cacheKey);
      
      if (value !== null) {
        // 回填内存缓存
        await this._setToMemory(cacheKey, value, this.config.memory.ttl);
        return value;
      }
      
      // 从文件缓存获取
      value = await this._getFromFile(cacheKey);
      
      if (value !== null) {
        // 回填内存缓存和Redis缓存
        await this._setToMemory(cacheKey, value, this.config.memory.ttl);
        await this._setToRedis(cacheKey, value, this.config.redis.ttl);
        return value;
      }
      
      return null;
    } catch (error) {
      logger.error('获取缓存失败', { error, namespace, key });
      return null;
    }
  }
  
  /**
   * 设置缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @param {any} value - 值
   * @param {number} ttl - 过期时间（秒）
   * @returns {Promise<void>}
   */
  async set(namespace, key, value, ttl = 0) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    // 如果未启用缓存，不执行操作
    if (!this.config.enabled) {
      return;
    }
    
    // 获取缓存键
    const cacheKey = this._getCacheKey(namespace, key);
    
    try {
      // 设置内存缓存
      await this._setToMemory(cacheKey, value, ttl || this.config.memory.ttl);
      
      // 设置Redis缓存
      await this._setToRedis(cacheKey, value, ttl || this.config.redis.ttl);
      
      // 设置文件缓存
      await this._setToFile(cacheKey, value, ttl || this.config.file.ttl);
    } catch (error) {
      logger.error('设置缓存失败', { error, namespace, key });
    }
  }
  
  /**
   * 删除缓存
   * @param {string} namespace - 命名空间
   * @param {string} key - 键
   * @returns {Promise<void>}
   */
  async del(namespace, key) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    // 如果未启用缓存，不执行操作
    if (!this.config.enabled) {
      return;
    }
    
    // 获取缓存键
    const cacheKey = this._getCacheKey(namespace, key);
    
    try {
      // 删除内存缓存
      if (this.config.memory.enabled) {
        this.caches[CACHE_LEVELS.MEMORY].del(cacheKey);
      }
      
      // 删除Redis缓存
      if (this.config.redis.enabled) {
        await this.caches[CACHE_LEVELS.REDIS].del(cacheKey);
      }
      
      // 删除文件缓存
      if (this.config.file.enabled) {
        const filePath = this._getFilePath(cacheKey);
        await fs.unlink(filePath).catch(() => {});
      }
    } catch (error) {
      logger.error('删除缓存失败', { error, namespace, key });
    }
  }
  
  /**
   * 清空命名空间
   * @param {string} namespace - 命名空间
   * @returns {Promise<void>}
   */
  async clear(namespace) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('多级缓存服务未初始化');
    }
    
    // 如果未启用缓存，不执行操作
    if (!this.config.enabled) {
      return;
    }
    
    try {
      // 清空内存缓存
      if (this.config.memory.enabled) {
        const keys = this.caches[CACHE_LEVELS.MEMORY].keys();
        const namespacedKeys = keys.filter(key => key.startsWith(`${namespace}:`));
        namespacedKeys.forEach(key => {
          this.caches[CACHE_LEVELS.MEMORY].del(key);
        });
      }
      
      // 清空Redis缓存
      if (this.config.redis.enabled) {
        const pattern = `${this.config.redis.keyPrefix}${namespace}:*`;
        const keys = await this.caches[CACHE_LEVELS.REDIS].keys(pattern);
        
        if (keys.length > 0) {
          // 删除前缀
          const cleanKeys = keys.map(key => key.replace(this.config.redis.keyPrefix, ''));
          await this.caches[CACHE_LEVELS.REDIS].del(cleanKeys);
        }
      }
      
      // 清空文件缓存
      if (this.config.file.enabled) {
        // 获取所有缓存文件
        const files = await fs.readdir(this.config.file.dir);
        
        // 逐个检查文件
        for (const file of files) {
          try {
            const filePath = path.join(this.config.file.dir, file);
            const data = await fs.readFile(filePath, 'utf8');
            const parsed = JSON.parse(data);
            
            // 检查是否属于指定命名空间
            if (parsed.key && parsed.key.startsWith(`${namespace}:`)) {
              await fs.unlink(filePath).catch(() => {});
            }
          } catch (e) {
            // 忽略文件读取错误
          }
        }
      }
    } catch (error) {
      logger.error('清空命名空间失败', { error, namespace });
    }
  }
  
  /**
   * 获取缓存统计
   * @returns {Object} 缓存统计
   */
  getStats() {
    return {
      ...this.stats,
      hitRatio: {
        [CACHE_LEVELS.MEMORY]: this._calculateHitRatio(CACHE_LEVELS.MEMORY),
        [CACHE_LEVELS.REDIS]: this._calculateHitRatio(CACHE_LEVELS.REDIS),
        [CACHE_LEVELS.FILE]: this._calculateHitRatio(CACHE_LEVELS.FILE)
      }
    };
  }
  
  /**
   * 计算命中率
   * @private
   * @param {string} level - 缓存级别
   * @returns {number} 命中率
   */
  _calculateHitRatio(level) {
    const hits = this.stats.hits[level];
    const misses = this.stats.misses[level];
    const total = hits + misses;
    
    if (total === 0) {
      return 0;
    }
    
    return hits / total;
  }
  
  /**
   * 关闭多级缓存服务
   * @returns {Promise<void>}
   */
  async close() {
    try {
      logger.info('关闭多级缓存服务');
      
      // 清除预热定时器
      if (this.preloadTimer) {
        clearInterval(this.preloadTimer);
        this.preloadTimer = null;
      }
      
      // 关闭Redis连接
      if (this.config.redis.enabled && this.caches[CACHE_LEVELS.REDIS]) {
        await this.caches[CACHE_LEVELS.REDIS].quit();
      }
      
      // 重置缓存实例
      this.caches = {};
      
      // 重置初始化状态
      this.initialized = false;
      
      logger.info('多级缓存服务已关闭');
    } catch (error) {
      logger.error('关闭多级缓存服务失败', { error });
      throw error;
    }
  }
}

// 创建单例
const multiLevelCacheService = new MultiLevelCacheService();

// 导出
module.exports = {
  multiLevelCacheService,
  MultiLevelCacheService,
  CACHE_LEVELS
};
