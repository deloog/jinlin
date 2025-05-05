/**
 * 提醒事项控制器
 */
const reminderService = require('../services/reminderService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取提醒事项列表
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getReminders = async (req, res) => {
  try {
    const { startDate, endDate, isCompleted, userId } = req.query;

    // 构建过滤条件
    const filters = {};
    if (userId) filters.userId = userId;
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (isCompleted !== undefined) {
      filters.isCompleted = isCompleted === 'true';
    }

    // 如果当前用户已认证，且没有指定userId，则使用当前用户ID
    if (req.user && !userId) {
      filters.userId = req.user.id;
    }

    let reminders;

    // 根据不同的查询条件使用不同的服务方法
    if (filters.userId && filters.startDate && filters.endDate && filters.isCompleted === false) {
      // 获取用户在特定日期范围内的未完成提醒事项
      reminders = await reminderService.getUserReminders(filters.userId, filters);
    } else {
      // 获取所有提醒事项
      reminders = await reminderService.getReminders(filters);
    }

    // 处理JSON字段
    const processedReminders = reminders.map(reminder => {
      const result = { ...reminder };

      // 解析JSON字段
      if (reminder.tags) result.tags = JSON.parse(reminder.tags);

      return result;
    });

    res.json({ data: processedReminders });
  } catch (error) {
    logger.error('获取提醒事项列表失败:', error);
    res.status(500).json({ error: '获取提醒事项列表失败' });
  }
};

/**
 * 获取单个提醒事项
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getReminder = async (req, res) => {
  try {
    const { id } = req.params;

    try {
      const reminder = await reminderService.getReminder(id);

      // 如果有用户认证，检查权限
      if (req.user && reminder.user_id && reminder.user_id !== req.user.id) {
        return res.status(403).json({ error: '无权查看此提醒事项' });
      }

      // 处理JSON字段
      const result = { ...reminder };
      if (reminder.tags) result.tags = JSON.parse(reminder.tags);

      res.json({ data: result });
    } catch (error) {
      if (error.message === '提醒事项不存在') {
        return res.status(404).json({ error: '提醒事项不存在' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('获取提醒事项失败:', error);
    res.status(500).json({ error: '获取提醒事项失败' });
  }
};

/**
 * 创建提醒事项
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.createReminder = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const reminderData = req.body;

    // 如果有用户认证，添加用户ID
    if (req.user) {
      reminderData.user_id = req.user.id;
    }

    // 创建提醒事项
    const reminder = await reminderService.createReminder(reminderData);

    res.status(201).json({ data: reminder });
  } catch (error) {
    logger.error('创建提醒事项失败:', error);
    res.status(500).json({ error: '创建提醒事项失败' });
  }
};

/**
 * 更新提醒事项
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.updateReminder = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const reminderData = req.body;

    try {
      // 更新提醒事项
      const updatedReminder = await reminderService.updateReminder(id, reminderData, req.user ? req.user.id : null);
      res.json({ data: updatedReminder });
    } catch (error) {
      if (error.message === '提醒事项不存在') {
        return res.status(404).json({ error: '提醒事项不存在' });
      }
      if (error.message === '无权更新此提醒事项') {
        return res.status(403).json({ error: '无权更新此提醒事项' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('更新提醒事项失败:', error);
    res.status(500).json({ error: '更新提醒事项失败' });
  }
};

/**
 * 删除提醒事项
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.deleteReminder = async (req, res) => {
  try {
    const { id } = req.params;

    try {
      // 删除提醒事项
      const success = await reminderService.deleteReminder(id, req.user ? req.user.id : null);

      if (success) {
        res.json({ message: '提醒事项删除成功' });
      } else {
        res.status(500).json({ error: '提醒事项删除失败' });
      }
    } catch (error) {
      if (error.message === '提醒事项不存在') {
        return res.status(404).json({ error: '提醒事项不存在' });
      }
      if (error.message === '无权删除此提醒事项') {
        return res.status(403).json({ error: '无权删除此提醒事项' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('删除提醒事项失败:', error);
    res.status(500).json({ error: '删除提醒事项失败' });
  }
};

/**
 * 标记提醒事项为已完成/未完成
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.markComplete = async (req, res) => {
  try {
    const { id } = req.params;
    const { completed } = req.body;

    if (completed === undefined) {
      return res.status(400).json({ error: '缺少completed参数' });
    }

    try {
      // 标记提醒事项
      const updatedReminder = await reminderService.markComplete(id, completed, req.user ? req.user.id : null);
      res.json({ data: updatedReminder });
    } catch (error) {
      if (error.message === '提醒事项不存在') {
        return res.status(404).json({ error: '提醒事项不存在' });
      }
      if (error.message === '无权更新此提醒事项') {
        return res.status(403).json({ error: '无权更新此提醒事项' });
      }
      throw error;
    }
  } catch (error) {
    logger.error('标记提醒事项完成状态失败:', error);
    res.status(500).json({ error: '标记提醒事项完成状态失败' });
  }
};
