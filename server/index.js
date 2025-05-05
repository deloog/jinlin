/**
 * Jinlin App Server
 * 服务器入口文件
 */
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const compression = require('compression');
const dotenv = require('dotenv');
const session = require('express-session');

// 导入配置
const env = process.env.NODE_ENV || 'development';

// 加载对应环境的配置文件
dotenv.config({ path: `.env.${env}` });

// 如果存在.env文件，也加载它（用于覆盖特定环境的配置）
dotenv.config();

// 初始化增强日志系统（在其他模块之前）
const logger = require('./utils/enhancedLogger');
logger.info(`服务器启动中，环境: ${env}`);

const { app: appConfig } = require('./config/app');
const { pool, testConnection } = require('./config/database');

// 导入路由
const holidayRoutes = require('./routes/holidayRoutes');
const reminderRoutes = require('./routes/reminderRoutes');
const userRoutes = require('./routes/userRoutes');
const syncRoutes = require('./routes/syncRoutes');
const solarTermRoutes = require('./routes/solarTermRoutes');
const localizationRoutes = require('./routes/localizationRoutes');
const aiRoutes = require('./routes/aiRoutes');
const lunarRoutes = require('./routes/lunarRoutes');
const deepseekRoutes = require('./routes/deepseekRoutes');
const healthRoutes = require('./routes/healthRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const fileRoutes = require('./routes/fileRoutes');
const timeZoneRoutes = require('./routes/timeZoneRoutes');
const monitoringRoutes = require('./routes/monitoringRoutes');
const prometheusRoutes = require('./routes/prometheusRoutes');
const swaggerRoutes = require('./routes/swaggerRoutes');
const systemRoutes = require('./routes/systemRoutes');
const configRoutes = require('./routes/configRoutes');
const exampleRoutes = require('./routes/exampleRoutes');
const authRoutes = require('./routes/authRoutes');
const backupRoutes = require('./routes/backupRoutes');

// 导入模型
const Holiday = require('./models/Holiday');
const Reminder = require('./models/Reminder');
const User = require('./models/User');
const SyncRecord = require('./models/SyncRecord');

// 导入服务
const { encryptionService } = require('./services/encryptionService');
const { apiKeyRotationService } = require('./services/apiKeyRotationService');
const { multiLevelCacheService } = require('./services/multiLevelCacheService');
const { asyncTaskService } = require('./services/asyncTaskService');
const { loadBalancerService } = require('./services/loadBalancerService');
const { alertService } = require('./services/alertService');
const { tracingService } = require('./services/tracingService');
const backupSchedulerService = require('./services/backupSchedulerService');
const backupTaskHandler = require('./services/backupTaskHandler');
const backupMonitoringService = require('./services/backupMonitoringService');

// 创建Express应用
const app = express();
const port = appConfig.port;

// 中间件
app.use(cors());
app.use(bodyParser.json());

// 会话中间件
app.use(session({
  secret: process.env.SESSION_SECRET || 'your_session_secret_key',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 1天
  }
}));

// 初始化分布式追踪
const telemetry = require('./utils/telemetry');
if (telemetry.isEnabled) {
  telemetry.initTelemetry().then(() => {
    logger.info('分布式追踪已初始化');
  }).catch(error => {
    logger.error('初始化分布式追踪失败', { error });
  });
}

// 请求日志中间件
app.use(logger.requestMiddleware);

// 监控中间件
const monitoringService = require('./services/monitoringService');
monitoringService.initialize();
app.use(monitoringService.requestLogger);

// Prometheus 监控中间件
const prometheusService = require('./services/prometheusService');
prometheusService.initialize();
app.use(prometheusService.requestDurationMiddleware);

// 静态文件
app.use(express.static('public'));

// 启用响应压缩
app.use(compression({
  // 只压缩大于1KB的响应
  threshold: 1024,
  // 压缩级别（0-9，9为最高压缩率但最慢）
  level: 6,
  // 不压缩的MIME类型
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    // 默认压缩所有文本和JSON响应
    return compression.filter(req, res);
  }
}));

// 安全中间件
const securityMiddleware = require('./middleware/securityMiddleware');
app.use(securityMiddleware.createSecurityMiddleware());

// 输入验证和净化中间件
const { sanitize } = require('./middleware/validationMiddleware');
app.use(sanitize());

// 加密中间件
const { encryptRequestData, decryptResponseData } = require('./middleware/encryptionMiddleware');
app.use(encryptRequestData());
app.use(decryptResponseData());

// API签名验证中间件
const { verifySignature } = require('./middleware/apiSignatureMiddleware');
app.use(verifySignature);

// 资源权限中间件
const { RESOURCE_TYPES, OPERATION_TYPES } = require('./middleware/resourcePermissionMiddleware');

// 负载均衡中间件
const { createLoadBalancerMiddleware, createHealthCheckMiddleware } = require('./middleware/loadBalancerMiddleware');
app.use(createLoadBalancerMiddleware());
app.get('/load-balancer/health', createHealthCheckMiddleware());

// 分布式追踪中间件
const { createTracingMiddleware, createDatabaseTracingMiddleware, createExternalTracingMiddleware } = require('./middleware/tracingMiddleware');
app.use(createTracingMiddleware());
app.use(createDatabaseTracingMiddleware());
app.use(createExternalTracingMiddleware());

// 速率限制中间件
const {
  globalLimiter,
  authLimiter,
  aiLimiter,
  dynamicLimiter
} = require('./middleware/rateLimitMiddleware');

// 应用全局速率限制
app.use(globalLimiter);

// 应用动态速率限制（根据系统负载动态调整限制）
app.use(dynamicLimiter);

// 初始化数据库
async function initializeDatabase() {
  try {
    // 测试数据库连接
    const connected = await testConnection();
    if (!connected) {
      console.error('无法连接到数据库，服务器将退出');
      process.exit(1);
    }

    // 使用 Knex 迁移系统
    const knex = require('./db/knex');

    // 检查是否需要运行迁移
    const [migrationStatus] = await knex.raw('SHOW TABLES LIKE "knex_migrations"');
    const needsMigration = migrationStatus.length === 0;

    if (needsMigration) {
      console.log('正在运行数据库迁移...');

      // 运行迁移
      await knex.migrate.latest();
      console.log('数据库迁移完成');

      // 检查是否需要运行种子
      const [userCount] = await knex('users').count('* as count');
      if (userCount[0].count === 0) {
        console.log('正在运行数据库种子...');
        await knex.seed.run();
        console.log('数据库种子完成');
      }
    } else {
      console.log('数据库已初始化，跳过迁移');
    }

    console.log('数据库初始化完成');
  } catch (error) {
    console.error('数据库初始化失败:', error);
    process.exit(1);
  }
}

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 版本端点
app.get('/version', (req, res) => {
  res.json({ version: '1.0.0' });
});

// 注册路由
app.use('/api/holidays', holidayRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/solar-terms', solarTermRoutes);
app.use('/api/localization', localizationRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/lunar', lunarRoutes);
app.use('/api/deepseek', deepseekRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/files', fileRoutes);
app.use('/api/time-zones', timeZoneRoutes);
app.use('/api/monitoring', monitoringRoutes);
app.use('/api/prometheus', prometheusRoutes);
app.use('/api/system', systemRoutes);
app.use('/api/config', configRoutes);
app.use('/api/examples', exampleRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/backup', backupRoutes);

// API文档
app.use('/api-docs', swaggerRoutes);

// 健康检查路由（不需要认证）
app.use('/health', healthRoutes);

// 错误日志中间件
app.use(logger.errorMiddleware);

// 导入错误处理中间件
const { notFoundHandler, errorHandler } = require('./middleware/errorMiddleware');

// 404处理
app.use(notFoundHandler);

// 错误处理中间件
app.use(errorHandler);

/**
 * 设置优雅关闭
 * @param {Object} server - HTTP服务器
 */
function setupGracefulShutdown(server) {
  // 处理进程信号
  ['SIGINT', 'SIGTERM', 'SIGQUIT'].forEach(signal => {
    process.on(signal, () => {
      logger.info(`收到信号 ${signal}，正在优雅关闭...`);

      // 关闭HTTP服务器
      server.close(() => {
        logger.info('HTTP服务器已关闭');

        // 关闭数据库连接
        require('./config/database').dbPoolManager.close()
          .then(() => logger.info('数据库连接已关闭'))
          .catch(err => logger.error('关闭数据库连接时出错', { error: err }))
          .finally(() => {
            // 关闭加密服务
            if (encryptionService && typeof encryptionService.close === 'function') {
              encryptionService.close()
                .then(() => logger.info('加密服务已关闭'))
                .catch(err => logger.error('关闭加密服务时出错', { error: err }))
                .finally(closeNextService);
            } else {
              closeNextService();
            }
          });
      });

      // 关闭下一个服务
      function closeNextService() {
        // 关闭API密钥轮换服务
        if (apiKeyRotationService && typeof apiKeyRotationService.close === 'function') {
          apiKeyRotationService.close()
            .then(() => logger.info('API密钥轮换服务已关闭'))
            .catch(err => logger.error('关闭API密钥轮换服务时出错', { error: err }))
            .finally(closeMultiLevelCache);
        } else {
          closeMultiLevelCache();
        }
      }

      // 关闭多级缓存服务
      function closeMultiLevelCache() {
        if (multiLevelCacheService && typeof multiLevelCacheService.close === 'function') {
          multiLevelCacheService.close()
            .then(() => logger.info('多级缓存服务已关闭'))
            .catch(err => logger.error('关闭多级缓存服务时出错', { error: err }))
            .finally(closeAsyncTask);
        } else {
          closeAsyncTask();
        }
      }

      // 关闭异步任务服务
      function closeAsyncTask() {
        if (asyncTaskService && typeof asyncTaskService.close === 'function') {
          asyncTaskService.close()
            .then(() => logger.info('异步任务服务已关闭'))
            .catch(err => logger.error('关闭异步任务服务时出错', { error: err }))
            .finally(closeLoadBalancer);
        } else {
          closeLoadBalancer();
        }
      }

      // 关闭负载均衡服务
      function closeLoadBalancer() {
        if (loadBalancerService && typeof loadBalancerService.close === 'function') {
          loadBalancerService.close()
            .then(() => logger.info('负载均衡服务已关闭'))
            .catch(err => logger.error('关闭负载均衡服务时出错', { error: err }))
            .finally(closeAlertService);
        } else {
          closeAlertService();
        }
      }

      // 关闭告警服务
      function closeAlertService() {
        if (alertService && typeof alertService.close === 'function') {
          alertService.close()
            .then(() => logger.info('告警服务已关闭'))
            .catch(err => logger.error('关闭告警服务时出错', { error: err }))
            .finally(closeTracingService);
        } else {
          closeTracingService();
        }
      }

      // 关闭分布式追踪服务
      function closeTracingService() {
        if (tracingService && typeof tracingService.close === 'function') {
          tracingService.close()
            .then(() => logger.info('分布式追踪服务已关闭'))
            .catch(err => logger.error('关闭分布式追踪服务时出错', { error: err }))
            .finally(closeBackupServices);
        } else {
          closeBackupServices();
        }
      }

      // 关闭备份服务
      function closeBackupServices() {
        // 关闭备份调度服务
        if (backupSchedulerService && typeof backupSchedulerService.disable === 'function') {
          try {
            backupSchedulerService.disable();
            logger.info('备份调度服务已关闭');
            closeBackupMonitoring();
          } catch (err) {
            logger.error('关闭备份调度服务时出错', { error: err });
            closeBackupMonitoring();
          }
        } else {
          closeBackupMonitoring();
        }
      }

      // 关闭备份监控服务
      function closeBackupMonitoring() {
        if (backupMonitoringService && typeof backupMonitoringService.stop === 'function') {
          try {
            backupMonitoringService.stop();
            logger.info('备份监控服务已关闭');
            closeCache();
          } catch (err) {
            logger.error('关闭备份监控服务时出错', { error: err });
            closeCache();
          }
        } else {
          closeCache();
        }
      }

      // 关闭缓存
      function closeCache() {
        if (require('./services/cacheService').close) {
          require('./services/cacheService').close()
            .then(() => logger.info('缓存服务已关闭'))
            .catch(err => logger.error('关闭缓存服务时出错', { error: err }))
            .finally(() => {
              logger.info('服务器已完全关闭');
              process.exit(0);
            });
        } else {
          logger.info('服务器已完全关闭');
          process.exit(0);
        }
      }

      // 设置超时强制退出
      setTimeout(() => {
        logger.error('强制关闭服务器（超时）');
        process.exit(1);
      }, 10000);
    });
  });
}

// 初始化服务
async function initializeServices() {
  try {
    // 初始化加密服务
    await encryptionService.initialize();
    logger.info('加密服务初始化成功');

    // 初始化API密钥轮换服务
    await apiKeyRotationService.initialize();
    logger.info('API密钥轮换服务初始化成功');

    // 初始化多级缓存服务
    await multiLevelCacheService.initialize();
    logger.info('多级缓存服务初始化成功');

    // 初始化异步任务服务
    await asyncTaskService.initialize();
    logger.info('异步任务服务初始化成功');

    // 初始化负载均衡服务
    await loadBalancerService.initialize();
    logger.info('负载均衡服务初始化成功');

    // 初始化告警服务
    await alertService.initialize();
    logger.info('告警服务初始化成功');

    // 初始化分布式追踪服务
    await tracingService.initialize();
    logger.info('分布式追踪服务初始化成功');

    // 初始化备份任务处理器
    await backupTaskHandler.initialize();
    logger.info('备份任务处理器初始化成功');

    // 初始化备份调度服务
    await backupSchedulerService.initialize();
    logger.info('备份调度服务初始化成功');

    // 初始化备份监控服务
    await backupMonitoringService.initialize();
    logger.info('备份监控服务初始化成功');

    // 注册异步任务处理器
    registerTaskHandlers();

    logger.info('所有服务初始化成功');
  } catch (error) {
    logger.error('初始化服务失败', { error });
    throw error;
  }
}

/**
 * 注册异步任务处理器
 */
function registerTaskHandlers() {
  // 注册邮件发送任务处理器
  asyncTaskService.registerHandler('send-email', async (data) => {
    logger.info('处理邮件发送任务', { to: data.to });
    // TODO: 实现邮件发送逻辑
    return { success: true };
  });

  // 注册数据同步任务处理器
  asyncTaskService.registerHandler('sync-data', async (data) => {
    logger.info('处理数据同步任务', { userId: data.userId });
    // TODO: 实现数据同步逻辑
    return { success: true };
  });

  // 注册报告生成任务处理器
  asyncTaskService.registerHandler('generate-report', async (data) => {
    logger.info('处理报告生成任务', { reportType: data.type });
    // TODO: 实现报告生成逻辑
    return { success: true };
  });

  // 注册通知发送任务处理器
  asyncTaskService.registerHandler('send-notification', async (data) => {
    logger.info('处理通知发送任务', { userId: data.userId });
    // TODO: 实现通知发送逻辑
    return { success: true };
  });

  logger.info('异步任务处理器注册成功');
}

// 启动服务器
const server = app.listen(port, async () => {
  try {
    // 初始化数据库
    await initializeDatabase();

    // 初始化服务
    await initializeServices();

    logger.info(`服务器运行在 http://localhost:${port}`, {
      port,
      env,
      nodeEnv: process.env.NODE_ENV
    });

    // 设置优雅关闭
    setupGracefulShutdown(server);
  } catch (error) {
    logger.error('服务器启动失败', { error });
    process.exit(1);
  }
});

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
  logger.error('未捕获的异常', { error });

  // 记录异常后退出
  setTimeout(() => process.exit(1), 1000);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('未处理的Promise拒绝', { reason, promise });
});

module.exports = app;
