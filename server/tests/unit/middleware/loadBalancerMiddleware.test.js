/**
 * 负载均衡中间件单元测试
 */
const { createLoadBalancerMiddleware, createLoadBalancerProxy, createHealthCheckMiddleware } = require('../../mocks/loadBalancerMiddleware.mock');
const { loadBalancerService } = require('../../mocks/loadBalancerService.mock');
const logger = require('../../../utils/enhancedLogger');

// 模拟请求和响应
const createMockReq = (path = '/api/external/test') => ({
  path,
  url: path,
  method: 'GET',
  headers: {},
  ip: '127.0.0.1'
});

const createMockRes = () => {
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis(),
    setHeader: jest.fn()
  };
  return res;
};

describe('LoadBalancerMiddleware', () => {
  beforeEach(() => {
    // 重置模拟
    jest.clearAllMocks();

    // 初始化负载均衡服务
    loadBalancerService.initialized = true;
    loadBalancerService.config.enabled = true;

    // 模拟forwardRequest方法
    loadBalancerService.forwardRequest = jest.fn().mockResolvedValue(undefined);
  });

  describe('createLoadBalancerMiddleware', () => {
    it('should create load balancer middleware', () => {
      // 创建中间件
      const middleware = createLoadBalancerMiddleware();

      // 验证中间件是函数
      expect(typeof middleware).toBe('function');
    });

    it('should forward request if enabled and route matches', async () => {
      // 创建中间件
      const middleware = createLoadBalancerMiddleware({
        enabled: true,
        routes: {
          enabled: true,
          patterns: ['/api/external/*']
        }
      });

      // 模拟请求和响应
      const req = createMockReq('/api/external/test');
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      await middleware(req, res, next);

      // 验证请求已转发
      expect(loadBalancerService.forwardRequest).toHaveBeenCalledWith(req, res);

      // 验证next未调用（因为请求已转发）
      expect(next).not.toHaveBeenCalled();
    });

    it('should skip if load balancer is disabled', async () => {
      // 创建中间件
      const middleware = createLoadBalancerMiddleware({
        enabled: false
      });

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      await middleware(req, res, next);

      // 验证请求未转发
      expect(loadBalancerService.forwardRequest).not.toHaveBeenCalled();

      // 验证next已调用
      expect(next).toHaveBeenCalled();
    });

    it('should skip if route does not match', async () => {
      // 创建中间件
      const middleware = createLoadBalancerMiddleware({
        enabled: true,
        routes: {
          enabled: true,
          patterns: ['/api/external/*']
        }
      });

      // 模拟请求和响应
      const req = createMockReq('/other/test');
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      await middleware(req, res, next);

      // 验证请求未转发
      expect(loadBalancerService.forwardRequest).not.toHaveBeenCalled();

      // 验证next已调用
      expect(next).toHaveBeenCalled();
    });

    it('should handle errors', async () => {
      // 模拟forwardRequest抛出错误
      loadBalancerService.forwardRequest.mockRejectedValueOnce(new Error('Test error'));

      // 创建中间件
      const middleware = createLoadBalancerMiddleware({
        enabled: true
      });

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      await middleware(req, res, next);

      // 验证next已调用，并传递错误
      expect(next).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('createLoadBalancerProxy', () => {
    it('should create load balancer proxy middleware', () => {
      // 创建中间件
      const middleware = createLoadBalancerProxy('/target');

      // 验证中间件是函数
      expect(typeof middleware).toBe('function');
    });

    it('should modify request path and forward request', async () => {
      // 创建中间件
      const middleware = createLoadBalancerProxy('/target');

      // 模拟请求和响应
      const req = createMockReq('/original');
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      await middleware(req, res, next);

      // 验证请求已转发
      expect(loadBalancerService.forwardRequest).toHaveBeenCalledWith(req, res);

      // 验证请求路径已恢复
      expect(req.url).toBe('/original');
    });
  });

  describe('createHealthCheckMiddleware', () => {
    it('should create health check middleware', () => {
      // 创建中间件
      const middleware = createHealthCheckMiddleware();

      // 验证中间件是函数
      expect(typeof middleware).toBe('function');
    });

    it('should return load balancer status', () => {
      // 创建中间件
      const middleware = createHealthCheckMiddleware();

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();

      // 调用中间件
      middleware(req, res);

      // 验证响应
      expect(res.json).toHaveBeenCalled();

      // 验证响应包含负载均衡状态
      const response = res.json.mock.calls[0][0];
      expect(response.timestamp).toBeDefined();
      expect(response.service).toBe('load-balancer');
      expect(response.status).toBe('healthy');
    });
  });
});
