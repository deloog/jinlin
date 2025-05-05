/**
 * 多级缓存服务单元测试
 */
const { MultiLevelCacheService, multiLevelCacheService, CACHE_LEVELS } = require('../../../services/multiLevelCacheService');
const logger = require('../../../utils/enhancedLogger');
const NodeCache = require('node-cache');

// 模拟configManager
jest.mock('../../../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

// 模拟Redis客户端
jest.mock('ioredis', () => {
  const mockRedis = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue('OK'),
    del: jest.fn().mockResolvedValue(1),
    keys: jest.fn().mockResolvedValue([]),
    quit: jest.fn().mockResolvedValue('OK'),
    on: jest.fn()
  };

  return jest.fn().mockImplementation(() => mockRedis);
});

// 模拟fs模块
jest.mock('fs', () => {
  const mockFs = {
    promises: {
      mkdir: jest.fn().mockResolvedValue(undefined),
      readFile: jest.fn().mockRejectedValue(new Error('File not found')),
      writeFile: jest.fn().mockResolvedValue(undefined),
      unlink: jest.fn().mockResolvedValue(undefined),
      access: jest.fn().mockRejectedValue(new Error('File not found')),
      readdir: jest.fn().mockResolvedValue([])
    }
  };

  return mockFs;
});

// 模拟NodeCache
jest.mock('node-cache', () => {
  const mockCache = function() {
    this.data = new Map();

    this.get = jest.fn(key => this.data.get(key));
    this.set = jest.fn((key, value, ttl) => {
      this.data.set(key, value);
      return true;
    });
    this.del = jest.fn(key => {
      if (Array.isArray(key)) {
        let count = 0;
        key.forEach(k => {
          if (this.data.delete(k)) count++;
        });
        return count;
      }
      return this.data.delete(key) ? 1 : 0;
    });
    this.keys = jest.fn(() => Array.from(this.data.keys()));
    this.flushAll = jest.fn(() => {
      this.data.clear();
      return true;
    });
  };

  return jest.fn().mockImplementation(() => new mockCache());
});

describe('MultiLevelCacheService', () => {
  let cacheService;

  beforeEach(async () => {
    // 创建新的缓存服务实例
    cacheService = new MultiLevelCacheService({
      memory: {
        enabled: true,
        ttl: 60
      },
      redis: {
        enabled: false
      },
      file: {
        enabled: false
      }
    });

    // 初始化服务
    await cacheService.initialize();

    // 重置日志模拟
    jest.clearAllMocks();
  });

  afterEach(async () => {
    // 关闭服务
    await cacheService.close();
  });

  describe('initialize', () => {
    it('should initialize the service', async () => {
      // 创建新实例
      const service = new MultiLevelCacheService({
        memory: { enabled: true },
        redis: { enabled: false },
        file: { enabled: false }
      });

      // 初始化前
      expect(service.initialized).toBe(false);

      // 初始化
      await service.initialize();

      // 初始化后
      expect(service.initialized).toBe(true);
      expect(service.caches[CACHE_LEVELS.MEMORY]).toBeDefined();

      // 清理
      await service.close();
    });

    it('should not initialize twice', async () => {
      // 已经在beforeEach中初始化
      expect(cacheService.initialized).toBe(true);

      // 记录日志调用次数
      const initialLogCalls = logger.info.mock.calls.length;

      // 尝试再次初始化
      await cacheService.initialize();

      // 应该仍然是初始化状态
      expect(cacheService.initialized).toBe(true);

      // 不应该有新的初始化日志
      expect(logger.info.mock.calls.length).toBe(initialLogCalls);
    });
  });

  describe('set and get', () => {
    it('should set and get a value from memory cache', async () => {
      // 设置缓存
      await cacheService.set('test', 'key1', 'value1');

      // 获取缓存
      const value = await cacheService.get('test', 'key1');

      // 验证值
      expect(value).toBe('value1');
    });

    it('should set and get a complex object from memory cache', async () => {
      // 复杂对象
      const complexObject = {
        id: 1,
        name: 'Test',
        nested: {
          field: 'value',
          array: [1, 2, 3]
        }
      };

      // 设置缓存
      await cacheService.set('test', 'complex', complexObject);

      // 获取缓存
      const value = await cacheService.get('test', 'complex');

      // 验证值
      expect(value).toEqual(complexObject);
    });

    it('should return null for non-existent key', async () => {
      // 获取不存在的缓存
      const value = await cacheService.get('test', 'non-existent');

      // 验证值
      expect(value).toBeNull();
    });
  });

  describe('delete', () => {
    it('should delete a cached item', async () => {
      // 设置缓存
      await cacheService.set('test', 'key2', 'value2');

      // 验证缓存存在
      const value1 = await cacheService.get('test', 'key2');
      expect(value1).toBe('value2');

      // 删除缓存
      await cacheService.del('test', 'key2');

      // 验证缓存已删除
      const value2 = await cacheService.get('test', 'key2');
      expect(value2).toBeNull();
    });
  });

  describe('clear', () => {
    it('should clear all cached items in a namespace', async () => {
      // 设置多个缓存
      await cacheService.set('ns1', 'key1', 'value1');
      await cacheService.set('ns1', 'key2', 'value2');
      await cacheService.set('ns2', 'key1', 'other1');

      // 清除ns1命名空间
      await cacheService.clear('ns1');

      // 验证ns1的缓存已清除
      const value1 = await cacheService.get('ns1', 'key1');
      const value2 = await cacheService.get('ns1', 'key2');
      expect(value1).toBeNull();
      expect(value2).toBeNull();

      // 验证ns2的缓存仍然存在
      const other1 = await cacheService.get('ns2', 'key1');
      expect(other1).toBe('other1');
    });
  });

  describe('error handling', () => {
    it('should handle errors when service is not initialized', async () => {
      // 创建未初始化的服务
      const service = new MultiLevelCacheService();

      // 尝试获取缓存
      await expect(service.get('test', 'key'))
        .rejects.toThrow('多级缓存服务未初始化');

      // 尝试设置缓存
      await expect(service.set('test', 'key', 'value'))
        .rejects.toThrow('多级缓存服务未初始化');

      // 尝试删除缓存
      await expect(service.del('test', 'key'))
        .rejects.toThrow('多级缓存服务未初始化');

      // 尝试清除缓存
      await expect(service.clear('test'))
        .rejects.toThrow('多级缓存服务未初始化');
    });
  });
});
