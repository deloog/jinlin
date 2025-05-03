# 节日提醒应用服务端

这个文件夹包含所有服务端相关的代码，可以直接复制到服务器上使用。

## 文件夹结构

- `database/` - 数据库模型和操作
  - `db.js` - 数据库连接和初始化
  - `schema.sql` - 数据库表结构
- `api/` - API接口定义和实现
  - `holiday_routes.js` - 节日相关API路由
  - `version_routes.js` - 版本相关API路由
- `models/` - 数据模型
  - `holiday.js` - 节日数据模型
  - `version.js` - 版本数据模型
- `server.js` - 服务器入口文件
- `config.js` - 配置文件
- `package.json` - 依赖管理

## 部署说明

### 准备工作

1. 安装Node.js和npm
2. 安装MySQL数据库

### 部署步骤

1. 复制整个`server`文件夹到服务器
2. 进入文件夹，运行`npm install`安装依赖
3. 配置数据库连接（修改`config.js`）
4. 运行`node server.js`启动服务

## API接口说明

### 获取节日数据

```
GET /api/holidays?region=CN&language=zh
```

参数：
- `region`: 地区代码，如CN、US等
- `language`: 语言代码，如zh、en等

返回：
```json
{
  "version": 1,
  "holidays": [
    {
      "id": "spring_festival",
      "name": "春节",
      "description": "中国农历新年...",
      "type": "traditional",
      "calculationType": "fixedLunar",
      "calculationRule": "01-01L",
      "importanceLevel": 5,
      "customs": "贴春联、放鞭炮...",
      "foods": "饺子、年糕...",
      "greetings": "新年快乐、恭喜发财..."
    }
  ]
}
```

### 获取全球节日

```
GET /api/holidays/global?language=zh
```

参数：
- `language`: 语言代码，如zh、en等

### 获取数据版本信息

```
GET /api/versions?regions=CN,US,JP
```

参数：
- `regions`: 地区代码列表，用逗号分隔

返回：
```json
{
  "versions": {
    "CN": 1,
    "US": 2,
    "JP": 1
  }
}
```

### 获取节日更新

```
GET /api/holidays/updates?region=CN&since_version=1&language=zh
```

参数：
- `region`: 地区代码
- `since_version`: 客户端当前版本
- `language`: 语言代码

返回：
```json
{
  "new_version": 2,
  "added": [...],
  "updated": [...],
  "deleted": [...]
}
```

## 数据库表结构

### holidays表

存储所有节日基本信息

```sql
CREATE TABLE holidays (
    id VARCHAR(50) PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    calculation_type VARCHAR(20) NOT NULL,
    calculation_rule VARCHAR(50) NOT NULL,
    importance_level INT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

### holiday_translations表

存储节日的多语言翻译

```sql
CREATE TABLE holiday_translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    holiday_id VARCHAR(50) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    customs TEXT,
    foods TEXT,
    greetings TEXT,
    FOREIGN KEY (holiday_id) REFERENCES holidays(id),
    UNIQUE KEY (holiday_id, language_code)
);
```

### regions表

存储地区信息

```sql
CREATE TABLE regions (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);
```

### holiday_regions表

节日与地区的关联表

```sql
CREATE TABLE holiday_regions (
    holiday_id VARCHAR(50) NOT NULL,
    region_code VARCHAR(10) NOT NULL,
    PRIMARY KEY (holiday_id, region_code),
    FOREIGN KEY (holiday_id) REFERENCES holidays(id),
    FOREIGN KEY (region_code) REFERENCES regions(code)
);
```

## 开发模式

### 启动服务器

在开发过程中，可以使用以下命令启动服务：

```bash
cd lib/server
npm run dev
```

这将使用nodemon启动服务器，当文件变化时自动重启。

### 初始化数据库

首次启动服务器后，需要初始化数据库并导入节日数据：

```bash
cd lib/server
node scripts/import_data.js
```

这将从assets/data目录下的JSON文件中导入节日数据到数据库。

### 测试API交互

可以使用以下命令启动API测试应用：

```bash
flutter run -d chrome -t lib/examples/api_test_app.dart
```

这将启动一个简单的测试应用，可以用来测试API交互。在应用中，可以切换使用模拟数据或真实服务器。
