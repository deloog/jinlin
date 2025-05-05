/**
 * 性能基准测试脚本
 * 
 * 对API进行基准测试，测试不同负载下的性能表现
 * 
 * 使用方法:
 * node benchmark.js [--scenario=<场景>]
 * 
 * 场景:
 * - health: 健康检查（默认）
 * - auth: 认证
 * - reminders: 提醒事项
 * - holidays: 节日
 * - all: 所有场景
 * 
 * 示例:
 * node benchmark.js
 * node benchmark.js --scenario=auth
 * node benchmark.js --scenario=all
 */

const autocannon = require('autocannon');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const { promisify } = require('util');

// 加载环境变量
dotenv.config();

// 解析命令行参数
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace('--', '')] = value;
  return acc;
}, {});

// 基准测试配置
const baseConfig = {
  url: process.env.API_URL || 'http://localhost:3000',
  connections: [10, 50, 100, 200],
  duration: 10,
  headers: {
    'Content-Type': 'application/json'
  }
};

// 测试场景
const scenarios = {
  health: {
    name: '健康检查',
    endpoint: '/health',
    method: 'GET'
  },
  version: {
    name: '版本信息',
    endpoint: '/version',
    method: 'GET'
  },
  auth: {
    name: '用户认证',
    endpoint: '/api/users/login',
    method: 'POST',
    body: JSON.stringify({
      email: 'test@example.com',
      password: 'password'
    })
  },
  reminders: {
    name: '提醒事项列表',
    endpoint: '/api/reminders',
    method: 'GET',
    setupAuth: true
  },
  holidays: {
    name: '节日列表',
    endpoint: '/api/holidays?country=global',
    method: 'GET'
  },
  solarTerms: {
    name: '节气列表',
    endpoint: '/api/solar-terms',
    method: 'GET'
  }
};

// 创建结果目录
const resultsDir = path.resolve(__dirname, 'results');
if (!fs.existsSync(resultsDir)) {
  fs.mkdirSync(resultsDir, { recursive: true });
}

// 获取当前时间戳
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

// 结果文件路径
const resultsFile = path.join(resultsDir, `benchmark-${timestamp}.json`);
const htmlFile = path.join(resultsDir, `benchmark-${timestamp}.html`);

/**
 * 获取认证令牌
 * @returns {Promise<string>} 认证令牌
 */
async function getAuthToken() {
  try {
    // 创建登录请求
    const loginInstance = autocannon({
      url: `${baseConfig.url}/api/users/login`,
      connections: 1,
      duration: 1,
      headers: {
        'Content-Type': 'application/json'
      },
      method: 'POST',
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password'
      })
    });
    
    // 等待响应
    const loginResult = await promisify(loginInstance.on.bind(loginInstance))('done');
    
    // 解析响应
    const responses = loginResult.requests.sent;
    if (responses > 0 && loginResult['2xx'] > 0) {
      // 提取令牌
      const response = loginInstance.requests[0].response;
      const responseBody = JSON.parse(response.body);
      
      if (responseBody.data && responseBody.data.access_token) {
        return responseBody.data.access_token;
      }
    }
    
    console.warn('无法获取认证令牌，将使用未认证请求');
    return null;
  } catch (error) {
    console.error('获取认证令牌失败:', error);
    return null;
  }
}

/**
 * 运行单个场景的基准测试
 * @param {Object} scenario - 场景配置
 * @param {number} connections - 连接数
 * @param {string} [token] - 认证令牌
 * @returns {Promise<Object>} 测试结果
 */
async function runScenario(scenario, connections, token) {
  console.log(`运行场景: ${scenario.name}, 连接数: ${connections}`);
  
  // 创建配置
  const config = {
    url: `${baseConfig.url}${scenario.endpoint}`,
    connections,
    duration: baseConfig.duration,
    headers: { ...baseConfig.headers },
    method: scenario.method
  };
  
  // 添加认证令牌
  if (scenario.setupAuth && token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  
  // 添加请求体
  if (scenario.body) {
    config.body = scenario.body;
  }
  
  // 运行测试
  return new Promise((resolve, reject) => {
    const instance = autocannon(config);
    
    instance.on('done', result => {
      resolve(result);
    });
    
    instance.on('error', error => {
      reject(error);
    });
  });
}

/**
 * 运行基准测试
 */
async function runBenchmark() {
  console.log('开始性能基准测试');
  
  // 确定要运行的场景
  const scenarioName = args.scenario || 'health';
  const scenariosToRun = scenarioName === 'all' 
    ? Object.values(scenarios) 
    : [scenarios[scenarioName]];
  
  if (scenariosToRun.length === 0) {
    console.error(`未知场景: ${scenarioName}`);
    process.exit(1);
  }
  
  // 获取认证令牌
  let token = null;
  if (scenariosToRun.some(s => s.setupAuth)) {
    token = await getAuthToken();
  }
  
  // 运行所有场景
  const results = {};
  
  for (const scenario of scenariosToRun) {
    console.log(`\n开始场景: ${scenario.name}`);
    results[scenario.name] = {};
    
    for (const connections of baseConfig.connections) {
      try {
        const result = await runScenario(scenario, connections, token);
        results[scenario.name][connections] = {
          requests: {
            total: result.requests.total,
            average: result.requests.average,
            max: result.requests.max
          },
          latency: {
            average: result.latency.average,
            min: result.latency.min,
            max: result.latency.max,
            p50: result.latency.p50,
            p90: result.latency.p90,
            p99: result.latency.p99
          },
          errors: result.errors,
          timeouts: result.timeouts,
          '2xx': result['2xx'],
          non2xx: result.non2xx
        };
        
        console.log(`  连接数: ${connections}, 平均RPS: ${result.requests.average.toFixed(2)}, 平均延迟: ${result.latency.average.toFixed(2)}ms`);
      } catch (error) {
        console.error(`  场景 ${scenario.name} 连接数 ${connections} 测试失败:`, error);
        results[scenario.name][connections] = { error: error.message };
      }
    }
  }
  
  // 保存结果
  fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
  console.log(`\n结果已保存到: ${resultsFile}`);
  
  // 生成HTML报告
  generateHtmlReport(results);
  console.log(`HTML报告已生成: ${htmlFile}`);
}

/**
 * 生成HTML报告
 * @param {Object} results - 测试结果
 */
function generateHtmlReport(results) {
  // 创建HTML内容
  let html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>性能基准测试报告</title>
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
    h1, h2, h3 {
      color: #2c3e50;
    }
    .scenario {
      margin-bottom: 40px;
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
    <h1>性能基准测试报告</h1>
    <p>测试时间: ${new Date().toLocaleString()}</p>
    
    <h2>测试配置</h2>
    <table>
      <tr>
        <th>参数</th>
        <th>值</th>
      </tr>
      <tr>
        <td>基础URL</td>
        <td>${baseConfig.url}</td>
      </tr>
      <tr>
        <td>连接数</td>
        <td>${baseConfig.connections.join(', ')}</td>
      </tr>
      <tr>
        <td>持续时间</td>
        <td>${baseConfig.duration}秒</td>
      </tr>
    </table>
    
    <h2>测试结果摘要</h2>
  `;
  
  // 为每个场景添加结果
  for (const [scenarioName, scenarioResults] of Object.entries(results)) {
    html += `
    <div class="scenario">
      <h3>${scenarioName}</h3>
      
      <div class="chart">
        <canvas id="rpsChart_${scenarioName.replace(/\s+/g, '_')}"></canvas>
      </div>
      
      <div class="chart">
        <canvas id="latencyChart_${scenarioName.replace(/\s+/g, '_')}"></canvas>
      </div>
      
      <table>
        <tr>
          <th>连接数</th>
          <th>平均RPS</th>
          <th>最大RPS</th>
          <th>平均延迟 (ms)</th>
          <th>最小延迟 (ms)</th>
          <th>最大延迟 (ms)</th>
          <th>P50延迟 (ms)</th>
          <th>P90延迟 (ms)</th>
          <th>P99延迟 (ms)</th>
          <th>错误数</th>
          <th>2xx响应</th>
          <th>非2xx响应</th>
        </tr>
    `;
    
    for (const [connections, result] of Object.entries(scenarioResults)) {
      if (result.error) {
        html += `
        <tr>
          <td>${connections}</td>
          <td colspan="11">错误: ${result.error}</td>
        </tr>
        `;
      } else {
        html += `
        <tr>
          <td>${connections}</td>
          <td>${result.requests.average.toFixed(2)}</td>
          <td>${result.requests.max}</td>
          <td>${result.latency.average.toFixed(2)}</td>
          <td>${result.latency.min}</td>
          <td>${result.latency.max}</td>
          <td>${result.latency.p50.toFixed(2)}</td>
          <td>${result.latency.p90.toFixed(2)}</td>
          <td>${result.latency.p99.toFixed(2)}</td>
          <td>${result.errors}</td>
          <td>${result['2xx']}</td>
          <td>${result.non2xx}</td>
        </tr>
        `;
      }
    }
    
    html += `
      </table>
    </div>
    `;
  }
  
  // 添加图表脚本
  html += `
  <script>
  `;
  
  for (const [scenarioName, scenarioResults] of Object.entries(results)) {
    const scenarioId = scenarioName.replace(/\s+/g, '_');
    const connections = Object.keys(scenarioResults);
    const rpsData = connections.map(conn => {
      return scenarioResults[conn].error ? 0 : scenarioResults[conn].requests.average;
    });
    const latencyData = connections.map(conn => {
      return scenarioResults[conn].error ? 0 : scenarioResults[conn].latency.average;
    });
    
    html += `
    // ${scenarioName} RPS图表
    const rpsCtx_${scenarioId} = document.getElementById('rpsChart_${scenarioId}').getContext('2d');
    new Chart(rpsCtx_${scenarioId}, {
      type: 'bar',
      data: {
        labels: ${JSON.stringify(connections)},
        datasets: [{
          label: '平均RPS',
          data: ${JSON.stringify(rpsData)},
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          borderColor: 'rgba(75, 192, 192, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: '${scenarioName} - 每秒请求数 (RPS)'
          }
        },
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
    
    // ${scenarioName} 延迟图表
    const latencyCtx_${scenarioId} = document.getElementById('latencyChart_${scenarioId}').getContext('2d');
    new Chart(latencyCtx_${scenarioId}, {
      type: 'bar',
      data: {
        labels: ${JSON.stringify(connections)},
        datasets: [{
          label: '平均延迟 (ms)',
          data: ${JSON.stringify(latencyData)},
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          borderColor: 'rgba(153, 102, 255, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: '${scenarioName} - 平均延迟 (ms)'
          }
        },
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
    `;
  }
  
  html += `
  </script>
</body>
</html>
  `;
  
  // 保存HTML文件
  fs.writeFileSync(htmlFile, html);
}

// 运行基准测试
runBenchmark().catch(err => {
  console.error('基准测试失败:', err);
  process.exit(1);
});
