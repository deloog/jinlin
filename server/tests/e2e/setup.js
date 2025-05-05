/**
 * 端到端测试设置
 * 
 * 此文件在所有端到端测试运行前执行，用于设置测试环境
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const knex = require('../../db/knex');
const logger = require('../../utils/logger');

// 测试服务器进程
let serverProcess = null;

// 测试服务器端口
const TEST_PORT = process.env.TEST_PORT || 3001;

/**
 * 启动测试服务器
 * @returns {Promise<void>}
 */
async function startTestServer() {
  return new Promise((resolve, reject) => {
    // 设置环境变量
    const env = {
      ...process.env,
      NODE_ENV: 'test',
      PORT: TEST_PORT,
      DB_NAME: 'reminder_test',
      LOG_LEVEL: 'error'
    };

    // 启动服务器
    serverProcess = spawn('node', [path.join(__dirname, '../../index.js')], {
      env,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    // 处理服务器输出
    let output = '';
    serverProcess.stdout.on('data', (data) => {
      output += data.toString();
      if (output.includes('Server is running on port')) {
        logger.info(`测试服务器已启动，端口: ${TEST_PORT}`);
        resolve();
      }
    });

    // 处理服务器错误
    serverProcess.stderr.on('data', (data) => {
      logger.error(`测试服务器错误: ${data.toString()}`);
    });

    // 设置超时
    const timeout = setTimeout(() => {
      reject(new Error('启动测试服务器超时'));
    }, 10000);

    // 处理服务器退出
    serverProcess.on('exit', (code) => {
      clearTimeout(timeout);
      if (code !== 0 && code !== null) {
        reject(new Error(`测试服务器异常退出，退出码: ${code}`));
      }
    });
  });
}

/**
 * 准备测试数据库
 * @returns {Promise<void>}
 */
async function prepareTestDatabase() {
  try {
    // 运行迁移
    logger.info('运行数据库迁移...');
    await knex.migrate.latest();

    // 清空测试数据
    logger.info('清空测试数据...');
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
    logger.info('插入测试数据...');
    await insertTestData();

    logger.info('测试数据库准备完成');
  } catch (error) {
    logger.error('准备测试数据库失败:', error);
    throw error;
  }
}

/**
 * 插入测试数据
 * @returns {Promise<void>}
 */
async function insertTestData() {
  // 插入测试用户
  await knex('users').insert([
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
  ]);

  // 插入测试提醒事项
  await knex('reminders').insert([
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
  ]);

  // 插入测试节日数据
  await knex('holidays').insert([
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
  ]);
}

/**
 * 全局设置
 */
module.exports = async () => {
  try {
    // 准备测试数据库
    await prepareTestDatabase();

    // 启动测试服务器
    await startTestServer();

    // 设置全局变量
    global.__TEST_SERVER_PROCESS__ = serverProcess;
    global.__TEST_SERVER_PORT__ = TEST_PORT;
    global.__TEST_BASE_URL__ = `http://localhost:${TEST_PORT}`;

    logger.info('端到端测试环境设置完成');
  } catch (error) {
    logger.error('设置端到端测试环境失败:', error);
    throw error;
  }
};
