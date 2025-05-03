// 启动服务器并显示详细日志
const app = require('./server');

// 设置更详细的错误处理
process.on('uncaughtException', (err) => {
  console.error('未捕获的异常:', err);
  console.error(err.stack);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的Promise拒绝:', reason);
  if (reason && reason.stack) {
    console.error(reason.stack);
  }
});

// 启动服务器
console.log('正在启动服务器，显示详细日志...');
