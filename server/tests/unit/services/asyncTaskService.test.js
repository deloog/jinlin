/**
 * 异步任务服务单元测试
 */
const { AsyncTaskService, TASK_STATUS, TASK_PRIORITY } = require('../../../services/asyncTaskService');
const logger = require('../../../utils/enhancedLogger');

// 模拟configManager
jest.mock('../../../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

describe('AsyncTaskService', () => {
  let asyncTaskService;

  beforeEach(() => {
    // 创建新的AsyncTaskService实例
    asyncTaskService = new AsyncTaskService();

    // 模拟任务处理器
    asyncTaskService.registerHandler('test-task', jest.fn().mockResolvedValue({ success: true }));
    asyncTaskService.registerHandler('failing-task', jest.fn().mockRejectedValue(new Error('Task failed')));

    // 初始化服务
    return asyncTaskService.initialize();
  });

  afterEach(async () => {
    // 关闭服务
    await asyncTaskService.close();
  });

  describe('initialize', () => {
    it('should initialize the service', async () => {
      // 重新创建实例
      const service = new AsyncTaskService();

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
      expect(asyncTaskService.initialized).toBe(true);

      // 尝试再次初始化
      await asyncTaskService.initialize();

      // 应该仍然是初始化状态
      expect(asyncTaskService.initialized).toBe(true);

      // 验证日志
      expect(logger.info).toHaveBeenCalledWith('异步任务处理服务初始化成功');
    });
  });

  describe('registerHandler', () => {
    it('should register a task handler', () => {
      // 注册处理器
      const handler = jest.fn();
      asyncTaskService.registerHandler('new-task', handler);

      // 验证处理器已注册
      expect(asyncTaskService.handlers.has('new-task')).toBe(true);
      expect(asyncTaskService.handlers.get('new-task')).toBe(handler);
    });

    it('should throw error if handler is not a function', () => {
      // 尝试注册非函数处理器
      expect(() => {
        asyncTaskService.registerHandler('invalid-task', 'not-a-function');
      }).toThrow('任务处理器必须是函数');
    });
  });

  describe('unregisterHandler', () => {
    it('should unregister a task handler', () => {
      // 先注册处理器
      const handler = jest.fn();
      asyncTaskService.registerHandler('temp-task', handler);

      // 验证处理器已注册
      expect(asyncTaskService.handlers.has('temp-task')).toBe(true);

      // 取消注册
      const result = asyncTaskService.unregisterHandler('temp-task');

      // 验证结果
      expect(result).toBe(true);
      expect(asyncTaskService.handlers.has('temp-task')).toBe(false);
    });

    it('should return false if handler does not exist', () => {
      // 尝试取消注册不存在的处理器
      const result = asyncTaskService.unregisterHandler('non-existent-task');

      // 验证结果
      expect(result).toBe(false);
    });
  });

  describe('addTask', () => {
    it('should add a task to the queue', async () => {
      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 验证任务ID
      expect(taskId).toBeDefined();
      expect(typeof taskId).toBe('string');

      // 验证任务已添加到队列
      expect(asyncTaskService.tasks.has(taskId)).toBe(true);

      // 验证任务属性
      const task = asyncTaskService.tasks.get(taskId);
      expect(task.type).toBe('test-task');
      expect(task.data).toEqual({ key: 'value' });
      expect(task.status).toBe(TASK_STATUS.PENDING);
      expect(task.priority).toBe(TASK_PRIORITY.NORMAL);
    });

    it('should add a task with custom priority', async () => {
      // 添加高优先级任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' }, {
        priority: TASK_PRIORITY.HIGH
      });

      // 验证任务优先级
      const task = asyncTaskService.tasks.get(taskId);
      expect(task.priority).toBe(TASK_PRIORITY.HIGH);
    });

    it('should throw error if service is not initialized', async () => {
      // 创建未初始化的服务
      const service = new AsyncTaskService();

      // 尝试添加任务
      await expect(service.addTask('test-task', {}))
        .rejects.toThrow('异步任务处理服务未初始化');
    });

    it('should throw error if queue is full', async () => {
      // 修改队列最大长度
      const originalMaxLength = asyncTaskService.config.queue.maxLength;
      asyncTaskService.config.queue.maxLength = 1;

      // 添加一个任务填满队列
      await asyncTaskService.addTask('test-task', { first: true });

      // 尝试添加另一个任务
      await expect(asyncTaskService.addTask('test-task', { second: true }))
        .rejects.toThrow('任务队列已满');

      // 恢复原始配置
      asyncTaskService.config.queue.maxLength = originalMaxLength;
    });
  });

  describe('getTask', () => {
    it('should get a task by ID', async () => {
      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 获取任务
      const task = asyncTaskService.getTask(taskId);

      // 验证任务
      expect(task).toBeDefined();
      expect(task.id).toBe(taskId);
      expect(task.type).toBe('test-task');
      expect(task.data).toEqual({ key: 'value' });
    });

    it('should return null if task does not exist', () => {
      // 获取不存在的任务
      const task = asyncTaskService.getTask('non-existent-task');

      // 验证结果
      expect(task).toBeNull();
    });
  });

  describe('cancelTask', () => {
    it('should cancel a pending task', async () => {
      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 取消任务
      const result = asyncTaskService.cancelTask(taskId);

      // 验证结果
      expect(result).toBe(true);

      // 验证任务状态
      const task = asyncTaskService.getTask(taskId);
      expect(task.status).toBe(TASK_STATUS.CANCELLED);
    });

    it('should return false if task does not exist', () => {
      // 尝试取消不存在的任务
      const result = asyncTaskService.cancelTask('non-existent-task');

      // 验证结果
      expect(result).toBe(false);
    });
  });

  describe('task processing', () => {
    it('should process tasks in the queue', async () => {
      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 等待任务处理完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务状态
      const task = asyncTaskService.getTask(taskId);
      expect(task.status).toBe(TASK_STATUS.COMPLETED);
      expect(task.result).toEqual({ success: true });
    });

    it('should handle task failures and retry', async () => {
      // 修改重试配置
      const originalMaxRetries = asyncTaskService.config.queue.retry.maxRetries;
      asyncTaskService.config.queue.retry.maxRetries = 1;
      asyncTaskService.config.queue.retry.delay = 50;

      // 添加失败任务
      const taskId = await asyncTaskService.addTask('failing-task', { key: 'value' });

      // 等待任务处理和重试
      await new Promise(resolve => setTimeout(resolve, 200));

      // 验证任务状态
      const task = asyncTaskService.getTask(taskId);
      expect(task.status).toBe(TASK_STATUS.FAILED);
      expect(task.error).toBe('Task failed');
      expect(task.retries).toBe(1);

      // 恢复原始配置
      asyncTaskService.config.queue.retry.maxRetries = originalMaxRetries;
    });
  });

  describe('cleanupTasks', () => {
    it('should clean up completed tasks', async () => {
      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 等待任务处理完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务已完成
      const task = asyncTaskService.getTask(taskId);
      expect(task.status).toBe(TASK_STATUS.COMPLETED);

      // 修改任务结束时间以模拟过期
      task.endTime = Date.now() - 25 * 60 * 60 * 1000; // 25小时前

      // 清理任务
      const count = asyncTaskService.cleanupTasks(24 * 60 * 60 * 1000); // 24小时

      // 验证清理结果
      expect(count).toBe(1);
      expect(asyncTaskService.tasks.has(taskId)).toBe(false);
    });
  });

  describe('pause and resume', () => {
    it('should pause and resume task processing', async () => {
      // 暂停任务处理
      asyncTaskService.pause();
      expect(asyncTaskService.paused).toBe(true);

      // 添加任务
      const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });

      // 等待一段时间
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务未处理
      const task1 = asyncTaskService.getTask(taskId);
      expect(task1.status).toBe(TASK_STATUS.PENDING);

      // 恢复任务处理
      asyncTaskService.resume();
      expect(asyncTaskService.paused).toBe(false);

      // 等待任务处理完成
      await new Promise(resolve => setTimeout(resolve, 100));

      // 验证任务已处理
      const task2 = asyncTaskService.getTask(taskId);
      expect(task2.status).toBe(TASK_STATUS.COMPLETED);
    });
  });
});
