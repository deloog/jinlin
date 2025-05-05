/**
 * 同步控制器
 */
const syncService = require('../services/syncService');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * 获取同步记录
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSyncRecords = async (req, res) => {
  try {
    const { entity_type, status, start_date, end_date, limit } = req.query;

    // 构建过滤条件
    const filters = {};
    if (entity_type) filters.entity_type = entity_type;
    if (status) filters.status = status;
    if (start_date) filters.startDate = start_date;
    if (end_date) filters.endDate = end_date;
    if (limit) filters.limit = parseInt(limit);

    // 获取同步记录
    const syncRecords = await syncService.getSyncRecords(req.user.id, filters);

    res.json({ data: syncRecords });
  } catch (error) {
    logger.error('获取同步记录失败:', error);
    res.status(500).json({ error: '获取同步记录失败' });
  }
};

/**
 * 获取最后同步时间
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getLastSyncTime = async (req, res) => {
  try {
    const { device_id } = req.query;

    if (!device_id) {
      return res.status(400).json({ error: '缺少device_id参数' });
    }

    // 获取最后同步时间
    const lastSyncTime = await syncService.getLastSyncTime(req.user.id, device_id);

    res.json({
      data: {
        last_sync_time: lastSyncTime
      }
    });
  } catch (error) {
    logger.error('获取最后同步时间失败:', error);
    res.status(500).json({ error: '获取最后同步时间失败' });
  }
};

/**
 * 同步数据
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.syncData = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { device_id, operations, last_sync_time } = req.body;

    // 处理同步操作
    const results = await syncService.processSyncOperations(req.user.id, device_id, operations, last_sync_time);

    // 获取服务器端更新
    const serverUpdates = await syncService.getServerUpdates(req.user.id, last_sync_time, {
      page_size: req.query.page_size,
      page: req.query.page
    });

    // 当前同步时间
    const syncTime = new Date().toISOString();

    res.json({
      message: '同步成功',
      data: {
        results,
        server_updates: serverUpdates,
        sync_time: syncTime
      }
    });
  } catch (error) {
    logger.error('同步数据失败:', error);
    res.status(500).json({ error: '同步数据失败' });
  }
};

/**
 * 解决同步冲突
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.resolveSyncConflict = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { sync_record_id, resolution, merged_data } = req.body;

    if (!sync_record_id) {
      return res.status(400).json({ error: '缺少sync_record_id参数' });
    }

    if (!resolution) {
      return res.status(400).json({ error: '缺少resolution参数' });
    }

    // 解决同步冲突
    const result = await syncService.resolveSyncConflict(req.user.id, sync_record_id, resolution, merged_data);

    res.json({
      message: '冲突解决成功',
      data: result
    });
  } catch (error) {
    logger.error('解决同步冲突失败:', error);

    if (error.message === '同步记录不存在') {
      return res.status(404).json({ error: '同步记录不存在' });
    }

    if (error.message === '无权解决此冲突') {
      return res.status(403).json({ error: '无权解决此冲突' });
    }

    if (error.message === '此记录不是冲突状态') {
      return res.status(400).json({ error: '此记录不是冲突状态' });
    }

    if (error.message === '合并解决方式需要提供合并后的数据') {
      return res.status(400).json({ error: '合并解决方式需要提供合并后的数据' });
    }

    if (error.message.startsWith('不支持的解决方式')) {
      return res.status(400).json({ error: error.message });
    }

    res.status(500).json({ error: '解决同步冲突失败' });
  }
};
