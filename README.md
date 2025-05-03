# 鲸灵提醒 (CetaMind Reminder)

一个基于Flutter开发的智能提醒应用，支持多语言、多平台，提供节日提醒和个人事项管理功能。

## 功能特点

- 多语言支持：中文、英文、日文、韩文、法文、德文
- 多平台支持：iOS、Android、Web、Windows、macOS、Linux
- 节日提醒：支持国际节日、传统节日、宗教节日、行业节日等
- 个人事项管理：支持创建、编辑、删除、完成提醒事项
- 农历支持：支持农历日期和节气显示
- 云同步：支持数据云同步，确保多设备数据一致
- 主题定制：支持浅色、深色主题和主题色定制
- 本地通知：支持提醒事项到期通知
- 数据备份：支持数据备份和恢复

## 技术架构

### 客户端

- **前端框架**：Flutter
- **状态管理**：Provider
- **本地存储**：SQLite、SharedPreferences
- **网络请求**：Dio、HTTP
- **国际化**：Intl
- **通知**：Flutter Local Notifications
- **云同步**：自定义API

### 服务器端

- **后端框架**：Node.js + Express
- **数据库**：MySQL
- **API文档**：Swagger
- **身份验证**：JWT
- **日志**：Winston

## 项目结构

```
jinlin_app/
├── lib/                    # 客户端代码
│   ├── app.dart            # 应用程序入口
│   ├── main.dart           # 主函数
│   ├── models/             # 数据模型
│   ├── providers/          # 状态管理
│   ├── routes/             # 路由管理
│   ├── screens/            # 屏幕组件
│   ├── services/           # 服务层
│   ├── utils/              # 工具类
│   ├── widgets/            # UI组件
│   └── l10n/               # 国际化资源
├── server/                 # 服务器端代码
│   ├── index.js            # 服务器入口
│   ├── routes/             # API路由
│   ├── controllers/        # 控制器
│   ├── models/             # 数据模型
│   └── utils/              # 工具类
├── test/                   # 测试代码
├── assets/                 # 资源文件
├── pubspec.yaml            # 依赖配置
└── README.md               # 项目说明
```

## 安装和运行

### 客户端

1. 安装Flutter：https://flutter.dev/docs/get-started/install
2. 克隆仓库：`git clone <repository-url>`
3. 安装依赖：`flutter pub get`
4. 运行应用：`flutter run`

### 服务器端

1. 安装Node.js：https://nodejs.org/
2. 进入服务器目录：`cd server`
3. 安装依赖：`npm install`
4. 配置环境变量：复制`.env.example`为`.env`并填写配置
5. 启动服务器：`npm start`

## 贡献指南

1. Fork仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m 'Add some feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 提交Pull Request

## 许可证

MIT License
# jinlin
