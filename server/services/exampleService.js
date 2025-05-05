/**
 * 示例服务
 * 
 * 用于演示熔断器和服务降级功能
 */
const logger = require('../utils/logger');
const { createCircuitBreaker } = require('../utils/circuitBreaker');
const { fallbackManager, ServicePriority } = require('../utils/fallbackStrategy');
const axios = require('axios');

/**
 * 模拟外部API调用
 * @param {string} url - 请求URL
 * @param {Object} options - 请求选项
 * @returns {Promise<Object>} 响应数据
 */
async function callExternalApi(url, options = {}) {
  try {
    const response = await axios.get(url, {
      timeout: 5000,
      ...options
    });
    
    return response.data;
  } catch (error) {
    logger.error(`调用外部API失败: ${url}`, error);
    throw error;
  }
}

// 创建熔断器
const apiCircuitBreaker = createCircuitBreaker(
  'external-api',
  callExternalApi,
  {
    failureThreshold: 3,
    resetTimeout: 30000,
    timeout: 5000
  }
);

/**
 * 使用熔断器调用外部API
 * @param {string} url - 请求URL
 * @param {Object} options - 请求选项
 * @returns {Promise<Object>} 响应数据
 */
async function callExternalApiWithCircuitBreaker(url, options = {}) {
  try {
    return await apiCircuitBreaker.execute(url, options);
  } catch (error) {
    logger.error(`熔断器调用外部API失败: ${url}`, error);
    throw error;
  }
}

/**
 * 获取天气信息（正常功能）
 * @param {string} city - 城市
 * @returns {Promise<Object>} 天气信息
 */
async function getWeather(city) {
  try {
    // 这里应该调用真实的天气API，这里只是模拟
    const url = `https://api.example.com/weather?city=${encodeURIComponent(city)}`;
    
    // 使用熔断器调用外部API
    const data = await callExternalApiWithCircuitBreaker(url);
    
    return {
      city,
      temperature: data.temperature,
      condition: data.condition,
      humidity: data.humidity,
      wind: data.wind,
      updated: new Date().toISOString()
    };
  } catch (error) {
    logger.error(`获取天气信息失败: ${city}`, error);
    throw error;
  }
}

/**
 * 获取天气信息（降级功能）
 * @param {string} city - 城市
 * @returns {Promise<Object>} 天气信息
 */
async function getWeatherFallback(city) {
  logger.info(`使用降级功能获取天气信息: ${city}`);
  
  return {
    city,
    temperature: '未知',
    condition: '未知',
    humidity: '未知',
    wind: '未知',
    updated: new Date().toISOString(),
    note: '这是降级数据，可能不准确'
  };
}

// 注册服务降级
fallbackManager.registerService(
  'weather-service',
  getWeather,
  getWeatherFallback,
  ServicePriority.MEDIUM
);

/**
 * 获取新闻（正常功能）
 * @param {string} category - 新闻类别
 * @returns {Promise<Array>} 新闻列表
 */
async function getNews(category) {
  try {
    // 这里应该调用真实的新闻API，这里只是模拟
    const url = `https://api.example.com/news?category=${encodeURIComponent(category)}`;
    
    // 使用熔断器调用外部API
    const data = await callExternalApiWithCircuitBreaker(url);
    
    return data.articles.map(article => ({
      title: article.title,
      description: article.description,
      url: article.url,
      publishedAt: article.publishedAt,
      source: article.source.name
    }));
  } catch (error) {
    logger.error(`获取新闻失败: ${category}`, error);
    throw error;
  }
}

/**
 * 获取新闻（降级功能）
 * @param {string} category - 新闻类别
 * @returns {Promise<Array>} 新闻列表
 */
async function getNewsFallback(category) {
  logger.info(`使用降级功能获取新闻: ${category}`);
  
  return [
    {
      title: '暂无新闻',
      description: '由于系统负载过高，暂时无法获取最新新闻',
      url: '#',
      publishedAt: new Date().toISOString(),
      source: '系统'
    }
  ];
}

// 注册服务降级
fallbackManager.registerService(
  'news-service',
  getNews,
  getNewsFallback,
  ServicePriority.LOW
);

/**
 * 获取用户信息（正常功能）
 * @param {string} userId - 用户ID
 * @returns {Promise<Object>} 用户信息
 */
async function getUserInfo(userId) {
  try {
    // 这里应该调用真实的用户API，这里只是模拟
    const url = `https://api.example.com/users/${encodeURIComponent(userId)}`;
    
    // 使用熔断器调用外部API
    const data = await callExternalApiWithCircuitBreaker(url);
    
    return {
      id: data.id,
      name: data.name,
      email: data.email,
      avatar: data.avatar,
      lastLogin: data.lastLogin
    };
  } catch (error) {
    logger.error(`获取用户信息失败: ${userId}`, error);
    throw error;
  }
}

/**
 * 获取用户信息（降级功能）
 * @param {string} userId - 用户ID
 * @returns {Promise<Object>} 用户信息
 */
async function getUserInfoFallback(userId) {
  logger.info(`使用降级功能获取用户信息: ${userId}`);
  
  return {
    id: userId,
    name: '未知用户',
    email: '未知',
    avatar: '/default-avatar.png',
    lastLogin: '未知',
    note: '这是降级数据，可能不准确'
  };
}

// 注册服务降级
fallbackManager.registerService(
  'user-service',
  getUserInfo,
  getUserInfoFallback,
  ServicePriority.HIGH
);

/**
 * 获取支付信息（正常功能）
 * @param {string} paymentId - 支付ID
 * @returns {Promise<Object>} 支付信息
 */
async function getPaymentInfo(paymentId) {
  try {
    // 这里应该调用真实的支付API，这里只是模拟
    const url = `https://api.example.com/payments/${encodeURIComponent(paymentId)}`;
    
    // 使用熔断器调用外部API
    const data = await callExternalApiWithCircuitBreaker(url);
    
    return {
      id: data.id,
      amount: data.amount,
      currency: data.currency,
      status: data.status,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt
    };
  } catch (error) {
    logger.error(`获取支付信息失败: ${paymentId}`, error);
    throw error;
  }
}

/**
 * 获取支付信息（降级功能）
 * @param {string} paymentId - 支付ID
 * @returns {Promise<Object>} 支付信息
 */
async function getPaymentInfoFallback(paymentId) {
  logger.info(`使用降级功能获取支付信息: ${paymentId}`);
  
  // 支付是关键服务，降级功能应该返回错误，而不是假数据
  throw new Error('支付服务暂时不可用，请稍后再试');
}

// 注册服务降级
fallbackManager.registerService(
  'payment-service',
  getPaymentInfo,
  getPaymentInfoFallback,
  ServicePriority.CRITICAL
);

module.exports = {
  getWeather: async (city) => fallbackManager.executeService('weather-service', city),
  getNews: async (category) => fallbackManager.executeService('news-service', category),
  getUserInfo: async (userId) => fallbackManager.executeService('user-service', userId),
  getPaymentInfo: async (paymentId) => fallbackManager.executeService('payment-service', paymentId),
  apiCircuitBreaker
};
