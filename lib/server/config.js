// 服务端配置文件
module.exports = {
  // 数据库配置
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'TFL5650056btg',
    database: process.env.DB_NAME || 'holiday_db'
  },

  // 服务器配置
  server: {
    port: process.env.PORT || 3002,
    env: process.env.NODE_ENV || 'development'
  },

  // JWT配置（用于认证）
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: '7d'
  }
};
