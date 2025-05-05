/**
 * 负载均衡中间件模拟
 */
const { loadBalancerService } = require('./loadBalancerService.mock');

/**
 * 创建负载均衡中间件
 * @param {Object} options - 选项
 * @returns {Function} 中间件函数
 */
function createLoadBalancerMiddleware(options = {}) {
  // 合并选项
  const middlewareConfig = {
    enabled: true,
    routes: {
      enabled: true,
      patterns: ['/api/external/*', '/api/proxy/*']
    },
    ...options
  };
  
  // 编译路由匹配模式
  const routePatterns = middlewareConfig.routes.patterns.map(pattern => {
    // 将通配符转换为正则表达式
    const regexPattern = pattern
      .replace(/\./g, '\\.')
      .replace(/\//g, '\\/')
      .replace(/\*\*/g, '.*')
      .replace(/\*/g, '[^\\/]*');
    
    return new RegExp(`^${regexPattern}$`);
  });
  
  // 返回中间件函数
  return async (req, res, next) => {
    try {
      // 如果未启用负载均衡，跳过
      if (!middlewareConfig.enabled) {
        return next();
      }
      
      // 检查路由是否匹配
      if (middlewareConfig.routes.enabled) {
        const path = req.path;
        let matched = false;
        
        for (const pattern of routePatterns) {
          if (pattern.test(path)) {
            matched = true;
            break;
          }
        }
        
        // 如果路由不匹配，跳过
        if (!matched) {
          return next();
        }
      }
      
      // 转发请求
      await loadBalancerService.forwardRequest(req, res);
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 创建负载均衡代理中间件
 * @param {string} targetPath - 目标路径
 * @param {Object} options - 选项
 * @returns {Function} 中间件函数
 */
function createLoadBalancerProxy(targetPath, options = {}) {
  // 合并选项
  const proxyConfig = {
    enabled: true,
    ...options
  };
  
  // 返回中间件函数
  return async (req, res, next) => {
    try {
      // 如果未启用负载均衡，跳过
      if (!proxyConfig.enabled) {
        return next();
      }
      
      // 修改请求路径
      const originalUrl = req.url;
      req.url = targetPath + (req.url === '/' ? '' : req.url);
      
      // 转发请求
      await loadBalancerService.forwardRequest(req, res);
      
      // 恢复原始路径
      req.url = originalUrl;
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 创建负载均衡健康检查中间件
 * @returns {Function} 中间件函数
 */
function createHealthCheckMiddleware() {
  return (req, res) => {
    try {
      // 获取负载均衡服务状态
      const status = {
        timestamp: Date.now(),
        service: 'load-balancer',
        status: loadBalancerService.initialized ? 'healthy' : 'initializing',
        nodes: Array.from(loadBalancerService.nodes.keys()).map(nodeId => {
          const node = loadBalancerService.nodes.get(nodeId);
          const health = loadBalancerService.nodeHealth.get(nodeId);
          const connections = loadBalancerService.nodeConnections.get(nodeId);
          const stats = loadBalancerService.nodeStats ? loadBalancerService.nodeStats.get(nodeId) : null;
          
          return {
            id: nodeId,
            url: node.url,
            status: health.status,
            connections,
            lastCheck: health.lastCheck,
            responseTime: health.responseTime,
            requests: stats ? stats.requests : 0,
            errors: stats ? stats.errors : 0,
            latency: stats ? stats.latency : 0
          };
        })
      };
      
      // 返回状态
      res.json(status);
    } catch (error) {
      res.status(500).json({
        timestamp: Date.now(),
        service: 'load-balancer',
        status: 'error',
        error: error.message
      });
    }
  };
}

module.exports = {
  createLoadBalancerMiddleware,
  createLoadBalancerProxy,
  createHealthCheckMiddleware
};
