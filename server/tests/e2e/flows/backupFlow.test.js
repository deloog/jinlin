/**
 * 备份流程端到端测试
 * 
 * 测试备份功能的完整流程
 */

const path = require('path');
const fs = require('fs');
const TestClient = require('../utils/testClient');
const { 
  checkResponseStatus,
  checkResponseFields,
  wait
} = require('../utils/testHelpers');
const logger = require('../../../utils/logger');

// 测试客户端
let client;

// 备份目录
const backupDir = process.env.BACKUP_DIR || path.resolve(process.cwd(), 'backups');

// 在所有测试前初始化
beforeAll(async () => {
  client = new TestClient();
  
  logger.info('备份流程测试开始');
  
  // 确保备份目录存在
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }
  
  // 登录管理员账号
  await loginAsAdmin();
});

// 在所有测试后清理
afterAll(async () => {
  logger.info('备份流程测试结束');
  
  // 清理测试生成的备份文件
  cleanupTestBackups();
});

/**
 * 登录为管理员
 */
async function loginAsAdmin() {
  try {
    const response = await client.login('admin@example.com', 'password');
    expect(response.status).toBe(200);
    expect(client.token).toBeTruthy();
  } catch (error) {
    logger.error('管理员登录失败', error);
    throw error;
  }
}

/**
 * 清理测试备份
 */
function cleanupTestBackups() {
  try {
    // 获取备份文件
    const files = fs.readdirSync(backupDir)
      .filter(file => file.includes('_test_'));
    
    // 删除测试备份文件
    for (const file of files) {
      fs.unlinkSync(path.join(backupDir, file));
    }
    
    logger.info(`已清理 ${files.length} 个测试备份文件`);
  } catch (error) {
    logger.error('清理测试备份失败', error);
  }
}

describe('备份流程', () => {
  // 第1步：获取备份状态
  test('1. 获取备份状态', async () => {
    // 执行获取备份状态
    const response = await client.agent
      .get('/api/backup/status')
      .set('Authorization', `Bearer ${client.token}`);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['status', 'history'])).toBe(true);
    
    // 验证状态
    expect(response.body.status).toBeDefined();
    expect(response.body.status.enabled).toBeDefined();
    expect(response.body.status.schedules).toBeDefined();
    
    logger.info('获取备份状态成功');
  });
  
  // 第2步：更新备份配置
  test('2. 更新备份配置', async () => {
    // 准备配置数据
    const configData = {
      enabled: true,
      schedules: {
        daily: '0 1 * * *',
        weekly: '0 2 * * 0',
        monthly: '0 3 1 * *'
      },
      retention: {
        daily: 7,
        weekly: 4,
        monthly: 12
      },
      upload: {
        enabled: false
      },
      notification: {
        success: true,
        failure: true
      },
      monitoring: {
        enabled: true,
        interval: 900000, // 15分钟
        thresholds: {
          age: {
            daily: 86400000, // 1天
            weekly: 604800000, // 7天
            monthly: 2678400000 // 31天
          }
        }
      }
    };
    
    // 执行更新备份配置
    const response = await client.agent
      .put('/api/backup/config')
      .set('Authorization', `Bearer ${client.token}`)
      .send(configData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message', 'config'])).toBe(true);
    
    // 验证配置
    expect(response.body.config.scheduler).toBeDefined();
    expect(response.body.config.scheduler.enabled).toBe(configData.enabled);
    expect(response.body.config.monitoring).toBeDefined();
    expect(response.body.config.monitoring.enabled).toBe(configData.monitoring.enabled);
    
    logger.info('更新备份配置成功');
  });
  
  // 第3步：执行手动备份
  test('3. 执行手动备份', async () => {
    // 准备备份数据
    const backupData = {
      type: 'db',
      upload: false
    };
    
    // 执行手动备份
    const response = await client.agent
      .post('/api/backup/execute')
      .set('Authorization', `Bearer ${client.token}`)
      .send(backupData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message', 'taskId'])).toBe(true);
    
    // 保存任务ID
    const taskId = response.body.taskId;
    expect(taskId).toBeTruthy();
    
    logger.info(`手动备份已启动，任务ID: ${taskId}`);
    
    // 等待备份完成
    await waitForBackupTask(taskId);
  }, 30000); // 增加超时时间
  
  // 第4步：获取备份任务状态
  test('4. 获取备份任务状态', async () => {
    // 准备备份数据
    const backupData = {
      type: 'db',
      upload: false
    };
    
    // 执行手动备份
    const executeResponse = await client.agent
      .post('/api/backup/execute')
      .set('Authorization', `Bearer ${client.token}`)
      .send(backupData);
    
    // 获取任务ID
    const taskId = executeResponse.body.taskId;
    
    // 执行获取备份任务状态
    const response = await client.agent
      .get(`/api/backup/task/${taskId}`)
      .set('Authorization', `Bearer ${client.token}`);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['task'])).toBe(true);
    
    // 验证任务
    expect(response.body.task.id).toBe(taskId);
    expect(response.body.task.type).toBe('backup');
    expect(response.body.task.data.type).toBe(backupData.type);
    
    logger.info('获取备份任务状态成功');
    
    // 等待备份完成
    await waitForBackupTask(taskId);
  }, 30000); // 增加超时时间
  
  // 第5步：删除备份文件
  test('5. 删除备份文件', async () => {
    // 创建测试备份文件
    const testBackupFile = createTestBackupFile();
    
    // 执行删除备份文件
    const response = await client.agent
      .delete(`/api/backup/file/${testBackupFile}`)
      .set('Authorization', `Bearer ${client.token}`);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message'])).toBe(true);
    
    // 验证文件已删除
    expect(fs.existsSync(path.join(backupDir, testBackupFile))).toBe(false);
    
    logger.info('删除备份文件成功');
  });
});

/**
 * 等待备份任务完成
 * @param {string} taskId - 任务ID
 * @returns {Promise<void>}
 */
async function waitForBackupTask(taskId) {
  const maxAttempts = 10;
  const interval = 1000; // 1秒
  
  for (let i = 0; i < maxAttempts; i++) {
    // 获取任务状态
    const response = await client.agent
      .get(`/api/backup/task/${taskId}`)
      .set('Authorization', `Bearer ${client.token}`);
    
    // 检查任务是否完成
    if (response.body.task.status === 'completed') {
      logger.info(`备份任务已完成: ${taskId}`);
      return;
    }
    
    // 检查任务是否失败
    if (response.body.task.status === 'failed') {
      logger.error(`备份任务失败: ${taskId}`, response.body.task.error);
      throw new Error(`备份任务失败: ${response.body.task.error}`);
    }
    
    // 等待一段时间
    await wait(interval);
  }
  
  logger.warn(`备份任务未在预期时间内完成: ${taskId}`);
}

/**
 * 创建测试备份文件
 * @returns {string} 文件名
 */
function createTestBackupFile() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const fileName = `test_${timestamp}_daily.txt`;
  const filePath = path.join(backupDir, fileName);
  
  // 创建文件
  fs.writeFileSync(filePath, 'This is a test backup file');
  
  logger.info(`已创建测试备份文件: ${fileName}`);
  
  return fileName;
}
