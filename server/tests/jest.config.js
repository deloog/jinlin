/**
 * Jest配置文件
 */
module.exports = {
  // 测试环境
  testEnvironment: 'node',

  // 测试文件匹配模式
  testMatch: [
    '**/tests/**/*.test.js',
    '**/tests/**/*.spec.js'
  ],

  // 忽略的文件和目录
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
    '/coverage/'
  ],

  // 模块映射
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../$1'
  },

  // 模块目录
  moduleDirectories: ['node_modules', '<rootDir>/../'],

  // 覆盖率收集
  collectCoverage: true,
  collectCoverageFrom: [
    'services/**/*.js',
    'controllers/**/*.js',
    'middleware/**/*.js',
    'utils/**/*.js',
    '!**/node_modules/**',
    '!**/tests/**'
  ],

  // 覆盖率报告格式
  coverageReporters: ['text', 'lcov', 'clover', 'html'],

  // 覆盖率阈值
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },

  // 测试超时时间
  testTimeout: 10000,

  // 测试前的设置
  setupFilesAfterEnv: ['./setup.js'],



  // 是否显示每个测试的详细信息
  verbose: true
};
