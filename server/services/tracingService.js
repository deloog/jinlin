/**
 * 分布式追踪服务
 *
 * 提供分布式追踪功能：
 * - 请求链路追踪
 * - 性能瓶颈自动识别
 * - 追踪数据可视化
 * - 与监控系统集成
 */
const { EventEmitter } = require('events');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { v4: uuidv4 } = require('uuid');

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用追踪
  enabled: process.env.TRACING_ENABLED === 'true' || true,

  // 采样率
  samplingRate: parseFloat(process.env.TRACING_SAMPLING_RATE || '0.1'),

  // 是否启用分布式追踪
  distributed: process.env.DISTRIBUTED_TRACING_ENABLED === 'true' || false,

  // 追踪头
  headers: {
    traceId: process.env.TRACE_ID_HEADER || 'x-trace-id',
    spanId: process.env.SPAN_ID_HEADER || 'x-span-id',
    parentSpanId: process.env.PARENT_SPAN_ID_HEADER || 'x-parent-span-id'
  },

  // 追踪数据保留时间（毫秒）
  retention: parseInt(process.env.TRACE_RETENTION || '86400000', 10), // 默认24小时

  // 性能阈值
  thresholds: {
    // 慢请求阈值（毫秒）
    slowRequest: parseInt(process.env.SLOW_REQUEST_THRESHOLD || '1000', 10),

    // 慢数据库查询阈值（毫秒）
    slowQuery: parseInt(process.env.SLOW_QUERY_THRESHOLD || '500', 10),

    // 慢外部调用阈值（毫秒）
    slowExternalCall: parseInt(process.env.SLOW_EXTERNAL_CALL_THRESHOLD || '1000', 10)
  },

  // 导出配置
  exporters: {
    // 日志导出器
    log: {
      enabled: process.env.TRACE_LOG_EXPORTER_ENABLED === 'true' || true,
      slowOnly: process.env.TRACE_LOG_SLOW_ONLY === 'true' || false
    },

    // Zipkin导出器
    zipkin: {
      enabled: process.env.ZIPKIN_EXPORTER_ENABLED === 'true' || false,
      endpoint: process.env.ZIPKIN_ENDPOINT || 'http://localhost:9411/api/v2/spans'
    },

    // Jaeger导出器
    jaeger: {
      enabled: process.env.JAEGER_EXPORTER_ENABLED === 'true' || false,
      endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces'
    }
  }
};

// 追踪上下文类
class TraceContext {
  /**
   * 构造函数
   * @param {Object} options - 选项
   */
  constructor(options = {}) {
    // 追踪ID
    this.traceId = options.traceId || uuidv4();

    // 根Span ID
    this.rootSpanId = options.rootSpanId;

    // 活动Span
    this.activeSpan = null;

    // Span映射
    this.spans = new Map();

    // 开始时间
    this.startTime = Date.now();

    // 结束时间
    this.endTime = null;

    // 是否完成
    this.completed = false;

    // 标签
    this.tags = options.tags || {};

    // 元数据
    this.metadata = options.metadata || {};
  }

  /**
   * 创建Span
   * @param {string} name - Span名称
   * @param {Object} options - 选项
   * @returns {Object} Span
   */
  createSpan(name, options = {}) {
    // 创建Span ID
    const spanId = options.spanId || uuidv4();

    // 确定父Span ID
    let parentSpanId = options.parentSpanId;

    if (!parentSpanId && this.activeSpan) {
      parentSpanId = this.activeSpan.id;
    }

    // 如果没有根Span ID，将此Span设为根Span
    if (!this.rootSpanId) {
      this.rootSpanId = spanId;
    }

    // 创建Span
    const span = {
      id: spanId,
      name,
      traceId: this.traceId,
      parentId: parentSpanId,
      startTime: Date.now(),
      endTime: null,
      duration: null,
      tags: { ...options.tags },
      events: [],
      status: 'active'
    };

    // 添加到Span映射
    this.spans.set(spanId, span);

    // 设置为活动Span
    this.activeSpan = span;

    return span;
  }

  /**
   * 结束Span
   * @param {string} spanId - Span ID
   * @param {Object} options - 选项
   * @returns {Object} Span
   */
  endSpan(spanId, options = {}) {
    // 获取Span
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    // 设置结束时间
    span.endTime = options.endTime || Date.now();

    // 计算持续时间
    span.duration = span.endTime - span.startTime;

    // 添加标签
    if (options.tags) {
      Object.assign(span.tags, options.tags);
    }

    // 设置状态
    span.status = options.status || 'completed';

    // 如果是活动Span，将活动Span设为父Span
    if (this.activeSpan && this.activeSpan.id === spanId) {
      this.activeSpan = this.spans.get(span.parentId) || null;
    }

    return span;
  }

  /**
   * 添加Span事件
   * @param {string} spanId - Span ID
   * @param {string} name - 事件名称
   * @param {Object} attributes - 事件属性
   * @returns {Object} 事件
   */
  addSpanEvent(spanId, name, attributes = {}) {
    // 获取Span
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    // 创建事件
    const event = {
      name,
      timestamp: Date.now(),
      attributes
    };

    // 添加到Span事件
    span.events.push(event);

    return event;
  }

  /**
   * 设置Span标签
   * @param {string} spanId - Span ID
   * @param {string} key - 标签键
   * @param {any} value - 标签值
   * @returns {Object} Span
   */
  setSpanTag(spanId, key, value) {
    // 获取Span
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    // 设置标签
    span.tags[key] = value;

    return span;
  }

  /**
   * 设置Span状态
   * @param {string} spanId - Span ID
   * @param {string} status - 状态
   * @param {string} message - 消息
   * @returns {Object} Span
   */
  setSpanStatus(spanId, status, message) {
    // 获取Span
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    // 设置状态
    span.status = status;

    // 设置消息
    if (message) {
      span.tags.statusMessage = message;
    }

    return span;
  }

  /**
   * 完成追踪
   * @returns {Object} 追踪上下文
   */
  complete() {
    // 结束所有活动Span
    for (const [spanId, span] of this.spans.entries()) {
      if (span.status === 'active') {
        this.endSpan(spanId);
      }
    }

    // 设置结束时间
    this.endTime = Date.now();

    // 设置为已完成
    this.completed = true;

    return this;
  }

  /**
   * 获取追踪数据
   * @returns {Object} 追踪数据
   */
  getData() {
    return {
      traceId: this.traceId,
      rootSpanId: this.rootSpanId,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.endTime ? this.endTime - this.startTime : null,
      completed: this.completed,
      tags: this.tags,
      metadata: this.metadata,
      spans: Array.from(this.spans.values())
    };
  }
}

// 分布式追踪服务类
class TracingService extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} config - 配置
   */
  constructor(config = {}) {
    super();

    // 合并配置
    this.config = {
      ...DEFAULT_CONFIG,
      ...config,
      headers: {
        ...DEFAULT_CONFIG.headers,
        ...(config.headers || {})
      },
      thresholds: {
        ...DEFAULT_CONFIG.thresholds,
        ...(config.thresholds || {})
      },
      exporters: {
        ...DEFAULT_CONFIG.exporters,
        ...(config.exporters || {}),
        log: {
          ...DEFAULT_CONFIG.exporters.log,
          ...(config.exporters?.log || {})
        },
        zipkin: {
          ...DEFAULT_CONFIG.exporters.zipkin,
          ...(config.exporters?.zipkin || {})
        },
        jaeger: {
          ...DEFAULT_CONFIG.exporters.jaeger,
          ...(config.exporters?.jaeger || {})
        }
      }
    };

    // 活动追踪
    this.activeTraces = new Map();

    // 已完成追踪
    this.completedTraces = [];

    // 追踪计数器
    this.traceCounters = {
      created: 0,
      completed: 0,
      exported: 0,
      sampled: 0,
      errors: 0
    };

    // 性能统计
    this.performanceStats = {
      requests: {
        count: 0,
        totalDuration: 0,
        avgDuration: 0,
        slowCount: 0
      },
      database: {
        count: 0,
        totalDuration: 0,
        avgDuration: 0,
        slowCount: 0
      },
      external: {
        count: 0,
        totalDuration: 0,
        avgDuration: 0,
        slowCount: 0
      }
    };

    // 清理定时器
    this.cleanupTimer = null;

    // 初始化状态
    this.initialized = false;

    // 注册配置架构
    this._registerConfigSchema();

    logger.info('分布式追踪服务已创建');
  }

  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');

    // 注册追踪配置架构
    configManager.registerSchema('tracing.enabled', Joi.boolean().default(true));
    configManager.registerSchema('tracing.samplingRate', Joi.number().min(0).max(1).default(0.1));
    configManager.registerSchema('tracing.distributed', Joi.boolean().default(false));
    configManager.registerSchema('tracing.retention', Joi.number().min(1000).default(86400000));
  }

  /**
   * 初始化分布式追踪服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }

    try {
      logger.info('初始化分布式追踪服务');

      // 如果未启用追踪，不执行初始化
      if (!this.config.enabled) {
        logger.info('分布式追踪服务未启用');
        return;
      }

      // 启动清理定时器
      this._startCleanupTimer();

      this.initialized = true;
      logger.info('分布式追踪服务初始化成功');
    } catch (error) {
      logger.error('初始化分布式追踪服务失败', { error });
      throw error;
    }
  }

  /**
   * 启动清理定时器
   * @private
   */
  _startCleanupTimer() {
    // 清除现有定时器
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }

    // 设置新定时器
    this.cleanupTimer = setInterval(() => {
      this._cleanupTraces();
    }, 3600000); // 每小时清理一次

    logger.info('追踪清理定时器已启动');
  }

  /**
   * 清理追踪
   * @private
   */
  _cleanupTraces() {
    try {
      const now = Date.now();
      const retention = this.config.retention;

      // 清理已完成追踪
      this.completedTraces = this.completedTraces.filter(trace => {
        return now - trace.endTime < retention;
      });

      // 清理超时的活动追踪
      for (const [traceId, trace] of this.activeTraces.entries()) {
        if (now - trace.startTime > retention) {
          // 完成追踪
          trace.complete();

          // 从活动追踪中移除
          this.activeTraces.delete(traceId);

          // 添加到已完成追踪
          this.completedTraces.push(trace);

          // 更新计数器
          this.traceCounters.completed++;

          logger.debug(`清理超时追踪: ${traceId}`);
        }
      }

      logger.info(`清理追踪完成，剩余活动追踪: ${this.activeTraces.size}，已完成追踪: ${this.completedTraces.length}`);
    } catch (error) {
      logger.error('清理追踪失败', { error });
    }
  }

  /**
   * 创建追踪
   * @param {Object} options - 选项
   * @returns {TraceContext} 追踪上下文
   */
  createTrace(options = {}) {
    try {
      // 检查初始化状态
      if (!this.initialized) {
        throw new Error('分布式追踪服务未初始化');
      }

      // 如果未启用追踪，返回null
      if (!this.config.enabled) {
        return null;
      }

      // 应用采样率
      if (Math.random() > this.config.samplingRate) {
        return null;
      }

      // 更新计数器
      this.traceCounters.created++;
      this.traceCounters.sampled++;

      // 创建追踪上下文
      const trace = new TraceContext(options);

      // 添加到活动追踪
      this.activeTraces.set(trace.traceId, trace);

      // 发出追踪创建事件
      this.emit('trace:created', { traceId: trace.traceId });

      logger.debug(`创建追踪: ${trace.traceId}`);

      return trace;
    } catch (error) {
      logger.error('创建追踪失败', { error });
      this.traceCounters.errors++;
      return null;
    }
  }

  /**
   * 获取追踪
   * @param {string} traceId - 追踪ID
   * @returns {TraceContext|null} 追踪上下文
   */
  getTrace(traceId) {
    // 先从活动追踪中查找
    if (this.activeTraces.has(traceId)) {
      return this.activeTraces.get(traceId);
    }

    // 再从已完成追踪中查找
    return this.completedTraces.find(trace => trace.traceId === traceId) || null;
  }

  /**
   * 完成追踪
   * @param {string} traceId - 追踪ID
   * @returns {TraceContext|null} 追踪上下文
   */
  completeTrace(traceId) {
    try {
      // 获取追踪
      const trace = this.activeTraces.get(traceId);

      if (!trace) {
        return null;
      }

      // 完成追踪
      trace.complete();

      // 从活动追踪中移除
      this.activeTraces.delete(traceId);

      // 添加到已完成追踪
      this.completedTraces.push(trace);

      // 更新计数器
      this.traceCounters.completed++;

      // 发出追踪完成事件
      this.emit('trace:completed', { traceId, trace: trace.getData() });

      // 导出追踪
      this._exportTrace(trace);

      // 更新性能统计
      this._updatePerformanceStats(trace);

      logger.debug(`完成追踪: ${traceId}`);

      return trace;
    } catch (error) {
      logger.error('完成追踪失败', { error, traceId });
      this.traceCounters.errors++;
      return null;
    }
  }

  /**
   * 导出追踪
   * @private
   * @param {TraceContext} trace - 追踪上下文
   */
  _exportTrace(trace) {
    try {
      // 获取追踪数据
      const traceData = trace.getData();

      // 日志导出器
      if (this.config.exporters.log.enabled) {
        this._exportToLog(traceData);
      }

      // Zipkin导出器
      if (this.config.exporters.zipkin.enabled) {
        this._exportToZipkin(traceData);
      }

      // Jaeger导出器
      if (this.config.exporters.jaeger.enabled) {
        this._exportToJaeger(traceData);
      }

      // 更新计数器
      this.traceCounters.exported++;
    } catch (error) {
      logger.error('导出追踪失败', { error, traceId: trace.traceId });
    }
  }

  /**
   * 导出到日志
   * @private
   * @param {Object} traceData - 追踪数据
   */
  _exportToLog(traceData) {
    try {
      // 如果只记录慢请求
      if (this.config.exporters.log.slowOnly) {
        // 检查是否有慢Span
        const hasSlowSpan = traceData.spans.some(span => {
          if (!span.duration) return false;

          if (span.tags.type === 'request' && span.duration >= this.config.thresholds.slowRequest) {
            return true;
          }

          if (span.tags.type === 'db' && span.duration >= this.config.thresholds.slowQuery) {
            return true;
          }

          if (span.tags.type === 'external' && span.duration >= this.config.thresholds.slowExternalCall) {
            return true;
          }

          return false;
        });

        if (!hasSlowSpan) {
          return;
        }
      }

      // 记录追踪日志
      logger.info(`追踪: ${traceData.traceId}`, {
        traceId: traceData.traceId,
        duration: traceData.duration,
        rootSpan: traceData.spans.find(span => span.id === traceData.rootSpanId),
        spanCount: traceData.spans.length
      });

      // 记录慢Span日志
      for (const span of traceData.spans) {
        if (!span.duration) continue;

        let isSlowSpan = false;
        let threshold = 0;

        if (span.tags.type === 'request' && span.duration >= this.config.thresholds.slowRequest) {
          isSlowSpan = true;
          threshold = this.config.thresholds.slowRequest;
        } else if (span.tags.type === 'db' && span.duration >= this.config.thresholds.slowQuery) {
          isSlowSpan = true;
          threshold = this.config.thresholds.slowQuery;
        } else if (span.tags.type === 'external' && span.duration >= this.config.thresholds.slowExternalCall) {
          isSlowSpan = true;
          threshold = this.config.thresholds.slowExternalCall;
        }

        if (isSlowSpan) {
          logger.warn(`慢${span.tags.type}: ${span.name}`, {
            traceId: traceData.traceId,
            spanId: span.id,
            duration: span.duration,
            threshold,
            tags: span.tags
          });
        }
      }
    } catch (error) {
      logger.error('导出到日志失败', { error, traceId: traceData.traceId });
    }
  }

  /**
   * 导出到Zipkin
   * @private
   * @param {Object} traceData - 追踪数据
   */
  _exportToZipkin(traceData) {
    try {
      // TODO: 实现Zipkin导出逻辑
      logger.debug(`导出到Zipkin: ${traceData.traceId}`);
    } catch (error) {
      logger.error('导出到Zipkin失败', { error, traceId: traceData.traceId });
    }
  }

  /**
   * 导出到Jaeger
   * @private
   * @param {Object} traceData - 追踪数据
   */
  _exportToJaeger(traceData) {
    try {
      // TODO: 实现Jaeger导出逻辑
      logger.debug(`导出到Jaeger: ${traceData.traceId}`);
    } catch (error) {
      logger.error('导出到Jaeger失败', { error, traceId: traceData.traceId });
    }
  }

  /**
   * 更新性能统计
   * @private
   * @param {TraceContext} trace - 追踪上下文
   */
  _updatePerformanceStats(trace) {
    try {
      // 获取追踪数据
      const traceData = trace.getData();

      // 更新请求统计
      const requestSpans = traceData.spans.filter(span => span.tags.type === 'request' && span.duration);

      for (const span of requestSpans) {
        this.performanceStats.requests.count++;
        this.performanceStats.requests.totalDuration += span.duration;

        if (span.duration >= this.config.thresholds.slowRequest) {
          this.performanceStats.requests.slowCount++;
        }
      }

      if (this.performanceStats.requests.count > 0) {
        this.performanceStats.requests.avgDuration = this.performanceStats.requests.totalDuration / this.performanceStats.requests.count;
      }

      // 更新数据库统计
      const dbSpans = traceData.spans.filter(span => span.tags.type === 'db' && span.duration);

      for (const span of dbSpans) {
        this.performanceStats.database.count++;
        this.performanceStats.database.totalDuration += span.duration;

        if (span.duration >= this.config.thresholds.slowQuery) {
          this.performanceStats.database.slowCount++;
        }
      }

      if (this.performanceStats.database.count > 0) {
        this.performanceStats.database.avgDuration = this.performanceStats.database.totalDuration / this.performanceStats.database.count;
      }

      // 更新外部调用统计
      const externalSpans = traceData.spans.filter(span => span.tags.type === 'external' && span.duration);

      for (const span of externalSpans) {
        this.performanceStats.external.count++;
        this.performanceStats.external.totalDuration += span.duration;

        if (span.duration >= this.config.thresholds.slowExternalCall) {
          this.performanceStats.external.slowCount++;
        }
      }

      if (this.performanceStats.external.count > 0) {
        this.performanceStats.external.avgDuration = this.performanceStats.external.totalDuration / this.performanceStats.external.count;
      }
    } catch (error) {
      logger.error('更新性能统计失败', { error, traceId: trace.traceId });
    }
  }

  /**
   * 获取追踪统计
   * @returns {Object} 追踪统计
   */
  getTracingStats() {
    return {
      traces: {
        active: this.activeTraces.size,
        completed: this.completedTraces.length,
        created: this.traceCounters.created,
        completed: this.traceCounters.completed,
        exported: this.traceCounters.exported,
        sampled: this.traceCounters.sampled,
        errors: this.traceCounters.errors
      },
      performance: {
        requests: { ...this.performanceStats.requests },
        database: { ...this.performanceStats.database },
        external: { ...this.performanceStats.external }
      }
    };
  }

  /**
   * 从请求中提取追踪上下文
   * @param {Object} req - 请求对象
   * @returns {Object} 追踪上下文选项
   */
  extractTraceContext(req) {
    try {
      // 如果未启用分布式追踪，返回空对象
      if (!this.config.distributed) {
        return {};
      }

      // 获取追踪头
      const traceId = req.get(this.config.headers.traceId);
      const spanId = req.get(this.config.headers.spanId);
      const parentSpanId = req.get(this.config.headers.parentSpanId);

      // 如果没有追踪ID，返回空对象
      if (!traceId) {
        return {};
      }

      return {
        traceId,
        rootSpanId: spanId,
        parentSpanId,
        tags: {
          'http.method': req.method,
          'http.url': req.originalUrl,
          'http.host': req.get('host'),
          'http.user_agent': req.get('user-agent')
        },
        metadata: {
          distributed: true,
          source: 'external'
        }
      };
    } catch (error) {
      logger.error('提取追踪上下文失败', { error });
      return {};
    }
  }

  /**
   * 注入追踪上下文到请求头
   * @param {Object} headers - 请求头
   * @param {TraceContext} trace - 追踪上下文
   * @param {string} spanId - Span ID
   * @returns {Object} 更新后的请求头
   */
  injectTraceContext(headers, trace, spanId) {
    try {
      // 如果未启用分布式追踪，返回原始请求头
      if (!this.config.distributed) {
        return headers;
      }

      // 如果没有追踪上下文，返回原始请求头
      if (!trace) {
        return headers;
      }

      // 注入追踪头
      headers[this.config.headers.traceId] = trace.traceId;
      headers[this.config.headers.spanId] = spanId;

      // 如果有活动Span，注入父Span ID
      if (trace.activeSpan && trace.activeSpan.id !== spanId) {
        headers[this.config.headers.parentSpanId] = trace.activeSpan.id;
      }

      return headers;
    } catch (error) {
      logger.error('注入追踪上下文失败', { error });
      return headers;
    }
  }

  /**
   * 创建追踪中间件
   * @returns {Function} 中间件函数
   */
  createMiddleware() {
    return (req, res, next) => {
      try {
        // 如果未启用追踪，跳过
        if (!this.config.enabled) {
          return next();
        }

        // 提取追踪上下文
        const contextOptions = this.extractTraceContext(req);

        // 创建追踪
        const trace = this.createTrace(contextOptions);

        // 如果没有创建追踪（采样率），跳过
        if (!trace) {
          return next();
        }

        // 创建请求Span
        const requestSpan = trace.createSpan('http.request', {
          tags: {
            type: 'request',
            'http.method': req.method,
            'http.url': req.originalUrl,
            'http.route': req.route?.path,
            'http.host': req.get('host'),
            'http.user_agent': req.get('user-agent')
          }
        });

        // 将追踪上下文添加到请求对象
        req.trace = trace;
        req.traceId = trace.traceId;
        req.requestSpanId = requestSpan.id;

        // 监听响应完成事件
        res.on('finish', () => {
          // 添加响应标签
          trace.setSpanTag(requestSpan.id, 'http.status_code', res.statusCode);

          // 设置Span状态
          if (res.statusCode >= 400) {
            trace.setSpanStatus(requestSpan.id, 'error', `HTTP ${res.statusCode}`);
          }

          // 结束请求Span
          trace.endSpan(requestSpan.id);

          // 完成追踪
          this.completeTrace(trace.traceId);
        });

        next();
      } catch (error) {
        logger.error('追踪中间件错误', { error });
        next();
      }
    };
  }

  /**
   * 关闭分布式追踪服务
   * @returns {Promise<void>}
   */
  async close() {
    try {
      logger.info('关闭分布式追踪服务');

      // 清除清理定时器
      if (this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = null;
      }

      // 完成所有活动追踪
      for (const [traceId, trace] of this.activeTraces.entries()) {
        trace.complete();
        this.completedTraces.push(trace);
      }

      // 清空活动追踪
      this.activeTraces.clear();

      // 重置状态
      this.initialized = false;

      logger.info('分布式追踪服务已关闭');
    } catch (error) {
      logger.error('关闭分布式追踪服务失败', { error });
      throw error;
    }
  }
}

// 创建单例
const tracingService = new TracingService();

// 导出
module.exports = {
  tracingService,
  TracingService,
  TraceContext
};
