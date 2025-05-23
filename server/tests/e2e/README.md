# 端到端测试

本目录包含服务端的端到端测试，用于验证整个系统的功能。

## 目录结构

```
e2e/
├── setup.js                # 端到端测试设置
├── teardown.js             # 端到端测试清理
├── utils/                  # 测试工具函数
│   ├── testClient.js       # 测试客户端
│   ├── testDatabase.js     # 测试数据库工具
│   └── testHelpers.js      # 测试辅助函数
├── scenarios/              # 测试场景
│   ├── auth/               # 认证相关测试
│   ├── reminders/          # 提醒事项相关测试
│   ├── holidays/           # 节日相关测试
│   ├── solarTerms/         # 节气相关测试
│   └── sync/               # 同步相关测试
└── flows/                  # 端到端流程测试
    ├── userJourney.test.js # 用户旅程测试
    └── dataSync.test.js    # 数据同步流程测试
```

## 运行端到端测试

```bash
# Linux/Mac
npm run test:e2e

# Windows
npm run test:win-e2e
```

## 测试原则

1. 端到端测试应该模拟真实用户的操作流程
2. 每个测试应该是独立的，不依赖于其他测试的状态
3. 测试应该在隔离的环境中运行，不影响生产数据
4. 测试应该包括正常路径和错误路径
5. 测试应该验证关键业务流程的完整性

## 测试覆盖范围

端到端测试应该覆盖以下关键流程：

1. 用户注册和登录流程
2. 第三方登录流程
3. 创建、更新和删除提醒事项
4. 数据同步流程
5. 节日和节气显示
6. 多语言支持
7. 错误处理和恢复
