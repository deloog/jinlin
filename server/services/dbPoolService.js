/**
 * 数据库连接池服务
 * 
 * 提供增强的数据库连接池管理功能：
 * - 连接池健康检查
 * - 自动扩缩容
 * - 读写分离
 * - 主从切换
 * - 连接池监控
 */
const mysql = require('mysql2/promise');
const { EventEmitter } = require('events');
const logger = require('../utils/logger');
const { monitoringService } = require('./monitoringService');

// 默认配置
const DEFAULT_CONFIG = {
  // 主数据库配置
  master: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'jinlin_app',
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT || '10', 10),
    queueLimit: parseInt(process.env.DB_QUEUE_LIMIT || '0', 10),
    waitForConnections: true
  },
  
  // 从数据库配置（可选）
  slaves: [],
  
  // 连接池配置
  pool: {
    minConnections: parseInt(process.env.DB_MIN_CONNECTIONS || '5', 10),
    maxConnections: parseInt(process.env.DB_MAX_CONNECTIONS || '20', 10),
    idleTimeout: parseInt(process.env.DB_IDLE_TIMEOUT || '60000', 10),
    healthCheckInterval: parseInt(process.env.DB_HEALTH_CHECK_INTERVAL || '30000', 10),
    retryInterval: parseInt(process.env.DB_RETRY_INTERVAL || '5000', 10),
    maxRetries: parseInt(process.env.DB_MAX_RETRIES || '3', 10),
    acquireTimeout: parseInt(process.env.DB_ACQUIRE_TIMEOUT || '10000', 10)
  },
  
  // 读写分离配置
  readWrite: {
    enabled: process.env.DB_READ_WRITE_SPLIT === 'true',
    readOnlyTables: (process.env.DB_READ_ONLY_TABLES || '').split(',').filter(Boolean),
    writeOnlyTables: (process.env.DB_WRITE_ONLY_TABLES || '').split(',').filter(Boolean),
    strategy: process.env.DB_READ_STRATEGY || 'round-robin' // round-robin, random, least-connections
  },
  
  // 自动扩缩容配置
  autoScale: {
    enabled: process.env.DB_AUTO_SCALE === 'true',
    scaleUpThreshold: parseInt(process.env.DB_SCALE_UP_THRESHOLD || '80', 10), // 使用率超过80%时扩容
    scaleDownThreshold: parseInt(process.env.DB_SCALE_DOWN_THRESHOLD || '20', 10), // 使用率低于20%时缩容
    scaleStep: parseInt(process.env.DB_SCALE_STEP || '2', 10), // 每次扩缩容的连接数
    cooldownPeriod: parseInt(process.env.DB_SCALE_COOLDOWN || '60000', 10) // 冷却期（毫秒）
  }
};

// 从环境变量加载从数据库配置
if (process.env.DB_SLAVES) {
  try {
    const slavesConfig = JSON.parse(process.env.DB_SLAVES);
    if (Array.isArray(slavesConfig)) {
      DEFAULT_CONFIG.slaves = slavesConfig;
    }
  } catch (error) {
    logger.error('解析从数据库配置失败:', error);
  }
}

/**
 * 数据库连接池管理器
 */
class DbPoolManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} config - 配置
   */
  constructor(config = {}) {
    super();
    
    // 合并配置
    this.config = {
      master: { ...DEFAULT_CONFIG.master, ...config.master },
      slaves: config.slaves || DEFAULT_CONFIG.slaves,
      pool: { ...DEFAULT_CONFIG.pool, ...config.pool },
      readWrite: { ...DEFAULT_CONFIG.readWrite, ...config.readWrite },
      autoScale: { ...DEFAULT_CONFIG.autoScale, ...config.autoScale }
    };
    
    // 连接池
    this.masterPool = null;
    this.slavePools = [];
    
    // 连接池状态
    this.poolStatus = {
      master: {
        healthy: false,
        connections: {
          total: 0,
          active: 0,
          idle: 0
        },
        lastError: null,
        lastErrorTime: null
      },
      slaves: []
    };
    
    // 读取策略计数器
    this.roundRobinCounter = 0;
    
    // 上次扩缩容时间
    this.lastScaleTime = 0;
    
    // 初始化连接池
    this._initPools();
    
    // 启动健康检查
    this._startHealthCheck();
    
    logger.info('数据库连接池管理器已初始化');
  }
  
  /**
   * 初始化连接池
   * @private
   */
  _initPools() {
    // 初始化主连接池
    this._initMasterPool();
    
    // 初始化从连接池
    this._initSlavePools();
  }
  
  /**
   * 初始化主连接池
   * @private
   */
  _initMasterPool() {
    try {
      // 创建主连接池
      this.masterPool = mysql.createPool({
        ...this.config.master,
        connectionLimit: this.config.pool.minConnections
      });
      
      logger.info('主数据库连接池已初始化');
      
      // 初始化主连接池状态
      this.poolStatus.master = {
        healthy: false,
        connections: {
          total: 0,
          active: 0,
          idle: 0
        },
        lastError: null,
        lastErrorTime: null
      };
      
      // 测试连接
      this._testMasterConnection();
    } catch (error) {
      logger.error('初始化主数据库连接池失败:', error);
      this.poolStatus.master.healthy = false;
      this.poolStatus.master.lastError = error.message;
      this.poolStatus.master.lastErrorTime = new Date();
      
      this.emit('master-init-error', { error });
    }
  }
  
  /**
   * 初始化从连接池
   * @private
   */
  _initSlavePools() {
    // 清理现有从连接池
    this.slavePools = [];
    this.poolStatus.slaves = [];
    
    // 创建从连接池
    for (let i = 0; i < this.config.slaves.length; i++) {
      try {
        const slaveConfig = this.config.slaves[i];
        
        // 创建从连接池
        const slavePool = mysql.createPool({
          ...slaveConfig,
          connectionLimit: this.config.pool.minConnections
        });
        
        this.slavePools.push(slavePool);
        
        // 初始化从连接池状态
        this.poolStatus.slaves.push({
          id: i,
          healthy: false,
          connections: {
            total: 0,
            active: 0,
            idle: 0
          },
          lastError: null,
          lastErrorTime: null
        });
        
        logger.info(`从数据库连接池 ${i} 已初始化`);
        
        // 测试连接
        this._testSlaveConnection(i);
      } catch (error) {
        logger.error(`初始化从数据库连接池 ${i} 失败:`, error);
        
        this.poolStatus.slaves.push({
          id: i,
          healthy: false,
          connections: {
            total: 0,
            active: 0,
            idle: 0
          },
          lastError: error.message,
          lastErrorTime: new Date()
        });
        
        this.slavePools.push(null);
        
        this.emit('slave-init-error', { slaveId: i, error });
      }
    }
  }
  
  /**
   * 测试主连接
   * @private
   */
  async _testMasterConnection() {
    if (!this.masterPool) {
      return;
    }
    
    try {
      const connection = await this.masterPool.getConnection();
      
      // 执行简单查询
      await connection.query('SELECT 1 AS result');
      
      connection.release();
      
      // 更新状态
      this.poolStatus.master.healthy = true;
      
      this.emit('master-connected');
      
      logger.info('主数据库连接成功');
      
      return true;
    } catch (error) {
      logger.error('测试主数据库连接失败:', error);
      
      // 更新状态
      this.poolStatus.master.healthy = false;
      this.poolStatus.master.lastError = error.message;
      this.poolStatus.master.lastErrorTime = new Date();
      
      this.emit('master-connection-error', { error });
      
      return false;
    }
  }
  
  /**
   * 测试从连接
   * @param {number} slaveId - 从数据库ID
   * @private
   */
  async _testSlaveConnection(slaveId) {
    const slavePool = this.slavePools[slaveId];
    
    if (!slavePool) {
      return;
    }
    
    try {
      const connection = await slavePool.getConnection();
      
      // 执行简单查询
      await connection.query('SELECT 1 AS result');
      
      connection.release();
      
      // 更新状态
      this.poolStatus.slaves[slaveId].healthy = true;
      
      this.emit('slave-connected', { slaveId });
      
      logger.info(`从数据库 ${slaveId} 连接成功`);
      
      return true;
    } catch (error) {
      logger.error(`测试从数据库 ${slaveId} 连接失败:`, error);
      
      // 更新状态
      this.poolStatus.slaves[slaveId].healthy = false;
      this.poolStatus.slaves[slaveId].lastError = error.message;
      this.poolStatus.slaves[slaveId].lastErrorTime = new Date();
      
      this.emit('slave-connection-error', { slaveId, error });
      
      return false;
    }
  }
  
  /**
   * 启动健康检查
   * @private
   */
  _startHealthCheck() {
    // 设置健康检查定时器
    this.healthCheckInterval = setInterval(() => {
      this._performHealthCheck();
    }, this.config.pool.healthCheckInterval);
    
    logger.info(`数据库健康检查已启动，间隔: ${this.config.pool.healthCheckInterval}ms`);
  }
  
  /**
   * 执行健康检查
   * @private
   */
  async _performHealthCheck() {
    try {
      // 检查主连接池
      await this._checkMasterHealth();
      
      // 检查从连接池
      for (let i = 0; i < this.slavePools.length; i++) {
        await this._checkSlaveHealth(i);
      }
      
      // 更新连接池状态
      await this._updatePoolStats();
      
      // 自动扩缩容
      if (this.config.autoScale.enabled) {
        this._autoScale();
      }
      
      // 更新监控指标
      this._updateMonitoringMetrics();
    } catch (error) {
      logger.error('执行数据库健康检查失败:', error);
    }
  }
  
  /**
   * 检查主连接池健康
   * @private
   */
  async _checkMasterHealth() {
    if (!this.masterPool) {
      return;
    }
    
    const wasHealthy = this.poolStatus.master.healthy;
    const isHealthy = await this._testMasterConnection();
    
    // 如果状态发生变化
    if (wasHealthy !== isHealthy) {
      if (isHealthy) {
        logger.info('主数据库已恢复');
        this.emit('master-recovered');
      } else {
        logger.warn('主数据库不可用');
        this.emit('master-down');
      }
    }
  }
  
  /**
   * 检查从连接池健康
   * @param {number} slaveId - 从数据库ID
   * @private
   */
  async _checkSlaveHealth(slaveId) {
    if (!this.slavePools[slaveId]) {
      return;
    }
    
    const wasHealthy = this.poolStatus.slaves[slaveId].healthy;
    const isHealthy = await this._testSlaveConnection(slaveId);
    
    // 如果状态发生变化
    if (wasHealthy !== isHealthy) {
      if (isHealthy) {
        logger.info(`从数据库 ${slaveId} 已恢复`);
        this.emit('slave-recovered', { slaveId });
      } else {
        logger.warn(`从数据库 ${slaveId} 不可用`);
        this.emit('slave-down', { slaveId });
      }
    }
  }
  
  /**
   * 更新连接池统计信息
   * @private
   */
  async _updatePoolStats() {
    try {
      // 更新主连接池统计信息
      if (this.masterPool) {
        const stats = await this._getPoolStats(this.masterPool);
        this.poolStatus.master.connections = stats;
      }
      
      // 更新从连接池统计信息
      for (let i = 0; i < this.slavePools.length; i++) {
        if (this.slavePools[i]) {
          const stats = await this._getPoolStats(this.slavePools[i]);
          this.poolStatus.slaves[i].connections = stats;
        }
      }
    } catch (error) {
      logger.error('更新连接池统计信息失败:', error);
    }
  }
  
  /**
   * 获取连接池统计信息
   * @param {Object} pool - 连接池
   * @returns {Promise<Object>} 统计信息
   * @private
   */
  async _getPoolStats(pool) {
    // 注意：mysql2不直接暴露连接池统计信息，这里使用一个变通方法
    try {
      // 获取连接池内部状态
      const poolStats = pool.pool ? pool.pool : { _allConnections: [], _freeConnections: [] };
      
      return {
        total: poolStats._allConnections ? poolStats._allConnections.length : 0,
        active: poolStats._allConnections && poolStats._freeConnections ? 
                poolStats._allConnections.length - poolStats._freeConnections.length : 0,
        idle: poolStats._freeConnections ? poolStats._freeConnections.length : 0
      };
    } catch (error) {
      logger.error('获取连接池统计信息失败:', error);
      return { total: 0, active: 0, idle: 0 };
    }
  }
  
  /**
   * 自动扩缩容
   * @private
   */
  async _autoScale() {
    // 检查冷却期
    const now = Date.now();
    if (now - this.lastScaleTime < this.config.autoScale.cooldownPeriod) {
      return;
    }
    
    try {
      // 主连接池扩缩容
      if (this.masterPool && this.poolStatus.master.healthy) {
        await this._scalePool(
          this.masterPool, 
          this.poolStatus.master.connections,
          'master'
        );
      }
      
      // 从连接池扩缩容
      for (let i = 0; i < this.slavePools.length; i++) {
        if (this.slavePools[i] && this.poolStatus.slaves[i].healthy) {
          await this._scalePool(
            this.slavePools[i], 
            this.poolStatus.slaves[i].connections,
            `slave-${i}`
          );
        }
      }
    } catch (error) {
      logger.error('自动扩缩容失败:', error);
    }
  }
  
  /**
   * 扩缩容连接池
   * @param {Object} pool - 连接池
   * @param {Object} stats - 连接池统计信息
   * @param {string} poolName - 连接池名称
   * @private
   */
  async _scalePool(pool, stats, poolName) {
    // 计算使用率
    const usageRate = stats.total > 0 ? (stats.active / stats.total) * 100 : 0;
    
    // 获取当前连接限制
    const currentLimit = pool.config.connectionLimit;
    
    // 检查是否需要扩容
    if (usageRate > this.config.autoScale.scaleUpThreshold && 
        currentLimit < this.config.pool.maxConnections) {
      
      // 计算新的连接限制
      const newLimit = Math.min(
        currentLimit + this.config.autoScale.scaleStep,
        this.config.pool.maxConnections
      );
      
      // 更新连接限制
      pool.config.connectionLimit = newLimit;
      
      logger.info(`扩容连接池 ${poolName}: ${currentLimit} -> ${newLimit} (使用率: ${usageRate.toFixed(2)}%)`);
      
      this.emit('pool-scaled-up', { 
        poolName, 
        oldLimit: currentLimit, 
        newLimit, 
        usageRate 
      });
      
      this.lastScaleTime = Date.now();
    }
    // 检查是否需要缩容
    else if (usageRate < this.config.autoScale.scaleDownThreshold && 
             currentLimit > this.config.pool.minConnections &&
             stats.active < currentLimit / 2) {
      
      // 计算新的连接限制
      const newLimit = Math.max(
        currentLimit - this.config.autoScale.scaleStep,
        this.config.pool.minConnections
      );
      
      // 更新连接限制
      pool.config.connectionLimit = newLimit;
      
      logger.info(`缩容连接池 ${poolName}: ${currentLimit} -> ${newLimit} (使用率: ${usageRate.toFixed(2)}%)`);
      
      this.emit('pool-scaled-down', { 
        poolName, 
        oldLimit: currentLimit, 
        newLimit, 
        usageRate 
      });
      
      this.lastScaleTime = Date.now();
    }
  }
  
  /**
   * 更新监控指标
   * @private
   */
  _updateMonitoringMetrics() {
    try {
      // 构建监控指标
      const metrics = {
        master: {
          ...this.poolStatus.master,
          config: {
            host: this.config.master.host,
            port: this.config.master.port,
            database: this.config.master.database,
            connectionLimit: this.masterPool ? this.masterPool.config.connectionLimit : 0
          }
        },
        slaves: this.poolStatus.slaves.map((slave, index) => ({
          ...slave,
          config: this.config.slaves[index] ? {
            host: this.config.slaves[index].host,
            port: this.config.slaves[index].port,
            database: this.config.slaves[index].database,
            connectionLimit: this.slavePools[index] ? this.slavePools[index].config.connectionLimit : 0
          } : {}
        })),
        readWriteSplit: {
          enabled: this.config.readWrite.enabled,
          strategy: this.config.readWrite.strategy
        },
        autoScale: {
          enabled: this.config.autoScale.enabled,
          lastScaleTime: this.lastScaleTime
        }
      };
      
      // 更新监控指标
      if (monitoringService && typeof monitoringService.updateDbPoolMetrics === 'function') {
        monitoringService.updateDbPoolMetrics(metrics);
      }
    } catch (error) {
      logger.error('更新数据库连接池监控指标失败:', error);
    }
  }
  
  /**
   * 获取连接
   * @param {Object} options - 选项
   * @returns {Promise<Object>} 连接对象
   */
  async getConnection(options = {}) {
    const { readOnly = false, table = null } = options;
    
    // 检查是否启用读写分离
    const useReadWriteSplit = this.config.readWrite.enabled && 
                             this.slavePools.length > 0 && 
                             this.slavePools.some((pool, index) => pool && this.poolStatus.slaves[index].healthy);
    
    // 确定是否使用从库
    let useSlave = false;
    
    if (useReadWriteSplit) {
      // 如果指定了表，检查是否是只读表或只写表
      if (table) {
        if (this.config.readWrite.readOnlyTables.includes(table)) {
          useSlave = true;
        } else if (this.config.readWrite.writeOnlyTables.includes(table)) {
          useSlave = false;
        } else {
          useSlave = readOnly;
        }
      } else {
        useSlave = readOnly;
      }
    }
    
    // 如果使用从库，选择一个健康的从库
    if (useSlave) {
      const slavePool = this._selectSlavePool();
      
      if (slavePool) {
        try {
          const connection = await slavePool.getConnection();
          
          // 包装连接，添加释放方法
          return this._wrapConnection(connection, 'slave');
        } catch (error) {
          logger.error('从从库获取连接失败，尝试主库:', error);
          // 从库获取连接失败，尝试主库
        }
      }
    }
    
    // 使用主库
    if (!this.masterPool || !this.poolStatus.master.healthy) {
      throw new Error('主数据库不可用');
    }
    
    try {
      const connection = await this.masterPool.getConnection();
      
      // 包装连接，添加释放方法
      return this._wrapConnection(connection, 'master');
    } catch (error) {
      logger.error('从主库获取连接失败:', error);
      throw error;
    }
  }
  
  /**
   * 包装连接对象
   * @param {Object} connection - 原始连接对象
   * @param {string} source - 连接来源
   * @returns {Object} 包装后的连接对象
   * @private
   */
  _wrapConnection(connection, source) {
    // 保存原始release方法
    const originalRelease = connection.release;
    
    // 重写release方法
    connection.release = () => {
      try {
        originalRelease.call(connection);
      } catch (error) {
        logger.error(`释放${source}连接失败:`, error);
      }
    };
    
    // 添加来源标记
    connection._source = source;
    
    return connection;
  }
  
  /**
   * 选择从库连接池
   * @returns {Object|null} 从库连接池
   * @private
   */
  _selectSlavePool() {
    // 获取健康的从库
    const healthySlaves = this.slavePools
      .map((pool, index) => ({ pool, index }))
      .filter(item => item.pool && this.poolStatus.slaves[item.index].healthy);
    
    if (healthySlaves.length === 0) {
      return null;
    }
    
    // 根据策略选择从库
    switch (this.config.readWrite.strategy) {
      case 'random':
        // 随机选择
        return healthySlaves[Math.floor(Math.random() * healthySlaves.length)].pool;
        
      case 'least-connections':
        // 选择连接数最少的
        return healthySlaves.reduce((min, current) => {
          const minActive = this.poolStatus.slaves[min.index].connections.active;
          const currentActive = this.poolStatus.slaves[current.index].connections.active;
          
          return currentActive < minActive ? current : min;
        }).pool;
        
      case 'round-robin':
      default:
        // 轮询
        this.roundRobinCounter = (this.roundRobinCounter + 1) % healthySlaves.length;
        return healthySlaves[this.roundRobinCounter].pool;
    }
  }
  
  /**
   * 执行查询
   * @param {string} sql - SQL语句
   * @param {Array} params - 查询参数
   * @param {Object} options - 选项
   * @returns {Promise<Array>} 查询结果
   */
  async query(sql, params = [], options = {}) {
    // 确定是否是只读查询
    const isReadOnly = sql.trim().toLowerCase().startsWith('select');
    
    // 提取表名（简单实现，实际应使用SQL解析器）
    let table = null;
    
    if (options.table) {
      table = options.table;
    } else {
      // 简单的表名提取
      const fromMatch = sql.match(/from\s+`?(\w+)`?/i);
      if (fromMatch && fromMatch[1]) {
        table = fromMatch[1];
      }
    }
    
    // 获取连接
    const connection = await this.getConnection({
      readOnly: isReadOnly,
      table
    });
    
    try {
      // 执行查询
      const [results] = await connection.query(sql, params);
      return results;
    } finally {
      // 释放连接
      connection.release();
    }
  }
  
  /**
   * 执行事务
   * @param {Function} callback - 回调函数
   * @returns {Promise<*>} 事务结果
   */
  async transaction(callback) {
    // 事务必须在主库上执行
    if (!this.masterPool || !this.poolStatus.master.healthy) {
      throw new Error('主数据库不可用，无法执行事务');
    }
    
    const connection = await this.masterPool.getConnection();
    
    try {
      // 开始事务
      await connection.beginTransaction();
      
      // 执行回调
      const result = await callback(connection);
      
      // 提交事务
      await connection.commit();
      
      return result;
    } catch (error) {
      // 回滚事务
      try {
        await connection.rollback();
      } catch (rollbackError) {
        logger.error('事务回滚失败:', rollbackError);
      }
      
      throw error;
    } finally {
      // 释放连接
      connection.release();
    }
  }
  
  /**
   * 关闭连接池
   */
  async close() {
    // 清理健康检查定时器
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      this.healthCheckInterval = null;
    }
    
    // 关闭主连接池
    if (this.masterPool) {
      try {
        await this.masterPool.end();
        logger.info('主数据库连接池已关闭');
      } catch (error) {
        logger.error('关闭主数据库连接池失败:', error);
      }
      
      this.masterPool = null;
    }
    
    // 关闭从连接池
    for (let i = 0; i < this.slavePools.length; i++) {
      if (this.slavePools[i]) {
        try {
          await this.slavePools[i].end();
          logger.info(`从数据库连接池 ${i} 已关闭`);
        } catch (error) {
          logger.error(`关闭从数据库连接池 ${i} 失败:`, error);
        }
      }
    }
    
    this.slavePools = [];
    
    logger.info('数据库连接池管理器已关闭');
  }
  
  /**
   * 获取连接池状态
   * @returns {Object} 连接池状态
   */
  getStatus() {
    return { ...this.poolStatus };
  }
}

// 创建单例
const dbPoolManager = new DbPoolManager();

module.exports = {
  dbPoolManager,
  DbPoolManager
};
