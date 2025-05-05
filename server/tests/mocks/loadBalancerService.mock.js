/**
 * 负载均衡服务模拟
 */
const { EventEmitter } = require('events');

// 节点状态常量
const NODE_STATUS = {
  HEALTHY: 'healthy',
  UNHEALTHY: 'unhealthy',
  UNKNOWN: 'unknown'
};

// 负载均衡算法常量
const ALGORITHMS = {
  ROUND_ROBIN: 'round-robin',
  LEAST_CONNECTIONS: 'least-connections',
  IP_HASH: 'ip-hash',
  RANDOM: 'random'
};

class LoadBalancerService extends EventEmitter {
  constructor(config = {}) {
    super();

    this.config = {
      enabled: true,
      strategy: {
        algorithm: ALGORITHMS.ROUND_ROBIN,
        sticky: false
      },
      nodes: {
        discovery: 'static',
        static: [],
        healthCheck: {
          enabled: true,
          interval: 10000,
          path: '/health',
          timeout: 5000,
          healthyThreshold: 2,
          unhealthyThreshold: 2
        }
      },
      ...config
    };

    this.initialized = false;
    this.nodes = new Map();
    this.nodeHealth = new Map();
    this.nodeConnections = new Map();
    this.roundRobinCounter = 0;
  }

  async initialize() {
    if (this.initialized) {
      return;
    }

    // 初始化节点
    if (this.config.nodes.discovery === 'static') {
      this._initializeStaticNodes();
    }

    this.initialized = true;
    return true;
  }

  async close() {
    this.initialized = false;
    return true;
  }

  _initializeStaticNodes() {
    // 清空现有节点
    this.nodes.clear();
    this.nodeHealth.clear();
    this.nodeConnections.clear();

    // 添加静态节点
    if (Array.isArray(this.config.nodes.static)) {
      this.config.nodes.static.forEach(nodeUrl => {
        const url = new URL(nodeUrl);
        const nodeId = `${url.hostname}${url.port ? ':' + url.port : ''}`;

        this.nodes.set(nodeId, {
          id: nodeId,
          url: nodeUrl,
          hostname: url.hostname,
          port: url.port || (url.protocol === 'https:' ? 443 : 80),
          protocol: url.protocol
        });

        this.nodeHealth.set(nodeId, {
          status: NODE_STATUS.UNKNOWN,
          lastCheck: null,
          consecutiveSuccesses: 0,
          consecutiveFailures: 0
        });

        this.nodeConnections.set(nodeId, 0);
      });
    }
  }

  selectNode(request) {
    if (!this.initialized) {
      throw new Error('负载均衡服务未初始化');
    }

    // 获取健康节点
    const healthyNodes = this._getHealthyNodes();

    if (healthyNodes.length === 0) {
      return null;
    }

    let selectedNode;

    // 根据算法选择节点
    switch (this.config.strategy.algorithm) {
      case ALGORITHMS.LEAST_CONNECTIONS:
        selectedNode = this._selectLeastConnectionsNode(healthyNodes);
        break;

      case ALGORITHMS.IP_HASH:
        selectedNode = this._selectIpHashNode(healthyNodes, request.ip);
        break;

      case ALGORITHMS.RANDOM:
        selectedNode = this._selectRandomNode(healthyNodes);
        break;

      case ALGORITHMS.ROUND_ROBIN:
      default:
        selectedNode = this._selectRoundRobinNode(healthyNodes);
        break;
    }

    return selectedNode;
  }

  _getHealthyNodes() {
    return Array.from(this.nodes.values()).filter(node => {
      const health = this.nodeHealth.get(node.id);
      return health && health.status === NODE_STATUS.HEALTHY;
    });
  }

  _selectRoundRobinNode(nodes) {
    if (nodes.length === 0) {
      return null;
    }

    this.roundRobinCounter = (this.roundRobinCounter + 1) % nodes.length;
    return nodes[this.roundRobinCounter];
  }

  _selectLeastConnectionsNode(nodes) {
    if (nodes.length === 0) {
      return null;
    }

    let minConnections = Infinity;
    let selectedNode = null;

    for (const node of nodes) {
      const connections = this.nodeConnections.get(node.id) || 0;

      if (connections < minConnections) {
        minConnections = connections;
        selectedNode = node;
      }
    }

    return selectedNode;
  }

  _selectIpHashNode(nodes, ip) {
    if (nodes.length === 0) {
      return null;
    }

    const hash = this._hashString(ip || '127.0.0.1');
    const index = hash % nodes.length;

    return nodes[index];
  }

  _selectRandomNode(nodes) {
    if (nodes.length === 0) {
      return null;
    }

    const index = Math.floor(Math.random() * nodes.length);
    return nodes[index];
  }

  _hashString(str) {
    let hash = 0;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }

    return Math.abs(hash);
  }

  async _sendRequest(url, options = {}) {
    // 模拟HTTP请求
    return {
      statusCode: 200,
      headers: {
        'content-type': 'application/json'
      },
      body: { success: true }
    };
  }

  async forwardRequest(req, res) {
    // 选择节点
    const node = this.selectNode(req);

    if (!node) {
      res.status(503).json({ error: '没有可用的服务节点' });
      return;
    }

    try {
      // 增加连接计数
      this.nodeConnections.set(node.id, (this.nodeConnections.get(node.id) || 0) + 1);

      // 模拟转发请求
      const response = await this._sendRequest(`${node.url}${req.url}`);

      // 减少连接计数
      this.nodeConnections.set(node.id, Math.max(0, (this.nodeConnections.get(node.id) || 1) - 1));

      // 设置响应头
      if (response.headers) {
        Object.keys(response.headers).forEach(header => {
          res.setHeader(header, response.headers[header]);
        });
      }

      // 设置状态码和响应体
      res.status(response.statusCode).send(response.body);
    } catch (error) {
      // 减少连接计数
      this.nodeConnections.set(node.id, Math.max(0, (this.nodeConnections.get(node.id) || 1) - 1));

      // 返回错误
      res.status(502).json({ error: '转发请求失败', message: error.message });
    }
  }
}

// 创建实例
const loadBalancerService = new LoadBalancerService();

// 初始化节点
loadBalancerService.nodes = new Map([
  ['node1', { id: 'node1', url: 'http://localhost:3001' }],
  ['node2', { id: 'node2', url: 'http://localhost:3002' }]
]);

loadBalancerService.nodeHealth = new Map([
  ['node1', { status: NODE_STATUS.HEALTHY }],
  ['node2', { status: NODE_STATUS.HEALTHY }]
]);

loadBalancerService.nodeConnections = new Map([
  ['node1', 0],
  ['node2', 0]
]);

module.exports = {
  LoadBalancerService,
  NODE_STATUS,
  ALGORITHMS,
  loadBalancerService
};
