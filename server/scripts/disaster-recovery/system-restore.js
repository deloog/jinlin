/**
 * 系统恢复脚本
 * 
 * 此脚本用于在灾难发生后恢复整个系统
 * 
 * 使用方法:
 * node system-restore.js [--env=<环境>] [--backup-date=<备份日期>] [--components=<组件列表>]
 * 
 * 示例:
 * node system-restore.js
 * node system-restore.js --env=production --backup-date=2023-07-01
 * node system-restore.js --components=database,files,config
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const logger = require('../../utils/logger');

// 解析命令行参数
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace('--', '')] = value;
  return acc;
}, {});

// 设置环境
const env = args.env || process.env.NODE_ENV || 'development';
dotenv.config({ path: path.resolve(process.cwd(), `.env.${env}`) });

// 设置备份日期
const backupDate = args['backup-date'] || new Date().toISOString().split('T')[0];

// 设置要恢复的组件
const components = args.components ? args.components.split(',') : ['database', 'files', 'config', 'app'];

// 配置
const config = {
  backupDir: process.env.BACKUP_DIR || path.resolve(process.cwd(), 'backups'),
  dbConfig: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'reminder_db'
  },
  appDir: process.env.APP_DIR || process.cwd(),
  configDir: process.env.CONFIG_DIR || path.resolve(process.cwd(), 'config'),
  filesDir: process.env.FILES_DIR || path.resolve(process.cwd(), 'uploads')
};

/**
 * 查找最近的备份文件
 * @param {string} dir - 备份目录
 * @param {string} prefix - 文件前缀
 * @param {string} date - 备份日期
 * @returns {string|null} - 备份文件路径
 */
function findLatestBackup(dir, prefix, date) {
  try {
    if (!fs.existsSync(dir)) {
      logger.error(`备份目录不存在: ${dir}`);
      return null;
    }

    // 获取指定日期的备份文件
    const files = fs.readdirSync(dir)
      .filter(file => file.startsWith(prefix) && file.includes(date))
      .sort()
      .reverse();

    if (files.length === 0) {
      logger.error(`未找到${date}的备份文件`);
      return null;
    }

    return path.join(dir, files[0]);
  } catch (error) {
    logger.error(`查找备份文件失败: ${error.message}`);
    return null;
  }
}

/**
 * 恢复数据库
 * @returns {Promise<boolean>} - 是否恢复成功
 */
async function restoreDatabase() {
  try {
    logger.info('=== 开始恢复数据库 ===');

    // 查找最近的数据库备份
    const dbBackupFile = findLatestBackup(
      config.backupDir,
      `${config.dbConfig.database}_`,
      backupDate
    );

    if (!dbBackupFile) {
      return false;
    }

    logger.info(`使用备份文件: ${dbBackupFile}`);

    // 调用数据库恢复脚本
    const restoreScript = path.resolve(__dirname, 'database-restore.js');
    execSync(`node ${restoreScript} --backup-file=${dbBackupFile} --env=${env}`, {
      stdio: 'inherit'
    });

    logger.info('=== 数据库恢复完成 ===');
    return true;
  } catch (error) {
    logger.error(`恢复数据库失败: ${error.message}`);
    return false;
  }
}

/**
 * 恢复文件
 * @returns {Promise<boolean>} - 是否恢复成功
 */
async function restoreFiles() {
  try {
    logger.info('=== 开始恢复文件 ===');

    // 查找最近的文件备份
    const filesBackupFile = findLatestBackup(
      config.backupDir,
      'files_',
      backupDate
    );

    if (!filesBackupFile) {
      return false;
    }

    logger.info(`使用备份文件: ${filesBackupFile}`);

    // 确保目标目录存在
    if (!fs.existsSync(config.filesDir)) {
      fs.mkdirSync(config.filesDir, { recursive: true });
    }

    // 解压文件
    const fileExt = path.extname(filesBackupFile).toLowerCase();
    let extractCommand;

    switch (fileExt) {
      case '.tar.gz':
      case '.tgz':
        extractCommand = `tar -xzf ${filesBackupFile} -C ${config.filesDir}`;
        break;
      case '.tar.bz2':
      case '.tbz2':
        extractCommand = `tar -xjf ${filesBackupFile} -C ${config.filesDir}`;
        break;
      case '.tar.xz':
      case '.txz':
        extractCommand = `tar -xJf ${filesBackupFile} -C ${config.filesDir}`;
        break;
      case '.zip':
        extractCommand = `unzip -o ${filesBackupFile} -d ${config.filesDir}`;
        break;
      default:
        logger.error(`不支持的文件格式: ${fileExt}`);
        return false;
    }

    execSync(extractCommand, { stdio: 'inherit' });

    logger.info('=== 文件恢复完成 ===');
    return true;
  } catch (error) {
    logger.error(`恢复文件失败: ${error.message}`);
    return false;
  }
}

/**
 * 恢复配置
 * @returns {Promise<boolean>} - 是否恢复成功
 */
async function restoreConfig() {
  try {
    logger.info('=== 开始恢复配置 ===');

    // 查找最近的配置备份
    const configBackupFile = findLatestBackup(
      config.backupDir,
      'config_',
      backupDate
    );

    if (!configBackupFile) {
      return false;
    }

    logger.info(`使用备份文件: ${configBackupFile}`);

    // 确保目标目录存在
    if (!fs.existsSync(config.configDir)) {
      fs.mkdirSync(config.configDir, { recursive: true });
    }

    // 解压配置文件
    const fileExt = path.extname(configBackupFile).toLowerCase();
    let extractCommand;

    switch (fileExt) {
      case '.tar.gz':
      case '.tgz':
        extractCommand = `tar -xzf ${configBackupFile} -C ${config.configDir}`;
        break;
      case '.tar.bz2':
      case '.tbz2':
        extractCommand = `tar -xjf ${configBackupFile} -C ${config.configDir}`;
        break;
      case '.tar.xz':
      case '.txz':
        extractCommand = `tar -xJf ${configBackupFile} -C ${config.configDir}`;
        break;
      case '.zip':
        extractCommand = `unzip -o ${configBackupFile} -d ${config.configDir}`;
        break;
      default:
        logger.error(`不支持的文件格式: ${fileExt}`);
        return false;
    }

    execSync(extractCommand, { stdio: 'inherit' });

    logger.info('=== 配置恢复完成 ===');
    return true;
  } catch (error) {
    logger.error(`恢复配置失败: ${error.message}`);
    return false;
  }
}

/**
 * 重启应用
 * @returns {Promise<boolean>} - 是否重启成功
 */
async function restartApp() {
  try {
    logger.info('=== 开始重启应用 ===');

    // 安装依赖
    logger.info('安装依赖...');
    execSync('npm install', {
      cwd: config.appDir,
      stdio: 'inherit'
    });

    // 运行数据库迁移
    logger.info('运行数据库迁移...');
    execSync('npm run migrate', {
      cwd: config.appDir,
      stdio: 'inherit'
    });

    // 重启应用
    logger.info('重启应用...');
    if (env === 'production') {
      // 使用PM2重启应用
      execSync('pm2 restart all', {
        stdio: 'inherit'
      });
    } else {
      // 开发环境直接启动应用
      const child = spawn('npm', ['run', 'dev'], {
        cwd: config.appDir,
        detached: true,
        stdio: 'ignore'
      });
      child.unref();
    }

    logger.info('=== 应用重启完成 ===');
    return true;
  } catch (error) {
    logger.error(`重启应用失败: ${error.message}`);
    return false;
  }
}

/**
 * 验证系统恢复
 * @returns {Promise<boolean>} - 是否验证成功
 */
async function validateSystem() {
  try {
    logger.info('=== 开始验证系统 ===');

    // 等待应用启动
    logger.info('等待应用启动...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 检查应用是否正常运行
    logger.info('检查应用状态...');
    const healthCheck = execSync('curl -s http://localhost:3000/api/health', {
      encoding: 'utf-8'
    });

    const healthData = JSON.parse(healthCheck);
    if (healthData.status !== 'ok') {
      logger.error(`应用健康检查失败: ${JSON.stringify(healthData)}`);
      return false;
    }

    logger.info('应用健康检查通过');

    // 检查数据库连接
    logger.info('检查数据库连接...');
    const dbCheck = execSync('curl -s http://localhost:3000/api/health/db', {
      encoding: 'utf-8'
    });

    const dbData = JSON.parse(dbCheck);
    if (dbData.status !== 'ok') {
      logger.error(`数据库健康检查失败: ${JSON.stringify(dbData)}`);
      return false;
    }

    logger.info('数据库健康检查通过');

    logger.info('=== 系统验证完成 ===');
    return true;
  } catch (error) {
    logger.error(`验证系统失败: ${error.message}`);
    return false;
  }
}

/**
 * 主函数
 */
async function main() {
  try {
    logger.info('=== 开始系统恢复过程 ===');
    logger.info(`环境: ${env}`);
    logger.info(`备份日期: ${backupDate}`);
    logger.info(`要恢复的组件: ${components.join(', ')}`);

    // 恢复数据库
    if (components.includes('database')) {
      const dbRestored = await restoreDatabase();
      if (!dbRestored) {
        logger.error('数据库恢复失败，中止系统恢复');
        process.exit(1);
      }
    }

    // 恢复文件
    if (components.includes('files')) {
      const filesRestored = await restoreFiles();
      if (!filesRestored) {
        logger.warn('文件恢复失败，继续系统恢复');
      }
    }

    // 恢复配置
    if (components.includes('config')) {
      const configRestored = await restoreConfig();
      if (!configRestored) {
        logger.warn('配置恢复失败，继续系统恢复');
      }
    }

    // 重启应用
    if (components.includes('app')) {
      const appRestarted = await restartApp();
      if (!appRestarted) {
        logger.error('应用重启失败，中止系统恢复');
        process.exit(1);
      }
    }

    // 验证系统
    const validated = await validateSystem();
    if (!validated) {
      logger.error('系统验证失败，恢复可能不完整');
      process.exit(1);
    }

    logger.info('=== 系统恢复过程完成 ===');
    process.exit(0);
  } catch (error) {
    logger.error(`系统恢复过程失败: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
main();
