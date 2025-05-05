/**
 * 系统备份脚本
 * 
 * 此脚本用于创建系统的完整备份，包括数据库、文件和配置
 * 
 * 使用方法:
 * node backup.js [--type=<备份类型>] [--env=<环境>] [--upload=<是否上传>]
 * 
 * 备份类型:
 * - full: 完整备份（默认）
 * - db: 仅数据库备份
 * - files: 仅文件备份
 * - config: 仅配置备份
 * 
 * 示例:
 * node backup.js
 * node backup.js --type=db --env=production
 * node backup.js --upload=true
 */

const { execSync } = require('child_process');
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

// 设置备份类型
const backupType = args.type || 'full';

// 是否上传备份
const shouldUpload = args.upload === 'true';

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
  filesDir: process.env.FILES_DIR || path.resolve(process.cwd(), 'uploads'),
  s3: {
    bucket: process.env.S3_BACKUP_BUCKET || 'reminder-app-backups',
    region: process.env.S3_REGION || 'us-east-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  },
  retention: {
    daily: parseInt(process.env.BACKUP_RETENTION_DAILY || '7'),
    weekly: parseInt(process.env.BACKUP_RETENTION_WEEKLY || '4'),
    monthly: parseInt(process.env.BACKUP_RETENTION_MONTHLY || '12')
  }
};

/**
 * 确保备份目录存在
 */
function ensureBackupDir() {
  if (!fs.existsSync(config.backupDir)) {
    fs.mkdirSync(config.backupDir, { recursive: true });
    logger.info(`创建备份目录: ${config.backupDir}`);
  }
}

/**
 * 生成备份文件名
 * @param {string} prefix - 文件前缀
 * @returns {string} - 备份文件名
 */
function generateBackupFileName(prefix) {
  const now = new Date();
  const timestamp = now.toISOString().replace(/[:.]/g, '-');
  const dayOfWeek = now.getDay();
  const dayOfMonth = now.getDate();
  
  let suffix = 'daily';
  
  // 每周日创建周备份
  if (dayOfWeek === 0) {
    suffix = 'weekly';
  }
  
  // 每月1日创建月备份
  if (dayOfMonth === 1) {
    suffix = 'monthly';
  }
  
  return `${prefix}_${timestamp}_${suffix}`;
}

/**
 * 清理旧备份
 */
function cleanupOldBackups() {
  try {
    logger.info('清理旧备份文件');
    
    if (!fs.existsSync(config.backupDir)) {
      return;
    }
    
    const files = fs.readdirSync(config.backupDir);
    const now = new Date();
    
    for (const file of files) {
      const filePath = path.join(config.backupDir, file);
      const stats = fs.statSync(filePath);
      const fileAge = Math.floor((now - stats.mtime) / (1000 * 60 * 60 * 24)); // 天数
      
      if (file.includes('_daily_') && fileAge > config.retention.daily) {
        fs.unlinkSync(filePath);
        logger.info(`删除过期的每日备份: ${file}`);
      } else if (file.includes('_weekly_') && fileAge > config.retention.daily * config.retention.weekly) {
        fs.unlinkSync(filePath);
        logger.info(`删除过期的每周备份: ${file}`);
      } else if (file.includes('_monthly_') && fileAge > config.retention.daily * config.retention.weekly * config.retention.monthly) {
        fs.unlinkSync(filePath);
        logger.info(`删除过期的每月备份: ${file}`);
      }
    }
  } catch (error) {
    logger.error(`清理旧备份失败: ${error.message}`);
  }
}

/**
 * 备份数据库
 * @returns {Promise<string|null>} - 备份文件路径
 */
async function backupDatabase() {
  try {
    logger.info('=== 开始备份数据库 ===');
    
    const fileName = generateBackupFileName(config.dbConfig.database);
    const backupFile = path.join(config.backupDir, `${fileName}.sql`);
    
    logger.info(`备份数据库到: ${backupFile}`);
    
    // 使用mysqldump创建备份
    execSync(`mysqldump -h ${config.dbConfig.host} -P ${config.dbConfig.port} -u ${config.dbConfig.user} -p${config.dbConfig.password} ${config.dbConfig.database} > ${backupFile}`);
    
    // 压缩备份文件
    logger.info('压缩备份文件');
    execSync(`gzip -f ${backupFile}`);
    const compressedFile = `${backupFile}.gz`;
    
    logger.info(`数据库备份完成: ${compressedFile}`);
    return compressedFile;
  } catch (error) {
    logger.error(`备份数据库失败: ${error.message}`);
    return null;
  }
}

/**
 * 备份文件
 * @returns {Promise<string|null>} - 备份文件路径
 */
async function backupFiles() {
  try {
    logger.info('=== 开始备份文件 ===');
    
    if (!fs.existsSync(config.filesDir)) {
      logger.warn(`文件目录不存在: ${config.filesDir}`);
      return null;
    }
    
    const fileName = generateBackupFileName('files');
    const backupFile = path.join(config.backupDir, `${fileName}.tar.gz`);
    
    logger.info(`备份文件到: ${backupFile}`);
    
    // 使用tar创建备份
    execSync(`tar -czf ${backupFile} -C ${path.dirname(config.filesDir)} ${path.basename(config.filesDir)}`);
    
    logger.info(`文件备份完成: ${backupFile}`);
    return backupFile;
  } catch (error) {
    logger.error(`备份文件失败: ${error.message}`);
    return null;
  }
}

/**
 * 备份配置
 * @returns {Promise<string|null>} - 备份文件路径
 */
async function backupConfig() {
  try {
    logger.info('=== 开始备份配置 ===');
    
    if (!fs.existsSync(config.configDir)) {
      logger.warn(`配置目录不存在: ${config.configDir}`);
      return null;
    }
    
    const fileName = generateBackupFileName('config');
    const backupFile = path.join(config.backupDir, `${fileName}.tar.gz`);
    
    logger.info(`备份配置到: ${backupFile}`);
    
    // 使用tar创建备份
    execSync(`tar -czf ${backupFile} -C ${path.dirname(config.configDir)} ${path.basename(config.configDir)}`);
    
    // 备份环境变量文件
    const envFiles = fs.readdirSync(config.appDir)
      .filter(file => file.startsWith('.env'));
    
    if (envFiles.length > 0) {
      logger.info('备份环境变量文件');
      const envBackupFile = path.join(config.backupDir, `${fileName}_env.tar.gz`);
      const envFileList = envFiles.join(' ');
      
      execSync(`tar -czf ${envBackupFile} -C ${config.appDir} ${envFileList}`);
      logger.info(`环境变量文件备份完成: ${envBackupFile}`);
    }
    
    logger.info(`配置备份完成: ${backupFile}`);
    return backupFile;
  } catch (error) {
    logger.error(`备份配置失败: ${error.message}`);
    return null;
  }
}

/**
 * 上传备份到S3
 * @param {string} filePath - 备份文件路径
 * @returns {Promise<boolean>} - 是否上传成功
 */
async function uploadToS3(filePath) {
  try {
    if (!config.s3.accessKeyId || !config.s3.secretAccessKey) {
      logger.warn('缺少S3凭证，跳过上传');
      return false;
    }
    
    logger.info(`上传备份到S3: ${filePath}`);
    
    const fileName = path.basename(filePath);
    const s3Path = `${env}/${fileName}`;
    
    // 使用AWS CLI上传
    execSync(`aws s3 cp ${filePath} s3://${config.s3.bucket}/${s3Path} --region ${config.s3.region}`, {
      env: {
        ...process.env,
        AWS_ACCESS_KEY_ID: config.s3.accessKeyId,
        AWS_SECRET_ACCESS_KEY: config.s3.secretAccessKey
      }
    });
    
    logger.info(`备份上传成功: s3://${config.s3.bucket}/${s3Path}`);
    return true;
  } catch (error) {
    logger.error(`上传备份失败: ${error.message}`);
    return false;
  }
}

/**
 * 主函数
 */
async function main() {
  try {
    logger.info('=== 开始系统备份过程 ===');
    logger.info(`环境: ${env}`);
    logger.info(`备份类型: ${backupType}`);
    logger.info(`上传备份: ${shouldUpload}`);
    
    // 确保备份目录存在
    ensureBackupDir();
    
    const backupFiles = [];
    
    // 备份数据库
    if (backupType === 'full' || backupType === 'db') {
      const dbBackupFile = await backupDatabase();
      if (dbBackupFile) {
        backupFiles.push(dbBackupFile);
      }
    }
    
    // 备份文件
    if (backupType === 'full' || backupType === 'files') {
      const filesBackupFile = await backupFiles();
      if (filesBackupFile) {
        backupFiles.push(filesBackupFile);
      }
    }
    
    // 备份配置
    if (backupType === 'full' || backupType === 'config') {
      const configBackupFile = await backupConfig();
      if (configBackupFile) {
        backupFiles.push(configBackupFile);
      }
    }
    
    // 上传备份
    if (shouldUpload && backupFiles.length > 0) {
      for (const file of backupFiles) {
        await uploadToS3(file);
      }
    }
    
    // 清理旧备份
    cleanupOldBackups();
    
    logger.info('=== 系统备份过程完成 ===');
    process.exit(0);
  } catch (error) {
    logger.error(`系统备份过程失败: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
main();
