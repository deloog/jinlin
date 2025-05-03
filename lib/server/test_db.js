// 测试数据库连接
const mysql = require('mysql2/promise');
const config = require('./config');

async function testConnection() {
  console.log('测试数据库连接...');
  console.log('数据库配置:', {
    host: config.database.host,
    port: config.database.port,
    user: config.database.user,
    database: config.database.database
  });

  try {
    // 创建连接
    const connection = await mysql.createConnection({
      host: config.database.host,
      port: config.database.port,
      user: config.database.user,
      password: config.database.password
    });

    console.log('数据库连接成功!');

    // 检查数据库是否存在
    const [rows] = await connection.query(
      `SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${config.database.database}'`
    );

    if (rows.length === 0) {
      console.log(`数据库 ${config.database.database} 不存在，正在创建...`);
      await connection.query(`CREATE DATABASE IF NOT EXISTS ${config.database.database}`);
      console.log(`数据库 ${config.database.database} 创建成功!`);
    } else {
      console.log(`数据库 ${config.database.database} 已存在`);
    }

    // 关闭连接
    await connection.end();
  } catch (error) {
    console.error('数据库连接失败:', error);
  }
}

testConnection();
