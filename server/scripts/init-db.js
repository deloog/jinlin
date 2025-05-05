/**
 * 数据库初始化脚本
 * 
 * 用于CI/CD环境中初始化测试数据库
 */

const knex = require('../db/knex');
const logger = require('../utils/logger');

/**
 * 初始化数据库
 * @returns {Promise<void>}
 */
async function initDatabase() {
  try {
    logger.info('开始初始化数据库');
    
    // 运行迁移
    logger.info('运行数据库迁移');
    await knex.migrate.latest();
    
    // 清空所有表
    logger.info('清空所有表');
    const tables = await knex.raw('SHOW TABLES');
    const tableNames = tables[0].map(table => Object.values(table)[0]);
    
    // 禁用外键检查
    await knex.raw('SET FOREIGN_KEY_CHECKS = 0');
    
    // 清空所有表
    for (const tableName of tableNames) {
      if (tableName !== 'knex_migrations' && tableName !== 'knex_migrations_lock') {
        await knex(tableName).truncate();
      }
    }
    
    // 启用外键检查
    await knex.raw('SET FOREIGN_KEY_CHECKS = 1');
    
    // 插入测试数据
    logger.info('插入测试数据');
    await insertTestData();
    
    logger.info('数据库初始化完成');
  } catch (error) {
    logger.error('数据库初始化失败', error);
    throw error;
  } finally {
    // 关闭数据库连接
    await knex.destroy();
  }
}

/**
 * 插入测试数据
 * @returns {Promise<void>}
 */
async function insertTestData() {
  try {
    // 插入测试用户
    const users = [
      {
        username: 'testuser',
        email: 'test@example.com',
        password: '$2b$10$eCQDz.GfKB7jFZ7JeXE5aeKIYwbZOB0xOxwrLYpLD/xt9ZSZj2mAu', // 密码: password
        display_name: 'Test User',
        role: 'user',
        is_email_verified: true,
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        username: 'testadmin',
        email: 'admin@example.com',
        password: '$2b$10$eCQDz.GfKB7jFZ7JeXE5aeKIYwbZOB0xOxwrLYpLD/xt9ZSZj2mAu', // 密码: password
        display_name: 'Test Admin',
        role: 'admin',
        is_email_verified: true,
        created_at: new Date(),
        updated_at: new Date()
      }
    ];
    
    const userIds = await knex('users').insert(users);
    logger.info(`已插入 ${userIds.length} 个测试用户`);
    
    // 插入测试提醒事项
    const reminders = [
      {
        user_id: 1,
        title: '测试提醒事项1',
        description: '这是一个测试提醒事项',
        reminder_date: new Date(Date.now() + 86400000), // 明天
        is_completed: false,
        priority: 'medium',
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        user_id: 1,
        title: '测试提醒事项2',
        description: '这是另一个测试提醒事项',
        reminder_date: new Date(Date.now() + 172800000), // 后天
        is_completed: true,
        priority: 'high',
        created_at: new Date(),
        updated_at: new Date()
      }
    ];
    
    const reminderIds = await knex('reminders').insert(reminders);
    logger.info(`已插入 ${reminderIds.length} 个测试提醒事项`);
    
    // 插入测试节日数据
    const holidays = [
      {
        name: '测试节日1',
        date: '2023-01-01',
        description: '这是一个测试节日',
        country: 'global',
        type: 'fixed',
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        name: '测试节日2',
        date: '2023-12-25',
        description: '这是另一个测试节日',
        country: 'global',
        type: 'fixed',
        created_at: new Date(),
        updated_at: new Date()
      }
    ];
    
    const holidayIds = await knex('holidays').insert(holidays);
    logger.info(`已插入 ${holidayIds.length} 个测试节日`);
    
    // 插入测试节气数据
    const solarTerms = [
      {
        name: '立春',
        date: '2023-02-04',
        description: '立春，为二十四节气之一，标志着春季的开始',
        year: 2023,
        created_at: new Date(),
        updated_at: new Date()
      },
      {
        name: '雨水',
        date: '2023-02-19',
        description: '雨水，为二十四节气之一，此时降水开始增多',
        year: 2023,
        created_at: new Date(),
        updated_at: new Date()
      }
    ];
    
    const solarTermIds = await knex('solar_terms').insert(solarTerms);
    logger.info(`已插入 ${solarTermIds.length} 个测试节气`);
  } catch (error) {
    logger.error('插入测试数据失败', error);
    throw error;
  }
}

// 执行初始化
initDatabase().catch(error => {
  logger.error('数据库初始化脚本执行失败', error);
  process.exit(1);
});
