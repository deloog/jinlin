# Jinlin App Server

这是Jinlin App的服务器端应用程序，提供API接口供客户端调用。

## 功能

- 节日数据管理
- 提醒事项管理
- 用户认证和授权
- 数据同步

## 技术栈

- Node.js
- Express
- MySQL
- JWT

## 安装

1. 克隆仓库

```bash
git clone <repository-url>
cd server
```

2. 安装依赖

```bash
npm install
```

3. 配置环境变量

```bash
cp .env.example .env
```

然后编辑`.env`文件，填写正确的配置信息。

4. 启动服务器

```bash
npm start
```

开发模式：

```bash
npm run dev
```

## API文档

### 健康检查

```
GET /health
```

返回服务器状态。

### 版本

```
GET /version
```

返回服务器版本。

### 节日API

#### 获取节日列表

```
GET /holidays
```

查询参数：
- `language`: 语言代码
- `region`: 地区代码
- `startDate`: 开始日期
- `endDate`: 结束日期

#### 获取单个节日

```
GET /holidays/:id
```

#### 创建节日

```
POST /holidays
```

请求体：
```json
{
  "name": "节日名称",
  "description": "节日描述",
  "date": "2023-01-01",
  "type": "national",
  "region": "CN",
  "language": "zh",
  "is_lunar": false,
  "is_recurring": true
}
```

#### 更新节日

```
PUT /holidays/:id
```

请求体同创建节日。

#### 删除节日

```
DELETE /holidays/:id
```

#### 批量创建节日

```
POST /holidays/batch
```

请求体：
```json
{
  "holidays": [
    {
      "name": "节日1",
      "description": "节日1描述",
      "date": "2023-01-01",
      "type": "national",
      "region": "CN",
      "language": "zh",
      "is_lunar": false,
      "is_recurring": true
    },
    {
      "name": "节日2",
      "description": "节日2描述",
      "date": "2023-01-02",
      "type": "traditional",
      "region": "CN",
      "language": "zh",
      "is_lunar": true,
      "is_recurring": true
    }
  ]
}
```

### 提醒事项API

#### 获取提醒事项列表

```
GET /reminders
```

查询参数：
- `startDate`: 开始日期
- `endDate`: 结束日期
- `isCompleted`: 是否已完成

#### 获取单个提醒事项

```
GET /reminders/:id
```

#### 创建提醒事项

```
POST /reminders
```

请求体：
```json
{
  "title": "提醒事项标题",
  "notes": "提醒事项备注",
  "date": "2023-01-01",
  "time": "12:00",
  "priority": "medium",
  "is_completed": false,
  "is_recurring": false,
  "recurrence_pattern": null
}
```

#### 更新提醒事项

```
PUT /reminders/:id
```

请求体同创建提醒事项。

#### 删除提醒事项

```
DELETE /reminders/:id
```

#### 标记提醒事项为已完成/未完成

```
PUT /reminders/:id/complete
```

请求体：
```json
{
  "completed": true
}
```

## 许可证

ISC
