// 版本API路由
const express = require('express');
const Version = require('../models/version');
const router = express.Router();

// 获取数据版本信息
// GET /api/versions?regions=CN,US,JP
router.get('/', async (req, res) => {
  try {
    const { regions } = req.query;
    
    if (!regions) {
      return res.status(400).json({ 
        error: 'Missing required parameter: regions' 
      });
    }
    
    // 解析地区列表
    const regionList = regions.split(',');
    
    // 获取版本信息
    const versions = await Version.getByRegions(regionList);
    
    res.json({ versions });
  } catch (error) {
    console.error('获取版本信息失败:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
