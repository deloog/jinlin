/**
 * 测试辅助函数
 * 
 * 提供测试中常用的辅助函数
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const logger = require('../../../utils/logger');

/**
 * 生成随机字符串
 * @param {number} length - 字符串长度
 * @returns {string} 随机字符串
 */
function generateRandomString(length = 10) {
  return crypto.randomBytes(Math.ceil(length / 2))
    .toString('hex')
    .slice(0, length);
}

/**
 * 生成随机电子邮件
 * @returns {string} 随机电子邮件
 */
function generateRandomEmail() {
  return `test_${Date.now()}_${generateRandomString(5)}@example.com`;
}

/**
 * 生成随机用户名
 * @returns {string} 随机用户名
 */
function generateRandomUsername() {
  return `test_user_${Date.now()}_${generateRandomString(5)}`;
}

/**
 * 生成测试用户数据
 * @param {Object} overrides - 覆盖默认值的对象
 * @returns {Object} 测试用户数据
 */
function generateTestUserData(overrides = {}) {
  return {
    username: generateRandomUsername(),
    email: generateRandomEmail(),
    password: 'Password123!',
    display_name: `Test User ${Date.now()}`,
    ...overrides
  };
}

/**
 * 生成测试提醒事项数据
 * @param {Object} overrides - 覆盖默认值的对象
 * @returns {Object} 测试提醒事项数据
 */
function generateTestReminderData(overrides = {}) {
  return {
    title: `测试提醒事项 ${Date.now()}`,
    description: `这是一个测试提醒事项，创建于 ${new Date().toISOString()}`,
    reminder_date: new Date(Date.now() + 86400000), // 明天
    is_completed: false,
    priority: 'medium',
    ...overrides
  };
}

/**
 * 生成测试JWT令牌
 * @param {Object} payload - 令牌载荷
 * @param {string} secret - 密钥
 * @param {Object} options - 选项
 * @returns {string} JWT令牌
 */
function generateTestToken(payload, secret = process.env.JWT_SECRET, options = {}) {
  try {
    return jwt.sign(payload, secret, {
      expiresIn: '1h',
      ...options
    });
  } catch (error) {
    logger.error('生成测试令牌失败:', error);
    throw error;
  }
}

/**
 * 验证JWT令牌
 * @param {string} token - JWT令牌
 * @param {string} secret - 密钥
 * @returns {Object} 解码后的载荷
 */
function verifyToken(token, secret = process.env.JWT_SECRET) {
  try {
    return jwt.verify(token, secret);
  } catch (error) {
    logger.error('验证令牌失败:', error);
    throw error;
  }
}

/**
 * 等待指定时间
 * @param {number} ms - 毫秒数
 * @returns {Promise<void>}
 */
function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 重试函数
 * @param {Function} fn - 要重试的函数
 * @param {Object} options - 选项
 * @param {number} options.retries - 重试次数
 * @param {number} options.delay - 重试延迟（毫秒）
 * @param {Function} options.shouldRetry - 决定是否重试的函数
 * @returns {Promise<any>} 函数结果
 */
async function retry(fn, { retries = 3, delay = 1000, shouldRetry = () => true } = {}) {
  try {
    return await fn();
  } catch (error) {
    if (retries <= 0 || !shouldRetry(error)) {
      throw error;
    }
    
    logger.warn(`重试函数，剩余重试次数: ${retries - 1}`);
    await wait(delay);
    return retry(fn, { retries: retries - 1, delay, shouldRetry });
  }
}

/**
 * 检查响应状态码
 * @param {Object} response - 响应对象
 * @param {number} expectedStatus - 预期状态码
 * @returns {boolean} 是否匹配
 */
function checkResponseStatus(response, expectedStatus) {
  if (response.status !== expectedStatus) {
    logger.warn(`响应状态码不匹配，预期: ${expectedStatus}，实际: ${response.status}`);
    logger.debug('响应体:', response.body);
    return false;
  }
  return true;
}

/**
 * 检查响应体是否包含指定字段
 * @param {Object} response - 响应对象
 * @param {Array<string>} fields - 字段数组
 * @returns {boolean} 是否包含所有字段
 */
function checkResponseFields(response, fields) {
  const missingFields = fields.filter(field => {
    const fieldParts = field.split('.');
    let current = response.body;
    
    for (const part of fieldParts) {
      if (current === undefined || current === null) {
        return true;
      }
      current = current[part];
    }
    
    return current === undefined;
  });
  
  if (missingFields.length > 0) {
    logger.warn(`响应缺少字段: ${missingFields.join(', ')}`);
    logger.debug('响应体:', response.body);
    return false;
  }
  
  return true;
}

module.exports = {
  generateRandomString,
  generateRandomEmail,
  generateRandomUsername,
  generateTestUserData,
  generateTestReminderData,
  generateTestToken,
  verifyToken,
  wait,
  retry,
  checkResponseStatus,
  checkResponseFields
};
