/**
 * 缓存服务
 * 提供内存缓存功能，用于缓存频繁访问的数据
 *
 * 增强功能：
 * - 支持Redis分布式缓存（可选）
 * - 缓存穿透保护（空值缓存）
 * - 缓存击穿保护（互斥锁）
 * - 缓存雪崩保护（随机过期时间）
 */
const logger = require('../utils/logger');
const Redis = require('ioredis');
const { promisify } = require('util');
const crypto = require('crypto');

// 缓存类型
const CacheType = {
  MEMORY: 'MEMORY',     // 内存缓存
  REDIS: 'REDIS',       // Redis缓存
  MULTI_LEVEL: 'MULTI_LEVEL' // 多级缓存（内存+Redis）
};

// 缓存配置
const config = {
  type: process.env.CACHE_TYPE || CacheType.MEMORY,
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    db: process.env.REDIS_DB || 0,
    keyPrefix: 'cache:'
  },
  defaultTTL: parseInt(process.env.CACHE_DEFAULT_TTL || '3600', 10), // 默认1小时
  nullValueTTL: parseInt(process.env.CACHE_NULL_VALUE_TTL || '60', 10), // 空值缓存1分钟
  enableNullCache: process.env.CACHE_ENABLE_NULL_CACHE !== 'false', // 默认启用空值缓存
  randomizeTTL: process.env.CACHE_RANDOMIZE_TTL !== 'false', // 默认启用随机过期时间
  randomizeTTLFactor: parseFloat(process.env.CACHE_RANDOMIZE_TTL_FACTOR || '0.1') // 默认随机因子10%
};

// 缓存存储
const cache = new Map();

// Redis客户端
let redisClient = null;
let redisGet = null;
let redisSet = null;
let redisDel = null;
let redisExists = null;
let redisExpire = null;

// 互斥锁
const locks = new Map();

// 缓存统计
const stats = {
  hits: 0,
  misses: 0,
  sets: 0,
  deletes: 0,
  errors: 0,
  lockTimeouts: 0,
  nullCacheHits: 0
};

// 初始化Redis客户端（如果需要）
if (config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) {
  try {
    redisClient = new Redis(config.redis);

    // 监听Redis事件
    redisClient.on('connect', () => {
      logger.info('Redis连接成功');
    });

    redisClient.on('error', (error) => {
      logger.error('Redis错误:', error);
      stats.errors++;
    });

    redisClient.on('close', () => {
      logger.warn('Redis连接关闭');
    });

    // 将Redis命令转换为Promise
    redisGet = promisify(redisClient.get).bind(redisClient);
    redisSet = promisify(redisClient.set).bind(redisClient);
    redisDel = promisify(redisClient.del).bind(redisClient);
    redisExists = promisify(redisClient.exists).bind(redisClient);
    redisExpire = promisify(redisClient.expire).bind(redisClient);

    logger.info(`缓存服务已初始化，类型: ${config.type}`);
  } catch (error) {
    logger.error('初始化Redis缓存失败:', error);
    stats.errors++;

    // 如果Redis初始化失败，降级为内存缓存
    if (config.type === CacheType.REDIS) {
      config.type = CacheType.MEMORY;
      logger.warn('Redis初始化失败，降级为内存缓存');
    }
  }
} else {
  logger.info(`缓存服务已初始化，类型: ${config.type}`);
}

/**
 * 生成缓存键
 * @param {string} namespace - 命名空间
 * @param {string} key - 键
 * @returns {string} 缓存键
 */
function generateCacheKey(namespace, key) {
  return `${namespace}:${key}`;
}

/**
 * 计算随机过期时间
 * @param {number} ttl - 过期时间（秒）
 * @returns {number} 随机过期时间（秒）
 * @private
 */
function _randomizeTTL(ttl) {
  if (!config.randomizeTTL) {
    return ttl;
  }

  const factor = config.randomizeTTLFactor;
  const min = Math.floor(ttl * (1 - factor));
  const max = Math.ceil(ttl * (1 + factor));

  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// 导入分布式锁服务
const { lockManager } = require('./distributedLockService');

/**
 * 获取分布式锁
 * @param {string} lockKey - 锁键
 * @param {number} timeout - 超时时间（毫秒）
 * @returns {Promise<Object|null>} 锁对象，如果获取失败则返回null
 * @private
 */
async function _acquireLock(lockKey, timeout = 5000) {
  try {
    // 使用分布式锁服务获取锁
    const lock = await lockManager.acquireLock(lockKey, {
      lockTimeout: timeout,
      retryCount: 3,
      retryDelay: 100
    });

    if (lock && lock.acquired) {
      // 存储锁对象，用于后续释放
      locks.set(lockKey, lock);
      return lock;
    }

    return null;
  } catch (error) {
    logger.error('获取分布式锁失败:', error);
    stats.errors++;
    return null;
  }
}

/**
 * 释放分布式锁
 * @param {string} lockKey - 锁键
 * @returns {Promise<boolean>} 是否释放成功
 * @private
 */
async function _releaseLock(lockKey) {
  try {
    const lock = locks.get(lockKey);

    if (!lock) {
      return false;
    }

    // 使用分布式锁服务释放锁
    const result = await lockManager.releaseLock(lock);

    if (result) {
      locks.delete(lockKey);
      return true;
    }

    return false;
  } catch (error) {
    logger.error('释放分布式锁失败:', error);
    stats.errors++;
    return false;
  }
}

/**
 * 设置缓存
 * @param {string} namespace - 命名空间
 * @param {string} key - 键
 * @param {*} value - 值
 * @param {number} ttl - 过期时间（秒），默认使用配置中的默认值
 * @returns {Promise<boolean>} 是否成功
 */
async function set(namespace, key, value, ttl = config.defaultTTL) {
  try {
    const cacheKey = generateCacheKey(namespace, key);

    // 计算随机过期时间（防止缓存雪崩）
    const finalTTL = _randomizeTTL(ttl);

    // 序列化值（如果不是字符串）
    const serializedValue = typeof value === 'string' ? value : JSON.stringify(value);

    // 根据缓存类型存储数据
    if (config.type === CacheType.MEMORY || config.type === CacheType.MULTI_LEVEL) {
      // 存储到内存缓存
      const expires = finalTTL > 0 ? Date.now() + (finalTTL * 1000) : 0;

      cache.set(cacheKey, {
        value: serializedValue,
        expires
      });

      // 如果设置了过期时间，则设置定时器自动清除
      if (expires > 0) {
        setTimeout(() => {
          if (cache.has(cacheKey)) {
            cache.delete(cacheKey);
          }
        }, finalTTL * 1000);
      }
    }

    // 如果使用Redis，存储到Redis
    if ((config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) && redisClient) {
      try {
        if (finalTTL > 0) {
          await redisSet(cacheKey, serializedValue, 'EX', finalTTL);
        } else {
          await redisSet(cacheKey, serializedValue);
        }
      } catch (error) {
        logger.error('设置Redis缓存失败:', error);
        stats.errors++;

        // 如果是Redis缓存且失败，返回失败
        if (config.type === CacheType.REDIS) {
          return false;
        }
        // 如果是多级缓存，继续使用内存缓存
      }
    }

    stats.sets++;
    return true;
  } catch (error) {
    logger.error('设置缓存失败:', error);
    stats.errors++;
    return false;
  }
}

/**
 * 获取缓存
 * @param {string} namespace - 命名空间
 * @param {string} key - 键
 * @param {Function} [fallbackFn] - 回退函数，当缓存未命中时调用
 * @returns {Promise<*>} 缓存值，如果不存在则返回null或回退函数的结果
 */
async function get(namespace, key, fallbackFn = null) {
  try {
    const cacheKey = generateCacheKey(namespace, key);
    let data = null;
    let source = null;

    // 根据缓存类型获取数据
    if (config.type === CacheType.MEMORY || config.type === CacheType.MULTI_LEVEL) {
      // 从内存缓存获取
      if (cache.has(cacheKey)) {
        const cacheItem = cache.get(cacheKey);

        // 检查是否已过期
        if (cacheItem.expires === 0 || cacheItem.expires > Date.now()) {
          data = cacheItem.value;
          source = 'memory';
        } else {
          // 已过期，删除缓存
          cache.delete(cacheKey);
        }
      }
    }

    // 如果内存缓存未命中且使用Redis，从Redis获取
    if (data === null &&
        (config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) &&
        redisClient) {
      try {
        data = await redisGet(cacheKey);

        if (data !== null) {
          source = 'redis';

          // 如果是多级缓存，更新内存缓存
          if (config.type === CacheType.MULTI_LEVEL) {
            // 获取TTL
            const ttl = await redisClient.ttl(cacheKey);

            if (ttl > 0) {
              const expires = Date.now() + (ttl * 1000);
              cache.set(cacheKey, { value: data, expires });
            } else if (ttl === -1) {
              // 永不过期
              cache.set(cacheKey, { value: data, expires: 0 });
            }
          }
        }
      } catch (error) {
        logger.error('从Redis获取缓存失败:', error);
        stats.errors++;
      }
    }

    // 如果缓存命中
    if (data !== null) {
      // 检查是否是空值缓存（缓存穿透保护）
      if (data === 'NULL' && config.enableNullCache) {
        stats.nullCacheHits++;
        stats.hits++;
        logger.debug(`空值缓存命中: ${namespace}:${key}`);
        return null;
      }

      // 反序列化值（如果不是字符串）
      let value;
      try {
        value = JSON.parse(data);
      } catch (e) {
        // 如果解析失败，说明是字符串
        value = data;
      }

      stats.hits++;
      logger.debug(`缓存命中 [${source}]: ${namespace}:${key}`);
      return value;
    }

    // 缓存未命中
    stats.misses++;
    logger.debug(`缓存未命中: ${namespace}:${key}`);

    // 如果提供了回退函数，调用回退函数
    if (fallbackFn) {
      return _handleCacheMiss(namespace, key, fallbackFn);
    }

    return null;
  } catch (error) {
    logger.error('获取缓存失败:', error);
    stats.errors++;

    // 如果提供了回退函数，调用回退函数
    if (fallbackFn) {
      try {
        return await fallbackFn();
      } catch (fallbackError) {
        logger.error('回退函数执行失败:', fallbackError);
        return null;
      }
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
async function _handleCacheMiss(namespace, key, fallbackFn) {
  const lockKey = generateCacheKey(namespace, key);

  // 尝试获取锁，防止缓存击穿
  const lock = await _acquireLock(lockKey);

  if (!lock) {
    // 无法获取锁，可能是并发请求过多
    stats.lockTimeouts++;
    logger.warn(`无法获取缓存锁: ${lockKey}`);
    return fallbackFn();
  }

  try {
    // 再次检查缓存，可能在等待锁的过程中已经被其他请求填充
    const cachedValue = await get(namespace, key);
    if (cachedValue !== null) {
      return cachedValue;
    }

    // 调用回退函数获取数据
    const value = await fallbackFn();

    // 将数据存入缓存
    if (value === null && config.enableNullCache) {
      // 存储空值，防止缓存穿透
      await set(namespace, key, 'NULL', config.nullValueTTL);
      logger.debug(`存储空值缓存: ${namespace}:${key}`);
    } else if (value !== null) {
      await set(namespace, key, value);
    }

    return value;
  } finally {
    // 释放锁
    await _releaseLock(lockKey);
  }
}

/**
 * 删除缓存
 * @param {string} namespace - 命名空间
 * @param {string} key - 键
 * @returns {Promise<boolean>} 是否成功
 */
async function del(namespace, key) {
  try {
    const cacheKey = generateCacheKey(namespace, key);
    let result = false;

    // 根据缓存类型删除数据
    if (config.type === CacheType.MEMORY || config.type === CacheType.MULTI_LEVEL) {
      // 从内存缓存删除
      if (cache.has(cacheKey)) {
        cache.delete(cacheKey);
        result = true;
      }
    }

    // 如果使用Redis，从Redis删除
    if ((config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) && redisClient) {
      try {
        const redisResult = await redisDel(cacheKey);
        result = result || redisResult > 0;
      } catch (error) {
        logger.error('从Redis删除缓存失败:', error);
        stats.errors++;

        // 如果是Redis缓存且失败，返回失败
        if (config.type === CacheType.REDIS) {
          return false;
        }
        // 如果是多级缓存，继续使用内存缓存的结果
      }
    }

    if (result) {
      stats.deletes++;
    }

    return result;
  } catch (error) {
    logger.error('删除缓存失败:', error);
    stats.errors++;
    return false;
  }
}

/**
 * 清除命名空间下的所有缓存
 * @param {string} namespace - 命名空间
 * @returns {Promise<number>} 清除的缓存项数量
 */
async function clearNamespace(namespace) {
  try {
    const prefix = `${namespace}:`;
    let count = 0;

    // 清除内存缓存
    if (config.type === CacheType.MEMORY || config.type === CacheType.MULTI_LEVEL) {
      for (const key of cache.keys()) {
        if (key.startsWith(prefix)) {
          cache.delete(key);
          count++;
        }
      }
    }

    // 清除Redis缓存
    if ((config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) && redisClient) {
      try {
        // 获取所有匹配的键
        const keys = await redisClient.keys(`${config.redis.keyPrefix}${prefix}*`);

        if (keys.length > 0) {
          // 删除所有匹配的键
          const redisResult = await redisClient.del(...keys);
          count += redisResult;
        }
      } catch (error) {
        logger.error('从Redis清除命名空间缓存失败:', error);
        stats.errors++;

        // 如果是Redis缓存且失败，返回失败
        if (config.type === CacheType.REDIS) {
          return 0;
        }
        // 如果是多级缓存，继续使用内存缓存的结果
      }
    }

    stats.deletes += count;
    return count;
  } catch (error) {
    logger.error('清除命名空间缓存失败:', error);
    stats.errors++;
    return 0;
  }
}

/**
 * 清除所有缓存
 * @returns {Promise<number>} 清除的缓存项数量
 */
async function clearAll() {
  try {
    let count = 0;

    // 清除内存缓存
    if (config.type === CacheType.MEMORY || config.type === CacheType.MULTI_LEVEL) {
      count = cache.size;
      cache.clear();
    }

    // 清除Redis缓存
    if ((config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) && redisClient) {
      try {
        // 获取所有键数量
        const redisCount = await redisClient.dbsize();

        // 清空数据库
        await redisClient.flushdb();

        count += redisCount;
      } catch (error) {
        logger.error('从Redis清除所有缓存失败:', error);
        stats.errors++;

        // 如果是Redis缓存且失败，返回失败
        if (config.type === CacheType.REDIS) {
          return 0;
        }
        // 如果是多级缓存，继续使用内存缓存的结果
      }
    }

    stats.deletes += count;
    return count;
  } catch (error) {
    logger.error('清除所有缓存失败:', error);
    stats.errors++;
    return 0;
  }
}

/**
 * 获取缓存统计信息
 * @returns {Promise<Object>} 统计信息
 */
async function getStats() {
  const hitRate = stats.hits + stats.misses > 0
    ? (stats.hits / (stats.hits + stats.misses)) * 100
    : 0;

  const result = {
    ...stats,
    size: cache.size,
    hitRate: hitRate.toFixed(2),
    cacheType: config.type
  };

  // 如果使用Redis，获取Redis统计信息
  if ((config.type === CacheType.REDIS || config.type === CacheType.MULTI_LEVEL) && redisClient) {
    try {
      // 获取Redis信息
      const info = await redisClient.info();
      const memory = await redisClient.info('memory');
      const keyspace = await redisClient.info('keyspace');

      // 解析Redis信息
      const redisStats = {
        connected: redisClient.status === 'ready',
        usedMemory: parseInt(memory.match(/used_memory:(\d+)/)?.[1] || '0', 10),
        keys: parseInt(keyspace.match(/keys=(\d+)/)?.[1] || '0', 10),
        expires: parseInt(keyspace.match(/expires=(\d+)/)?.[1] || '0', 10)
      };

      result.redis = redisStats;
    } catch (error) {
      logger.error('获取Redis统计信息失败:', error);
      stats.errors++;

      result.redis = {
        connected: false,
        error: error.message
      };
    }
  }

  return result;
}

/**
 * 缓存装饰器
 * 用于包装函数，自动缓存函数结果
 * @param {string} namespace - 命名空间
 * @param {Function} fn - 要缓存的函数
 * @param {Function} keyGenerator - 键生成函数，接收与fn相同的参数，返回缓存键
 * @param {Object} options - 配置选项
 * @param {number} options.ttl - 过期时间（秒）
 * @param {boolean} options.useNullCache - 是否缓存空值
 * @param {number} options.nullValueTTL - 空值缓存过期时间（秒）
 * @returns {Function} 包装后的函数
 */
function memoize(namespace, fn, keyGenerator, options = {}) {
  const {
    ttl = config.defaultTTL,
    useNullCache = config.enableNullCache,
    nullValueTTL = config.nullValueTTL
  } = options;

  return async function(...args) {
    // 生成缓存键
    const key = keyGenerator(...args);

    // 尝试从缓存获取
    const cachedResult = await get(namespace, key);
    if (cachedResult !== null) {
      return cachedResult;
    }

    // 使用缓存击穿保护
    return await get(namespace, key, async () => {
      // 执行原函数
      const result = await fn(...args);

      // 缓存结果
      if (result === null && useNullCache) {
        // 缓存空值（防止缓存穿透）
        await set(namespace, key, 'NULL', nullValueTTL);
        return null;
      } else if (result !== null) {
        await set(namespace, key, result, ttl);
      }

      return result;
    });
  };
}

module.exports = {
  set,
  get,
  del,
  clearNamespace,
  clearAll,
  getStats,
  memoize
};
