/**
 * OAuth服务
 *
 * 处理第三方登录认证
 */
const axios = require('axios');
const querystring = require('querystring');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const oauthConfig = require('../config/oauth');
const logger = require('../utils/enhancedLogger');
const User = require('../models/User');
const { generateToken, generateRefreshToken } = require('../middleware/auth');

/**
 * 获取OAuth提供商授权URL
 * @param {string} provider - 提供商名称
 * @param {Object} options - 选项
 * @returns {string} 授权URL
 */
function getAuthorizationUrl(provider, options = {}) {
  const state = options.state || crypto.randomBytes(16).toString('hex');

  switch (provider) {
    case 'google':
      if (!oauthConfig.google.enabled) {
        throw new Error('Google OAuth未启用');
      }

      return `https://accounts.google.com/o/oauth2/v2/auth?${querystring.stringify({
        client_id: oauthConfig.google.clientId,
        redirect_uri: `${oauthConfig.callbackUrl}/google`,
        response_type: 'code',
        scope: oauthConfig.google.scope.join(' '),
        state,
        access_type: 'offline',
        prompt: 'consent'
      })}`;

    case 'facebook':
      if (!oauthConfig.facebook.enabled) {
        throw new Error('Facebook OAuth未启用');
      }

      return `https://www.facebook.com/v12.0/dialog/oauth?${querystring.stringify({
        client_id: oauthConfig.facebook.clientId,
        redirect_uri: `${oauthConfig.callbackUrl}/facebook`,
        response_type: 'code',
        scope: oauthConfig.facebook.scope.join(','),
        state
      })}`;

    case 'apple':
      if (!oauthConfig.apple.enabled) {
        throw new Error('Apple OAuth未启用');
      }

      return `https://appleid.apple.com/auth/authorize?${querystring.stringify({
        client_id: oauthConfig.apple.clientId,
        redirect_uri: `${oauthConfig.callbackUrl}/apple`,
        response_type: 'code',
        scope: oauthConfig.apple.scope.join(' '),
        state,
        response_mode: 'form_post'
      })}`;

    case 'wechat':
      if (!oauthConfig.wechat.enabled) {
        throw new Error('微信OAuth未启用');
      }

      return `https://open.weixin.qq.com/connect/qrconnect?${querystring.stringify({
        appid: oauthConfig.wechat.appId,
        redirect_uri: `${oauthConfig.callbackUrl}/wechat`,
        response_type: 'code',
        scope: oauthConfig.wechat.scope.join(','),
        state
      })}#wechat_redirect`;

    case 'qq':
      if (!oauthConfig.qq.enabled) {
        throw new Error('QQ OAuth未启用');
      }

      return `https://graph.qq.com/oauth2.0/authorize?${querystring.stringify({
        client_id: oauthConfig.qq.appId,
        redirect_uri: `${oauthConfig.callbackUrl}/qq`,
        response_type: 'code',
        scope: oauthConfig.qq.scope.join(','),
        state
      })}`;

    case 'weibo':
      if (!oauthConfig.weibo.enabled) {
        throw new Error('微博OAuth未启用');
      }

      return `https://api.weibo.com/oauth2/authorize?${querystring.stringify({
        client_id: oauthConfig.weibo.appKey,
        redirect_uri: `${oauthConfig.callbackUrl}/weibo`,
        response_type: 'code',
        scope: oauthConfig.weibo.scope.join(','),
        state
      })}`;

    case 'tiktok':
      if (!oauthConfig.tiktok.enabled) {
        throw new Error('抖音OAuth未启用');
      }

      return `https://open.douyin.com/platform/oauth/connect?${querystring.stringify({
        client_key: oauthConfig.tiktok.clientKey,
        redirect_uri: `${oauthConfig.callbackUrl}/tiktok`,
        response_type: 'code',
        scope: oauthConfig.tiktok.scope.join(','),
        state
      })}`;

    default:
      throw new Error(`不支持的OAuth提供商: ${provider}`);
  }
}

/**
 * 处理OAuth回调
 * @param {string} provider - 提供商名称
 * @param {string} code - 授权码
 * @param {string} state - 状态
 * @returns {Promise<Object>} 用户信息和令牌
 */
async function handleCallback(provider, code, state) {
  try {
    // 获取访问令牌
    const tokenData = await getAccessToken(provider, code);

    // 获取用户信息
    const userInfo = await getUserInfo(provider, tokenData);

    // 创建或更新用户
    const user = await createOrUpdateUser(provider, userInfo);

    // 生成JWT令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    return {
      user,
      accessToken,
      refreshToken,
      expiresIn: 3600 // 1小时
    };
  } catch (error) {
    logger.error(`处理${provider}回调失败:`, error);
    throw error;
  }
}

/**
 * 获取访问令牌
 * @param {string} provider - 提供商名称
 * @param {string} code - 授权码
 * @returns {Promise<Object>} 令牌数据
 */
async function getAccessToken(provider, code) {
  try {
    logger.info(`正在获取${provider}访问令牌，授权码: ${code.substring(0, 5)}...`);

    switch (provider) {
      case 'google':
        try {
          const googleResponse = await axios.post('https://oauth2.googleapis.com/token', {
            code,
            client_id: oauthConfig.google.clientId,
            client_secret: oauthConfig.google.clientSecret,
            redirect_uri: `${oauthConfig.callbackUrl}/google`,
            grant_type: 'authorization_code'
          });

          logger.debug(`成功获取Google访问令牌，令牌类型: ${googleResponse.data.token_type}`);
          return googleResponse.data;
        } catch (error) {
          logger.error(`获取Google访问令牌失败:`, {
            error: error.message,
            status: error.response?.status,
            data: error.response?.data
          });
          throw new Error(`获取Google访问令牌失败: ${error.response?.data?.error_description || error.message}`);
        }

      case 'facebook':
        try {
          const facebookResponse = await axios.get(`https://graph.facebook.com/v12.0/oauth/access_token?${querystring.stringify({
            code,
            client_id: oauthConfig.facebook.clientId,
            client_secret: oauthConfig.facebook.clientSecret,
            redirect_uri: `${oauthConfig.callbackUrl}/facebook`
          })}`);

          logger.debug(`成功获取Facebook访问令牌，过期时间: ${facebookResponse.data.expires_in}秒`);
          return facebookResponse.data;
        } catch (error) {
          logger.error(`获取Facebook访问令牌失败:`, {
            error: error.message,
            status: error.response?.status,
            data: error.response?.data
          });
          throw new Error(`获取Facebook访问令牌失败: ${error.response?.data?.error?.message || error.message}`);
        }

      // 其他提供商的实现类似...

      default:
        logger.warn(`尝试获取不支持的OAuth提供商访问令牌: ${provider}`);
        throw new Error(`不支持的OAuth提供商: ${provider}`);
    }
  } catch (error) {
    // 如果是我们已经处理过的错误，直接抛出
    if (error.message.includes('获取') && error.message.includes('访问令牌失败')) {
      throw error;
    }

    // 否则，记录错误并抛出通用错误
    logger.error(`获取${provider}访问令牌失败:`, error);
    throw new Error(`获取${provider}访问令牌失败: ${error.message}`);
  }
}

/**
 * 获取用户信息
 * @param {string} provider - 提供商名称
 * @param {Object} tokenData - 令牌数据
 * @returns {Promise<Object>} 用户信息
 */
async function getUserInfo(provider, tokenData) {
  try {
    logger.info(`正在获取${provider}用户信息`);

    if (!tokenData || !tokenData.access_token) {
      logger.error(`获取${provider}用户信息失败: 无效的令牌数据`, { tokenData });
      throw new Error(`获取${provider}用户信息失败: 无效的令牌数据`);
    }

    switch (provider) {
      case 'google':
        try {
          const googleResponse = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
            headers: {
              Authorization: `Bearer ${tokenData.access_token}`
            }
          });

          if (!googleResponse.data.sub) {
            logger.error(`获取Google用户信息失败: 响应中缺少用户ID`, { data: googleResponse.data });
            throw new Error(`获取Google用户信息失败: 响应中缺少用户ID`);
          }

          logger.debug(`成功获取Google用户信息，用户ID: ${googleResponse.data.sub}`);

          return {
            id: googleResponse.data.sub,
            email: googleResponse.data.email,
            name: googleResponse.data.name,
            picture: googleResponse.data.picture
          };
        } catch (error) {
          logger.error(`获取Google用户信息失败:`, {
            error: error.message,
            status: error.response?.status,
            data: error.response?.data
          });
          throw new Error(`获取Google用户信息失败: ${error.response?.data?.error?.message || error.message}`);
        }

      case 'facebook':
        try {
          const facebookResponse = await axios.get(`https://graph.facebook.com/me?fields=id,email,name,picture&access_token=${tokenData.access_token}`);

          if (!facebookResponse.data.id) {
            logger.error(`获取Facebook用户信息失败: 响应中缺少用户ID`, { data: facebookResponse.data });
            throw new Error(`获取Facebook用户信息失败: 响应中缺少用户ID`);
          }

          logger.debug(`成功获取Facebook用户信息，用户ID: ${facebookResponse.data.id}`);

          return {
            id: facebookResponse.data.id,
            email: facebookResponse.data.email,
            name: facebookResponse.data.name,
            picture: facebookResponse.data.picture?.data?.url
          };
        } catch (error) {
          logger.error(`获取Facebook用户信息失败:`, {
            error: error.message,
            status: error.response?.status,
            data: error.response?.data
          });
          throw new Error(`获取Facebook用户信息失败: ${error.response?.data?.error?.message || error.message}`);
        }

      // 其他提供商的实现类似...

      default:
        logger.warn(`尝试获取不支持的OAuth提供商用户信息: ${provider}`);
        throw new Error(`不支持的OAuth提供商: ${provider}`);
    }
  } catch (error) {
    // 如果是我们已经处理过的错误，直接抛出
    if (error.message.includes('获取') && error.message.includes('用户信息失败')) {
      throw error;
    }

    // 否则，记录错误并抛出通用错误
    logger.error(`获取${provider}用户信息失败:`, error);
    throw new Error(`获取${provider}用户信息失败: ${error.message}`);
  }
}

/**
 * 创建或更新用户
 * @param {string} provider - 提供商名称
 * @param {Object} userInfo - 用户信息
 * @returns {Promise<Object>} 用户对象
 */
async function createOrUpdateUser(provider, userInfo) {
  try {
    logger.info(`正在创建或更新${provider}用户，用户ID: ${userInfo.id}`);

    // 验证用户信息
    if (!userInfo || !userInfo.id) {
      logger.error(`创建或更新${provider}用户失败: 无效的用户信息`, { userInfo });
      throw new Error(`创建或更新${provider}用户失败: 无效的用户信息`);
    }

    // 查找是否已存在关联的用户
    try {
      const existingUser = await User.findByProviderIdAndType(userInfo.id, provider);

      if (existingUser) {
        logger.info(`找到现有${provider}用户，用户ID: ${existingUser.id}`);

        // 更新用户信息
        try {
          // 解析现有提供商数据
          let providerData = {};
          try {
            if (existingUser.provider_data) {
              providerData = JSON.parse(existingUser.provider_data);
            }
          } catch (parseError) {
            logger.warn(`解析现有提供商数据失败，将重置:`, parseError);
            providerData = {};
          }

          // 更新用户信息
          const updatedUser = await User.update(existingUser.id, {
            display_name: userInfo.name,
            avatar_url: userInfo.picture,
            provider_data: JSON.stringify({
              ...providerData,
              [provider]: userInfo
            })
          });

          logger.info(`成功更新${provider}用户，用户ID: ${updatedUser.id}`);
          return updatedUser;
        } catch (updateError) {
          logger.error(`更新${provider}用户失败:`, updateError);
          throw new Error(`更新${provider}用户失败: ${updateError.message}`);
        }
      } else {
        logger.info(`未找到现有${provider}用户，检查是否存在相同邮箱的用户`);

        // 检查是否存在相同邮箱的用户
        let user = null;

        if (userInfo.email) {
          try {
            user = await User.getByEmail(userInfo.email);
          } catch (emailError) {
            logger.error(`通过邮箱查找用户失败:`, emailError);
            // 继续处理，视为未找到用户
          }
        }

        if (user) {
          logger.info(`找到相同邮箱的用户，用户ID: ${user.id}，关联到${provider}`);

          // 关联现有用户
          try {
            // 解析现有提供商数据
            let providerData = {};
            try {
              if (user.provider_data) {
                providerData = JSON.parse(user.provider_data);
              }
            } catch (parseError) {
              logger.warn(`解析现有提供商数据失败，将重置:`, parseError);
              providerData = {};
            }

            // 更新用户信息
            const updatedUser = await User.update(user.id, {
              provider_id: userInfo.id,
              provider_type: provider,
              provider_data: JSON.stringify({
                ...providerData,
                [provider]: userInfo
              })
            });

            logger.info(`成功关联${provider}用户，用户ID: ${updatedUser.id}`);
            return updatedUser;
          } catch (updateError) {
            logger.error(`关联${provider}用户失败:`, updateError);
            throw new Error(`关联${provider}用户失败: ${updateError.message}`);
          }
        } else {
          logger.info(`未找到相同邮箱的用户，创建新用户`);

          // 创建新用户
          try {
            const username = generateUsername(userInfo.email, userInfo.name);

            const newUser = await User.create({
              username,
              email: userInfo.email || `${username}@${provider}.user`,
              password: crypto.randomBytes(16).toString('hex'), // 生成随机密码
              display_name: userInfo.name,
              avatar_url: userInfo.picture,
              provider_id: userInfo.id,
              provider_type: provider,
              provider_data: JSON.stringify({
                [provider]: userInfo
              }),
              is_email_verified: true // 第三方登录的邮箱视为已验证
            });

            logger.info(`成功创建${provider}用户，用户ID: ${newUser.id}`);
            return newUser;
          } catch (createError) {
            logger.error(`创建${provider}用户失败:`, createError);
            throw new Error(`创建${provider}用户失败: ${createError.message}`);
          }
        }
      }
    } catch (findError) {
      // 如果是我们已经处理过的错误，直接抛出
      if (findError.message.includes('创建') || findError.message.includes('更新') || findError.message.includes('关联')) {
        throw findError;
      }

      logger.error(`查找${provider}用户失败:`, findError);
      throw new Error(`查找${provider}用户失败: ${findError.message}`);
    }
  } catch (error) {
    // 如果是我们已经处理过的错误，直接抛出
    if (error.message.includes('创建') || error.message.includes('更新') || error.message.includes('关联') || error.message.includes('查找')) {
      throw error;
    }

    // 否则，记录错误并抛出通用错误
    logger.error(`创建或更新${provider}用户失败:`, error);
    throw new Error(`创建或更新${provider}用户失败: ${error.message}`);
  }
}

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

module.exports = {
  getAuthorizationUrl,
  handleCallback
};
