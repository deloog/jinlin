/**
 * 负载均衡服务
 *
 * 提供智能负载均衡功能：
 * - 基于服务健康度的动态负载均衡
 * - 支持请求路由和服务发现
 * - 支持自动扩缩容
 */
const { EventEmitter } = require('events');
const http = require('http');
const https = require('https');
const logger = require('../utils/enhancedLogger');
const { configManager } = require('./configService');
const { multiLevelCacheService } = require('./multiLevelCacheService');

// 缓存命名空间
const CACHE_NAMESPACE = 'loadbalancer';

// 默认配置
const DEFAULT_CONFIG = {
  // 是否启用负载均衡
  enabled: process.env.LOAD_BALANCER_ENABLED === 'true' || false,

  // 服务节点配置
  nodes: {
    // 服务发现方式: 'static', 'dns', 'consul', 'kubernetes'
    discovery: process.env.LOAD_BALANCER_DISCOVERY || 'static',

    // 静态节点列表
    static: (process.env.LOAD_BALANCER_STATIC_NODES || 'http://localhost:3000').split(','),

    // 健康检查配置
    healthCheck: {
      // 是否启用健康检查
      enabled: process.env.LOAD_BALANCER_HEALTH_CHECK_ENABLED === 'true' || true,

      // 健康检查间隔（毫秒）
      interval: parseInt(process.env.LOAD_BALANCER_HEALTH_CHECK_INTERVAL || '10000', 10),

      // 健康检查路径
      path: process.env.LOAD_BALANCER_HEALTH_CHECK_PATH || '/health',

      // 健康检查超时（毫秒）
      timeout: parseInt(process.env.LOAD_BALANCER_HEALTH_CHECK_TIMEOUT || '5000', 10),

      // 健康阈值
      healthyThreshold: parseInt(process.env.LOAD_BALANCER_HEALTHY_THRESHOLD || '2', 10),

      // 不健康阈值
      unhealthyThreshold: parseInt(process.env.LOAD_BALANCER_UNHEALTHY_THRESHOLD || '2', 10)
    }
  },

  // 负载均衡策略配置
  strategy: {
    // 负载均衡算法: 'round-robin', 'least-connections', 'ip-hash', 'weighted', 'adaptive'
    algorithm: process.env.LOAD_BALANCER_ALGORITHM || 'adaptive',

    // 会话保持
    sessionAffinity: {
      // 是否启用会话保持
      enabled: process.env.LOAD_BALANCER_SESSION_AFFINITY_ENABLED === 'true' || false,

      // 会话保持方式: 'cookie', 'ip'
      method: process.env.LOAD_BALANCER_SESSION_AFFINITY_METHOD || 'cookie',

      // Cookie名称
      cookieName: process.env.LOAD_BALANCER_SESSION_COOKIE_NAME || 'SERVERID',

      // Cookie过期时间（秒）
      cookieMaxAge: parseInt(process.env.LOAD_BALANCER_SESSION_COOKIE_MAX_AGE || '3600', 10)
    },

    // 自动扩缩容配置
    autoScaling: {
      // 是否启用自动扩缩容
      enabled: process.env.LOAD_BALANCER_AUTO_SCALING_ENABLED === 'true' || false,

      // 最小节点数
      minNodes: parseInt(process.env.LOAD_BALANCER_MIN_NODES || '1', 10),

      // 最大节点数
      maxNodes: parseInt(process.env.LOAD_BALANCER_MAX_NODES || '5', 10),

      // CPU阈值（百分比）
      cpuThreshold: parseInt(process.env.LOAD_BALANCER_CPU_THRESHOLD || '70', 10),

      // 内存阈值（百分比）
      memoryThreshold: parseInt(process.env.LOAD_BALANCER_MEMORY_THRESHOLD || '80', 10),

      // 请求阈值（每秒请求数）
      requestThreshold: parseInt(process.env.LOAD_BALANCER_REQUEST_THRESHOLD || '1000', 10),

      // 冷却时间（秒）
      cooldown: parseInt(process.env.LOAD_BALANCER_COOLDOWN || '300', 10)
    }
  },

  // 请求超时配置
  timeout: {
    // 连接超时（毫秒）
    connect: parseInt(process.env.LOAD_BALANCER_CONNECT_TIMEOUT || '5000', 10),

    // 读取超时（毫秒）
    read: parseInt(process.env.LOAD_BALANCER_READ_TIMEOUT || '30000', 10),

    // 写入超时（毫秒）
    write: parseInt(process.env.LOAD_BALANCER_WRITE_TIMEOUT || '30000', 10)
  },

  // 重试配置
  retry: {
    // 是否启用重试
    enabled: process.env.LOAD_BALANCER_RETRY_ENABLED === 'true' || true,

    // 最大重试次数
    maxRetries: parseInt(process.env.LOAD_BALANCER_MAX_RETRIES || '3', 10),

    // 重试延迟（毫秒）
    delay: parseInt(process.env.LOAD_BALANCER_RETRY_DELAY || '1000', 10),

    // 重试状态码
    statusCodes: (process.env.LOAD_BALANCER_RETRY_STATUS_CODES || '408,500,502,503,504').split(',').map(Number)
  },

  // 熔断配置
  circuitBreaker: {
    // 是否启用熔断
    enabled: process.env.LOAD_BALANCER_CIRCUIT_BREAKER_ENABLED === 'true' || true,

    // 错误阈值（百分比）
    errorThreshold: parseInt(process.env.LOAD_BALANCER_ERROR_THRESHOLD || '50', 10),

    // 熔断窗口（毫秒）
    windowMs: parseInt(process.env.LOAD_BALANCER_WINDOW_MS || '10000', 10),

    // 最小请求数
    minRequests: parseInt(process.env.LOAD_BALANCER_MIN_REQUESTS || '20', 10),

    // 半开状态超时（毫秒）
    halfOpenTimeout: parseInt(process.env.LOAD_BALANCER_HALF_OPEN_TIMEOUT || '30000', 10)
  }
};

// 节点状态
const NODE_STATUS = {
  HEALTHY: 'healthy',
  UNHEALTHY: 'unhealthy',
  DRAINING: 'draining',
  UNKNOWN: 'unknown'
};

// 负载均衡算法
const ALGORITHMS = {
  ROUND_ROBIN: 'round-robin',
  LEAST_CONNECTIONS: 'least-connections',
  IP_HASH: 'ip-hash',
  WEIGHTED: 'weighted',
  ADAPTIVE: 'adaptive'
};

// 负载均衡服务类
class LoadBalancerService extends EventEmitter {
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
      nodes: {
        ...DEFAULT_CONFIG.nodes,
        ...(config.nodes || {}),
        healthCheck: {
          ...DEFAULT_CONFIG.nodes.healthCheck,
          ...(config.nodes?.healthCheck || {})
        }
      },
      strategy: {
        ...DEFAULT_CONFIG.strategy,
        ...(config.strategy || {}),
        sessionAffinity: {
          ...DEFAULT_CONFIG.strategy.sessionAffinity,
          ...(config.strategy?.sessionAffinity || {})
        },
        autoScaling: {
          ...DEFAULT_CONFIG.strategy.autoScaling,
          ...(config.strategy?.autoScaling || {})
        }
      },
      timeout: {
        ...DEFAULT_CONFIG.timeout,
        ...(config.timeout || {})
      },
      retry: {
        ...DEFAULT_CONFIG.retry,
        ...(config.retry || {})
      },
      circuitBreaker: {
        ...DEFAULT_CONFIG.circuitBreaker,
        ...(config.circuitBreaker || {})
      }
    };

    // 服务节点
    this.nodes = new Map();

    // 节点健康状态
    this.nodeHealth = new Map();

    // 节点连接数
    this.nodeConnections = new Map();

    // 节点权重
    this.nodeWeights = new Map();

    // 节点统计
    this.nodeStats = new Map();

    // 轮询索引
    this.roundRobinIndex = 0;

    // 健康检查定时器
    this.healthCheckTimer = null;

    // 自动扩缩容定时器
    this.autoScalingTimer = null;

    // 初始化状态
    this.initialized = false;

    // 注册配置架构
    this._registerConfigSchema();

    logger.info('负载均衡服务已创建');
  }

  /**
   * 注册配置架构
   * @private
   */
  _registerConfigSchema() {
    const Joi = require('joi');

    // 注册负载均衡配置架构
    configManager.registerSchema('loadBalancer.enabled', Joi.boolean().default(false));
    configManager.registerSchema('loadBalancer.strategy.algorithm', Joi.string().valid('round-robin', 'least-connections', 'ip-hash', 'weighted', 'adaptive').default('adaptive'));
    configManager.registerSchema('loadBalancer.nodes.healthCheck.enabled', Joi.boolean().default(true));
    configManager.registerSchema('loadBalancer.retry.enabled', Joi.boolean().default(true));
    configManager.registerSchema('loadBalancer.retry.maxRetries', Joi.number().min(0).default(3));
  }

  /**
   * 初始化负载均衡服务
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.initialized) {
      return;
    }

    try {
      logger.info('初始化负载均衡服务');

      // 如果未启用负载均衡，不执行初始化
      if (!this.config.enabled) {
        logger.info('负载均衡服务未启用');
        return;
      }

      // 初始化服务节点
      await this._initializeNodes();

      // 启动健康检查
      if (this.config.nodes.healthCheck.enabled) {
        this._startHealthCheck();
      }

      // 启动自动扩缩容
      if (this.config.strategy.autoScaling.enabled) {
        this._startAutoScaling();
      }

      this.initialized = true;
      logger.info('负载均衡服务初始化成功');
    } catch (error) {
      logger.error('初始化负载均衡服务失败', { error });
      throw error;
    }
  }

  /**
   * 初始化服务节点
   * @private
   * @returns {Promise<void>}
   */
  async _initializeNodes() {
    try {
      // 根据服务发现方式初始化节点
      switch (this.config.nodes.discovery) {
        case 'static':
          await this._initializeStaticNodes();
          break;

        case 'dns':
          await this._initializeDnsNodes();
          break;

        case 'consul':
          await this._initializeConsulNodes();
          break;

        case 'kubernetes':
          await this._initializeKubernetesNodes();
          break;

        default:
          throw new Error(`不支持的服务发现方式: ${this.config.nodes.discovery}`);
      }

      logger.info(`已初始化 ${this.nodes.size} 个服务节点`);
    } catch (error) {
      logger.error('初始化服务节点失败', { error });
      throw error;
    }
  }

  /**
   * 初始化静态节点
   * @private
   * @returns {Promise<void>}
   */
  async _initializeStaticNodes() {
    try {
      // 获取静态节点列表
      const staticNodes = this.config.nodes.static;

      // 初始化每个节点
      for (let i = 0; i < staticNodes.length; i++) {
        const nodeUrl = staticNodes[i].trim();

        if (!nodeUrl) {
          continue;
        }

        // 解析URL
        const url = new URL(nodeUrl);

        // 创建节点ID
        const nodeId = `${url.hostname}:${url.port}`;

        // 添加节点
        this.nodes.set(nodeId, {
          id: nodeId,
          url: nodeUrl,
          hostname: url.hostname,
          port: url.port,
          protocol: url.protocol,
          weight: 1
        });

        // 初始化节点健康状态
        this.nodeHealth.set(nodeId, {
          status: NODE_STATUS.UNKNOWN,
          lastCheck: null,
          consecutiveSuccesses: 0,
          consecutiveFailures: 0
        });

        // 初始化节点连接数
        this.nodeConnections.set(nodeId, 0);

        // 初始化节点权重
        this.nodeWeights.set(nodeId, 1);

        // 初始化节点统计
        this.nodeStats.set(nodeId, {
          requests: 0,
          errors: 0,
          latency: 0,
          lastRequest: null
        });
      }
    } catch (error) {
      logger.error('初始化静态节点失败', { error });
      throw error;
    }
  }

  /**
   * 初始化DNS节点
   * @private
   * @returns {Promise<void>}
   */
  async _initializeDnsNodes() {
    // TODO: 实现DNS服务发现
    logger.warn('DNS服务发现尚未实现');
  }

  /**
   * 初始化Consul节点
   * @private
   * @returns {Promise<void>}
   */
  async _initializeConsulNodes() {
    // TODO: 实现Consul服务发现
    logger.warn('Consul服务发现尚未实现');
  }

  /**
   * 初始化Kubernetes节点
   * @private
   * @returns {Promise<void>}
   */
  async _initializeKubernetesNodes() {
    // TODO: 实现Kubernetes服务发现
    logger.warn('Kubernetes服务发现尚未实现');
  }

  /**
   * 启动健康检查
   * @private
   */
  _startHealthCheck() {
    // 清除现有定时器
    if (this.healthCheckTimer) {
      clearInterval(this.healthCheckTimer);
    }

    // 设置新定时器
    this.healthCheckTimer = setInterval(() => {
      this._checkNodesHealth().catch(error => {
        logger.error('检查节点健康状态失败', { error });
      });
    }, this.config.nodes.healthCheck.interval);

    logger.info('健康检查定时器已启动');
  }

  /**
   * 检查节点健康状态
   * @private
   * @returns {Promise<void>}
   */
  async _checkNodesHealth() {
    try {
      // 检查每个节点的健康状态
      const checkPromises = [];

      for (const [nodeId, node] of this.nodes.entries()) {
        checkPromises.push(this._checkNodeHealth(nodeId, node));
      }

      // 等待所有健康检查完成
      await Promise.all(checkPromises);

      // 发出健康检查完成事件
      this.emit('health-check-complete', {
        nodes: Array.from(this.nodes.keys()),
        health: Object.fromEntries(this.nodeHealth)
      });
    } catch (error) {
      logger.error('检查节点健康状态失败', { error });
    }
  }

  /**
   * 检查节点健康状态
   * @private
   * @param {string} nodeId - 节点ID
   * @param {Object} node - 节点
   * @returns {Promise<void>}
   */
  async _checkNodeHealth(nodeId, node) {
    try {
      // 获取节点健康状态
      const health = this.nodeHealth.get(nodeId);

      // 构建健康检查URL
      const healthCheckUrl = `${node.url}${this.config.nodes.healthCheck.path}`;

      // 发送健康检查请求
      const startTime = Date.now();
      const response = await this._sendRequest(healthCheckUrl, {
        method: 'GET',
        timeout: this.config.nodes.healthCheck.timeout
      });
      const endTime = Date.now();

      // 计算响应时间
      const responseTime = endTime - startTime;

      // 检查响应状态
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 健康检查成功
        health.consecutiveSuccesses++;
        health.consecutiveFailures = 0;
        health.lastCheck = new Date();
        health.responseTime = responseTime;

        // 检查是否达到健康阈值
        if (health.status !== NODE_STATUS.HEALTHY && health.consecutiveSuccesses >= this.config.nodes.healthCheck.healthyThreshold) {
          health.status = NODE_STATUS.HEALTHY;

          // 发出节点健康事件
          this.emit('node:healthy', { nodeId, node, health });

          logger.info('节点健康', { nodeId, responseTime });
        }
      } else {
        // 健康检查失败
        health.consecutiveSuccesses = 0;
        health.consecutiveFailures++;
        health.lastCheck = new Date();
        health.responseTime = responseTime;
        health.lastError = `HTTP ${response.statusCode}`;

        // 检查是否达到不健康阈值
        if (health.status !== NODE_STATUS.UNHEALTHY && health.consecutiveFailures >= this.config.nodes.healthCheck.unhealthyThreshold) {
          health.status = NODE_STATUS.UNHEALTHY;

          // 发出节点不健康事件
          this.emit('node:unhealthy', { nodeId, node, health });

          logger.warn('节点不健康', { nodeId, statusCode: response.statusCode });
        }
      }
    } catch (error) {
      // 健康检查失败
      const health = this.nodeHealth.get(nodeId);

      health.consecutiveSuccesses = 0;
      health.consecutiveFailures++;
      health.lastCheck = new Date();
      health.lastError = error.message || String(error);

      // 检查是否达到不健康阈值
      if (health.status !== NODE_STATUS.UNHEALTHY && health.consecutiveFailures >= this.config.nodes.healthCheck.unhealthyThreshold) {
        health.status = NODE_STATUS.UNHEALTHY;

        // 发出节点不健康事件
        this.emit('node:unhealthy', { nodeId, node, health });

        logger.warn('节点不健康', { nodeId, error: health.lastError });
      }
    }
  }

  /**
   * 发送请求
   * @private
   * @param {string} url - URL
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 响应
   */
  _sendRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
      // 解析URL
      const parsedUrl = new URL(url);

      // 选择HTTP客户端
      const client = parsedUrl.protocol === 'https:' ? https : http;

      // 构建请求选项
      const requestOptions = {
        method: options.method || 'GET',
        headers: options.headers || {},
        timeout: options.timeout || this.config.timeout.connect
      };

      // 发送请求
      const req = client.request(url, requestOptions, (res) => {
        // 设置响应超时
        res.setTimeout(options.timeout || this.config.timeout.read);

        // 收集响应数据
        const chunks = [];

        res.on('data', (chunk) => {
          chunks.push(chunk);
        });

        res.on('end', () => {
          // 合并响应数据
          const body = Buffer.concat(chunks).toString();

          // 解析JSON响应
          let parsedBody;
          try {
            parsedBody = JSON.parse(body);
          } catch (e) {
            parsedBody = body;
          }

          // 返回响应
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: parsedBody
          });
        });
      });

      // 设置请求超时
      req.setTimeout(options.timeout || this.config.timeout.connect);

      // 处理错误
      req.on('error', (error) => {
        reject(error);
      });

      // 处理超时
      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timed out'));
      });

      // 发送请求体
      if (options.body) {
        req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
      }

      // 结束请求
      req.end();
    });
  }

  /**
   * 启动自动扩缩容
   * @private
   */
  _startAutoScaling() {
    // 清除现有定时器
    if (this.autoScalingTimer) {
      clearInterval(this.autoScalingTimer);
    }

    // 设置新定时器
    this.autoScalingTimer = setInterval(() => {
      this._checkAutoScaling().catch(error => {
        logger.error('检查自动扩缩容失败', { error });
      });
    }, 60000); // 每分钟检查一次

    logger.info('自动扩缩容定时器已启动');
  }

  /**
   * 检查自动扩缩容
   * @private
   * @returns {Promise<void>}
   */
  async _checkAutoScaling() {
    try {
      // 获取系统负载
      const systemLoad = await this._getSystemLoad();

      // 检查是否需要扩容
      if (this._needsScaleUp(systemLoad)) {
        await this._scaleUp();
      }
      // 检查是否需要缩容
      else if (this._needsScaleDown(systemLoad)) {
        await this._scaleDown();
      }
    } catch (error) {
      logger.error('检查自动扩缩容失败', { error });
    }
  }

  /**
   * 获取系统负载
   * @private
   * @returns {Promise<Object>} 系统负载
   */
  async _getSystemLoad() {
    try {
      // 计算CPU使用率
      const os = require('os');
      const cpus = os.cpus();
      const cpuUsage = process.cpuUsage();
      const cpuUsagePercent = (cpuUsage.user + cpuUsage.system) / (cpus.length * 1000000) * 100;

      // 计算内存使用率
      const totalMemory = os.totalmem();
      const freeMemory = os.freemem();
      const memoryUsagePercent = (totalMemory - freeMemory) / totalMemory * 100;

      // 计算请求率
      const requestRate = this._calculateRequestRate();

      return {
        cpu: cpuUsagePercent,
        memory: memoryUsagePercent,
        requestRate
      };
    } catch (error) {
      logger.error('获取系统负载失败', { error });
      throw error;
    }
  }

  /**
   * 计算请求率
   * @private
   * @returns {number} 请求率
   */
  _calculateRequestRate() {
    // 计算每秒请求数
    let totalRequests = 0;

    for (const stats of this.nodeStats.values()) {
      totalRequests += stats.requests;
    }

    // 重置请求计数
    for (const stats of this.nodeStats.values()) {
      stats.requests = 0;
    }

    // 返回每秒请求数
    return totalRequests / 60;
  }

  /**
   * 检查是否需要扩容
   * @private
   * @param {Object} systemLoad - 系统负载
   * @returns {boolean} 是否需要扩容
   */
  _needsScaleUp(systemLoad) {
    // 检查节点数是否已达到最大值
    if (this.nodes.size >= this.config.strategy.autoScaling.maxNodes) {
      return false;
    }

    // 检查CPU使用率
    if (systemLoad.cpu >= this.config.strategy.autoScaling.cpuThreshold) {
      return true;
    }

    // 检查内存使用率
    if (systemLoad.memory >= this.config.strategy.autoScaling.memoryThreshold) {
      return true;
    }

    // 检查请求率
    if (systemLoad.requestRate >= this.config.strategy.autoScaling.requestThreshold) {
      return true;
    }

    return false;
  }

  /**
   * 检查是否需要缩容
   * @private
   * @param {Object} systemLoad - 系统负载
   * @returns {boolean} 是否需要缩容
   */
  _needsScaleDown(systemLoad) {
    // 检查节点数是否已达到最小值
    if (this.nodes.size <= this.config.strategy.autoScaling.minNodes) {
      return false;
    }

    // 检查CPU使用率
    if (systemLoad.cpu < this.config.strategy.autoScaling.cpuThreshold * 0.5) {
      return true;
    }

    // 检查内存使用率
    if (systemLoad.memory < this.config.strategy.autoScaling.memoryThreshold * 0.5) {
      return true;
    }

    // 检查请求率
    if (systemLoad.requestRate < this.config.strategy.autoScaling.requestThreshold * 0.5) {
      return true;
    }

    return false;
  }

  /**
   * 扩容
   * @private
   * @returns {Promise<void>}
   */
  async _scaleUp() {
    try {
      // TODO: 实现扩容逻辑
      logger.info('扩容');

      // 发出扩容事件
      this.emit('scale:up', {
        currentNodes: this.nodes.size,
        maxNodes: this.config.strategy.autoScaling.maxNodes
      });
    } catch (error) {
      logger.error('扩容失败', { error });
      throw error;
    }
  }

  /**
   * 缩容
   * @private
   * @returns {Promise<void>}
   */
  async _scaleDown() {
    try {
      // TODO: 实现缩容逻辑
      logger.info('缩容');

      // 发出缩容事件
      this.emit('scale:down', {
        currentNodes: this.nodes.size,
        minNodes: this.config.strategy.autoScaling.minNodes
      });
    } catch (error) {
      logger.error('缩容失败', { error });
      throw error;
    }
  }

  /**
   * 选择节点
   * @param {Object} request - 请求
   * @returns {Object|null} 节点
   */
  selectNode(request) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('负载均衡服务未初始化');
    }

    // 如果未启用负载均衡，返回null
    if (!this.config.enabled) {
      return null;
    }

    try {
      // 获取健康节点
      const healthyNodes = this._getHealthyNodes();

      // 如果没有健康节点，返回null
      if (healthyNodes.length === 0) {
        logger.warn('没有健康节点可用');
        return null;
      }

      // 检查会话保持
      if (this.config.strategy.sessionAffinity.enabled) {
        const nodeId = this._getSessionNode(request);

        if (nodeId && this.nodes.has(nodeId) && this.nodeHealth.get(nodeId).status === NODE_STATUS.HEALTHY) {
          return this.nodes.get(nodeId);
        }
      }

      // 根据负载均衡算法选择节点
      let selectedNode;

      switch (this.config.strategy.algorithm) {
        case ALGORITHMS.ROUND_ROBIN:
          selectedNode = this._selectNodeRoundRobin(healthyNodes);
          break;

        case ALGORITHMS.LEAST_CONNECTIONS:
          selectedNode = this._selectNodeLeastConnections(healthyNodes);
          break;

        case ALGORITHMS.IP_HASH:
          selectedNode = this._selectNodeIpHash(healthyNodes, request);
          break;

        case ALGORITHMS.WEIGHTED:
          selectedNode = this._selectNodeWeighted(healthyNodes);
          break;

        case ALGORITHMS.ADAPTIVE:
          selectedNode = this._selectNodeAdaptive(healthyNodes);
          break;

        default:
          selectedNode = this._selectNodeRoundRobin(healthyNodes);
      }

      // 更新节点统计
      if (selectedNode) {
        const nodeId = selectedNode.id;
        const stats = this.nodeStats.get(nodeId);

        stats.requests++;
        stats.lastRequest = new Date();

        // 增加节点连接数
        this.nodeConnections.set(nodeId, this.nodeConnections.get(nodeId) + 1);
      }

      return selectedNode;
    } catch (error) {
      logger.error('选择节点失败', { error });
      return null;
    }
  }

  /**
   * 获取健康节点
   * @private
   * @returns {Array<Object>} 健康节点
   */
  _getHealthyNodes() {
    const healthyNodes = [];

    for (const [nodeId, node] of this.nodes.entries()) {
      const health = this.nodeHealth.get(nodeId);

      if (health.status === NODE_STATUS.HEALTHY) {
        healthyNodes.push(node);
      }
    }

    return healthyNodes;
  }

  /**
   * 获取会话节点
   * @private
   * @param {Object} request - 请求
   * @returns {string|null} 节点ID
   */
  _getSessionNode(request) {
    try {
      // 根据会话保持方式获取节点ID
      switch (this.config.strategy.sessionAffinity.method) {
        case 'cookie':
          // 从Cookie获取节点ID
          if (request.headers && request.headers.cookie) {
            const cookies = request.headers.cookie.split(';');

            for (const cookie of cookies) {
              const [name, value] = cookie.trim().split('=');

              if (name === this.config.strategy.sessionAffinity.cookieName) {
                return value;
              }
            }
          }
          break;

        case 'ip':
          // 从IP获取节点ID
          if (request.ip) {
            // 使用IP哈希选择节点
            const ipHash = this._hashString(request.ip);
            const nodeIds = Array.from(this.nodes.keys());
            const index = ipHash % nodeIds.length;

            return nodeIds[index];
          }
          break;
      }

      return null;
    } catch (error) {
      logger.error('获取会话节点失败', { error });
      return null;
    }
  }

  /**
   * 轮询选择节点
   * @private
   * @param {Array<Object>} nodes - 节点列表
   * @returns {Object} 节点
   */
  _selectNodeRoundRobin(nodes) {
    // 增加轮询索引
    this.roundRobinIndex = (this.roundRobinIndex + 1) % nodes.length;

    return nodes[this.roundRobinIndex];
  }

  /**
   * 最少连接选择节点
   * @private
   * @param {Array<Object>} nodes - 节点列表
   * @returns {Object} 节点
   */
  _selectNodeLeastConnections(nodes) {
    let minConnections = Infinity;
    let selectedNode = null;

    for (const node of nodes) {
      const connections = this.nodeConnections.get(node.id);

      if (connections < minConnections) {
        minConnections = connections;
        selectedNode = node;
      }
    }

    return selectedNode;
  }

  /**
   * IP哈希选择节点
   * @private
   * @param {Array<Object>} nodes - 节点列表
   * @param {Object} request - 请求
   * @returns {Object} 节点
   */
  _selectNodeIpHash(nodes, request) {
    // 获取客户端IP
    const ip = request.ip || '127.0.0.1';

    // 计算哈希值
    const hash = this._hashString(ip);

    // 选择节点
    const index = hash % nodes.length;

    return nodes[index];
  }

  /**
   * 加权选择节点
   * @private
   * @param {Array<Object>} nodes - 节点列表
   * @returns {Object} 节点
   */
  _selectNodeWeighted(nodes) {
    // 计算总权重
    let totalWeight = 0;

    for (const node of nodes) {
      totalWeight += this.nodeWeights.get(node.id);
    }

    // 生成随机数
    const random = Math.random() * totalWeight;

    // 选择节点
    let weightSum = 0;

    for (const node of nodes) {
      weightSum += this.nodeWeights.get(node.id);

      if (random <= weightSum) {
        return node;
      }
    }

    // 默认返回第一个节点
    return nodes[0];
  }

  /**
   * 自适应选择节点
   * @private
   * @param {Array<Object>} nodes - 节点列表
   * @returns {Object} 节点
   */
  _selectNodeAdaptive(nodes) {
    // 计算节点得分
    const scores = new Map();

    for (const node of nodes) {
      const nodeId = node.id;
      const connections = this.nodeConnections.get(nodeId);
      const health = this.nodeHealth.get(nodeId);
      const stats = this.nodeStats.get(nodeId);

      // 计算得分（越低越好）
      let score = connections;

      // 考虑响应时间
      if (health.responseTime) {
        score += health.responseTime / 100;
      }

      // 考虑错误率
      if (stats.requests > 0) {
        const errorRate = stats.errors / stats.requests;
        score += errorRate * 1000;
      }

      scores.set(nodeId, score);
    }

    // 选择得分最低的节点
    let minScore = Infinity;
    let selectedNode = null;

    for (const node of nodes) {
      const score = scores.get(node.id);

      if (score < minScore) {
        minScore = score;
        selectedNode = node;
      }
    }

    return selectedNode;
  }

  /**
   * 哈希字符串
   * @private
   * @param {string} str - 字符串
   * @returns {number} 哈希值
   */
  _hashString(str) {
    let hash = 0;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }

    return Math.abs(hash);
  }

  /**
   * 转发请求
   * @param {Object} request - 请求
   * @param {Object} response - 响应
   * @returns {Promise<void>}
   */
  async forwardRequest(request, response) {
    // 检查初始化状态
    if (!this.initialized) {
      throw new Error('负载均衡服务未初始化');
    }

    // 如果未启用负载均衡，返回错误
    if (!this.config.enabled) {
      response.status(500).json({ error: '负载均衡服务未启用' });
      return;
    }

    try {
      // 选择节点
      const node = this.selectNode(request);

      // 如果没有可用节点，返回错误
      if (!node) {
        response.status(503).json({ error: '没有可用的服务节点' });
        return;
      }

      // 构建转发URL
      const forwardUrl = `${node.url}${request.url}`;

      // 转发请求
      const startTime = Date.now();
      let result;

      try {
        // 发送请求
        result = await this._sendRequest(forwardUrl, {
          method: request.method,
          headers: request.headers,
          body: request.body,
          timeout: this.config.timeout.connect
        });
      } catch (error) {
        // 更新节点统计
        const stats = this.nodeStats.get(node.id);
        stats.errors++;

        // 减少节点连接数
        this.nodeConnections.set(node.id, Math.max(0, this.nodeConnections.get(node.id) - 1));

        // 检查是否需要重试
        if (this.config.retry.enabled && request.retries < this.config.retry.maxRetries) {
          // 增加重试次数
          request.retries = (request.retries || 0) + 1;

          // 延迟重试
          await new Promise(resolve => setTimeout(resolve, this.config.retry.delay));

          // 重试请求
          return this.forwardRequest(request, response);
        }

        // 返回错误
        response.status(502).json({ error: '转发请求失败', message: error.message });
        return;
      }

      // 计算响应时间
      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // 更新节点统计
      const stats = this.nodeStats.get(node.id);
      stats.latency = (stats.latency * 0.9) + (responseTime * 0.1);

      // 减少节点连接数
      this.nodeConnections.set(node.id, Math.max(0, this.nodeConnections.get(node.id) - 1));

      // 设置响应头
      for (const [name, value] of Object.entries(result.headers)) {
        response.setHeader(name, value);
      }

      // 设置会话保持Cookie
      if (this.config.strategy.sessionAffinity.enabled && this.config.strategy.sessionAffinity.method === 'cookie') {
        response.setHeader('Set-Cookie', `${this.config.strategy.sessionAffinity.cookieName}=${node.id}; Max-Age=${this.config.strategy.sessionAffinity.cookieMaxAge}; Path=/`);
      }

      // 设置响应状态码
      response.status(result.statusCode);

      // 发送响应
      response.send(result.body);
    } catch (error) {
      logger.error('转发请求失败', { error, url: request.url });
      response.status(500).json({ error: '转发请求失败', message: error.message });
    }
  }

  /**
   * 关闭负载均衡服务
   * @returns {Promise<void>}
   */
  async close() {
    try {
      logger.info('关闭负载均衡服务');

      // 清除健康检查定时器
      if (this.healthCheckTimer) {
        clearInterval(this.healthCheckTimer);
        this.healthCheckTimer = null;
      }

      // 清除自动扩缩容定时器
      if (this.autoScalingTimer) {
        clearInterval(this.autoScalingTimer);
        this.autoScalingTimer = null;
      }

      // 重置状态
      this.initialized = false;

      logger.info('负载均衡服务已关闭');
    } catch (error) {
      logger.error('关闭负载均衡服务失败', { error });
      throw error;
    }
  }
}

// 创建单例
const loadBalancerService = new LoadBalancerService();

// 导出
module.exports = {
  loadBalancerService,
  LoadBalancerService,
  NODE_STATUS,
  ALGORITHMS
};
