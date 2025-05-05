/**
 * 测试数据库工具
 * 
 * 提供与测试数据库交互的工具函数
 */

const knex = require('../../../db/knex');
const logger = require('../../../utils/logger');

/**
 * 测试数据库类
 */
class TestDatabase {
  /**
   * 构造函数
   */
  constructor() {
    this.knex = knex;
  }

  /**
   * 清空表
   * @param {string} tableName - 表名
   * @returns {Promise<void>}
   */
  async clearTable(tableName) {
    try {
      logger.info(`清空表: ${tableName}`);
      await this.knex.raw('SET FOREIGN_KEY_CHECKS = 0');
      await this.knex(tableName).truncate();
      await this.knex.raw('SET FOREIGN_KEY_CHECKS = 1');
    } catch (error) {
      logger.error(`清空表 ${tableName} 失败:`, error);
      throw error;
    }
  }

  /**
   * 插入测试用户
   * @param {Object} userData - 用户数据
   * @returns {Promise<number>} 用户ID
   */
  async insertUser(userData) {
    try {
      const [id] = await this.knex('users').insert({
        username: userData.username || `test_${Date.now()}`,
        email: userData.email || `test_${Date.now()}@example.com`,
        password: userData.password || '$2b$10$eCQDz.GfKB7jFZ7JeXE5aeKIYwbZOB0xOxwrLYpLD/xt9ZSZj2mAu', // 密码: password
        display_name: userData.display_name || 'Test User',
        role: userData.role || 'user',
        is_email_verified: userData.is_email_verified !== undefined ? userData.is_email_verified : true,
        created_at: new Date(),
        updated_at: new Date()
      });
      
      return id;
    } catch (error) {
      logger.error('插入测试用户失败:', error);
      throw error;
    }
  }

  /**
   * 插入测试提醒事项
   * @param {Object} reminderData - 提醒事项数据
   * @returns {Promise<number>} 提醒事项ID
   */
  async insertReminder(reminderData) {
    try {
      const [id] = await this.knex('reminders').insert({
        user_id: reminderData.user_id,
        title: reminderData.title || '测试提醒事项',
        description: reminderData.description || '这是一个测试提醒事项',
        reminder_date: reminderData.reminder_date || new Date(Date.now() + 86400000), // 明天
        is_completed: reminderData.is_completed !== undefined ? reminderData.is_completed : false,
        priority: reminderData.priority || 'medium',
        created_at: new Date(),
        updated_at: new Date()
      });
      
      return id;
    } catch (error) {
      logger.error('插入测试提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 插入测试节日
   * @param {Object} holidayData - 节日数据
   * @returns {Promise<number>} 节日ID
   */
  async insertHoliday(holidayData) {
    try {
      const [id] = await this.knex('holidays').insert({
        name: holidayData.name || '测试节日',
        date: holidayData.date || '2023-01-01',
        description: holidayData.description || '这是一个测试节日',
        country: holidayData.country || 'global',
        type: holidayData.type || 'fixed',
        created_at: new Date(),
        updated_at: new Date()
      });
      
      return id;
    } catch (error) {
      logger.error('插入测试节日失败:', error);
      throw error;
    }
  }

  /**
   * 插入测试节气
   * @param {Object} solarTermData - 节气数据
   * @returns {Promise<number>} 节气ID
   */
  async insertSolarTerm(solarTermData) {
    try {
      const [id] = await this.knex('solar_terms').insert({
        name: solarTermData.name || '立春',
        date: solarTermData.date || '2023-02-04',
        description: solarTermData.description || '这是一个测试节气',
        year: solarTermData.year || 2023,
        created_at: new Date(),
        updated_at: new Date()
      });
      
      return id;
    } catch (error) {
      logger.error('插入测试节气失败:', error);
      throw error;
    }
  }

  /**
   * 获取用户
   * @param {number} id - 用户ID
   * @returns {Promise<Object>} 用户数据
   */
  async getUser(id) {
    try {
      return await this.knex('users').where({ id }).first();
    } catch (error) {
      logger.error('获取用户失败:', error);
      throw error;
    }
  }

  /**
   * 获取提醒事项
   * @param {number} id - 提醒事项ID
   * @returns {Promise<Object>} 提醒事项数据
   */
  async getReminder(id) {
    try {
      return await this.knex('reminders').where({ id }).first();
    } catch (error) {
      logger.error('获取提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 获取用户的所有提醒事项
   * @param {number} userId - 用户ID
   * @returns {Promise<Array>} 提醒事项数组
   */
  async getUserReminders(userId) {
    try {
      return await this.knex('reminders').where({ user_id: userId });
    } catch (error) {
      logger.error('获取用户提醒事项失败:', error);
      throw error;
    }
  }

  /**
   * 获取节日
   * @param {number} id - 节日ID
   * @returns {Promise<Object>} 节日数据
   */
  async getHoliday(id) {
    try {
      return await this.knex('holidays').where({ id }).first();
    } catch (error) {
      logger.error('获取节日失败:', error);
      throw error;
    }
  }

  /**
   * 获取节气
   * @param {number} id - 节气ID
   * @returns {Promise<Object>} 节气数据
   */
  async getSolarTerm(id) {
    try {
      return await this.knex('solar_terms').where({ id }).first();
    } catch (error) {
      logger.error('获取节气失败:', error);
      throw error;
    }
  }
}

module.exports = TestDatabase;
