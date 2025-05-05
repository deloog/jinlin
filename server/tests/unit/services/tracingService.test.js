/**
 * 分布式追踪服务单元测试
 */
const { TracingService, TraceContext } = require('../../mocks/tracingService.mock');
const logger = require('../../../utils/enhancedLogger');

// 模拟configManager
jest.mock('../../../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

describe('TracingService', () => {
  let tracingService;

  beforeEach(() => {
    // 创建新的TracingService实例
    tracingService = new TracingService({
      // 设置100%采样率以简化测试
      samplingRate: 1.0,
      // 禁用导出器以简化测试
      exporters: {
        log: { enabled: false },
        zipkin: { enabled: false },
        jaeger: { enabled: false }
      }
    });

    // 初始化服务
    return tracingService.initialize();
  });

  afterEach(async () => {
    // 关闭服务
    await tracingService.close();
  });

  describe('initialize', () => {
    it('should initialize the service', async () => {
      // 重新创建实例
      const service = new TracingService({
        samplingRate: 1.0,
        exporters: {
          log: { enabled: false },
          zipkin: { enabled: false },
          jaeger: { enabled: false }
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
      expect(tracingService.initialized).toBe(true);

      // 尝试再次初始化
      await tracingService.initialize();

      // 应该仍然是初始化状态
      expect(tracingService.initialized).toBe(true);
    });
  });

  describe('createTrace', () => {
    it('should create a trace', () => {
      // 创建追踪
      const trace = tracingService.createTrace({
        tags: { test: 'value' }
      });

      // 验证追踪
      expect(trace).toBeInstanceOf(TraceContext);
      expect(trace.traceId).toBeDefined();
      expect(trace.tags.test).toBe('value');

      // 验证追踪已添加到活动追踪
      expect(tracingService.activeTraces.has(trace.traceId)).toBe(true);
    });

    it('should throw error if service is not initialized', () => {
      // 创建未初始化的服务
      const service = new TracingService();

      // 尝试创建追踪
      expect(() => {
        service.createTrace();
      }).toThrow('分布式追踪服务未初始化');
    });
  });

  describe('getTrace', () => {
    it('should get a trace by ID', () => {
      // 创建追踪
      const trace = tracingService.createTrace();

      // 获取追踪
      const retrievedTrace = tracingService.getTrace(trace.traceId);

      // 验证追踪
      expect(retrievedTrace).toBe(trace);
    });

    it('should return null if trace does not exist', () => {
      // 获取不存在的追踪
      const trace = tracingService.getTrace('non-existent-trace');

      // 验证结果
      expect(trace).toBeNull();
    });
  });

  describe('completeTrace', () => {
    it('should complete a trace', () => {
      // 创建追踪
      const trace = tracingService.createTrace();

      // 完成追踪
      const completedTrace = tracingService.completeTrace(trace.traceId);

      // 验证追踪已完成
      expect(completedTrace.completed).toBe(true);
      expect(completedTrace.endTime).toBeDefined();

      // 验证追踪已从活动追踪中移除
      expect(tracingService.activeTraces.has(trace.traceId)).toBe(false);

      // 验证追踪已添加到已完成追踪
      expect(tracingService.completedTraces).toContain(completedTrace);
    });

    it('should return null if trace does not exist', () => {
      // 尝试完成不存在的追踪
      const completedTrace = tracingService.completeTrace('non-existent-trace');

      // 验证结果
      expect(completedTrace).toBeNull();
    });
  });

  describe('extractTraceContext', () => {
    it('should extract trace context from request headers', () => {
      // 模拟请求对象
      const req = {
        get: (header) => {
          const headers = {
            'x-trace-id': 'test-trace-id',
            'x-span-id': 'test-span-id',
            'x-parent-span-id': 'test-parent-span-id',
            'host': 'test-host',
            'user-agent': 'test-agent'
          };
          return headers[header];
        },
        method: 'GET',
        originalUrl: '/test'
      };

      // 启用分布式追踪
      tracingService.config.distributed = true;

      // 提取追踪上下文
      const context = tracingService.extractTraceContext(req);

      // 验证上下文
      expect(context.traceId).toBe('test-trace-id');
      expect(context.rootSpanId).toBe('test-span-id');
      expect(context.parentSpanId).toBe('test-parent-span-id');
      expect(context.tags['http.method']).toBe('GET');
      expect(context.tags['http.url']).toBe('/test');
      expect(context.tags['http.host']).toBe('test-host');
      expect(context.tags['http.user_agent']).toBe('test-agent');
    });

    it('should return empty object if distributed tracing is disabled', () => {
      // 模拟请求对象
      const req = {
        get: (header) => {
          const headers = {
            'x-trace-id': 'test-trace-id'
          };
          return headers[header];
        },
        method: 'GET',
        originalUrl: '/test'
      };

      // 禁用分布式追踪
      tracingService.config.distributed = false;

      // 提取追踪上下文
      const context = tracingService.extractTraceContext(req);

      // 验证上下文为空对象
      expect(context).toEqual({});
    });
  });

  describe('injectTraceContext', () => {
    it('should inject trace context into headers', () => {
      // 创建追踪
      const trace = tracingService.createTrace();

      // 创建span
      const span = trace.createSpan('test-span');

      // 启用分布式追踪
      tracingService.config.distributed = true;

      // 注入追踪上下文
      const headers = {};
      const injectedHeaders = tracingService.injectTraceContext(headers, trace, span.id);

      // 验证头部
      expect(injectedHeaders[tracingService.config.headers.traceId]).toBe(trace.traceId);
      expect(injectedHeaders[tracingService.config.headers.spanId]).toBe(span.id);
    });

    it('should return original headers if distributed tracing is disabled', () => {
      // 创建追踪
      const trace = tracingService.createTrace();

      // 创建span
      const span = trace.createSpan('test-span');

      // 禁用分布式追踪
      tracingService.config.distributed = false;

      // 注入追踪上下文
      const headers = { 'original': 'value' };
      const injectedHeaders = tracingService.injectTraceContext(headers, trace, span.id);

      // 验证头部未修改
      expect(injectedHeaders).toEqual({ 'original': 'value' });
    });
  });

  describe('getTracingStats', () => {
    it('should get tracing statistics', () => {
      // 创建并完成一些追踪
      const trace1 = tracingService.createTrace();
      tracingService.completeTrace(trace1.traceId);

      const trace2 = tracingService.createTrace();
      tracingService.completeTrace(trace2.traceId);

      // 创建一个活动追踪
      tracingService.createTrace();

      // 获取追踪统计
      const stats = tracingService.getTracingStats();

      // 验证统计
      expect(stats.traces.active).toBe(1);
      expect(stats.traces.completed).toBe(2);
      expect(stats.traces.created).toBe(3);
      expect(stats.traces.sampled).toBe(3);
    });
  });
});

describe('TraceContext', () => {
  let traceContext;

  beforeEach(() => {
    // 创建新的TraceContext实例
    traceContext = new TraceContext({
      tags: { test: 'value' }
    });
  });

  describe('createSpan', () => {
    it('should create a span', () => {
      // 创建span
      const span = traceContext.createSpan('test-span', {
        tags: { span: 'tag' }
      });

      // 验证span
      expect(span.id).toBeDefined();
      expect(span.name).toBe('test-span');
      expect(span.traceId).toBe(traceContext.traceId);
      expect(span.tags.span).toBe('tag');
      expect(span.status).toBe('active');

      // 验证span已添加到spans映射
      expect(traceContext.spans.has(span.id)).toBe(true);

      // 验证activeSpan已设置
      expect(traceContext.activeSpan).toBe(span);
    });

    it('should set parent span ID if active span exists', () => {
      // 创建父span
      const parentSpan = traceContext.createSpan('parent-span');

      // 创建子span
      const childSpan = traceContext.createSpan('child-span');

      // 验证父子关系
      expect(childSpan.parentId).toBe(parentSpan.id);
    });
  });

  describe('endSpan', () => {
    it('should end a span', () => {
      // 创建span
      const span = traceContext.createSpan('test-span');

      // 结束span
      const endedSpan = traceContext.endSpan(span.id);

      // 验证span已结束
      expect(endedSpan.endTime).toBeDefined();
      expect(endedSpan.duration).toBeDefined();
      expect(endedSpan.status).toBe('completed');
    });

    it('should return null if span does not exist', () => {
      // 尝试结束不存在的span
      const endedSpan = traceContext.endSpan('non-existent-span');

      // 验证结果
      expect(endedSpan).toBeNull();
    });
  });

  describe('addSpanEvent', () => {
    it('should add an event to a span', () => {
      // 创建span
      const span = traceContext.createSpan('test-span');

      // 添加事件
      const event = traceContext.addSpanEvent(span.id, 'test-event', {
        key: 'value'
      });

      // 验证事件
      expect(event.name).toBe('test-event');
      expect(event.timestamp).toBeDefined();
      expect(event.attributes.key).toBe('value');

      // 验证事件已添加到span
      expect(span.events).toContain(event);
    });
  });

  describe('setSpanTag', () => {
    it('should set a tag on a span', () => {
      // 创建span
      const span = traceContext.createSpan('test-span');

      // 设置标签
      const taggedSpan = traceContext.setSpanTag(span.id, 'tag-key', 'tag-value');

      // 验证标签
      expect(taggedSpan.tags['tag-key']).toBe('tag-value');
    });
  });

  describe('setSpanStatus', () => {
    it('should set status on a span', () => {
      // 创建span
      const span = traceContext.createSpan('test-span');

      // 设置状态
      const statusSpan = traceContext.setSpanStatus(span.id, 'error', 'Error message');

      // 验证状态
      expect(statusSpan.status).toBe('error');
      expect(statusSpan.tags.statusMessage).toBe('Error message');
    });
  });

  describe('complete', () => {
    it('should complete the trace context', () => {
      // 创建一些span
      const span1 = traceContext.createSpan('span1');
      const span2 = traceContext.createSpan('span2');

      // 结束一个span
      traceContext.endSpan(span1.id);

      // 完成追踪上下文
      const completedContext = traceContext.complete();

      // 验证上下文已完成
      expect(completedContext.completed).toBe(true);
      expect(completedContext.endTime).toBeDefined();

      // 验证所有span已结束
      expect(traceContext.spans.get(span1.id).status).toBe('completed');
      expect(traceContext.spans.get(span2.id).status).toBe('completed');
    });
  });

  describe('getData', () => {
    it('should get trace context data', () => {
      // 创建span
      const span = traceContext.createSpan('test-span');

      // 结束span
      traceContext.endSpan(span.id);

      // 完成追踪上下文
      traceContext.complete();

      // 获取数据
      const data = traceContext.getData();

      // 验证数据
      expect(data.traceId).toBe(traceContext.traceId);
      expect(data.rootSpanId).toBe(span.id);
      expect(data.completed).toBe(true);
      expect(data.tags.test).toBe('value');
      expect(data.spans).toHaveLength(1);
      expect(data.spans[0].id).toBe(span.id);
    });
  });
});
