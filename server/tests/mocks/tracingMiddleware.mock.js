/**
 * 分布式追踪中间件模拟
 */
const { tracingService } = require('./tracingService.mock');

/**
 * 创建追踪中间件
 * @param {Object} options 中间件选项
 * @returns {Function} 中间件函数
 */
function createTracingMiddleware(options = {}) {
  return function tracingMiddleware(req, res, next) {
    // 如果追踪服务未启用，则跳过
    if (!tracingService.config.enabled) {
      return next();
    }
    
    // 路由匹配
    if (options.routes && options.routes.enabled) {
      const { include, exclude } = options.routes;
      
      // 检查排除路径
      if (exclude && Array.isArray(exclude)) {
        for (const pattern of exclude) {
          if (matchPath(req.path, pattern)) {
            return next();
          }
        }
      }
      
      // 检查包含路径
      let matched = false;
      if (include && Array.isArray(include)) {
        for (const pattern of include) {
          if (matchPath(req.path, pattern)) {
            matched = true;
            break;
          }
        }
        
        if (!matched) {
          return next();
        }
      }
    }
    
    try {
      // 提取追踪上下文
      const context = tracingService.extractTraceContext(req);
      
      // 创建追踪
      const trace = tracingService.createTrace({
        ...context,
        tags: {
          ...context.tags,
          environment: process.env.NODE_ENV || 'development',
          'service.name': 'test-app',
          'service.version': '1.0.0'
        }
      });
      
      // 创建请求span
      const span = trace.createSpan('http.request', {
        tags: {
          'http.method': req.method,
          'http.url': req.originalUrl,
          'http.path': req.path,
          'http.remote_addr': req.ip
        }
      });
      
      // 将追踪上下文添加到请求
      req.trace = trace;
      req.traceId = trace.traceId;
      req.requestSpanId = span.id;
      
      // 添加辅助方法
      req.createSpan = (name, options) => trace.createSpan(name, options);
      req.endSpan = (spanId, options) => trace.endSpan(spanId, options);
      
      // 响应完成时结束span和追踪
      res.on('finish', () => {
        trace.endSpan(span.id, {
          tags: {
            'http.status_code': res.statusCode
          }
        });
        
        tracingService.completeTrace(trace.traceId);
      });
      
      next();
    } catch (error) {
      console.error('追踪中间件错误:', error);
      next();
    }
  };
}

/**
 * 创建数据库追踪中间件
 * @param {Object} options 中间件选项
 * @returns {Function} 中间件函数
 */
function createDatabaseTracingMiddleware(options = {}) {
  return function databaseTracingMiddleware(req, res, next) {
    // 如果追踪服务未启用或请求没有追踪上下文，则跳过
    if (!tracingService.config.enabled || !req.trace) {
      return next();
    }
    
    // 添加数据库追踪方法
    req.createDatabaseSpan = (operation, query, params) => {
      const span = req.createSpan('db.query', {
        tags: {
          'db.type': 'mysql',
          'db.operation': operation,
          'db.statement': query
        }
      });
      
      return span;
    };
    
    next();
  };
}

/**
 * 创建外部服务追踪中间件
 * @param {Object} options 中间件选项
 * @returns {Function} 中间件函数
 */
function createExternalTracingMiddleware(options = {}) {
  return function externalTracingMiddleware(req, res, next) {
    // 如果追踪服务未启用或请求没有追踪上下文，则跳过
    if (!tracingService.config.enabled || !req.trace) {
      return next();
    }
    
    // 添加外部服务追踪方法
    req.createExternalSpan = (url, method) => {
      const span = req.createSpan('http.client', {
        tags: {
          'http.url': url,
          'http.method': method
        }
      });
      
      return span;
    };
    
    next();
  };
}

/**
 * 匹配路径
 * @param {string} path 请求路径
 * @param {string} pattern 匹配模式
 * @returns {boolean} 是否匹配
 */
function matchPath(path, pattern) {
  if (pattern === path) {
    return true;
  }
  
  if (pattern.endsWith('*')) {
    const prefix = pattern.slice(0, -1);
    return path.startsWith(prefix);
  }
  
  return false;
}

module.exports = {
  createTracingMiddleware,
  createDatabaseTracingMiddleware,
  createExternalTracingMiddleware
};
