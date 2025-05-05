/**
 * 测试服务单元测试
 */
const { TestService } = require('../../../services/testService');

describe('TestService', () => {
  let testService;
  
  beforeEach(() => {
    testService = new TestService();
  });
  
  describe('initialize', () => {
    it('should initialize the service', async () => {
      expect(testService.initialized).toBe(false);
      
      await testService.initialize();
      
      expect(testService.initialized).toBe(true);
    });
  });
  
  describe('set and get', () => {
    it('should set and get a value', async () => {
      await testService.initialize();
      
      await testService.set('test-key', 'test-value');
      
      const value = await testService.get('test-key');
      
      expect(value).toBe('test-value');
    });
    
    it('should return null for non-existent key', async () => {
      await testService.initialize();
      
      const value = await testService.get('non-existent');
      
      expect(value).toBeNull();
    });
  });
  
  describe('close', () => {
    it('should close the service', async () => {
      await testService.initialize();
      expect(testService.initialized).toBe(true);
      
      await testService.close();
      
      expect(testService.initialized).toBe(false);
    });
  });
});
