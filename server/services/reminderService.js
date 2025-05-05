/**
 * 提醒事项服务
 */
const Reminder = require('../models/Reminder');
const logger = require('../utils/logger');

/**
 * 获取提醒事项列表
 * @param {Object} filters - 过滤条件
 * @returns {Array} 提醒事项列表
 */
exports.getReminders = async (filters = {}) => {
  try {
    return await Reminder.getAll(filters);
  } catch (error) {
    logger.error('获取提醒事项列表失败:', error);
    throw error;
  }
};

/**
 * 获取单个提醒事项
 * @param {string} id - 提醒事项ID
 * @returns {Object} 提醒事项对象
 */
exports.getReminder = async (id) => {
  try {
    const reminder = await Reminder.getById(id);
    
    if (!reminder) {
      throw new Error('提醒事项不存在');
    }
    
    return reminder;
  } catch (error) {
    logger.error('获取提醒事项失败:', error);
    throw error;
  }
};

/**
 * 创建提醒事项
 * @param {Object} reminderData - 提醒事项数据
 * @returns {Object} 创建的提醒事项
 */
exports.createReminder = async (reminderData) => {
  try {
    return await Reminder.create(reminderData);
  } catch (error) {
    logger.error('创建提醒事项失败:', error);
    throw error;
  }
};

/**
 * 更新提醒事项
 * @param {string} id - 提醒事项ID
 * @param {Object} reminderData - 提醒事项数据
 * @param {string} userId - 用户ID
 * @returns {Object} 更新的提醒事项
 */
exports.updateReminder = async (id, reminderData, userId) => {
  try {
    const reminder = await Reminder.getById(id);
    
    if (!reminder) {
      throw new Error('提醒事项不存在');
    }
    
    // 检查权限
    if (userId && reminder.user_id && reminder.user_id !== userId) {
      throw new Error('无权更新此提醒事项');
    }
    
    return await Reminder.update(id, reminderData);
  } catch (error) {
    logger.error('更新提醒事项失败:', error);
    throw error;
  }
};

/**
 * 删除提醒事项
 * @param {string} id - 提醒事项ID
 * @param {string} userId - 用户ID
 * @returns {boolean} 是否成功
 */
exports.deleteReminder = async (id, userId) => {
  try {
    const reminder = await Reminder.getById(id);
    
    if (!reminder) {
      throw new Error('提醒事项不存在');
    }
    
    // 检查权限
    if (userId && reminder.user_id && reminder.user_id !== userId) {
      throw new Error('无权删除此提醒事项');
    }
    
    return await Reminder.delete(id);
  } catch (error) {
    logger.error('删除提醒事项失败:', error);
    throw error;
  }
};

/**
 * 标记提醒事项为已完成/未完成
 * @param {string} id - 提醒事项ID
 * @param {boolean} completed - 是否已完成
 * @param {string} userId - 用户ID
 * @returns {Object} 更新的提醒事项
 */
exports.markComplete = async (id, completed, userId) => {
  try {
    const reminder = await Reminder.getById(id);
    
    if (!reminder) {
      throw new Error('提醒事项不存在');
    }
    
    // 检查权限
    if (userId && reminder.user_id && reminder.user_id !== userId) {
      throw new Error('无权更新此提醒事项');
    }
    
    return await Reminder.markComplete(id, completed);
  } catch (error) {
    logger.error('标记提醒事项完成状态失败:', error);
    throw error;
  }
};

/**
 * 获取用户的提醒事项
 * @param {string} userId - 用户ID
 * @param {Object} filters - 过滤条件
 * @returns {Array} 提醒事项列表
 */
exports.getUserReminders = async (userId, filters = {}) => {
  try {
    const userFilters = { ...filters, userId };
    return await Reminder.getAll(userFilters);
  } catch (error) {
    logger.error('获取用户提醒事项失败:', error);
    throw error;
  }
};

/**
 * 获取即将到期的提醒事项
 * @param {string} userId - 用户ID
 * @param {number} days - 天数
 * @returns {Array} 提醒事项列表
 */
exports.getUpcomingReminders = async (userId, days = 7) => {
  try {
    const today = new Date();
    const endDate = new Date();
    endDate.setDate(today.getDate() + days);
    
    const filters = {
      userId,
      startDate: today.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      isCompleted: false
    };
    
    return await Reminder.getAll(filters);
  } catch (error) {
    logger.error('获取即将到期的提醒事项失败:', error);
    throw error;
  }
};

/**
 * 获取过期的提醒事项
 * @param {string} userId - 用户ID
 * @returns {Array} 提醒事项列表
 */
exports.getOverdueReminders = async (userId) => {
  try {
    const today = new Date();
    
    const filters = {
      userId,
      endDate: today.toISOString().split('T')[0],
      isCompleted: false
    };
    
    const reminders = await Reminder.getAll(filters);
    
    // 过滤出过期的提醒事项
    return reminders.filter(reminder => {
      const reminderDate = new Date(reminder.date);
      return reminderDate < today;
    });
  } catch (error) {
    logger.error('获取过期的提醒事项失败:', error);
    throw error;
  }
};
