const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');
const dotenv = require('dotenv');

// 加载环境变量
dotenv.config();

// 创建Express应用
const app = express();
const port = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(bodyParser.json());

// 数据库连接池
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'jinlin_app',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 初始化数据库
async function initializeDatabase() {
  try {
    const connection = await pool.getConnection();
    
    // 创建节日表
    await connection.query(`
      CREATE TABLE IF NOT EXISTS holidays (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        date VARCHAR(10) NOT NULL,
        type VARCHAR(50) NOT NULL,
        region VARCHAR(10),
        language VARCHAR(10),
        is_lunar BOOLEAN NOT NULL DEFAULT 0,
        is_recurring BOOLEAN NOT NULL DEFAULT 1,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        is_deleted BOOLEAN NOT NULL DEFAULT 0,
        deleted_at DATETIME
      )
    `);
    
    // 创建提醒事项表
    await connection.query(`
      CREATE TABLE IF NOT EXISTS reminders (
        id VARCHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        notes TEXT,
        date VARCHAR(10) NOT NULL,
        time VARCHAR(5),
        priority VARCHAR(20) NOT NULL DEFAULT 'medium',
        is_completed BOOLEAN NOT NULL DEFAULT 0,
        completed_at DATETIME,
        is_recurring BOOLEAN NOT NULL DEFAULT 0,
        recurrence_pattern VARCHAR(100),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        is_deleted BOOLEAN NOT NULL DEFAULT 0,
        deleted_at DATETIME
      )
    `);
    
    // 创建用户表
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY,
        username VARCHAR(100) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        last_login DATETIME
      )
    `);
    
    // 创建设置表
    await connection.query(`
      CREATE TABLE IF NOT EXISTS settings (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        key VARCHAR(100) NOT NULL,
        value TEXT,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        UNIQUE KEY user_key (user_id, key),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    // 创建同步记录表
    await connection.query(`
      CREATE TABLE IF NOT EXISTS sync_records (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        device_id VARCHAR(100) NOT NULL,
        sync_time DATETIME NOT NULL,
        status VARCHAR(20) NOT NULL,
        details TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    connection.release();
    console.log('数据库初始化完成');
  } catch (error) {
    console.error('数据库初始化失败:', error);
    process.exit(1);
  }
}

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 版本端点
app.get('/version', (req, res) => {
  res.json({ version: '1.0.0' });
});

// 节日API
const holidaysRouter = express.Router();

// 获取节日列表
holidaysRouter.get('/', async (req, res) => {
  try {
    const { language, region, startDate, endDate } = req.query;
    
    let query = 'SELECT * FROM holidays WHERE is_deleted = 0';
    const params = [];
    
    if (language) {
      query += ' AND language = ?';
      params.push(language);
    }
    
    if (region) {
      query += ' AND region = ?';
      params.push(region);
    }
    
    if (startDate) {
      query += ' AND date >= ?';
      params.push(startDate);
    }
    
    if (endDate) {
      query += ' AND date <= ?';
      params.push(endDate);
    }
    
    query += ' ORDER BY date ASC';
    
    const [rows] = await pool.query(query, params);
    
    res.json({ data: rows });
  } catch (error) {
    console.error('获取节日列表失败:', error);
    res.status(500).json({ error: '获取节日列表失败' });
  }
});

// 获取单个节日
holidaysRouter.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query(
      'SELECT * FROM holidays WHERE id = ? AND is_deleted = 0',
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: '节日不存在' });
    }
    
    res.json({ data: rows[0] });
  } catch (error) {
    console.error('获取节日失败:', error);
    res.status(500).json({ error: '获取节日失败' });
  }
});

// 创建节日
holidaysRouter.post('/', async (req, res) => {
  try {
    const holiday = req.body;
    
    // 验证必填字段
    if (!holiday.name || !holiday.date || !holiday.type) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    // 生成ID
    const id = holiday.id || uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      `INSERT INTO holidays (
        id, name, description, date, type, region, language, 
        is_lunar, is_recurring, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        holiday.name,
        holiday.description || null,
        holiday.date,
        holiday.type,
        holiday.region || null,
        holiday.language || null,
        holiday.is_lunar ? 1 : 0,
        holiday.is_recurring ? 1 : 0,
        now,
        now
      ]
    );
    
    // 获取创建的节日
    const [rows] = await pool.query('SELECT * FROM holidays WHERE id = ?', [id]);
    
    res.status(201).json({ data: rows[0] });
  } catch (error) {
    console.error('创建节日失败:', error);
    res.status(500).json({ error: '创建节日失败' });
  }
});

// 更新节日
holidaysRouter.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const holiday = req.body;
    
    // 验证必填字段
    if (!holiday.name || !holiday.date || !holiday.type) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      `UPDATE holidays SET 
        name = ?, 
        description = ?, 
        date = ?, 
        type = ?, 
        region = ?, 
        language = ?, 
        is_lunar = ?, 
        is_recurring = ?, 
        updated_at = ?
      WHERE id = ? AND is_deleted = 0`,
      [
        holiday.name,
        holiday.description || null,
        holiday.date,
        holiday.type,
        holiday.region || null,
        holiday.language || null,
        holiday.is_lunar ? 1 : 0,
        holiday.is_recurring ? 1 : 0,
        now,
        id
      ]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '节日不存在' });
    }
    
    // 获取更新后的节日
    const [rows] = await pool.query('SELECT * FROM holidays WHERE id = ?', [id]);
    
    res.json({ data: rows[0] });
  } catch (error) {
    console.error('更新节日失败:', error);
    res.status(500).json({ error: '更新节日失败' });
  }
});

// 删除节日
holidaysRouter.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      'UPDATE holidays SET is_deleted = 1, deleted_at = ?, updated_at = ? WHERE id = ?',
      [now, now, id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '节日不存在' });
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('删除节日失败:', error);
    res.status(500).json({ error: '删除节日失败' });
  }
});

// 批量操作节日
holidaysRouter.post('/batch', async (req, res) => {
  try {
    const { holidays } = req.body;
    
    if (!Array.isArray(holidays)) {
      return res.status(400).json({ error: '无效的请求格式' });
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const createdHolidays = [];
    
    // 使用事务
    const connection = await pool.getConnection();
    await connection.beginTransaction();
    
    try {
      for (const holiday of holidays) {
        // 验证必填字段
        if (!holiday.name || !holiday.date || !holiday.type) {
          await connection.rollback();
          connection.release();
          return res.status(400).json({ error: '缺少必填字段' });
        }
        
        // 生成ID
        const id = holiday.id || uuidv4();
        
        await connection.query(
          `INSERT INTO holidays (
            id, name, description, date, type, region, language, 
            is_lunar, is_recurring, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            id,
            holiday.name,
            holiday.description || null,
            holiday.date,
            holiday.type,
            holiday.region || null,
            holiday.language || null,
            holiday.is_lunar ? 1 : 0,
            holiday.is_recurring ? 1 : 0,
            now,
            now
          ]
        );
        
        // 获取创建的节日
        const [rows] = await connection.query('SELECT * FROM holidays WHERE id = ?', [id]);
        createdHolidays.push(rows[0]);
      }
      
      await connection.commit();
      connection.release();
      
      res.status(201).json({ data: createdHolidays });
    } catch (error) {
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    console.error('批量创建节日失败:', error);
    res.status(500).json({ error: '批量创建节日失败' });
  }
});

// 提醒事项API
const remindersRouter = express.Router();

// 获取提醒事项列表
remindersRouter.get('/', async (req, res) => {
  try {
    const { startDate, endDate, isCompleted } = req.query;
    
    let query = 'SELECT * FROM reminders WHERE is_deleted = 0';
    const params = [];
    
    if (startDate) {
      query += ' AND date >= ?';
      params.push(startDate);
    }
    
    if (endDate) {
      query += ' AND date <= ?';
      params.push(endDate);
    }
    
    if (isCompleted !== undefined) {
      query += ' AND is_completed = ?';
      params.push(isCompleted === 'true' ? 1 : 0);
    }
    
    query += ' ORDER BY date ASC, time ASC';
    
    const [rows] = await pool.query(query, params);
    
    res.json({ data: rows });
  } catch (error) {
    console.error('获取提醒事项列表失败:', error);
    res.status(500).json({ error: '获取提醒事项列表失败' });
  }
});

// 获取单个提醒事项
remindersRouter.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query(
      'SELECT * FROM reminders WHERE id = ? AND is_deleted = 0',
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: '提醒事项不存在' });
    }
    
    res.json({ data: rows[0] });
  } catch (error) {
    console.error('获取提醒事项失败:', error);
    res.status(500).json({ error: '获取提醒事项失败' });
  }
});

// 创建提醒事项
remindersRouter.post('/', async (req, res) => {
  try {
    const reminder = req.body;
    
    // 验证必填字段
    if (!reminder.title || !reminder.date) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    // 生成ID
    const id = reminder.id || uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      `INSERT INTO reminders (
        id, title, notes, date, time, priority, 
        is_completed, completed_at, is_recurring, 
        recurrence_pattern, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        reminder.title,
        reminder.notes || null,
        reminder.date,
        reminder.time || null,
        reminder.priority || 'medium',
        reminder.is_completed ? 1 : 0,
        reminder.completed_at || null,
        reminder.is_recurring ? 1 : 0,
        reminder.recurrence_pattern || null,
        now,
        now
      ]
    );
    
    // 获取创建的提醒事项
    const [rows] = await pool.query('SELECT * FROM reminders WHERE id = ?', [id]);
    
    res.status(201).json({ data: rows[0] });
  } catch (error) {
    console.error('创建提醒事项失败:', error);
    res.status(500).json({ error: '创建提醒事项失败' });
  }
});

// 更新提醒事项
remindersRouter.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const reminder = req.body;
    
    // 验证必填字段
    if (!reminder.title || !reminder.date) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      `UPDATE reminders SET 
        title = ?, 
        notes = ?, 
        date = ?, 
        time = ?, 
        priority = ?, 
        is_completed = ?, 
        completed_at = ?, 
        is_recurring = ?, 
        recurrence_pattern = ?, 
        updated_at = ?
      WHERE id = ? AND is_deleted = 0`,
      [
        reminder.title,
        reminder.notes || null,
        reminder.date,
        reminder.time || null,
        reminder.priority || 'medium',
        reminder.is_completed ? 1 : 0,
        reminder.completed_at || null,
        reminder.is_recurring ? 1 : 0,
        reminder.recurrence_pattern || null,
        now,
        id
      ]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '提醒事项不存在' });
    }
    
    // 获取更新后的提醒事项
    const [rows] = await pool.query('SELECT * FROM reminders WHERE id = ?', [id]);
    
    res.json({ data: rows[0] });
  } catch (error) {
    console.error('更新提醒事项失败:', error);
    res.status(500).json({ error: '更新提醒事项失败' });
  }
});

// 删除提醒事项
remindersRouter.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    const [result] = await pool.query(
      'UPDATE reminders SET is_deleted = 1, deleted_at = ?, updated_at = ? WHERE id = ?',
      [now, now, id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '提醒事项不存在' });
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('删除提醒事项失败:', error);
    res.status(500).json({ error: '删除提醒事项失败' });
  }
});

// 标记提醒事项为已完成/未完成
remindersRouter.put('/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { completed } = req.body;
    
    if (completed === undefined) {
      return res.status(400).json({ error: '缺少completed字段' });
    }
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const completedAt = completed ? now : null;
    
    const [result] = await pool.query(
      'UPDATE reminders SET is_completed = ?, completed_at = ?, updated_at = ? WHERE id = ? AND is_deleted = 0',
      [completed ? 1 : 0, completedAt, now, id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '提醒事项不存在' });
    }
    
    // 获取更新后的提醒事项
    const [rows] = await pool.query('SELECT * FROM reminders WHERE id = ?', [id]);
    
    res.json({ data: rows[0] });
  } catch (error) {
    console.error('更新提醒事项完成状态失败:', error);
    res.status(500).json({ error: '更新提醒事项完成状态失败' });
  }
});

// 注册路由
app.use('/holidays', holidaysRouter);
app.use('/reminders', remindersRouter);

// 启动服务器
app.listen(port, async () => {
  await initializeDatabase();
  console.log(`服务器运行在 http://localhost:${port}`);
});

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
  console.error('未捕获的异常:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的Promise拒绝:', reason);
});

module.exports = app;
