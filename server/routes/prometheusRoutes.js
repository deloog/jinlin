/**
 * Prometheus 路由
 */
const express = require('express');
const prometheusController = require('../controllers/prometheusController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// 获取指标
router.get('/metrics', authMiddleware.isAdmin, prometheusController.getMetrics);

module.exports = router;
