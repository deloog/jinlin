/**
 * 负载测试脚本
 * 
 * 使用autocannon进行API负载测试
 * 
 * 使用方法:
 * node loadTest.js [--url=<URL>] [--connections=<连接数>] [--duration=<持续时间>]
 * 
 * 示例:
 * node loadTest.js
 * node loadTest.js --url=http://localhost:3000/health
 * node loadTest.js --connections=100 --duration=30
 */

const autocannon = require('autocannon');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// 加载环境变量
dotenv.config();

// 解析命令行参数
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace('--', '')] = value;
  return acc;
}, {});

// 测试配置
const config = {
  url: args.url || 'http://localhost:3000/health',
  connections: parseInt(args.connections || '10'),
  duration: parseInt(args.duration || '10'),
  headers: {},
  requests: []
};

// 如果需要认证，可以在这里添加令牌
if (args.token) {
  config.headers['Authorization'] = `Bearer ${args.token}`;
}

// 如果是POST请求，可以在这里添加请求体
if (args.method === 'POST') {
  config.method = 'POST';
  config.body = args.body || '{}';
  config.headers['Content-Type'] = 'application/json';
}

// 创建结果目录
const resultsDir = path.resolve(__dirname, 'results');
if (!fs.existsSync(resultsDir)) {
  fs.mkdirSync(resultsDir, { recursive: true });
}

// 获取当前时间戳
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

// 结果文件路径
const resultsFile = path.join(resultsDir, `load-test-${timestamp}.json`);

/**
 * 运行负载测试
 */
async function runLoadTest() {
  console.log(`开始负载测试: ${config.url}`);
  console.log(`连接数: ${config.connections}, 持续时间: ${config.duration}秒`);
  
  // 运行测试
  const result = await autocannon(config);
  
  // 保存结果
  fs.writeFileSync(resultsFile, JSON.stringify(result, null, 2));
  
  // 打印结果
  console.log('测试完成!');
  console.log(`结果已保存到: ${resultsFile}`);
  console.log('\n摘要:');
  console.log(`请求数: ${result.requests.total}`);
  console.log(`平均RPS: ${result.requests.average}`);
  console.log(`最大RPS: ${result.requests.max}`);
  console.log(`平均延迟: ${result.latency.average}ms`);
  console.log(`最大延迟: ${result.latency.max}ms`);
  console.log(`错误数: ${result.errors}`);
  console.log(`超时数: ${result.timeouts}`);
  console.log(`2xx响应: ${result['2xx']}`);
  console.log(`非2xx响应: ${result.non2xx}`);
  
  // 生成HTML报告
  generateHtmlReport(result);
}

/**
 * 生成HTML报告
 * @param {Object} result - 测试结果
 */
function generateHtmlReport(result) {
  const htmlFile = path.join(resultsDir, `load-test-${timestamp}.html`);
  
  // 创建HTML内容
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>负载测试报告</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      color: #333;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    h1, h2 {
      color: #2c3e50;
    }
    .summary {
      background-color: #f8f9fa;
      padding: 20px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .summary-item {
      margin-bottom: 10px;
    }
    .summary-label {
      font-weight: bold;
      display: inline-block;
      width: 150px;
    }
    .chart {
      margin-bottom: 30px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    th, td {
      padding: 10px;
      border: 1px solid #ddd;
      text-align: left;
    }
    th {
      background-color: #f2f2f2;
    }
    tr:nth-child(even) {
      background-color: #f9f9f9;
    }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
  <div class="container">
    <h1>负载测试报告</h1>
    <p>测试时间: ${new Date().toLocaleString()}</p>
    
    <div class="summary">
      <h2>测试配置</h2>
      <div class="summary-item">
        <span class="summary-label">URL:</span>
        <span>${config.url}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">连接数:</span>
        <span>${config.connections}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">持续时间:</span>
        <span>${config.duration}秒</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">方法:</span>
        <span>${config.method || 'GET'}</span>
      </div>
    </div>
    
    <div class="summary">
      <h2>测试结果摘要</h2>
      <div class="summary-item">
        <span class="summary-label">请求数:</span>
        <span>${result.requests.total}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">平均RPS:</span>
        <span>${result.requests.average.toFixed(2)}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">最大RPS:</span>
        <span>${result.requests.max}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">平均延迟:</span>
        <span>${result.latency.average.toFixed(2)}ms</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">最大延迟:</span>
        <span>${result.latency.max}ms</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">错误数:</span>
        <span>${result.errors}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">超时数:</span>
        <span>${result.timeouts}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">2xx响应:</span>
        <span>${result['2xx']}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">非2xx响应:</span>
        <span>${result.non2xx}</span>
      </div>
    </div>
    
    <div class="chart">
      <h2>请求/秒 (RPS)</h2>
      <canvas id="rpsChart"></canvas>
    </div>
    
    <div class="chart">
      <h2>延迟 (ms)</h2>
      <canvas id="latencyChart"></canvas>
    </div>
    
    <h2>延迟百分位</h2>
    <table>
      <tr>
        <th>百分位</th>
        <th>延迟 (ms)</th>
      </tr>
      <tr>
        <td>50%</td>
        <td>${result.latency.p50.toFixed(2)}</td>
      </tr>
      <tr>
        <td>75%</td>
        <td>${result.latency.p75.toFixed(2)}</td>
      </tr>
      <tr>
        <td>90%</td>
        <td>${result.latency.p90.toFixed(2)}</td>
      </tr>
      <tr>
        <td>99%</td>
        <td>${result.latency.p99.toFixed(2)}</td>
      </tr>
      <tr>
        <td>99.9%</td>
        <td>${result.latency.p999.toFixed(2)}</td>
      </tr>
    </table>
  </div>
  
  <script>
    // RPS图表
    const rpsCtx = document.getElementById('rpsChart').getContext('2d');
    new Chart(rpsCtx, {
      type: 'line',
      data: {
        labels: Array.from({ length: ${result.requests.sent.length} }, (_, i) => i + 1),
        datasets: [{
          label: 'RPS',
          data: ${JSON.stringify(result.requests.sent)},
          borderColor: 'rgba(75, 192, 192, 1)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
    
    // 延迟图表
    const latencyCtx = document.getElementById('latencyChart').getContext('2d');
    new Chart(latencyCtx, {
      type: 'line',
      data: {
        labels: ['平均', 'Min', 'Max', 'P50', 'P75', 'P90', 'P99', 'P999'],
        datasets: [{
          label: '延迟 (ms)',
          data: [
            ${result.latency.average.toFixed(2)},
            ${result.latency.min},
            ${result.latency.max},
            ${result.latency.p50.toFixed(2)},
            ${result.latency.p75.toFixed(2)},
            ${result.latency.p90.toFixed(2)},
            ${result.latency.p99.toFixed(2)},
            ${result.latency.p999.toFixed(2)}
          ],
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          borderColor: 'rgba(153, 102, 255, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  </script>
</body>
</html>
  `;
  
  // 保存HTML文件
  fs.writeFileSync(htmlFile, html);
  
  console.log(`HTML报告已生成: ${htmlFile}`);
}

// 运行测试
runLoadTest().catch(err => {
  console.error('测试失败:', err);
  process.exit(1);
});
