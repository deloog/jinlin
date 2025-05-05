/**
 * 端到端测试清理
 * 
 * 此文件在所有端到端测试运行后执行，用于清理测试环境
 */

const knex = require('../../db/knex');
const logger = require('../../utils/logger');

/**
 * 停止测试服务器
 * @returns {Promise<void>}
 */
async function stopTestServer() {
  return new Promise((resolve) => {
    const serverProcess = global.__TEST_SERVER_PROCESS__;
    
    if (serverProcess) {
      logger.info('正在停止测试服务器...');
      
      // 设置超时，确保服务器能够正常关闭
      const timeout = setTimeout(() => {
        logger.warn('测试服务器关闭超时，强制终止');
        serverProcess.kill('SIGKILL');
        resolve();
      }, 5000);
      
      // 监听服务器退出
      serverProcess.on('exit', () => {
        clearTimeout(timeout);
        logger.info('测试服务器已停止');
        resolve();
      });
      
      // 发送关闭信号
      serverProcess.kill('SIGTERM');
    } else {
      logger.warn('测试服务器进程不存在');
      resolve();
    }
  });
}

/**
 * 清理测试数据库
 * @returns {Promise<void>}
 */
async function cleanupTestDatabase() {
  try {
    logger.info('清理测试数据库...');
    
    // 清空测试数据
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
    
    // 关闭数据库连接
    await knex.destroy();
    
    logger.info('测试数据库已清理');
  } catch (error) {
    logger.error('清理测试数据库失败:', error);
    throw error;
  }
}

/**
 * 全局清理
 */
module.exports = async () => {
  try {
    // 停止测试服务器
    await stopTestServer();
    
    // 清理测试数据库
    await cleanupTestDatabase();
    
    // 清理全局变量
    delete global.__TEST_SERVER_PROCESS__;
    delete global.__TEST_SERVER_PORT__;
    delete global.__TEST_BASE_URL__;
    
    logger.info('端到端测试环境清理完成');
  } catch (error) {
    logger.error('清理端到端测试环境失败:', error);
    throw error;
  }
};
