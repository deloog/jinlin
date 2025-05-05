/**
 * Prometheus 监控服务
 * 提供 Prometheus 指标收集和导出功能
 */
const promClient = require('prom-client');
const os = require('os');
const logger = require('../utils/logger');

// 创建注册表
const register = new promClient.Registry();

// 添加默认指标
promClient.collectDefaultMetrics({ register });

// 自定义指标
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP请求持续时间（秒）',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
});

const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'HTTP请求总数',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestErrorCounter = new promClient.Counter({
  name: 'http_request_errors_total',
  help: 'HTTP请求错误总数',
  labelNames: ['method', 'route', 'status_code', 'error_type']
});

const databaseQueryDurationSeconds = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: '数据库查询持续时间（秒）',
  labelNames: ['query_type', 'table'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2]
});

const databaseQueryCounter = new promClient.Counter({
  name: 'database_queries_total',
  help: '数据库查询总数',
  labelNames: ['query_type', 'table']
});

const databaseErrorCounter = new promClient.Counter({
  name: 'database_errors_total',
  help: '数据库错误总数',
  labelNames: ['query_type', 'table', 'error_type']
});

const cacheHitCounter = new promClient.Counter({
  name: 'cache_hits_total',
  help: '缓存命中总数',
  labelNames: ['cache_type']
});

const cacheMissCounter = new promClient.Counter({
  name: 'cache_misses_total',
  help: '缓存未命中总数',
  labelNames: ['cache_type']
});

const activeUsersGauge = new promClient.Gauge({
  name: 'active_users',
  help: '活跃用户数'
});

const reminderCountGauge = new promClient.Gauge({
  name: 'reminder_count',
  help: '提醒事项总数'
});

const syncQueueSizeGauge = new promClient.Gauge({
  name: 'sync_queue_size',
  help: '同步队列大小'
});

const aiRequestCounter = new promClient.Counter({
  name: 'ai_requests_total',
  help: 'AI请求总数',
  labelNames: ['provider', 'model', 'status']
});

const aiRequestDurationSeconds = new promClient.Histogram({
  name: 'ai_request_duration_seconds',
  help: 'AI请求持续时间（秒）',
  labelNames: ['provider', 'model'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 20, 30]
});

// 注册自定义指标
register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCounter);
register.registerMetric(httpRequestErrorCounter);
register.registerMetric(databaseQueryDurationSeconds);
register.registerMetric(databaseQueryCounter);
register.registerMetric(databaseErrorCounter);
register.registerMetric(cacheHitCounter);
register.registerMetric(cacheMissCounter);
register.registerMetric(activeUsersGauge);
register.registerMetric(reminderCountGauge);
register.registerMetric(syncQueueSizeGauge);
register.registerMetric(aiRequestCounter);
register.registerMetric(aiRequestDurationSeconds);

/**
 * 初始化 Prometheus 监控服务
 */
function initialize() {
  logger.info('Prometheus监控服务已初始化');
  
  // 定期更新一些指标
  setInterval(updateMetrics, 60000);
}

/**
 * 更新指标
 */
async function updateMetrics() {
  try {
    // 更新活跃用户数
    const knex = require('../db/knex');
    const [activeUsersResult] = await knex('users')
      .count('* as count')
      .where('updated_at', '>', knex.raw('DATE_SUB(NOW(), INTERVAL 1 DAY)'));
    
    activeUsersGauge.set(activeUsersResult[0].count || 0);
    
    // 更新提醒事项总数
    const [reminderCountResult] = await knex('reminders').count('* as count');
    reminderCountGauge.set(reminderCountResult[0].count || 0);
    
    // 更新同步队列大小
    const [syncQueueResult] = await knex('sync_records')
      .count('* as count')
      .where('status', 'pending');
    
    syncQueueSizeGauge.set(syncQueueResult[0].count || 0);
  } catch (error) {
    logger.error('更新Prometheus指标失败:', error);
  }
}

/**
 * 请求计时中间件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 * @param {Function} next - 下一个中间件
 */
function requestDurationMiddleware(req, res, next) {
  const start = process.hrtime();
  
  // 添加响应完成监听器
  res.on('finish', () => {
    const route = req.route ? req.route.path : req.path;
    const method = req.method;
    const statusCode = res.statusCode;
    
    // 计算持续时间
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;
    
    // 记录请求持续时间
    httpRequestDurationMicroseconds.labels(method, route, statusCode).observe(duration);
    
    // 增加请求计数
    httpRequestCounter.labels(method, route, statusCode).inc();
    
    // 如果是错误，增加错误计数
    if (statusCode >= 400) {
      const errorType = statusCode >= 500 ? 'server_error' : 'client_error';
      httpRequestErrorCounter.labels(method, route, statusCode, errorType).inc();
    }
  });
  
  next();
}

/**
 * 记录数据库查询
 * @param {string} queryType - 查询类型
 * @param {string} table - 表名
 * @param {Function} queryFn - 查询函数
 * @returns {Promise} 查询结果
 */
async function recordDatabaseQuery(queryType, table, queryFn) {
  const start = process.hrtime();
  
  try {
    // 执行查询
    const result = await queryFn();
    
    // 计算持续时间
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;
    
    // 记录查询持续时间
    databaseQueryDurationSeconds.labels(queryType, table).observe(duration);
    
    // 增加查询计数
    databaseQueryCounter.labels(queryType, table).inc();
    
    return result;
  } catch (error) {
    // 计算持续时间
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;
    
    // 记录查询持续时间
    databaseQueryDurationSeconds.labels(queryType, table).observe(duration);
    
    // 增加错误计数
    databaseErrorCounter.labels(queryType, table, error.code || 'unknown').inc();
    
    throw error;
  }
}

/**
 * 记录缓存命中
 * @param {string} cacheType - 缓存类型
 */
function recordCacheHit(cacheType) {
  cacheHitCounter.labels(cacheType).inc();
}

/**
 * 记录缓存未命中
 * @param {string} cacheType - 缓存类型
 */
function recordCacheMiss(cacheType) {
  cacheMissCounter.labels(cacheType).inc();
}

/**
 * 记录AI请求
 * @param {string} provider - 提供商
 * @param {string} model - 模型
 * @param {Function} requestFn - 请求函数
 * @returns {Promise} 请求结果
 */
async function recordAiRequest(provider, model, requestFn) {
  const start = process.hrtime();
  
  try {
    // 执行请求
    const result = await requestFn();
    
    // 计算持续时间
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;
    
    // 记录请求持续时间
    aiRequestDurationSeconds.labels(provider, model).observe(duration);
    
    // 增加请求计数
    aiRequestCounter.labels(provider, model, 'success').inc();
    
    return result;
  } catch (error) {
    // 计算持续时间
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;
    
    // 记录请求持续时间
    aiRequestDurationSeconds.labels(provider, model).observe(duration);
    
    // 增加错误计数
    aiRequestCounter.labels(provider, model, 'error').inc();
    
    throw error;
  }
}

/**
 * 获取指标
 * @returns {Promise<string>} 指标数据
 */
async function getMetrics() {
  return register.metrics();
}

/**
 * 获取内容类型
 * @returns {string} 内容类型
 */
function getContentType() {
  return register.contentType;
}

module.exports = {
  initialize,
  requestDurationMiddleware,
  recordDatabaseQuery,
  recordCacheHit,
  recordCacheMiss,
  recordAiRequest,
  getMetrics,
  getContentType,
  register
};
