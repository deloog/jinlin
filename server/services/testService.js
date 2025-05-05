/**
 * 测试服务
 */
class TestService {
  constructor() {
    this.initialized = false;
    this.data = new Map();
  }
  
  async initialize() {
    this.initialized = true;
    return true;
  }
  
  async close() {
    this.initialized = false;
    return true;
  }
  
  async set(key, value) {
    this.data.set(key, value);
    return true;
  }
  
  async get(key) {
    return this.data.get(key) || null;
  }
}

const testService = new TestService();

module.exports = {
  TestService,
  testService
};
