/**
 * 认证控制器
 */
const { validationResult } = require('express-validator');
const crypto = require('crypto');
const logger = require('../utils/enhancedLogger');
const { getAuthorizationUrl, handleCallback } = require('../services/oauthService');
const User = require('../models/User');
const { generateToken, generateRefreshToken } = require('../middleware/auth');

/**
 * 获取OAuth授权URL
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getOAuthUrl = async (req, res) => {
  try {
    const { provider } = req.params;
    
    // 生成状态参数
    const state = crypto.randomBytes(16).toString('hex');
    
    // 将状态参数存储在会话中
    req.session.oauthState = state;
    
    // 获取授权URL
    const authUrl = getAuthorizationUrl(provider, { state });
    
    res.json({
      url: authUrl
    });
  } catch (error) {
    logger.error('获取OAuth授权URL失败:', error);
    res.status(500).json({ error: error.message || '获取OAuth授权URL失败' });
  }
};

/**
 * 处理OAuth回调
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.handleOAuthCallback = async (req, res) => {
  try {
    const { provider } = req.params;
    const { code, state } = req.query;
    
    // 验证状态参数
    if (req.session.oauthState !== state) {
      return res.status(400).json({ error: '无效的状态参数' });
    }
    
    // 清除会话中的状态参数
    delete req.session.oauthState;
    
    // 处理回调
    const result = await handleCallback(provider, code, state);
    
    // 返回结果
    res.json({
      message: '登录成功',
      data: {
        user: result.user,
        access_token: result.accessToken,
        refresh_token: result.refreshToken,
        expires_in: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('处理OAuth回调失败:', error);
    res.status(500).json({ error: error.message || '处理OAuth回调失败' });
  }
};

/**
 * 第三方登录
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.thirdPartyLogin = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { provider } = req.params;
    const { token, userData } = req.body;
    
    // 验证提供商
    const supportedProviders = ['google', 'facebook', 'apple', 'wechat', 'qq', 'weibo', 'tiktok'];
    if (!supportedProviders.includes(provider)) {
      return res.status(400).json({ error: `不支持的提供商: ${provider}` });
    }
    
    // 验证令牌和用户数据
    if (!token || !userData || !userData.id) {
      return res.status(400).json({ error: '缺少令牌或用户数据' });
    }
    
    // 查找或创建用户
    let user = await User.findByProviderIdAndType(userData.id, provider);
    
    if (!user) {
      // 检查是否存在相同邮箱的用户
      if (userData.email) {
        user = await User.getByEmail(userData.email);
      }
      
      if (user) {
        // 关联现有用户
        user = await User.update(user.id, {
          provider_id: userData.id,
          provider_type: provider,
          provider_data: JSON.stringify({
            ...JSON.parse(user.provider_data || '{}'),
            [provider]: userData
          })
        });
      } else {
        // 创建新用户
        const username = generateUsername(userData.email, userData.name);
        
        user = await User.create({
          username,
          email: userData.email || `${username}@${provider}.user`,
          password: crypto.randomBytes(16).toString('hex'), // 生成随机密码
          display_name: userData.name,
          avatar_url: userData.picture,
          provider_id: userData.id,
          provider_type: provider,
          provider_data: JSON.stringify({
            [provider]: userData
          }),
          is_email_verified: true // 第三方登录的邮箱视为已验证
        });
      }
    } else {
      // 更新用户信息
      user = await User.update(user.id, {
        display_name: userData.name,
        avatar_url: userData.picture,
        provider_data: JSON.stringify({
          ...JSON.parse(user.provider_data || '{}'),
          [provider]: userData
        })
      });
    }
    
    // 生成JWT令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);
    
    res.json({
      message: '登录成功',
      data: {
        user,
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: 3600 // 1小时
      }
    });
  } catch (error) {
    logger.error('第三方登录失败:', error);
    res.status(500).json({ error: error.message || '第三方登录失败' });
  }
};

/**
 * 生成用户名
 * @param {string} email - 电子邮件
 * @param {string} name - 名称
 * @returns {string} 用户名
 */
function generateUsername(email, name) {
  if (email) {
    return email.split('@')[0];
  }
  
  if (name) {
    return name.toLowerCase().replace(/\s+/g, '_');
  }
  
  return `user_${Date.now()}`;
}
