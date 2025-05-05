# 测试指南

本文档提供了如何运行和编写测试的指南，以确保代码质量和功能正确性。

## 测试结构

测试目录结构如下：

```
tests/
├── jest.config.js        # Jest配置文件
├── setup.js              # 测试设置文件
├── unit/                 # 单元测试
│   ├── services/         # 服务单元测试
│   ├── controllers/      # 控制器单元测试
│   └── middleware/       # 中间件单元测试
└── integration/          # 集成测试
    └── services/         # 服务集成测试
```

## 运行测试

### 运行所有测试

```bash
# Linux/Mac
npm test

# Windows
npm run test:win
```

### 运行单元测试

```bash
# Linux/Mac
npm run test:unit

# Windows
npm run test:win-unit
```

### 运行集成测试

```bash
# Linux/Mac
npm run test:integration

# Windows
npm run test:win-integration
```

### 生成测试覆盖率报告

```bash
# Linux/Mac
npm run test:coverage

# Windows
npm run test:win-coverage
```

覆盖率报告将生成在 `coverage/` 目录中。

## 编写测试

### 单元测试

单元测试应该测试单个组件（如服务、控制器或中间件）的功能，并模拟其依赖项。

示例：

```javascript
// 测试异步任务服务
describe('AsyncTaskService', () => {
  let asyncTaskService;
  
  beforeEach(() => {
    // 创建新的AsyncTaskService实例
    asyncTaskService = new AsyncTaskService();
    
    // 初始化服务
    return asyncTaskService.initialize();
  });
  
  afterEach(async () => {
    // 关闭服务
    await asyncTaskService.close();
  });
  
  it('should add a task to the queue', async () => {
    // 添加任务
    const taskId = await asyncTaskService.addTask('test-task', { key: 'value' });
    
    // 验证任务已添加
    expect(asyncTaskService.tasks.has(taskId)).toBe(true);
  });
});
```

### 集成测试

集成测试应该测试多个组件之间的交互，确保它们能够协同工作。

示例：

```javascript
// 测试缓存和异步任务服务的集成
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
    const taskId = await asyncTaskService.addTask('cache-test-task', { key: 'test-key', value: 5 });
    
    // 等待任务完成
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // 验证任务结果
    const result = asyncTaskService.getTaskResult(taskId);
    expect(result).toEqual({ value: 10 });
  });
});
```

## 模拟依赖

使用Jest的模拟功能来隔离被测试的组件：

```javascript
// 模拟日志服务
jest.mock('../utils/enhancedLogger', () => ({
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn()
}));

// 模拟配置管理器
jest.mock('../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));
```

## 测试覆盖率目标

- 分支覆盖率：70%
- 函数覆盖率：80%
- 行覆盖率：80%
- 语句覆盖率：80%

## 最佳实践

1. 每个测试应该只测试一个功能点
2. 使用描述性的测试名称
3. 在测试前后正确设置和清理环境
4. 模拟外部依赖以隔离被测试的组件
5. 使用断言来验证预期结果
6. 测试正常路径和错误路径
7. 保持测试简单和可维护
