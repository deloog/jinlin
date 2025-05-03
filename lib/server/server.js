// 服务端入口文件
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const config = require('./config');
const db = require('./database/db');
const holidayRoutes = require('./api/holiday_routes');
const versionRoutes = require('./api/version_routes');
const reminderRoutes = require('./api/reminder_routes');

// 添加更多日志输出
console.log('服务器启动中...');

// 创建Express应用
const app = express();
const port = config.server.port;

// 中间件
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 请求日志中间件
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log(`请求头: ${JSON.stringify(req.headers)}`);
  console.log(`请求参数: ${JSON.stringify(req.query)}`);
  next();
});

// 路由
app.use('/api/holidays', holidayRoutes);
app.use('/api/versions', versionRoutes);
app.use('/api/reminders', reminderRoutes);

// 健康检查
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// 初始化数据库并启动服务器
db.initialize()
  .then(() => {
    app.listen(port, () => {
      console.log(`服务器运行在 http://localhost:${port}`);
    });
  })
  .catch(err => {
    console.error('数据库初始化失败:', err);
    process.exit(1);
  });

module.exports = app;
