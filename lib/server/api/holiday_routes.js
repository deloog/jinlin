// 节日API路由
const express = require('express');
const Holiday = require('../models/holiday');
const Version = require('../models/version');
const router = express.Router();

// 获取特定地区和语言的节日
// GET /api/holidays?region=CN&language=zh
router.get('/', async (req, res) => {
  try {
    const { region, language } = req.query;
    
    if (!region || !language) {
      return res.status(400).json({ 
        error: 'Missing required parameters: region and language' 
      });
    }
    
    // 获取节日数据
    const holidays = await Holiday.getByRegionAndLanguage(region, language);
    
    // 获取数据版本
    const version = await Version.getByRegion(region);
    
    res.json({
      version,
      holidays
    });
  } catch (error) {
    console.error('获取节日数据失败:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 获取全球节日
// GET /api/holidays/global?language=zh
router.get('/global', async (req, res) => {
  try {
    const { language } = req.query;
    
    if (!language) {
      return res.status(400).json({ 
        error: 'Missing required parameter: language' 
      });
    }
    
    // 获取全球节日数据
    const holidays = await Holiday.getGlobalHolidays(language);
    
    // 获取数据版本
    const version = await Version.getByRegion('GLOBAL');
    
    res.json({
      version,
      holidays
    });
  } catch (error) {
    console.error('获取全球节日数据失败:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 获取节日更新
// GET /api/holidays/updates?region=CN&since_version=1&language=zh
router.get('/updates', async (req, res) => {
  try {
    const { region, since_version, language } = req.query;
    
    if (!region || !since_version || !language) {
      return res.status(400).json({ 
        error: 'Missing required parameters: region, since_version, and language' 
      });
    }
    
    // 获取当前版本
    const currentVersion = await Version.getByRegion(region);
    
    // 如果请求的版本已经是最新的，返回空更新
    if (parseInt(since_version) >= currentVersion) {
      return res.json({
        new_version: currentVersion,
        added: [],
        updated: [],
        deleted: []
      });
    }
    
    // 获取更新数据
    const updates = await Holiday.getUpdatesSince(region, since_version, language);
    
    res.json({
      new_version: currentVersion,
      ...updates
    });
  } catch (error) {
    console.error('获取节日更新失败:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 添加新节日（需要管理员权限）
// POST /api/holidays
router.post('/', async (req, res) => {
  try {
    const { holiday, translations, regions } = req.body;
    
    if (!holiday || !translations || !regions) {
      return res.status(400).json({ 
        error: 'Missing required data: holiday, translations, or regions' 
      });
    }
    
    // 添加新节日
    await Holiday.add(holiday, translations, regions);
    
    res.status(201).json({ message: 'Holiday added successfully' });
  } catch (error) {
    console.error('添加节日失败:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
