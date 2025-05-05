/**
 * 测试客户端
 * 
 * 提供与API交互的工具函数
 */

const request = require('supertest');
const logger = require('../../../utils/logger');

/**
 * 测试客户端类
 */
class TestClient {
  /**
   * 构造函数
   * @param {string} baseUrl - 基础URL
   */
  constructor(baseUrl) {
    this.baseUrl = baseUrl || global.__TEST_BASE_URL__ || 'http://localhost:3001';
    this.token = null;
    this.refreshToken = null;
    this.agent = request.agent(this.baseUrl);
  }

  /**
   * 登录
   * @param {string} email - 电子邮件
   * @param {string} password - 密码
   * @returns {Promise<Object>} 登录响应
   */
  async login(email, password) {
    try {
      const response = await this.agent
        .post('/api/users/login')
        .send({ email, password });

      if (response.status === 200 && response.body.data) {
        this.token = response.body.data.access_token;
        this.refreshToken = response.body.data.refresh_token;
      }

      return response;
    } catch (error) {
      logger.error('登录失败:', error);
      throw error;
    }
  }

  /**
   * 注册
   * @param {Object} userData - 用户数据
   * @returns {Promise<Object>} 注册响应
   */
  async register(userData) {
    try {
      return await this.agent
        .post('/api/users/register')
        .send(userData);
    } catch (error) {
      logger.error('注册失败:', error);
      throw error;
    }
  }

  /**
   * 第三方登录
   * @param {string} provider - 提供商
   * @param {string} token - 令牌
   * @param {Object} userData - 用户数据
   * @returns {Promise<Object>} 登录响应
   */
  async thirdPartyLogin(provider, token, userData) {
    try {
      const response = await this.agent
        .post(`/api/auth/login/${provider}`)
        .send({ token, userData });

      if (response.status === 200 && response.body.data) {
        this.token = response.body.data.access_token;
        this.refreshToken = response.body.data.refresh_token;
      }

      return response;
    } catch (error) {
      logger.error('第三方登录失败:', error);
      throw error;
    }
  }

  /**
   * 获取用户资料
   * @returns {Promise<Object>} 用户资料响应
   */
  async getUserProfile() {
    try {
      return await this.agent
        .get('/api/users/profile')
        .set('Authorization', `Bearer ${this.token}`);
    } catch (error) {
      logger.error('获取用户资料失败:', error);
      throw error;
    }
  }

  /**
   * 获取提醒事项列表
   * @returns {Promise<Object>} 提醒事项列表响应
   */
  async getReminders() {
    try {
      return await this.agent
        .get('/api/reminders')
        .set('Authorization', `Bearer ${this.token}`);
    } catch (error) {
      logger.error('获取提醒事项列表失败:', error);
      throw error;
    }
  }

  /**
   * 创建提醒事项
   * @param {Object} reminderData - 提醒事项数据
   * @returns {Promise<Object>} 创建提醒事项响应
   */
  async createReminder(reminderData) {
    try {
      return await this.agent
        .post('/api/reminders')
        .set('Authorization', `Bearer ${this.token}`)
        .send(reminderData);
    } catch (error) {
      logger.error('创建提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 更新提醒事项
   * @param {number} id - 提醒事项ID
   * @param {Object} reminderData - 提醒事项数据
   * @returns {Promise<Object>} 更新提醒事项响应
   */
  async updateReminder(id, reminderData) {
    try {
      return await this.agent
        .put(`/api/reminders/${id}`)
        .set('Authorization', `Bearer ${this.token}`)
        .send(reminderData);
    } catch (error) {
      logger.error('更新提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 删除提醒事项
   * @param {number} id - 提醒事项ID
   * @returns {Promise<Object>} 删除提醒事项响应
   */
  async deleteReminder(id) {
    try {
      return await this.agent
        .delete(`/api/reminders/${id}`)
        .set('Authorization', `Bearer ${this.token}`);
    } catch (error) {
      logger.error('删除提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 获取节日列表
   * @param {string} country - 国家/地区
   * @returns {Promise<Object>} 节日列表响应
   */
  async getHolidays(country) {
    try {
      return await this.agent
        .get(`/api/holidays?country=${country || 'global'}`);
    } catch (error) {
      logger.error('获取节日列表失败:', error);
      throw error;
    }
  }

  /**
   * 获取节气列表
   * @param {number} year - 年份
   * @returns {Promise<Object>} 节气列表响应
   */
  async getSolarTerms(year) {
    try {
      return await this.agent
        .get(`/api/solar-terms?year=${year || new Date().getFullYear()}`);
    } catch (error) {
      logger.error('获取节气列表失败:', error);
      throw error;
    }
  }

  /**
   * 同步数据
   * @param {Object} syncData - 同步数据
   * @returns {Promise<Object>} 同步响应
   */
  async syncData(syncData) {
    try {
      return await this.agent
        .post('/api/sync')
        .set('Authorization', `Bearer ${this.token}`)
        .send(syncData);
    } catch (error) {
      logger.error('同步数据失败:', error);
      throw error;
    }
  }

  /**
   * 刷新令牌
   * @returns {Promise<Object>} 刷新令牌响应
   */
  async refreshAccessToken() {
    try {
      const response = await this.agent
        .post('/api/users/refresh-token')
        .send({ refresh_token: this.refreshToken });

      if (response.status === 200 && response.body.data) {
        this.token = response.body.data.access_token;
        this.refreshToken = response.body.data.refresh_token;
      }

      return response;
    } catch (error) {
      logger.error('刷新令牌失败:', error);
      throw error;
    }
  }

  /**
   * 登出
   * @returns {Promise<Object>} 登出响应
   */
  async logout() {
    try {
      const response = await this.agent
        .post('/api/users/logout')
        .set('Authorization', `Bearer ${this.token}`);

      if (response.status === 200) {
        this.token = null;
        this.refreshToken = null;
      }

      return response;
    } catch (error) {
      logger.error('登出失败:', error);
      throw error;
    }
  }
}

module.exports = TestClient;
