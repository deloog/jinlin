/**
 * 数据同步流程端到端测试
 * 
 * 测试数据同步的完整流程
 */

const TestClient = require('../utils/testClient');
const TestDatabase = require('../utils/testDatabase');
const { 
  generateTestUserData, 
  generateTestReminderData,
  checkResponseStatus,
  checkResponseFields,
  wait
} = require('../utils/testHelpers');
const logger = require('../../../utils/logger');

// 测试客户端
let client;

// 测试数据库
let db;

// 测试数据
const testUser = generateTestUserData();
let userId;
let clientReminders = [];

// 在所有测试前初始化
beforeAll(async () => {
  client = new TestClient();
  db = new TestDatabase();
  
  logger.info('数据同步测试开始');
  
  // 注册测试用户
  const registerResponse = await client.register(testUser);
  userId = registerResponse.body.data.user.id;
  
  // 登录
  await client.login(testUser.email, testUser.password);
});

// 在所有测试后清理
afterAll(async () => {
  logger.info('数据同步测试结束');
});

describe('数据同步流程', () => {
  // 第1步：准备客户端数据
  test('1. 准备客户端数据', async () => {
    // 生成客户端提醒事项数据
    for (let i = 0; i < 5; i++) {
      const reminderData = generateTestReminderData({
        title: `客户端提醒事项 ${i + 1}`,
        client_id: `client_${Date.now()}_${i}`,
        is_synced: false,
        last_modified: new Date().toISOString()
      });
      
      clientReminders.push(reminderData);
    }
    
    expect(clientReminders.length).toBe(5);
    logger.info('客户端数据准备完成');
  });
  
  // 第2步：首次同步（上传客户端数据）
  test('2. 首次同步（上传客户端数据）', async () => {
    // 准备同步数据
    const syncData = {
      reminders: {
        created: clientReminders,
        updated: [],
        deleted: []
      },
      last_sync: null
    };
    
    // 执行同步
    const response = await client.syncData(syncData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, [
      'data.reminders.created', 
      'data.reminders.updated', 
      'data.reminders.deleted',
      'data.last_sync'
    ])).toBe(true);
    
    // 验证同步结果
    expect(response.body.data.reminders.created.length).toBe(5);
    
    // 更新客户端提醒事项数据
    for (let i = 0; i < clientReminders.length; i++) {
      const serverReminder = response.body.data.reminders.created[i];
      clientReminders[i].id = serverReminder.id;
      clientReminders[i].is_synced = true;
    }
    
    // 验证服务器数据
    const userReminders = await db.getUserReminders(userId);
    expect(userReminders.length).toBe(5);
    
    logger.info('首次同步成功');
  });
  
  // 第3步：修改客户端数据
  test('3. 修改客户端数据', async () => {
    // 修改部分客户端提醒事项
    clientReminders[0].title = `修改的提醒事项 ${Date.now()}`;
    clientReminders[0].is_synced = false;
    clientReminders[0].last_modified = new Date().toISOString();
    
    clientReminders[1].description = `修改的描述 ${Date.now()}`;
    clientReminders[1].is_synced = false;
    clientReminders[1].last_modified = new Date().toISOString();
    
    // 标记一个提醒事项为删除
    const deletedReminder = clientReminders[2];
    clientReminders.splice(2, 1);
    
    // 添加新的提醒事项
    const newReminder = generateTestReminderData({
      title: `新的客户端提醒事项 ${Date.now()}`,
      client_id: `client_${Date.now()}_new`,
      is_synced: false,
      last_modified: new Date().toISOString()
    });
    
    clientReminders.push(newReminder);
    
    expect(clientReminders.length).toBe(5);
    logger.info('客户端数据修改完成');
  });
  
  // 第4步：再次同步（上传修改后的数据）
  test('4. 再次同步（上传修改后的数据）', async () => {
    // 等待一段时间，确保时间戳不同
    await wait(1000);
    
    // 准备同步数据
    const syncData = {
      reminders: {
        created: clientReminders.filter(r => !r.id),
        updated: clientReminders.filter(r => r.id && !r.is_synced),
        deleted: [{ id: clientReminders[2].id }]
      },
      last_sync: new Date().toISOString()
    };
    
    // 执行同步
    const response = await client.syncData(syncData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, [
      'data.reminders.created', 
      'data.reminders.updated', 
      'data.reminders.deleted',
      'data.last_sync'
    ])).toBe(true);
    
    // 验证同步结果
    expect(response.body.data.reminders.created.length).toBe(1);
    expect(response.body.data.reminders.updated.length).toBe(2);
    
    // 更新客户端提醒事项数据
    const createdReminder = response.body.data.reminders.created[0];
    clientReminders[clientReminders.length - 1].id = createdReminder.id;
    clientReminders[clientReminders.length - 1].is_synced = true;
    
    clientReminders[0].is_synced = true;
    clientReminders[1].is_synced = true;
    
    // 验证服务器数据
    const userReminders = await db.getUserReminders(userId);
    expect(userReminders.length).toBe(5);
    
    logger.info('再次同步成功');
  });
  
  // 第5步：服务器端修改数据
  test('5. 服务器端修改数据', async () => {
    // 在服务器端修改一个提醒事项
    const reminderId = clientReminders[0].id;
    await db.knex('reminders')
      .where({ id: reminderId })
      .update({
        title: `服务器修改的提醒事项 ${Date.now()}`,
        updated_at: new Date()
      });
    
    // 在服务器端添加一个新的提醒事项
    const serverReminderId = await db.insertReminder({
      user_id: userId,
      title: `服务器添加的提醒事项 ${Date.now()}`
    });
    
    logger.info('服务器端数据修改完成');
  });
  
  // 第6步：拉取服务器变更
  test('6. 拉取服务器变更', async () => {
    // 等待一段时间，确保时间戳不同
    await wait(1000);
    
    // 准备同步数据
    const syncData = {
      reminders: {
        created: [],
        updated: [],
        deleted: []
      },
      last_sync: new Date(Date.now() - 60000).toISOString() // 1分钟前
    };
    
    // 执行同步
    const response = await client.syncData(syncData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, [
      'data.reminders.created', 
      'data.reminders.updated', 
      'data.reminders.deleted',
      'data.last_sync'
    ])).toBe(true);
    
    // 验证同步结果
    expect(response.body.data.reminders.created.length).toBe(1); // 服务器添加的提醒事项
    expect(response.body.data.reminders.updated.length).toBe(1); // 服务器修改的提醒事项
    
    // 更新客户端提醒事项数据
    const updatedReminder = response.body.data.reminders.updated[0];
    const index = clientReminders.findIndex(r => r.id === updatedReminder.id);
    if (index !== -1) {
      clientReminders[index] = {
        ...clientReminders[index],
        ...updatedReminder,
        is_synced: true
      };
    }
    
    const createdReminder = response.body.data.reminders.created[0];
    clientReminders.push({
      ...createdReminder,
      is_synced: true
    });
    
    // 验证客户端数据
    expect(clientReminders.length).toBe(6);
    
    logger.info('拉取服务器变更成功');
  });
  
  // 第7步：冲突解决
  test('7. 冲突解决', async () => {
    // 在客户端修改一个提醒事项
    const conflictReminder = clientReminders[0];
    conflictReminder.title = `客户端冲突提醒事项 ${Date.now()}`;
    conflictReminder.is_synced = false;
    conflictReminder.last_modified = new Date().toISOString();
    
    // 在服务器端修改同一个提醒事项
    await db.knex('reminders')
      .where({ id: conflictReminder.id })
      .update({
        title: `服务器冲突提醒事项 ${Date.now()}`,
        updated_at: new Date()
      });
    
    // 等待一段时间，确保时间戳不同
    await wait(1000);
    
    // 准备同步数据
    const syncData = {
      reminders: {
        created: [],
        updated: [conflictReminder],
        deleted: []
      },
      last_sync: new Date(Date.now() - 60000).toISOString() // 1分钟前
    };
    
    // 执行同步
    const response = await client.syncData(syncData);
    
    // 验证响应
    expect(checkResponseStatus(response, 200)).toBe(true);
    expect(checkResponseFields(response, [
      'data.reminders.created', 
      'data.reminders.updated', 
      'data.reminders.deleted',
      'data.last_sync',
      'data.conflicts'
    ])).toBe(true);
    
    // 验证冲突
    expect(response.body.data.conflicts).toBeTruthy();
    expect(response.body.data.conflicts.reminders.length).toBeGreaterThan(0);
    
    logger.info('冲突解决测试成功');
  });
});
