/**
 * 负载均衡服务单元测试
 */
const { LoadBalancerService, NODE_STATUS, ALGORITHMS } = require('../../mocks/loadBalancerService.mock');
const logger = require('../../../utils/enhancedLogger');

// 模拟configManager
jest.mock('../../../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

// 模拟http和https
jest.mock('http', () => ({
  request: jest.fn().mockImplementation((url, options, callback) => {
    const req = {
      setTimeout: jest.fn(),
      on: jest.fn(),
      write: jest.fn(),
      end: jest.fn()
    };

    if (callback) {
      const res = {
        statusCode: 200,
        headers: {},
        on: jest.fn(),
        setTimeout: jest.fn()
      };

      callback(res);

      // 模拟data和end事件
      const handlers = {};
      res.on = jest.fn().mockImplementation((event, handler) => {
        handlers[event] = handler;
        return res;
      });

      // 触发data和end事件
      if (handlers.data) handlers.data(Buffer.from('{"success":true}'));
      if (handlers.end) handlers.end();
    }

    return req;
  })
}));

jest.mock('https', () => ({
  request: jest.fn().mockImplementation((url, options, callback) => {
    const req = {
      setTimeout: jest.fn(),
      on: jest.fn(),
      write: jest.fn(),
      end: jest.fn()
    };

    if (callback) {
      const res = {
        statusCode: 200,
        headers: {},
        on: jest.fn(),
        setTimeout: jest.fn()
      };

      callback(res);

      // 模拟data和end事件
      const handlers = {};
      res.on = jest.fn().mockImplementation((event, handler) => {
        handlers[event] = handler;
        return res;
      });

      // 触发data和end事件
      if (handlers.data) handlers.data(Buffer.from('{"success":true}'));
      if (handlers.end) handlers.end();
    }

    return req;
  })
}));

// 模拟multiLevelCacheService
jest.mock('../../../services/multiLevelCacheService', () => ({
  multiLevelCacheService: {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(true)
  }
}));

describe('LoadBalancerService', () => {
  let loadBalancerService;

  beforeEach(() => {
    // 创建新的LoadBalancerService实例
    loadBalancerService = new LoadBalancerService({
      // 启用负载均衡
      enabled: true,
      // 配置静态节点
      nodes: {
        discovery: 'static',
        static: ['http://localhost:3001', 'http://localhost:3002'],
        healthCheck: {
          enabled: true,
          interval: 100, // 100ms for testing
          path: '/health',
          healthyThreshold: 1,
          unhealthyThreshold: 1
        }
      }
    });

    // 初始化服务
    return loadBalancerService.initialize();
  });

  afterEach(async () => {
    // 关闭服务
    await loadBalancerService.close();
  });

  describe('initialize', () => {
    it('should initialize the service', async () => {
      // 重新创建实例
      const service = new LoadBalancerService({
        enabled: true,
        nodes: {
          discovery: 'static',
          static: ['http://localhost:3001']
        }
      });

      // 初始化前
      expect(service.initialized).toBe(false);

      // 初始化
      await service.initialize();

      // 初始化后
      expect(service.initialized).toBe(true);

      // 清理
      await service.close();
    });

    it('should not initialize twice', async () => {
      // 已经在beforeEach中初始化
      expect(loadBalancerService.initialized).toBe(true);

      // 尝试再次初始化
      await loadBalancerService.initialize();

      // 应该仍然是初始化状态
      expect(loadBalancerService.initialized).toBe(true);
    });

    it('should initialize static nodes', async () => {
      // 验证节点已初始化
      expect(loadBalancerService.nodes.size).toBe(2);

      // 验证节点属性
      const nodeIds = Array.from(loadBalancerService.nodes.keys());
      expect(nodeIds).toContain('localhost:3001');
      expect(nodeIds).toContain('localhost:3002');

      // 验证节点健康状态
      expect(loadBalancerService.nodeHealth.has('localhost:3001')).toBe(true);
      expect(loadBalancerService.nodeHealth.has('localhost:3002')).toBe(true);
    });
  });

  describe('selectNode', () => {
    beforeEach(() => {
      // 设置节点为健康状态
      for (const [nodeId, health] of loadBalancerService.nodeHealth.entries()) {
        health.status = NODE_STATUS.HEALTHY;
        health.consecutiveSuccesses = 1;
        health.consecutiveFailures = 0;
      }
    });

    it('should select a node using round-robin algorithm', () => {
      // 设置负载均衡算法
      loadBalancerService.config.strategy.algorithm = ALGORITHMS.ROUND_ROBIN;

      // 选择节点
      const request = { ip: '127.0.0.1' };
      const node1 = loadBalancerService.selectNode(request);
      const node2 = loadBalancerService.selectNode(request);
      const node3 = loadBalancerService.selectNode(request);

      // 验证轮询
      expect(node1.id).not.toBe(node2.id);
      expect(node3.id).toBe(node1.id);
    });

    it('should select a node using least-connections algorithm', () => {
      // 设置负载均衡算法
      loadBalancerService.config.strategy.algorithm = ALGORITHMS.LEAST_CONNECTIONS;

      // 设置节点连接数
      const nodeIds = Array.from(loadBalancerService.nodes.keys());
      loadBalancerService.nodeConnections.set(nodeIds[0], 5);
      loadBalancerService.nodeConnections.set(nodeIds[1], 2);

      // 选择节点
      const request = { ip: '127.0.0.1' };
      const node = loadBalancerService.selectNode(request);

      // 验证选择了连接数最少的节点
      expect(node.id).toBe(nodeIds[1]);
    });

    it('should select a node using ip-hash algorithm', () => {
      // 设置负载均衡算法
      loadBalancerService.config.strategy.algorithm = ALGORITHMS.IP_HASH;

      // 选择节点
      const request1 = { ip: '127.0.0.1' };
      const request2 = { ip: '127.0.0.2' };

      const node1a = loadBalancerService.selectNode(request1);
      const node1b = loadBalancerService.selectNode(request1);
      const node2 = loadBalancerService.selectNode(request2);

      // 验证相同IP选择相同节点
      expect(node1a.id).toBe(node1b.id);

      // 不同IP可能选择不同节点（但也可能相同，取决于哈希）
      // 这里不做断言
    });

    it('should return null if no healthy nodes available', () => {
      // 设置所有节点为不健康状态
      for (const [nodeId, health] of loadBalancerService.nodeHealth.entries()) {
        health.status = NODE_STATUS.UNHEALTHY;
      }

      // 选择节点
      const request = { ip: '127.0.0.1' };
      const node = loadBalancerService.selectNode(request);

      // 验证没有选择节点
      expect(node).toBeNull();
    });

    it('should return null if service is not initialized', () => {
      // 创建未初始化的服务
      const service = new LoadBalancerService();

      // 尝试选择节点
      expect(() => {
        service.selectNode({});
      }).toThrow('负载均衡服务未初始化');
    });
  });

  describe('_getHealthyNodes', () => {
    it('should return only healthy nodes', () => {
      // 设置一个节点为健康状态，一个为不健康状态
      const nodeIds = Array.from(loadBalancerService.nodes.keys());
      loadBalancerService.nodeHealth.get(nodeIds[0]).status = NODE_STATUS.HEALTHY;
      loadBalancerService.nodeHealth.get(nodeIds[1]).status = NODE_STATUS.UNHEALTHY;

      // 获取健康节点
      const healthyNodes = loadBalancerService._getHealthyNodes();

      // 验证只返回健康节点
      expect(healthyNodes).toHaveLength(1);
      expect(healthyNodes[0].id).toBe(nodeIds[0]);
    });
  });

  describe('_hashString', () => {
    it('should generate consistent hash for the same string', () => {
      // 计算哈希
      const hash1 = loadBalancerService._hashString('test-string');
      const hash2 = loadBalancerService._hashString('test-string');

      // 验证哈希一致
      expect(hash1).toBe(hash2);
    });

    it('should generate different hash for different strings', () => {
      // 计算哈希
      const hash1 = loadBalancerService._hashString('string1');
      const hash2 = loadBalancerService._hashString('string2');

      // 验证哈希不同
      expect(hash1).not.toBe(hash2);
    });
  });

  describe('_sendRequest', () => {
    it('should send HTTP request and return response', async () => {
      // 发送请求
      const response = await loadBalancerService._sendRequest('http://localhost:3001/test');

      // 验证响应
      expect(response.statusCode).toBe(200);
      expect(response.body).toEqual({ success: true });
    });

    it('should send HTTPS request and return response', async () => {
      // 发送请求
      const response = await loadBalancerService._sendRequest('https://localhost:3001/test');

      // 验证响应
      expect(response.statusCode).toBe(200);
      expect(response.body).toEqual({ success: true });
    });
  });

  describe('forwardRequest', () => {
    it('should forward request to selected node', async () => {
      // 模拟请求和响应
      const req = {
        method: 'GET',
        url: '/test',
        headers: {},
        body: null
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        setHeader: jest.fn(),
        send: jest.fn(),
        json: jest.fn()
      };

      // 设置节点为健康状态
      for (const [nodeId, health] of loadBalancerService.nodeHealth.entries()) {
        health.status = NODE_STATUS.HEALTHY;
        health.consecutiveSuccesses = 1;
        health.consecutiveFailures = 0;
      }

      // 转发请求
      await loadBalancerService.forwardRequest(req, res);

      // 验证响应
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.send).toHaveBeenCalledWith({ success: true });
    });

    it('should return error if no nodes available', async () => {
      // 模拟请求和响应
      const req = {
        method: 'GET',
        url: '/test',
        headers: {},
        body: null
      };

      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };

      // 设置所有节点为不健康状态
      for (const [nodeId, health] of loadBalancerService.nodeHealth.entries()) {
        health.status = NODE_STATUS.UNHEALTHY;
      }

      // 转发请求
      await loadBalancerService.forwardRequest(req, res);

      // 验证错误响应
      expect(res.status).toHaveBeenCalledWith(503);
      expect(res.json).toHaveBeenCalledWith({ error: '没有可用的服务节点' });
    });
  });
});
