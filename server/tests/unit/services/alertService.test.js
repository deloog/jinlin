/**
 * 告警服务单元测试
 */
const { AlertService } = require('../../mocks/alertService.mock');
const logger = require('../../../utils/enhancedLogger');

// 模拟configManager
jest.mock('../../../services/configService', () => ({
  configManager: {
    registerSchema: jest.fn(),
    get: jest.fn()
  }
}));

// 模拟asyncTaskService
jest.mock('../../../services/asyncTaskService', () => ({
  asyncTaskService: {
    registerHandler: jest.fn(),
    addTask: jest.fn().mockResolvedValue('task-id')
  }
}));

describe('AlertService', () => {
  let alertService;

  beforeEach(() => {
    // 创建新的AlertService实例
    alertService = new AlertService({
      // 禁用持久化以简化测试
      persistence: {
        enabled: false
      },
      // 配置告警级别
      levels: {
        info: {
          priority: 0,
          autoResolve: true,
          autoResolveTimeout: 100 // 100ms for testing
        },
        critical: {
          priority: 3,
          autoResolve: false,
          autoEscalate: true,
          escalateTimeout: 100 // 100ms for testing
        }
      }
    });

    // 初始化服务
    return alertService.initialize();
  });

  afterEach(async () => {
    // 关闭服务
    await alertService.close();
  });

  describe('initialize', () => {
    it('should initialize the service', async () => {
      // 重新创建实例
      const service = new AlertService({
        persistence: { enabled: false }
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
      expect(alertService.initialized).toBe(true);

      // 尝试再次初始化
      await alertService.initialize();

      // 应该仍然是初始化状态
      expect(alertService.initialized).toBe(true);
    });
  });

  describe('addAlert', () => {
    it('should add an alert', () => {
      // 添加告警
      const alertId = alertService.addAlert({
        type: 'test-alert',
        level: 'info',
        message: 'Test alert message'
      });

      // 验证告警ID
      expect(alertId).toBeDefined();
      expect(typeof alertId).toBe('string');

      // 验证告警已添加
      expect(alertService.activeAlerts.has(alertId)).toBe(true);

      // 验证告警属性
      const alert = alertService.getAlert(alertId);
      expect(alert.type).toBe('test-alert');
      expect(alert.level).toBe('info');
      expect(alert.message).toBe('Test alert message');
    });

    it('should use default level if invalid level provided', () => {
      // 添加带无效级别的告警
      const alertId = alertService.addAlert({
        type: 'test-alert',
        level: 'invalid-level',
        message: 'Test alert message'
      });

      // 验证告警级别已设为默认值
      const alert = alertService.getAlert(alertId);
      expect(alert.level).toBe('info');
    });

    it('should throw error if service is not initialized', () => {
      // 创建未初始化的服务
      const service = new AlertService();

      // 尝试添加告警
      expect(() => {
        service.addAlert({
          type: 'test-alert',
          level: 'info',
          message: 'Test alert message'
        });
      }).toThrow('告警服务未初始化');
    });
  });

  describe('resolveAlert', () => {
    it('should resolve an active alert', () => {
      // 添加告警
      const alertId = alertService.addAlert({
        type: 'test-alert',
        level: 'info',
        message: 'Test alert message'
      });

      // 解决告警
      const result = alertService.resolveAlert(alertId, {
        reason: 'test',
        message: 'Test resolution'
      });

      // 验证结果
      expect(result).toBe(true);

      // 验证告警已从活动告警中移除
      expect(alertService.activeAlerts.has(alertId)).toBe(false);

      // 验证告警已添加到已解决告警
      const resolvedAlert = alertService.getAlert(alertId);
      expect(resolvedAlert).toBeDefined();
      expect(resolvedAlert.resolved).toBe(true);
      expect(resolvedAlert.resolution.reason).toBe('test');
      expect(resolvedAlert.resolution.message).toBe('Test resolution');
    });

    it('should return false if alert does not exist', () => {
      // 尝试解决不存在的告警
      const result = alertService.resolveAlert('non-existent-alert');

      // 验证结果
      expect(result).toBe(false);
    });
  });

  describe('getAlert', () => {
    it('should get an alert by ID', () => {
      // 添加告警
      const alertId = alertService.addAlert({
        type: 'test-alert',
        level: 'info',
        message: 'Test alert message'
      });

      // 获取告警
      const alert = alertService.getAlert(alertId);

      // 验证告警
      expect(alert).toBeDefined();
      expect(alert.id).toBe(alertId);
      expect(alert.type).toBe('test-alert');
      expect(alert.message).toBe('Test alert message');
    });

    it('should return null if alert does not exist', () => {
      // 获取不存在的告警
      const alert = alertService.getAlert('non-existent-alert');

      // 验证结果
      expect(alert).toBeNull();
    });
  });

  describe('getActiveAlerts', () => {
    it('should get all active alerts', () => {
      // 添加多个告警
      const alertId1 = alertService.addAlert({
        type: 'test-alert-1',
        level: 'info',
        message: 'Test alert 1'
      });

      const alertId2 = alertService.addAlert({
        type: 'test-alert-2',
        level: 'warning',
        message: 'Test alert 2'
      });

      // 获取活动告警
      const activeAlerts = alertService.getActiveAlerts();

      // 验证活动告警
      expect(activeAlerts).toHaveLength(2);
      expect(activeAlerts.find(a => a.id === alertId1)).toBeDefined();
      expect(activeAlerts.find(a => a.id === alertId2)).toBeDefined();
    });
  });

  describe('getResolvedAlerts', () => {
    it('should get resolved alerts with limit', () => {
      // 添加并解决多个告警
      const alertIds = [];
      for (let i = 0; i < 5; i++) {
        const alertId = alertService.addAlert({
          type: `test-alert-${i}`,
          level: 'info',
          message: `Test alert ${i}`
        });
        alertIds.push(alertId);
        alertService.resolveAlert(alertId);
      }

      // 获取已解决告警（限制为3个）
      const resolvedAlerts = alertService.getResolvedAlerts(3);

      // 验证已解决告警
      expect(resolvedAlerts).toHaveLength(3);
    });
  });

  describe('getAlertStats', () => {
    it('should get alert statistics', () => {
      // 添加多个不同级别的告警
      alertService.addAlert({
        type: 'test-alert-1',
        level: 'info',
        message: 'Info alert'
      });

      alertService.addAlert({
        type: 'test-alert-2',
        level: 'warning',
        message: 'Warning alert'
      });

      alertService.addAlert({
        type: 'test-alert-3',
        level: 'error',
        message: 'Error alert'
      });

      // 获取告警统计
      const stats = alertService.getAlertStats();

      // 验证统计
      expect(stats.active).toBe(3);
      expect(stats.total).toBe(3);
      expect(stats.byLevel.info).toBe(1);
      expect(stats.byLevel.warning).toBe(1);
      expect(stats.byLevel.error).toBe(1);
    });
  });

  describe('cleanupResolvedAlerts', () => {
    it('should clean up old resolved alerts', async () => {
      // 添加并解决告警
      const alertId = alertService.addAlert({
        type: 'test-alert',
        level: 'info',
        message: 'Test alert'
      });
      alertService.resolveAlert(alertId);

      // 获取已解决告警
      const alert = alertService.getAlert(alertId);

      // 修改解决时间以模拟过期
      alert.resolvedAt = new Date(Date.now() - 2000).toISOString(); // 2秒前

      // 清理已解决告警（1秒前的）
      const count = alertService.cleanupResolvedAlerts(1000);

      // 验证清理结果
      expect(count).toBe(1);
      expect(alertService.getAlert(alertId)).toBeNull();
    });
  });

  describe('auto resolve and escalation', () => {
    it('should auto resolve alerts based on level config', async () => {
      // 添加info级别告警（配置为自动解决）
      const alertId = alertService.addAlert({
        type: 'auto-resolve-test',
        level: 'info',
        message: 'Auto resolve test'
      });

      // 获取告警
      const alert = alertService.getAlert(alertId);

      // 修改时间戳以模拟过期
      alert.timestamp = new Date(Date.now() - 200).toISOString(); // 200ms前

      // 手动触发自动解决检查
      alertService._checkAutoResolve();

      // 验证告警已解决
      expect(alertService.activeAlerts.has(alertId)).toBe(false);
      const resolvedAlert = alertService.getAlert(alertId);
      expect(resolvedAlert.resolved).toBe(true);
      expect(resolvedAlert.resolution.reason).toBe('auto_resolve');
    });

    it('should auto escalate alerts based on level config', async () => {
      // 添加critical级别告警（配置为自动升级）
      const alertId = alertService.addAlert({
        type: 'auto-escalate-test',
        level: 'critical',
        message: 'Auto escalate test'
      });

      // 获取告警
      const alert = alertService.getAlert(alertId);

      // 修改时间戳以模拟过期
      alert.timestamp = new Date(Date.now() - 200).toISOString(); // 200ms前

      // 手动触发自动升级检查
      alertService._checkEscalation();

      // 验证告警已升级
      const escalatedAlert = alertService.getAlert(alertId);
      expect(escalatedAlert.escalated).toBe(true);
      expect(escalatedAlert.escalatedAt).toBeDefined();
    });
  });
});
