/**
 * 告警服务模拟
 */
const { EventEmitter } = require('events');
const { v4: uuidv4 } = require('uuid');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用告警
  enabled: true,

  // 告警级别
  levels: {
    // 信息级别
    info: {
      color: 'blue',
      priority: 0,
      autoResolve: true,
      autoResolveTimeout: 100 // 100ms for testing
    },

    // 警告级别
    warning: {
      color: 'yellow',
      priority: 1,
      autoResolve: true,
      autoResolveTimeout: 200 // 200ms for testing
    },

    // 错误级别
    error: {
      color: 'red',
      priority: 2,
      autoResolve: false
    },

    // 严重级别
    critical: {
      color: 'purple',
      priority: 3,
      autoResolve: false,
      autoEscalate: true,
      escalateTimeout: 100 // 100ms for testing
    }
  },

  // 告警通知配置
  notifications: {
    enabled: true,
    channels: {
      console: { enabled: true, minLevel: 'info' },
      email: { enabled: false },
      webhook: { enabled: false }
    }
  },

  // 告警聚合配置
  aggregation: {
    enabled: false
  },

  // 告警持久化配置
  persistence: {
    enabled: false,
    maxAlerts: 100
  }
};

class AlertService extends EventEmitter {
  constructor(config = {}) {
    super();

    // 合并配置
    this.config = {
      ...DEFAULT_CONFIG,
      ...config,
      levels: {
        ...DEFAULT_CONFIG.levels,
        ...(config.levels || {})
      }
    };

    // 活动告警
    this.activeAlerts = new Map();

    // 已解决告警
    this.resolvedAlerts = [];

    // 告警计数器
    this.alertCounters = {
      total: 0,
      byLevel: {
        info: 0,
        warning: 0,
        error: 0,
        critical: 0
      },
      byType: new Map()
    };

    // 通知计数器
    this.notificationCounters = {
      total: 0,
      byChannel: {
        console: 0,
        email: 0,
        webhook: 0
      }
    };

    // 初始化状态
    this.initialized = false;
  }

  async initialize() {
    if (this.initialized) {
      return;
    }

    this.initialized = true;
    return true;
  }

  async close() {
    this.initialized = false;
    return true;
  }

  addAlert(alert) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('告警服务未初始化');
    }

    // 如果未启用告警，不执行操作
    if (!this.config.enabled) {
      return null;
    }

    // 验证告警级别
    if (!alert.level || !this.config.levels[alert.level]) {
      alert.level = 'info';
    }

    // 添加告警ID
    if (!alert.id) {
      alert.id = uuidv4();
    }

    // 添加时间戳
    if (!alert.timestamp) {
      alert.timestamp = new Date().toISOString();
    }

    // 添加到活动告警
    this.activeAlerts.set(alert.id, alert);

    // 更新告警计数器
    this.alertCounters.total++;
    this.alertCounters.byLevel[alert.level]++;

    // 按类型计数
    if (alert.type) {
      const typeCount = this.alertCounters.byType.get(alert.type) || 0;
      this.alertCounters.byType.set(alert.type, typeCount + 1);
    }

    // 发出告警添加事件
    this.emit('alert:added', { alertId: alert.id, alert });

    return alert.id;
  }

  resolveAlert(alertId, resolution = {}) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('告警服务未初始化');
    }

    // 如果未启用告警，不执行操作
    if (!this.config.enabled) {
      return false;
    }

    // 获取告警
    const alert = this.activeAlerts.get(alertId);

    if (!alert) {
      return false;
    }

    // 添加解决信息
    alert.resolved = true;
    alert.resolvedAt = new Date().toISOString();
    alert.resolution = {
      reason: resolution.reason || 'manual',
      message: resolution.message || '告警已手动解决',
      by: resolution.by || 'system'
    };

    // 从活动告警中移除
    this.activeAlerts.delete(alertId);

    // 添加到已解决告警
    this.resolvedAlerts.push(alert);

    // 限制已解决告警数量
    if (this.resolvedAlerts.length > this.config.persistence.maxAlerts) {
      this.resolvedAlerts = this.resolvedAlerts.slice(-this.config.persistence.maxAlerts);
    }

    // 发出告警解决事件
    this.emit('alert:resolved', { alertId, alert });

    return true;
  }

  getAlert(alertId) {
    // 先从活动告警中查找
    if (this.activeAlerts.has(alertId)) {
      return this.activeAlerts.get(alertId);
    }

    // 再从已解决告警中查找
    return this.resolvedAlerts.find(alert => alert.id === alertId) || null;
  }

  getActiveAlerts() {
    return Array.from(this.activeAlerts.values());
  }

  getResolvedAlerts(limit = 100) {
    return this.resolvedAlerts.slice(-limit);
  }

  getAlertStats() {
    return {
      active: this.activeAlerts.size,
      resolved: this.resolvedAlerts.length,
      total: this.alertCounters.total,
      byLevel: { ...this.alertCounters.byLevel },
      byType: Object.fromEntries(this.alertCounters.byType),
      notifications: {
        total: this.notificationCounters.total,
        byChannel: { ...this.notificationCounters.byChannel }
      }
    };
  }

  cleanupResolvedAlerts(maxAge = 30 * 24 * 60 * 60 * 1000) {
    const now = Date.now();
    const initialCount = this.resolvedAlerts.length;

    // 过滤掉超过最大年龄的告警
    this.resolvedAlerts = this.resolvedAlerts.filter(alert => {
      const resolvedAt = new Date(alert.resolvedAt).getTime();
      return now - resolvedAt < maxAge;
    });

    return initialCount - this.resolvedAlerts.length;
  }

  _checkAutoResolve() {
    const now = Date.now();

    // 检查每个活动告警
    for (const [alertId, alert] of this.activeAlerts.entries()) {
      // 获取告警级别配置
      const levelConfig = this.config.levels[alert.level];

      // 如果配置了自动解决
      if (levelConfig && levelConfig.autoResolve && levelConfig.autoResolveTimeout) {
        // 计算告警年龄
        const alertTimestamp = new Date(alert.timestamp).getTime();
        const alertAge = now - alertTimestamp;

        // 如果告警年龄超过自动解决超时
        if (alertAge >= levelConfig.autoResolveTimeout) {
          // 解决告警
          this.resolveAlert(alertId, {
            reason: 'auto_resolve',
            message: '告警已自动解决（超时）'
          });
        }
      }
    }
  }

  _checkEscalation() {
    const now = Date.now();

    // 检查每个活动告警
    for (const [alertId, alert] of this.activeAlerts.entries()) {
      // 获取告警级别配置
      const levelConfig = this.config.levels[alert.level];

      // 如果配置了自动升级
      if (levelConfig && levelConfig.autoEscalate && levelConfig.escalateTimeout) {
        // 检查是否已升级
        if (alert.escalated) {
          continue;
        }

        // 计算告警年龄
        const alertTimestamp = new Date(alert.timestamp).getTime();
        const alertAge = now - alertTimestamp;

        // 如果告警年龄超过升级超时
        if (alertAge >= levelConfig.escalateTimeout) {
          // 升级告警
          this._escalateAlert(alertId);
        }
      }
    }
  }

  _escalateAlert(alertId) {
    // 获取告警
    const alert = this.activeAlerts.get(alertId);

    if (!alert) {
      return;
    }

    // 标记为已升级
    alert.escalated = true;
    alert.escalatedAt = new Date().toISOString();

    // 更新告警
    this.activeAlerts.set(alertId, alert);

    // 发出告警升级事件
    this.emit('alert:escalated', { alertId, alert });
  }
}

module.exports = {
  AlertService
};
