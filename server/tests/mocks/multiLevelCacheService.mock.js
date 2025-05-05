/**
 * 多级缓存服务模拟
 */
const { EventEmitter } = require('events');

class MockMultiLevelCacheService extends EventEmitter {
  constructor() {
    super();
    this.cache = new Map();
    this.initialized = false;
    this.stats = {
      hits: 0,
      misses: 0,
      total: 0
    };
  }
  
  async initialize() {
    this.initialized = true;
    return true;
  }
  
  async close() {
    this.initialized = false;
    return true;
  }
  
  async get(namespace, key) {
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
    const cacheKey = `${namespace}:${key}`;
    const expires = ttl > 0 ? Date.now() + (ttl * 1000) : null;
    
    this.cache.set(cacheKey, { value, expires });
    return true;
  }
  
  async del(namespace, key) {
    const cacheKey = `${namespace}:${key}`;
    return this.cache.delete(cacheKey);
  }
  
  async clear(namespace) {
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
  
  getSize() {
    return this.cache.size;
  }
  
  getHitRate() {
    if (this.stats.total === 0) return 0;
    return this.stats.hits / this.stats.total;
  }
  
  getMissRate() {
    if (this.stats.total === 0) return 0;
    return this.stats.misses / this.stats.total;
  }
  
  async refresh(namespace, key, value, ttl = 0) {
    return this.set(namespace, key, value, ttl);
  }
  
  async has(namespace, key) {
    const cacheKey = `${namespace}:${key}`;
    const item = this.cache.get(cacheKey);
    
    if (!item) return false;
    
    if (item.expires && item.expires <= Date.now()) {
      this.cache.delete(cacheKey);
      return false;
    }
    
    return true;
  }
}

module.exports = {
  MockMultiLevelCacheService
};
