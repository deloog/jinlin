/**
 * 用户旅程端到端测试
 * 
 * 测试用户从注册到使用的完整流程
 */

const TestClient = require('../utils/testClient');
const TestDatabase = require('../utils/testDatabase');
const { 
  generateTestUserData, 
  generateTestReminderData,
  checkResponseStatus,
  checkResponseFields
} = require('../utils/testHelpers');
const logger = require('../../../utils/logger');

// 测试客户端
let client;

// 测试数据库
let db;

// 测试数据
const testUser = generateTestUserData();
let userId;
let reminderId;

// 在所有测试前初始化
beforeAll(async () => {
  client = new TestClient();
  db = new TestDatabase();
  
  logger.info('用户旅程测试开始');
});

// 在所有测试后清理
afterAll(async () => {
  logger.info('用户旅程测试结束');
});

describe('用户旅程', () => {
  // 第1步：用户注册
  test('1. 用户注册', async () => {
    // 执行注册
    const response = await client.register(testUser);
    
    // 验证响应
    expect(checkResponseStatus(response, 201)).toBe(true);
    expect(checkResponseFields(response, ['message', 'data.user.id'])).toBe(true);
    
    // 保存用户ID
    userId = response.body.data.user.id;
    
    // 验证用户已创建
    const user = await db.getUser(userId);
    expect(user).toBeTruthy();
    expect(user.email).toBe(testUser.email);
    
    logger.info(`用户注册成功，ID: ${userId}`);
  });
  
  // 第2步：用户登录
  test('2. 用户登录', async () => {
    // 执行登录
    const response = await client.login(testUser.email, testUser.password);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, [
      'message', 
      'data.user.id', 
      'data.access_token', 
      'data.refresh_token'
    ])).toBe(true);
    
    // 验证令牌已保存
    expect(client.token).toBeTruthy();
    expect(client.refreshToken).toBeTruthy();
    
    logger.info('用户登录成功');
  });
  
  // 第3步：获取用户资料
  test('3. 获取用户资料', async () => {
    // 执行获取用户资料
    const response = await client.getUserProfile();
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['data.id', 'data.email', 'data.username'])).toBe(true);
    
    // 验证用户资料
    expect(response.body.data.id).toBe(userId);
    expect(response.body.data.email).toBe(testUser.email);
    
    logger.info('获取用户资料成功');
  });
  
  // 第4步：创建提醒事项
  test('4. 创建提醒事项', async () => {
    // 准备提醒事项数据
    const reminderData = generateTestReminderData();
    
    // 执行创建提醒事项
    const response = await client.createReminder(reminderData);
    
    // 验证响应
    expect(checkResponseStatus(response, 201)).toBe(true);
    expect(checkResponseFields(response, ['message', 'data.id', 'data.title'])).toBe(true);
    
    // 保存提醒事项ID
    reminderId = response.body.data.id;
    
    // 验证提醒事项已创建
    const reminder = await db.getReminder(reminderId);
    expect(reminder).toBeTruthy();
    expect(reminder.title).toBe(reminderData.title);
    expect(reminder.user_id).toBe(userId);
    
    logger.info(`创建提醒事项成功，ID: ${reminderId}`);
  });
  
  // 第5步：获取提醒事项列表
  test('5. 获取提醒事项列表', async () => {
    // 执行获取提醒事项列表
    const response = await client.getReminders();
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['data', 'data[0].id', 'data[0].title'])).toBe(true);
    
    // 验证提醒事项列表
    expect(response.body.data.length).toBeGreaterThan(0);
    expect(response.body.data.some(item => item.id === reminderId)).toBe(true);
    
    logger.info('获取提醒事项列表成功');
  });
  
  // 第6步：更新提醒事项
  test('6. 更新提醒事项', async () => {
    // 准备更新数据
    const updateData = {
      title: `更新的提醒事项 ${Date.now()}`,
      is_completed: true
    };
    
    // 执行更新提醒事项
    const response = await client.updateReminder(reminderId, updateData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message', 'data.id', 'data.title'])).toBe(true);
    
    // 验证提醒事项已更新
    const reminder = await db.getReminder(reminderId);
    expect(reminder).toBeTruthy();
    expect(reminder.title).toBe(updateData.title);
    expect(reminder.is_completed).toBe(1); // MySQL中布尔值存储为0/1
    
    logger.info('更新提醒事项成功');
  });
  
  // 第7步：获取节日列表
  test('7. 获取节日列表', async () => {
    // 执行获取节日列表
    const response = await client.getHolidays('global');
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['data'])).toBe(true);
    
    // 验证节日列表
    expect(Array.isArray(response.body.data)).toBe(true);
    
    logger.info('获取节日列表成功');
  });
  
  // 第8步：获取节气列表
  test('8. 获取节气列表', async () => {
    // 执行获取节气列表
    const response = await client.getSolarTerms();
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['data'])).toBe(true);
    
    // 验证节气列表
    expect(Array.isArray(response.body.data)).toBe(true);
    
    logger.info('获取节气列表成功');
  });
  
  // 第9步：删除提醒事项
  test('9. 删除提醒事项', async () => {
    // 执行删除提醒事项
    const response = await client.deleteReminder(reminderId);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message'])).toBe(true);
    
    // 验证提醒事项已删除
    const reminder = await db.getReminder(reminderId);
    expect(reminder).toBeFalsy();
    
    logger.info('删除提醒事项成功');
  });
  
  // 第10步：刷新令牌
  test('10. 刷新令牌', async () => {
    // 保存旧令牌
    const oldToken = client.token;
    
    // 执行刷新令牌
    const response = await client.refreshAccessToken();
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['data.access_token', 'data.refresh_token'])).toBe(true);
    
    // 验证令牌已更新
    expect(client.token).not.toBe(oldToken);
    
    logger.info('刷新令牌成功');
  });
  
  // 第11步：用户登出
  test('11. 用户登出', async () => {
    // 执行登出
    const response = await client.logout();
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, ['message'])).toBe(true);
    
    // 验证令牌已清除
    expect(client.token).toBeNull();
    expect(client.refreshToken).toBeNull();
    
    logger.info('用户登出成功');
  });
});
