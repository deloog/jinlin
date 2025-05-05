/**
 * 健康检查路由
 */
const express = require('express');
const { pool } = require('../config/database');
const cacheService = require('../services/cacheService');
const os = require('os');
const logger = require('../utils/logger');

const router = express.Router();

/**
 * 基本健康检查
 * 返回应用程序的基本状态
 */
router.get('/', async (req, res) => {
  try {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    logger.error('健康检查失败:', error);
    res.status(500).json({ status: 'error', error: error.message });
  }
});

/**
 * 详细健康检查
 * 返回应用程序的详细状态，包括数据库连接、缓存状态等
 */
router.get('/details', async (req, res) => {
  try {
    // 检查数据库连接
    let dbStatus = 'ok';
    let dbError = null;
    
    try {
      await pool.query('SELECT 1');
    } catch (error) {
      dbStatus = 'error';
      dbError = error.message;
    }
    
    // 获取缓存统计信息
    const cacheStats = cacheService.getStats();
    
    // 获取系统信息
    const systemInfo = {
      platform: process.platform,
      arch: process.arch,
      nodeVersion: process.version,
      cpus: os.cpus().length,
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      loadAvg: os.loadavg()
    };
    
    // 获取进程信息
    const processInfo = {
      pid: process.pid,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage()
    };
    
    res.json({
      status: dbStatus === 'ok' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      database: {
        status: dbStatus,
        error: dbError
      },
      cache: cacheStats,
      system: systemInfo,
      process: processInfo
    });
  } catch (error) {
    logger.error('详细健康检查失败:', error);
    res.status(500).json({ status: 'error', error: error.message });
  }
});

/**
 * 版本信息
 * 返回应用程序的版本信息
 */
router.get('/version', (req, res) => {
  try {
    const packageJson = require('../package.json');
    
    res.json({
      name: packageJson.name,
      version: packageJson.version,
      description: packageJson.description,
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    logger.error('获取版本信息失败:', error);
    res.status(500).json({ status: 'error', error: error.message });
  }
});

/**
 * 缓存统计
 * 返回缓存的统计信息
 */
router.get('/cache', (req, res) => {
  try {
    const cacheStats = cacheService.getStats();
    
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      cache: cacheStats
    });
  } catch (error) {
    logger.error('获取缓存统计失败:', error);
    res.status(500).json({ status: 'error', error: error.message });
  }
});

/**
 * 清除缓存
 * 清除所有缓存
 */
router.post('/cache/clear', (req, res) => {
  try {
    const count = cacheService.clearAll();
    
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      message: `已清除${count}个缓存项`
    });
  } catch (error) {
    logger.error('清除缓存失败:', error);
    res.status(500).json({ status: 'error', error: error.message });
  }
});

module.exports = router;
