/**
 * 分布式追踪中间件单元测试
 */
const { createTracingMiddleware } = require('../../mocks/tracingMiddleware.mock');
const { tracingService } = require('../../mocks/tracingService.mock');
const logger = require('../../../utils/enhancedLogger');

// 模拟请求和响应
const createMockReq = (path = '/test') => ({
  path,
  method: 'GET',
  originalUrl: path,
  ip: '127.0.0.1',
  get: jest.fn().mockImplementation(header => {
    const headers = {
      'host': 'localhost:3000',
      'user-agent': 'jest-test'
    };
    return headers[header];
  })
});

const createMockRes = () => {
  const res = {
    on: jest.fn(),
    get: jest.fn(),
    statusCode: 200,
    _eventHandlers: {},
    on: function(event, handler) {
      this._eventHandlers[event] = handler;
      return this;
    },
    // 模拟响应完成
    finish: function() {
      if (this._eventHandlers.finish) {
        this._eventHandlers.finish();
      }
    }
  };
  return res;
};

describe('TracingMiddleware', () => {
  beforeEach(() => {
    // 重置模拟
    jest.clearAllMocks();

    // 初始化追踪服务
    tracingService.initialized = true;
    tracingService.config.enabled = true;
    tracingService.activeTraces = new Map();
    tracingService.completedTraces = [];
  });

  describe('createTracingMiddleware', () => {
    it('should create tracing middleware', () => {
      // 创建中间件
      const middleware = createTracingMiddleware();

      // 验证中间件是函数
      expect(typeof middleware).toBe('function');
    });

    it('should add trace context to request', () => {
      // 创建中间件
      const middleware = createTracingMiddleware();

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      middleware(req, res, next);

      // 验证追踪上下文已添加到请求
      expect(req.trace).toBeDefined();
      expect(req.traceId).toBeDefined();
      expect(req.requestSpanId).toBeDefined();
      expect(typeof req.createSpan).toBe('function');
      expect(typeof req.endSpan).toBe('function');

      // 验证next已调用
      expect(next).toHaveBeenCalled();
    });

    it('should skip if tracing is disabled', () => {
      // 禁用追踪
      tracingService.config.enabled = false;

      // 创建中间件
      const middleware = createTracingMiddleware();

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      middleware(req, res, next);

      // 验证没有创建追踪
      expect(req.trace).toBeUndefined();

      // 验证next已调用
      expect(next).toHaveBeenCalled();
    });

    it('should handle route matching', () => {
      // 创建带路由匹配的中间件
      const middleware = createTracingMiddleware({
        routes: {
          enabled: true,
          include: ['/api/*'],
          exclude: ['/api/health']
        }
      });

      // 模拟请求和响应
      const req1 = createMockReq('/api/test');
      const req2 = createMockReq('/api/health');
      const req3 = createMockReq('/other');

      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      middleware(req1, res, next); // 应该匹配
      expect(req1.trace).toBeDefined();

      next.mockClear();
      middleware(req2, res, next); // 应该排除
      expect(req2.trace).toBeUndefined();

      next.mockClear();
      middleware(req3, res, next); // 应该不匹配
      expect(req3.trace).toBeUndefined();
    });

    it('should complete trace when response finishes', () => {
      // 创建中间件
      const middleware = createTracingMiddleware();

      // 模拟请求和响应
      const req = createMockReq();
      const res = createMockRes();
      const next = jest.fn();

      // 调用中间件
      middleware(req, res, next);

      // 获取追踪ID
      const traceId = req.traceId;

      // 模拟响应完成
      res.finish();

      // 验证追踪已完成
      expect(tracingService.activeTraces.has(traceId)).toBe(false);
      expect(tracingService.completedTraces.length).toBe(1);
    });
  });
});
