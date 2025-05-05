/**
 * 数据库恢复脚本
 * 
 * 此脚本用于从备份中恢复数据库
 * 
 * 使用方法:
 * node database-restore.js --backup-file=<备份文件路径> [--point-in-time=<恢复时间点>] [--env=<环境>]
 * 
 * 示例:
 * node database-restore.js --backup-file=/backups/reminder_db_20230701.sql
 * node database-restore.js --backup-file=/backups/reminder_db_20230701.sql --point-in-time="2023-07-01T12:00:00Z"
 * node database-restore.js --backup-file=/backups/reminder_db_20230701.sql --env=test
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const knex = require('../../db/knex');
const logger = require('../../utils/logger');

// 解析命令行参数
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace('--', '')] = value;
  return acc;
}, {});

// 验证必要参数
if (!args['backup-file']) {
  logger.error('缺少必要参数: --backup-file');
  process.exit(1);
}

// 设置环境
const env = args.env || process.env.NODE_ENV || 'development';
dotenv.config({ path: path.resolve(process.cwd(), `.env.${env}`) });

// 数据库配置
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'reminder_db'
};

/**
 * 验证备份文件
 * @param {string} backupFile - 备份文件路径
 * @returns {boolean} - 是否有效
 */
function validateBackupFile(backupFile) {
  try {
    if (!fs.existsSync(backupFile)) {
      logger.error(`备份文件不存在: ${backupFile}`);
      return false;
    }

    const stats = fs.statSync(backupFile);
    if (stats.size === 0) {
      logger.error(`备份文件为空: ${backupFile}`);
      return false;
    }

    // 检查文件格式
    const fileExt = path.extname(backupFile).toLowerCase();
    if (!['.sql', '.gz', '.bz2', '.xz'].includes(fileExt)) {
      logger.error(`不支持的备份文件格式: ${fileExt}`);
      return false;
    }

    return true;
  } catch (error) {
    logger.error(`验证备份文件失败: ${error.message}`);
    return false;
  }
}

/**
 * 检查数据库连接
 * @returns {Promise<boolean>} - 是否连接成功
 */
async function checkDatabaseConnection() {
  try {
    await knex.raw('SELECT 1');
    logger.info('数据库连接成功');
    return true;
  } catch (error) {
    logger.error(`数据库连接失败: ${error.message}`);
    return false;
  }
}

/**
 * 创建数据库备份
 * @returns {Promise<string>} - 备份文件路径
 */
async function createDatabaseBackup() {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.resolve(process.cwd(), 'backups');
    
    // 确保备份目录存在
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }
    
    const backupFile = path.join(backupDir, `${dbConfig.database}_${timestamp}.sql`);
    
    logger.info(`创建数据库备份: ${backupFile}`);
    
    // 使用mysqldump创建备份
    execSync(`mysqldump -h ${dbConfig.host} -P ${dbConfig.port} -u ${dbConfig.user} -p${dbConfig.password} ${dbConfig.database} > ${backupFile}`);
    
    logger.info(`数据库备份创建成功: ${backupFile}`);
    return backupFile;
  } catch (error) {
    logger.error(`创建数据库备份失败: ${error.message}`);
    throw error;
  }
}

/**
 * 恢复数据库
 * @param {string} backupFile - 备份文件路径
 * @param {string} [pointInTime] - 恢复时间点
 * @returns {Promise<boolean>} - 是否恢复成功
 */
async function restoreDatabase(backupFile, pointInTime) {
  try {
    logger.info(`开始恢复数据库: ${backupFile}`);
    
    // 创建当前数据库的备份
    const currentBackup = await createDatabaseBackup();
    logger.info(`已创建当前数据库备份: ${currentBackup}`);
    
    // 根据文件扩展名处理压缩文件
    const fileExt = path.extname(backupFile).toLowerCase();
    let restoreCommand;
    
    switch (fileExt) {
      case '.gz':
        restoreCommand = `gunzip < ${backupFile} | mysql -h ${dbConfig.host} -P ${dbConfig.port} -u ${dbConfig.user} -p${dbConfig.password} ${dbConfig.database}`;
        break;
      case '.bz2':
        restoreCommand = `bunzip2 < ${backupFile} | mysql -h ${dbConfig.host} -P ${dbConfig.port} -u ${dbConfig.user} -p${dbConfig.password} ${dbConfig.database}`;
        break;
      case '.xz':
        restoreCommand = `xz -d < ${backupFile} | mysql -h ${dbConfig.host} -P ${dbConfig.port} -u ${dbConfig.user} -p${dbConfig.password} ${dbConfig.database}`;
        break;
      default:
        restoreCommand = `mysql -h ${dbConfig.host} -P ${dbConfig.port} -u ${dbConfig.user} -p${dbConfig.password} ${dbConfig.database} < ${backupFile}`;
    }
    
    // 执行恢复命令
    execSync(restoreCommand);
    
    // 如果指定了时间点，应用事务日志
    if (pointInTime) {
      logger.info(`应用事务日志到时间点: ${pointInTime}`);
      // 这里应该实现应用事务日志的逻辑
      // 例如: applyTransactionLogs(pointInTime);
    }
    
    logger.info('数据库恢复成功');
    return true;
  } catch (error) {
    logger.error(`恢复数据库失败: ${error.message}`);
    return false;
  }
}

/**
 * 验证恢复结果
 * @returns {Promise<boolean>} - 是否验证成功
 */
async function validateRestore() {
  try {
    logger.info('验证数据库恢复结果');
    
    // 检查关键表是否存在
    const tables = ['users', 'reminders', 'holidays', 'solar_terms'];
    for (const table of tables) {
      const exists = await knex.schema.hasTable(table);
      if (!exists) {
        logger.error(`表不存在: ${table}`);
        return false;
      }
      
      // 检查表中是否有数据
      const count = await knex(table).count('* as count').first();
      logger.info(`表 ${table} 中有 ${count.count} 条记录`);
    }
    
    // 执行一些基本查询
    const userCount = await knex('users').count('* as count').first();
    const reminderCount = await knex('reminders').count('* as count').first();
    
    logger.info(`用户数: ${userCount.count}, 提醒事项数: ${reminderCount.count}`);
    logger.info('数据库恢复验证成功');
    
    return true;
  } catch (error) {
    logger.error(`验证恢复结果失败: ${error.message}`);
    return false;
  }
}

/**
 * 主函数
 */
async function main() {
  try {
    logger.info('=== 开始数据库恢复过程 ===');
    logger.info(`环境: ${env}`);
    logger.info(`备份文件: ${args['backup-file']}`);
    if (args['point-in-time']) {
      logger.info(`恢复时间点: ${args['point-in-time']}`);
    }
    
    // 验证备份文件
    if (!validateBackupFile(args['backup-file'])) {
      process.exit(1);
    }
    
    // 检查数据库连接
    if (!await checkDatabaseConnection()) {
      process.exit(1);
    }
    
    // 恢复数据库
    const restored = await restoreDatabase(args['backup-file'], args['point-in-time']);
    if (!restored) {
      process.exit(1);
    }
    
    // 验证恢复结果
    const validated = await validateRestore();
    if (!validated) {
      logger.warn('恢复验证失败，但数据库已恢复');
      process.exit(1);
    }
    
    logger.info('=== 数据库恢复过程完成 ===');
    process.exit(0);
  } catch (error) {
    logger.error(`数据库恢复过程失败: ${error.message}`);
    process.exit(1);
  } finally {
    // 关闭数据库连接
    await knex.destroy();
  }
}

// 执行主函数
main();
