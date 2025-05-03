/**
 * 数据导入脚本
 * 
 * 用于将JSON文件中的节日数据导入到数据库
 */
const fs = require('fs');
const path = require('path');
const db = require('../database/db');

// 导入全球节日数据
async function importGlobalHolidays() {
  try {
    console.log('开始导入全球节日数据...');
    
    // 读取JSON文件
    const filePath = path.join(__dirname, '../../../assets/data/holidays_global.json');
    const jsonData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    // 获取数据库连接
    const conn = await db.pool.getConnection();
    
    try {
      await conn.beginTransaction();
      
      // 导入节日数据
      for (const holiday of jsonData.holidays) {
        // 插入节日基本信息
        await conn.query(
          'INSERT IGNORE INTO holidays (id, type, calculation_type, calculation_rule, importance_level) VALUES (?, ?, ?, ?, ?)',
          [
            holiday.id,
            holiday.type,
            holiday.calculationType,
            holiday.calculationRule,
            getImportanceLevel(holiday.importanceLevel)
          ]
        );
        
        // 插入英文翻译
        await conn.query(
          'INSERT IGNORE INTO holiday_translations (holiday_id, language_code, name, description, customs, foods, greetings) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            holiday.id,
            'en',
            holiday.name,
            holiday.description || '',
            holiday.customs || '',
            holiday.foods || '',
            holiday.greetings || ''
          ]
        );
        
        // 插入地区关联
        await conn.query(
          'INSERT IGNORE INTO holiday_regions (holiday_id, region_code) VALUES (?, ?)',
          [holiday.id, 'GLOBAL']
        );
      }
      
      // 更新全球数据版本
      await conn.query(
        'UPDATE data_versions SET version = version + 1 WHERE region_code = ?',
        ['GLOBAL']
      );
      
      await conn.commit();
      console.log(`成功导入 ${jsonData.holidays.length} 个全球节日`);
    } catch (error) {
      await conn.rollback();
      throw error;
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('导入全球节日数据失败:', error);
  }
}

// 导入地区节日数据
async function importRegionalHolidays(region, languageCode) {
  try {
    console.log(`开始导入 ${region} 地区节日数据...`);
    
    // 读取JSON文件
    const filePath = path.join(__dirname, `../../../assets/data/holidays_${region.toLowerCase()}.json`);
    const jsonData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    // 获取数据库连接
    const conn = await db.pool.getConnection();
    
    try {
      await conn.beginTransaction();
      
      // 导入节日数据
      for (const holiday of jsonData.holidays) {
        // 插入节日基本信息
        await conn.query(
          'INSERT IGNORE INTO holidays (id, type, calculation_type, calculation_rule, importance_level) VALUES (?, ?, ?, ?, ?)',
          [
            holiday.id,
            holiday.type,
            holiday.calculationType,
            holiday.calculationRule,
            getImportanceLevel(holiday.importanceLevel)
          ]
        );
        
        // 插入翻译
        await conn.query(
          'INSERT IGNORE INTO holiday_translations (holiday_id, language_code, name, description, customs, foods, greetings) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            holiday.id,
            languageCode,
            holiday.name,
            holiday.description || '',
            holiday.customs || '',
            holiday.foods || '',
            holiday.greetings || ''
          ]
        );
        
        // 插入地区关联
        await conn.query(
          'INSERT IGNORE INTO holiday_regions (holiday_id, region_code) VALUES (?, ?)',
          [holiday.id, region.toUpperCase()]
        );
      }
      
      // 更新地区数据版本
      await conn.query(
        'UPDATE data_versions SET version = version + 1 WHERE region_code = ?',
        [region.toUpperCase()]
      );
      
      await conn.commit();
      console.log(`成功导入 ${jsonData.holidays.length} 个 ${region} 地区节日`);
    } catch (error) {
      await conn.rollback();
      throw error;
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error(`导入 ${region} 地区节日数据失败:`, error);
  }
}

// 获取重要性级别
function getImportanceLevel(level) {
  switch (level) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 2;
  }
}

// 主函数
async function main() {
  try {
    // 初始化数据库
    await db.initialize();
    
    // 导入全球节日数据
    await importGlobalHolidays();
    
    // 导入地区节日数据
    await importRegionalHolidays('cn', 'zh');
    await importRegionalHolidays('us', 'en');
    
    console.log('数据导入完成');
    process.exit(0);
  } catch (error) {
    console.error('数据导入失败:', error);
    process.exit(1);
  }
}

// 执行主函数
main();
