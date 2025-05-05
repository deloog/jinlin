/**
 * 通知控制器
 */
const { validationResult } = require('express-validator');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { createError } = require('../utils/errorHandler');

/**
 * 保存设备令牌
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.saveDeviceToken = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { device_id, token, platform } = req.body;
    const userId = req.user.id;
    
    // 保存设备令牌
    const result = await notificationService.saveDeviceToken(userId, device_id, token, platform);
    
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
};

/**
 * 删除设备令牌
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.removeDeviceToken = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { device_id } = req.body;
    const userId = req.user.id;
    
    // 删除设备令牌
    const success = await notificationService.removeDeviceToken(userId, device_id);
    
    if (success) {
      res.json({ message: '设备令牌已删除' });
    } else {
      res.status(404).json({ error: '设备令牌不存在' });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * 获取用户的通知
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getUserNotifications = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { limit, offset, unread_only } = req.query;
    
    // 获取用户的通知
    const notifications = await notificationService.getUserNotifications(userId, {
      limit: limit ? parseInt(limit) : 20,
      offset: offset ? parseInt(offset) : 0,
      unreadOnly: unread_only === 'true'
    });
    
    res.json({ data: notifications });
  } catch (error) {
    next(error);
  }
};

/**
 * 标记通知为已读
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.markNotificationAsRead = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { notification_id } = req.params;
    const userId = req.user.id;
    
    // 标记通知为已读
    const success = await notificationService.markNotificationAsRead(notification_id, userId);
    
    if (success) {
      res.json({ message: '通知已标记为已读' });
    } else {
      res.status(404).json({ error: '通知不存在' });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * 标记所有通知为已读
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.markAllNotificationsAsRead = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    // 标记所有通知为已读
    const count = await notificationService.markAllNotificationsAsRead(userId);
    
    res.json({ message: `${count}条通知已标记为已读` });
  } catch (error) {
    next(error);
  }
};

/**
 * 删除通知
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.deleteNotification = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { notification_id } = req.params;
    const userId = req.user.id;
    
    // 删除通知
    const success = await notificationService.deleteNotification(notification_id, userId);
    
    if (success) {
      res.json({ message: '通知已删除' });
    } else {
      res.status(404).json({ error: '通知不存在' });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * 发送测试通知
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.sendTestNotification = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const userId = req.user.id;
    const { title, body } = req.body;
    
    // 创建通知
    const notification = await notificationService.createNotification({
      user_id: userId,
      title,
      body,
      type: 'test',
      data: {
        test: true,
        timestamp: new Date().toISOString()
      }
    });
    
    res.json({ data: notification });
  } catch (error) {
    next(error);
  }
};
