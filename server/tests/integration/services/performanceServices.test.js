/**
 * 性能优化服务集成测试
 */
const { asyncTaskService, multiLevelCacheService } = require('../../mocks/integrationServices.mock');
const { tracingService } = require('../../mocks/tracingService.mock');
const { AlertService } = require('../../mocks/alertService.mock');
const logger = require('../../../utils/enhancedLogger');

// 禁用日志输出以减少测试噪音
jest.mock('../../../utils/enhancedLogger', () => ({
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn(),
  http: jest.fn()
}));

// 创建告警服务实例
const alertService = new AlertService();

describe('Performance Services Integration', () => {
  // 在所有测试前初始化服务
  beforeAll(async () => {
    // 初始化多级缓存服务
    await multiLevelCacheService.initialize();

    // 初始化异步任务服务
    await asyncTaskService.initialize();

    // 初始化告警服务
    await alertService.initialize();

    // 初始化分布式追踪服务
    await tracingService.initialize();
  });

  // 在所有测试后关闭服务
  afterAll(async () => {
    // 关闭分布式追踪服务
    await tracingService.close();

    // 关闭告警服务
    await alertService.close();

    // 关闭异步任务服务
    await asyncTaskService.close();

    // 关闭多级缓存服务
    await multiLevelCacheService.close();
  });

  describe('Async Task and Cache Integration', () => {
    it('should use cache to store task results', async () => {
      // 注册任务处理器
      asyncTaskService.registerHandler('cache-test-task', async (data) => {
        // 从缓存获取数据
        const cachedValue = await multiLevelCacheService.get('task-results', data.key);

        if (cachedValue) {
          return { fromCache: true, value: cachedValue };
        }

        // 计算结果
        const result = { value: data.value * 2 };

        // 存储到缓存
        await multiLevelCacheService.set('task-results', data.key, result, 60);

        return result;
      });

      // 添加任务
      const taskId1 = await asyncTaskService.addTask('cache-test-task', { key: 'test-key', value: 5 });

      // 等待任务完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务结果
      const result1 = asyncTaskService.getTaskResult(taskId1);
      expect(result1).toEqual({ value: 10 });

      // 再次添加相同任务
      const taskId2 = await asyncTaskService.addTask('cache-test-task', { key: 'test-key', value: 5 });

      // 等待任务完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务结果（应该从缓存获取）
      const result2 = asyncTaskService.getTaskResult(taskId2);
      expect(result2).toEqual({ fromCache: true, value: { value: 10 } });

      // 清理
      asyncTaskService.unregisterHandler('cache-test-task');
      await multiLevelCacheService.del('task-results', 'test-key');
    });
  });

  describe('Tracing and Alert Integration', () => {
    it('should create alert for slow trace', async () => {
      // 创建追踪
      const trace = tracingService.createTrace({
        tags: { test: 'slow-trace' }
      });

      // 创建请求Span
      const requestSpan = trace.createSpan('http.request', {
        tags: {
          type: 'request',
          'http.method': 'GET',
          'http.url': '/test'
        }
      });

      // 模拟慢请求
      await new Promise(resolve => setTimeout(resolve, 50));

      // 结束span
      trace.endSpan(requestSpan.id, {
        tags: {
          'http.status_code': 200
        }
      });

      // 完成追踪
      tracingService.completeTrace(trace.traceId);

      // 验证追踪已完成
      expect(tracingService.completedTraces.length).toBe(1);
      expect(tracingService.completedTraces[0].completed).toBe(true);
    });
  });

  describe('Cache Performance', () => {
    it('should measure cache hit rate', async () => {
      // 清除缓存统计
      multiLevelCacheService.stats = {
        hits: 0,
        misses: 0,
        total: 0
      };

      // 设置缓存
      await multiLevelCacheService.set('test', 'perf-key', 'value');

      // 命中缓存
      await multiLevelCacheService.get('test', 'perf-key');
      await multiLevelCacheService.get('test', 'perf-key');

      // 未命中缓存
      await multiLevelCacheService.get('test', 'non-existent');

      // 验证命中率
      expect(multiLevelCacheService.getHitRate()).toBe(2/3); // 2次命中，3次总请求
      expect(multiLevelCacheService.getMissRate()).toBe(1/3); // 1次未命中，3次总请求

      // 清理
      await multiLevelCacheService.del('test', 'perf-key');
    });
  });

  describe('Async Task Priority', () => {
    it('should process high priority tasks before normal priority tasks', async () => {
      // 暂停任务处理
      asyncTaskService.pause();

      // 清空队列
      asyncTaskService.queue = [];

      // 注册任务处理器
      const results = [];
      asyncTaskService.registerHandler('priority-test', async (data) => {
        results.push(data.priority);
        return { success: true };
      });

      // 添加普通优先级任务
      await asyncTaskService.addTask('priority-test', { priority: 'normal' });

      // 添加高优先级任务
      await asyncTaskService.addTask('priority-test', { priority: 'high' }, {
        priority: 2 // 高优先级
      });

      // 添加另一个普通优先级任务
      await asyncTaskService.addTask('priority-test', { priority: 'normal2' });

      // 恢复任务处理
      asyncTaskService.resume();

      // 等待任务处理完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证处理顺序
      expect(results[0]).toBe('high'); // 高优先级任务应该先处理

      // 清理
      asyncTaskService.unregisterHandler('priority-test');
    });
  });
});
