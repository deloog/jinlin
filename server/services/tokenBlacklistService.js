/**
 * 令牌黑名单服务
 *
 * 实现令牌撤销机制，提高安全性
 * 支持：
 * - 将令牌加入黑名单
 * - 检查令牌是否在黑名单中
 * - 自动清理过期的黑名单记录
 */
const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');
const cacheService = require('./cacheService');
const { jwt: jwtConfig } = require('../config/app');
const { EventEmitter } = require('events');

// 默认配置
const DEFAULT_OPTIONS = {
  namespace: 'token_blacklist', // 缓存命名空间
  cleanupInterval: 3600000,     // 清理间隔（毫秒）
  defaultTTL: 86400,            // 默认黑名单过期时间（秒）
  // JWT密钥已从配置中获取
  enableJTI: false,             // 是否启用JTI（JWT ID）
  enableFingerprint: false,     // 是否启用指纹
  fingerprintHeader: 'X-Fingerprint', // 指纹请求头
  enableRedisTracking: true,    // 是否启用Redis跟踪
  enableEventLogging: true,     // 是否启用事件日志
  maxBlacklistSize: 10000,      // 最大黑名单大小
};

/**
 * 令牌黑名单管理器
 */
class TokenBlacklistManager extends EventEmitter {
  /**
   * 构造函数
   * @param {Object} options - 配置选项
   */
  constructor(options = {}) {
    super();
    this.options = { ...DEFAULT_OPTIONS, ...options };

    // 统计信息
    this.stats = {
      blacklisted: 0,
      checked: 0,
      rejected: 0,
      cleaned: 0,
      errors: 0
    };

    // 启动清理任务
    this._startCleanupTask();

    logger.info('令牌黑名单管理器已创建');
  }

  /**
   * 启动清理任务
   * @private
   */
  _startCleanupTask() {
    this.cleanupInterval = setInterval(() => {
      this._cleanupExpiredTokens();
    }, this.options.cleanupInterval);
  }

  /**
   * 清理过期的令牌
   * @private
   */
  async _cleanupExpiredTokens() {
    try {
      logger.debug('开始清理过期的黑名单令牌');

      // 这里简单实现，实际应该使用更高效的方式清理过期记录
      // 例如，使用Redis的过期机制自动清理

      // 由于我们使用分布式缓存，过期的令牌会自动被清理
      // 这里只需要记录一下清理操作
      this.stats.cleaned++;

      logger.debug('黑名单令牌清理完成');
    } catch (error) {
      logger.error('清理过期的黑名单令牌失败:', error);
      this.stats.errors++;
    }
  }

  /**
   * 生成令牌键
   * @param {string} token - 令牌
   * @returns {string} 令牌键
   * @private
   */
  _generateTokenKey(token) {
    try {
      // 解析令牌
      const decoded = jwt.verify(token, jwtConfig.secret, { ignoreExpiration: true });

      // 使用令牌ID（如果有）
      if (this.options.enableJTI && decoded.jti) {
        return decoded.jti;
      }

      // 使用用户ID和发行时间
      const userId = decoded.id || decoded.sub || 'unknown';
      const issuedAt = decoded.iat || Math.floor(Date.now() / 1000);

      return `${userId}:${issuedAt}`;
    } catch (error) {
      // 如果令牌无效，使用令牌的哈希值
      logger.warn('解析令牌失败，使用令牌哈希值:', error);
      return require('crypto').createHash('sha256').update(token).digest('hex');
    }
  }

  /**
   * 获取令牌过期时间
   * @param {string} token - 令牌
   * @returns {number} 过期时间（秒）
   * @private
   */
  _getTokenExpiry(token) {
    try {
      // 解析令牌
      const decoded = jwt.verify(token, jwtConfig.secret, { ignoreExpiration: true });

      // 如果令牌有过期时间，使用令牌的过期时间
      if (decoded.exp) {
        const now = Math.floor(Date.now() / 1000);
        const ttl = decoded.exp - now;

        // 如果令牌已经过期，使用默认过期时间
        if (ttl <= 0) {
          return this.options.defaultTTL;
        }

        return ttl;
      }
    } catch (error) {
      logger.warn('获取令牌过期时间失败:', error);
    }

    // 默认过期时间
    return this.options.defaultTTL;
  }

  /**
   * 将令牌加入黑名单
   * @param {string} token - 令牌
   * @param {Object} options - 选项
   * @param {number} options.ttl - 过期时间（秒）
   * @param {string} options.reason - 撤销原因
   * @returns {Promise<boolean>} 是否成功
   */
  async blacklistToken(token, options = {}) {
    try {
      // 生成令牌键
      const tokenKey = this._generateTokenKey(token);

      // 获取过期时间
      const ttl = options.ttl || this._getTokenExpiry(token);

      // 黑名单数据
      const blacklistData = {
        token: token.substring(0, 10) + '...', // 只存储令牌的一部分，避免泄露
        reason: options.reason || 'manual_revocation',
        timestamp: Date.now()
      };

      // 将令牌加入黑名单
      await cacheService.set(
        this.options.namespace,
        tokenKey,
        blacklistData,
        ttl
      );

      this.stats.blacklisted++;

      // 发送事件
      this._emitEvent('token-blacklisted', {
        tokenKey,
        reason: blacklistData.reason
      });

      logger.info(`令牌已加入黑名单: ${tokenKey}, 原因: ${blacklistData.reason}`);
      return true;
    } catch (error) {
      logger.error('将令牌加入黑名单失败:', error);
      this.stats.errors++;
      return false;
    }
  }

  /**
   * 检查令牌是否在黑名单中
   * @param {string} token - 令牌
   * @returns {Promise<boolean>} 是否在黑名单中
   */
  async isTokenBlacklisted(token) {
    try {
      // 生成令牌键
      const tokenKey = this._generateTokenKey(token);

      this.stats.checked++;

      // 检查令牌是否在黑名单中
      const blacklistData = await cacheService.get(
        this.options.namespace,
        tokenKey
      );

      const isBlacklisted = blacklistData !== null;

      if (isBlacklisted) {
        this.stats.rejected++;

        // 发送事件
        this._emitEvent('token-rejected', {
          tokenKey,
          reason: blacklistData.reason
        });

        logger.debug(`令牌在黑名单中: ${tokenKey}, 原因: ${blacklistData.reason}`);
      }

      return isBlacklisted;
    } catch (error) {
      logger.error('检查令牌是否在黑名单中失败:', error);
      this.stats.errors++;
      return false; // 出错时默认不拒绝令牌
    }
  }

  /**
   * 从黑名单中移除令牌
   * @param {string} token - 令牌
   * @returns {Promise<boolean>} 是否成功
   */
  async removeFromBlacklist(token) {
    try {
      // 生成令牌键
      const tokenKey = this._generateTokenKey(token);

      // 从黑名单中移除令牌
      await cacheService.del(
        this.options.namespace,
        tokenKey
      );

      // 发送事件
      this._emitEvent('token-removed-from-blacklist', {
        tokenKey
      });

      logger.info(`令牌已从黑名单中移除: ${tokenKey}`);
      return true;
    } catch (error) {
      logger.error('从黑名单中移除令牌失败:', error);
      this.stats.errors++;
      return false;
    }
  }

  /**
   * 撤销用户的所有令牌
   * @param {string} userId - 用户ID
   * @param {Object} options - 选项
   * @param {string} options.reason - 撤销原因
   * @returns {Promise<boolean>} 是否成功
   */
  async revokeAllUserTokens(userId, options = {}) {
    try {
      // 创建用户黑名单记录
      const userBlacklistKey = `user:${userId}`;

      // 黑名单数据
      const blacklistData = {
        userId,
        reason: options.reason || 'user_tokens_revoked',
        timestamp: Date.now()
      };

      // 将用户加入黑名单
      await cacheService.set(
        this.options.namespace,
        userBlacklistKey,
        blacklistData,
        this.options.defaultTTL
      );

      this.stats.blacklisted++;

      // 发送事件
      this._emitEvent('user-tokens-revoked', {
        userId,
        reason: blacklistData.reason
      });

      logger.info(`用户所有令牌已撤销: ${userId}, 原因: ${blacklistData.reason}`);
      return true;
    } catch (error) {
      logger.error('撤销用户所有令牌失败:', error);
      this.stats.errors++;
      return false;
    }
  }

  /**
   * 检查用户是否在黑名单中
   * @param {string} userId - 用户ID
   * @returns {Promise<boolean>} 是否在黑名单中
   */
  async isUserBlacklisted(userId) {
    try {
      // 用户黑名单键
      const userBlacklistKey = `user:${userId}`;

      // 检查用户是否在黑名单中
      const blacklistData = await cacheService.get(
        this.options.namespace,
        userBlacklistKey
      );

      return blacklistData !== null;
    } catch (error) {
      logger.error('检查用户是否在黑名单中失败:', error);
      this.stats.errors++;
      return false; // 出错时默认不拒绝用户
    }
  }

  /**
   * 从黑名单中移除用户
   * @param {string} userId - 用户ID
   * @returns {Promise<boolean>} 是否成功
   */
  async removeUserFromBlacklist(userId) {
    try {
      // 用户黑名单键
      const userBlacklistKey = `user:${userId}`;

      // 从黑名单中移除用户
      await cacheService.del(
        this.options.namespace,
        userBlacklistKey
      );

      // 发送事件
      this._emitEvent('user-removed-from-blacklist', {
        userId
      });

      logger.info(`用户已从黑名单中移除: ${userId}`);
      return true;
    } catch (error) {
      logger.error('从黑名单中移除用户失败:', error);
      this.stats.errors++;
      return false;
    }
  }

  /**
   * 发送事件
   * @param {string} eventName - 事件名称
   * @param {Object} data - 事件数据
   * @private
   */
  _emitEvent(eventName, data = {}) {
    if (this.options.enableEventLogging) {
      this.emit(eventName, {
        timestamp: Date.now(),
        ...data
      });
    }
  }

  /**
   * 获取统计信息
   * @returns {Object} 统计信息
   */
  getStats() {
    return { ...this.stats };
  }

  /**
   * 关闭令牌黑名单管理器
   */
  close() {
    // 清除清理任务
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }

    logger.info('令牌黑名单管理器已关闭');
  }
}

// 创建单例
const tokenBlacklistManager = new TokenBlacklistManager();

module.exports = {
  tokenBlacklistManager,
  TokenBlacklistManager
};
