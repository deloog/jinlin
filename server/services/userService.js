/**
 * 用户服务
 */
const User = require('../models/User');
const { generateToken, generateRefreshToken } = require('../middleware/auth');
const logger = require('../utils/logger');

/**
 * 注册用户
 * @param {Object} userData - 用户数据
 * @returns {Object} 用户和令牌
 */
exports.register = async (userData) => {
  try {
    // 创建用户
    const user = await User.create(userData);
    
    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);
    
    return {
      user,
      accessToken,
      refreshToken
    };
  } catch (error) {
    logger.error('注册用户失败:', error);
    throw error;
  }
};

/**
 * 用户登录
 * @param {string} email - 电子邮件
 * @param {string} password - 密码
 * @returns {Object} 用户和令牌
 */
exports.login = async (email, password) => {
  try {
    // 验证用户凭据
    const user = await User.verifyCredentials(email, password);
    
    if (!user) {
      throw new Error('电子邮件或密码无效');
    }
    
    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);
    
    return {
      user,
      accessToken,
      refreshToken
    };
  } catch (error) {
    logger.error('用户登录失败:', error);
    throw error;
  }
};

/**
 * 刷新令牌
 * @param {string} refreshToken - 刷新令牌
 * @returns {Object} 新令牌
 */
exports.refreshToken = async (refreshToken) => {
  try {
    // 验证刷新令牌
    const jwt = require('jsonwebtoken');
    const { jwt: jwtConfig } = require('../config/app');
    
    const decoded = jwt.verify(refreshToken, jwtConfig.secret);
    
    // 检查令牌类型
    if (decoded.type !== 'refresh') {
      throw new Error('无效的刷新令牌');
    }
    
    // 获取用户
    const user = await User.getById(decoded.id);
    if (!user) {
      throw new Error('用户不存在');
    }
    
    // 生成新令牌
    const accessToken = generateToken(user);
    const newRefreshToken = generateRefreshToken(user);
    
    return {
      accessToken,
      refreshToken: newRefreshToken
    };
  } catch (error) {
    logger.error('刷新令牌失败:', error);
    throw error;
  }
};

/**
 * 获取用户列表
 * @param {Object} filters - 过滤条件
 * @returns {Array} 用户列表
 */
exports.getUsers = async (filters = {}) => {
  try {
    return await User.getAll(filters);
  } catch (error) {
    logger.error('获取用户列表失败:', error);
    throw error;
  }
};

/**
 * 获取用户
 * @param {string} id - 用户ID
 * @returns {Object} 用户对象
 */
exports.getUser = async (id) => {
  try {
    const user = await User.getById(id);
    
    if (!user) {
      throw new Error('用户不存在');
    }
    
    return user;
  } catch (error) {
    logger.error('获取用户失败:', error);
    throw error;
  }
};

/**
 * 更新用户
 * @param {string} id - 用户ID
 * @param {Object} userData - 用户数据
 * @returns {Object} 更新的用户
 */
exports.updateUser = async (id, userData) => {
  try {
    const user = await User.getById(id);
    
    if (!user) {
      throw new Error('用户不存在');
    }
    
    return await User.update(id, userData);
  } catch (error) {
    logger.error('更新用户失败:', error);
    throw error;
  }
};

/**
 * 更改密码
 * @param {string} id - 用户ID
 * @param {string} currentPassword - 当前密码
 * @param {string} newPassword - 新密码
 * @returns {boolean} 是否成功
 */
exports.changePassword = async (id, currentPassword, newPassword) => {
  try {
    // 获取用户
    const user = await User.getById(id);
    
    if (!user) {
      throw new Error('用户不存在');
    }
    
    // 验证当前密码
    const fullUser = await User.getByEmail(user.email);
    const bcrypt = require('bcrypt');
    const isValid = await bcrypt.compare(currentPassword, fullUser.password);
    
    if (!isValid) {
      throw new Error('当前密码无效');
    }
    
    // 更新密码
    await User.update(id, {
      password: newPassword
    });
    
    return true;
  } catch (error) {
    logger.error('更改密码失败:', error);
    throw error;
  }
};

/**
 * 删除用户
 * @param {string} id - 用户ID
 * @returns {boolean} 是否成功
 */
exports.deleteUser = async (id) => {
  try {
    const user = await User.getById(id);
    
    if (!user) {
      throw new Error('用户不存在');
    }
    
    return await User.delete(id);
  } catch (error) {
    logger.error('删除用户失败:', error);
    throw error;
  }
};
