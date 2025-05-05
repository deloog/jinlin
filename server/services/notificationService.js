/**
 * 通知服务
 * 提供推送通知功能
 */
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const { createError } = require('../utils/errorHandler');

/**
 * 创建通知表
 */
async function createTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT,
        type VARCHAR(50) NOT NULL,
        data JSON,
        is_read BOOLEAN DEFAULT false,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_notifications_user_id (user_id),
        INDEX idx_notifications_type (type),
        INDEX idx_notifications_is_read (is_read)
      )
    `);
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notification_tokens (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        token VARCHAR(255) NOT NULL,
        platform VARCHAR(50) NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        UNIQUE KEY unique_user_device (user_id, device_id),
        INDEX idx_notification_tokens_user_id (user_id),
        INDEX idx_notification_tokens_token (token)
      )
    `);
    
    logger.info('通知表创建成功');
  } catch (error) {
    logger.error('创建通知表失败:', error);
    throw error;
  }
}

/**
 * 保存设备令牌
 * @param {string} userId - 用户ID
 * @param {string} deviceId - 设备ID
 * @param {string} token - 设备令牌
 * @param {string} platform - 平台（ios, android, web）
 * @returns {Object} 保存的令牌
 */
async function saveDeviceToken(userId, deviceId, token, platform) {
  try {
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    // 检查是否已存在
    const [existingTokens] = await pool.query(
      'SELECT * FROM notification_tokens WHERE user_id = ? AND device_id = ?',
      [userId, deviceId]
    );
    
    if (existingTokens.length > 0) {
      // 更新现有令牌
      await pool.query(
        'UPDATE notification_tokens SET token = ?, platform = ?, updated_at = ? WHERE user_id = ? AND device_id = ?',
        [token, platform, now, userId, deviceId]
      );
      
      return {
        id: existingTokens[0].id,
        user_id: userId,
        device_id: deviceId,
        token,
        platform,
        updated_at: now
      };
    } else {
      // 创建新令牌
      await pool.query(
        'INSERT INTO notification_tokens (id, user_id, device_id, token, platform, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [id, userId, deviceId, token, platform, now, now]
      );
      
      return {
        id,
        user_id: userId,
        device_id: deviceId,
        token,
        platform,
        created_at: now,
        updated_at: now
      };
    }
  } catch (error) {
    logger.error('保存设备令牌失败:', error);
    throw createError('database', '保存设备令牌失败', 'saveDeviceToken', error);
  }
}

/**
 * 删除设备令牌
 * @param {string} userId - 用户ID
 * @param {string} deviceId - 设备ID
 * @returns {boolean} 是否成功
 */
async function removeDeviceToken(userId, deviceId) {
  try {
    const [result] = await pool.query(
      'DELETE FROM notification_tokens WHERE user_id = ? AND device_id = ?',
      [userId, deviceId]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('删除设备令牌失败:', error);
    throw createError('database', '删除设备令牌失败', 'removeDeviceToken', error);
  }
}

/**
 * 获取用户的设备令牌
 * @param {string} userId - 用户ID
 * @returns {Array} 设备令牌列表
 */
async function getUserDeviceTokens(userId) {
  try {
    const [tokens] = await pool.query(
      'SELECT * FROM notification_tokens WHERE user_id = ?',
      [userId]
    );
    
    return tokens;
  } catch (error) {
    logger.error('获取用户设备令牌失败:', error);
    throw createError('database', '获取用户设备令牌失败', 'getUserDeviceTokens', error);
  }
}

/**
 * 创建通知
 * @param {Object} notification - 通知数据
 * @returns {Object} 创建的通知
 */
async function createNotification(notification) {
  try {
    const { user_id, title, body, type, data } = notification;
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    // 序列化数据
    const serializedData = data ? JSON.stringify(data) : null;
    
    await pool.query(
      'INSERT INTO notifications (id, user_id, title, body, type, data, is_read, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, user_id, title, body, type, serializedData, false, now, now]
    );
    
    return {
      id,
      user_id,
      title,
      body,
      type,
      data,
      is_read: false,
      created_at: now,
      updated_at: now
    };
  } catch (error) {
    logger.error('创建通知失败:', error);
    throw createError('database', '创建通知失败', 'createNotification', error);
  }
}

/**
 * 获取用户的通知
 * @param {string} userId - 用户ID
 * @param {Object} options - 选项
 * @returns {Array} 通知列表
 */
async function getUserNotifications(userId, options = {}) {
  try {
    const { limit = 20, offset = 0, unreadOnly = false } = options;
    
    let query = 'SELECT * FROM notifications WHERE user_id = ?';
    const params = [userId];
    
    if (unreadOnly) {
      query += ' AND is_read = false';
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const [notifications] = await pool.query(query, params);
    
    // 解析JSON数据
    return notifications.map(notification => {
      if (notification.data) {
        try {
          notification.data = JSON.parse(notification.data);
        } catch (e) {
          // 保持原样
        }
      }
      return notification;
    });
  } catch (error) {
    logger.error('获取用户通知失败:', error);
    throw createError('database', '获取用户通知失败', 'getUserNotifications', error);
  }
}

/**
 * 标记通知为已读
 * @param {string} notificationId - 通知ID
 * @param {string} userId - 用户ID
 * @returns {boolean} 是否成功
 */
async function markNotificationAsRead(notificationId, userId) {
  try {
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      'UPDATE notifications SET is_read = true, updated_at = ? WHERE id = ? AND user_id = ?',
      [now, notificationId, userId]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('标记通知为已读失败:', error);
    throw createError('database', '标记通知为已读失败', 'markNotificationAsRead', error);
  }
}

/**
 * 标记所有通知为已读
 * @param {string} userId - 用户ID
 * @returns {number} 更新的通知数量
 */
async function markAllNotificationsAsRead(userId) {
  try {
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      'UPDATE notifications SET is_read = true, updated_at = ? WHERE user_id = ? AND is_read = false',
      [now, userId]
    );
    
    return result.affectedRows;
  } catch (error) {
    logger.error('标记所有通知为已读失败:', error);
    throw createError('database', '标记所有通知为已读失败', 'markAllNotificationsAsRead', error);
  }
}

/**
 * 删除通知
 * @param {string} notificationId - 通知ID
 * @param {string} userId - 用户ID
 * @returns {boolean} 是否成功
 */
async function deleteNotification(notificationId, userId) {
  try {
    const [result] = await pool.query(
      'DELETE FROM notifications WHERE id = ? AND user_id = ?',
      [notificationId, userId]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('删除通知失败:', error);
    throw createError('database', '删除通知失败', 'deleteNotification', error);
  }
}

module.exports = {
  createTable,
  saveDeviceToken,
  removeDeviceToken,
  getUserDeviceTokens,
  createNotification,
  getUserNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification
};
