/**
 * 监控路由
 *
 * 提供监控和告警相关的API：
 * - 获取系统健康状态
 * - 获取系统指标
 * - 获取告警信息
 * - 获取追踪信息
 */
const express = require('express');
const { body } = require('express-validator');
const monitoringController = require('../controllers/monitoringController');
const authMiddleware = require('../middleware/auth');
const { globalLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用全局速率限制
router.use(globalLimiter);

// 获取系统指标
router.get('/metrics',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getSystemMetrics
);

// 获取请求计数器
router.get('/requests',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getRequestCounters
);

// 获取响应时间统计
router.get('/response-time',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getResponseTimeStats
);

// 获取告警
router.get('/alerts',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getAlerts
);

// 设置告警阈值
router.post('/alert-thresholds',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    body('cpu_usage').optional().isFloat({ min: 0, max: 100 }).withMessage('cpu_usage必须是0-100之间的浮点数'),
    body('memory_usage').optional().isFloat({ min: 0, max: 100 }).withMessage('memory_usage必须是0-100之间的浮点数'),
    body('error_rate').optional().isFloat({ min: 0, max: 100 }).withMessage('error_rate必须是0-100之间的浮点数'),
    body('response_time').optional().isInt({ min: 0 }).withMessage('response_time必须是非负整数')
  ],
  monitoringController.setAlertThresholds
);

// 解决告警
router.post('/alerts/:alertId/resolve',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  [
    body('reason').optional().isString().withMessage('reason必须是字符串'),
    body('message').optional().isString().withMessage('message必须是字符串')
  ],
  monitoringController.resolveAlert
);

// 获取系统健康状态
router.get('/health',
  monitoringController.getHealth
);

// 获取追踪信息
router.get('/traces',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getTraces
);

// 获取追踪详情
router.get('/traces/:traceId',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getTraceDetails
);

// 获取服务状态
router.get('/services',
  authMiddleware.isAuthenticated,
  authMiddleware.isAdmin,
  monitoringController.getServiceStatus
);

module.exports = router;
