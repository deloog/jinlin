/**
 * Jest测试设置文件
 */

// 设置测试环境变量
process.env.NODE_ENV = 'test';
process.env.PORT = '3001';
process.env.DB_HOST = 'localhost';
process.env.DB_USER = 'test';
process.env.DB_PASSWORD = 'test';
process.env.DB_NAME = 'reminder_test';
process.env.JWT_SECRET = 'test_jwt_secret';
process.env.REFRESH_TOKEN_SECRET = 'test_refresh_token_secret';

// 增加测试超时时间
jest.setTimeout(10000);

// 全局模拟
jest.mock('../utils/enhancedLogger', () => ({
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn(),
  http: jest.fn()
}));

// 模拟配置服务
jest.mock('../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

// 模拟app配置
jest.mock('../config/app', () => ({
  app: {
    name: 'test-app',
    version: '1.0.0',
    loadBalancer: {
      enabled: true
    },
    tracing: {
      enabled: true
    }
  }
}));

// 清理所有模拟
afterEach(() => {
  jest.clearAllMocks();
});
