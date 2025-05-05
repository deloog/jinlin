/**
 * Prometheus 控制器
 */
const prometheusService = require('../services/prometheusService');
const logger = require('../utils/logger');

/**
 * 获取指标
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getMetrics = async (req, res, next) => {
  try {
    // 获取指标
    const metrics = await prometheusService.getMetrics();
    
    // 设置内容类型
    res.set('Content-Type', prometheusService.getContentType());
    
    // 发送指标
    res.end(metrics);
  } catch (error) {
    logger.error('获取Prometheus指标失败:', error);
    next(error);
  }
};
