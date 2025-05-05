/**
 * 农历路由
 */
const express = require('express');
const lunarController = require('../controllers/lunarController');

const router = express.Router();

// 获取农历节日
router.get('/holidays', lunarController.getLunarHolidays);

// 获取当前日期的农历信息
router.get('/date-info', lunarController.getLunarDateInfo);

module.exports = router;
