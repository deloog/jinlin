// 数据库连接和初始化
const mysql = require('mysql2/promise');
const config = require('../config');
const fs = require('fs');
const path = require('path');

console.log('初始化数据库连接...');
console.log('数据库配置:', {
  host: config.database.host,
  port: config.database.port,
  user: config.database.user,
  database: config.database.database
});

// 创建数据库连接池
const pool = mysql.createPool({
  host: config.database.host,
  port: config.database.port,
  user: config.database.user,
  password: config.database.password,
  database: config.database.database,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 初始化数据库
async function initialize() {
  try {
    // 读取SQL文件
    const sqlPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // 分割SQL语句
    const statements = sql.split(';').filter(statement => statement.trim() !== '');

    // 执行每个SQL语句
    for (const statement of statements) {
      await pool.query(statement);
    }

    console.log('数据库初始化成功');
    return true;
  } catch (error) {
    console.error('数据库初始化失败:', error);
    throw error;
  }
}

// 执行SQL查询
async function query(sql, params) {
  try {
    const [rows] = await pool.query(sql, params);
    return rows;
  } catch (error) {
    console.error('SQL查询失败:', error);
    throw error;
  }
}

module.exports = {
  pool,
  initialize,
  query
};
