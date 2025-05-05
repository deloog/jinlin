/**
 * 示例路由
 *
 * @swagger
 * tags:
 *   name: Example
 *   description: 示例API，用于演示熔断器、服务降级和资源权限控制功能
 */
const express = require('express');
const exampleController = require('../controllers/exampleController');
const authMiddleware = require('../middleware/auth');
const { requireResourcePermission, RESOURCE_TYPES, OPERATION_TYPES } = require('../middleware/resourcePermissionMiddleware');

const router = express.Router();

/**
 * @swagger
 * /api/examples/weather:
 *   get:
 *     summary: 获取天气信息
 *     description: 获取指定城市的天气信息
 *     tags: [Example]
 *     parameters:
 *       - in: query
 *         name: city
 *         required: true
 *         schema:
 *           type: string
 *         description: 城市名称
 *     responses:
 *       200:
 *         description: 天气信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 data:
 *                   type: object
 *                   description: 天气数据
 *       400:
 *         description: 参数错误
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/weather',
  exampleController.getWeather
);

/**
 * @swagger
 * /api/examples/news:
 *   get:
 *     summary: 获取新闻
 *     description: 获取指定类别的新闻
 *     tags: [Example]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: 新闻类别，默认为general
 *     responses:
 *       200:
 *         description: 新闻列表
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 data:
 *                   type: array
 *                   description: 新闻数据
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/news',
  exampleController.getNews
);

/**
 * @swagger
 * /api/examples/users/{userId}:
 *   get:
 *     summary: 获取用户信息
 *     description: 获取指定用户的信息
 *     tags: [Example]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: 用户ID
 *     responses:
 *       200:
 *         description: 用户信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 data:
 *                   type: object
 *                   description: 用户数据
 *       400:
 *         description: 参数错误
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/users/:userId',
  authMiddleware.authenticate, // 认证用户
  requireResourcePermission(RESOURCE_TYPES.USER, OPERATION_TYPES.READ, req => req.params.userId), // 检查资源权限
  exampleController.getUserInfo
);

/**
 * @swagger
 * /api/examples/payments/{paymentId}:
 *   get:
 *     summary: 获取支付信息
 *     description: 获取指定支付的信息
 *     tags: [Example]
 *     parameters:
 *       - in: path
 *         name: paymentId
 *         required: true
 *         schema:
 *           type: string
 *         description: 支付ID
 *     responses:
 *       200:
 *         description: 支付信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 data:
 *                   type: object
 *                   description: 支付数据
 *       400:
 *         description: 参数错误
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/payments/:paymentId',
  exampleController.getPaymentInfo
);

/**
 * @swagger
 * /api/examples/simulate-failure:
 *   post:
 *     summary: 模拟故障
 *     description: 模拟服务故障，触发服务降级
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               service:
 *                 type: string
 *                 description: 服务名称
 *               duration:
 *                 type: number
 *                 description: 故障持续时间（秒），默认为60
 *     responses:
 *       200:
 *         description: 模拟故障成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 message:
 *                   type: string
 *                   description: 成功消息
 *                 service:
 *                   type: string
 *                   description: 服务名称
 *                 duration:
 *                   type: number
 *                   description: 故障持续时间（秒）
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/simulate-failure',
  authMiddleware.authenticate, // 认证用户
  requireResourcePermission(RESOURCE_TYPES.SYSTEM, OPERATION_TYPES.MANAGE), // 检查系统管理权限
  exampleController.simulateFailure
);

/**
 * @swagger
 * /api/examples/restore-service/{service}:
 *   post:
 *     summary: 恢复服务
 *     description: 恢复降级的服务
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: service
 *         required: true
 *         schema:
 *           type: string
 *         description: 服务名称
 *     responses:
 *       200:
 *         description: 恢复服务成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 message:
 *                   type: string
 *                   description: 成功消息
 *                 service:
 *                   type: string
 *                   description: 服务名称
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         description: 服务不存在或未降级
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/restore-service/:service',
  authMiddleware.authenticate, // 认证用户
  requireResourcePermission(RESOURCE_TYPES.SYSTEM, OPERATION_TYPES.MANAGE), // 检查系统管理权限
  exampleController.restoreService
);

/**
 * @swagger
 * /api/examples/status:
 *   get:
 *     summary: 获取服务状态
 *     description: 获取服务状态信息
 *     tags: [Example]
 *     responses:
 *       200:
 *         description: 服务状态信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 system:
 *                   type: object
 *                   description: 系统状态
 *                 services:
 *                   type: array
 *                   description: 服务状态
 *                 circuitBreaker:
 *                   type: object
 *                   description: 熔断器状态
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/status',
  exampleController.getServiceStatus
);

/**
 * @swagger
 * /api/examples/sensitive-data:
 *   get:
 *     summary: 获取敏感数据
 *     description: 获取敏感数据示例，展示加密功能
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 敏感数据
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 data:
 *                   type: object
 *                   description: 敏感数据
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/sensitive-data',
  authMiddleware.authenticate, // 认证用户
  requireResourcePermission(RESOURCE_TYPES.USER, OPERATION_TYPES.READ, req => req.user.id), // 检查用户资源权限
  exampleController.getSensitiveData
);

/**
 * @swagger
 * /api/examples/tasks:
 *   post:
 *     summary: 提交异步任务
 *     description: 提交异步任务示例，展示异步处理功能
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               type:
 *                 type: string
 *                 description: 任务类型
 *                 enum: [send-email, sync-data, generate-report, send-notification]
 *               data:
 *                 type: object
 *                 description: 任务数据
 *               priority:
 *                 type: number
 *                 description: 任务优先级
 *                 enum: [0, 1, 2, 3]
 *     responses:
 *       200:
 *         description: 任务已提交
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 taskId:
 *                   type: string
 *                   description: 任务ID
 *                 message:
 *                   type: string
 *                   description: 成功消息
 *                 type:
 *                   type: string
 *                   description: 任务类型
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/tasks',
  authMiddleware.authenticate, // 认证用户
  exampleController.submitAsyncTask
);

/**
 * @swagger
 * /api/examples/tasks/{taskId}:
 *   get:
 *     summary: 获取任务状态
 *     description: 获取异步任务状态示例，展示异步处理功能
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: 任务ID
 *     responses:
 *       200:
 *         description: 任务状态
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 taskId:
 *                   type: string
 *                   description: 任务ID
 *                 status:
 *                   type: string
 *                   description: 任务状态
 *                 type:
 *                   type: string
 *                   description: 任务类型
 *                 createdAt:
 *                   type: number
 *                   description: 创建时间
 *                 startTime:
 *                   type: number
 *                   description: 开始时间
 *                 endTime:
 *                   type: number
 *                   description: 结束时间
 *                 result:
 *                   type: object
 *                   description: 任务结果
 *                 error:
 *                   type: string
 *                   description: 错误信息
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: 任务不存在
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/tasks/:taskId',
  authMiddleware.authenticate, // 认证用户
  exampleController.getTaskStatus
);

/**
 * @swagger
 * /api/examples/cache/{namespace}/{key}:
 *   get:
 *     summary: 获取缓存数据
 *     description: 获取缓存数据示例，展示多级缓存功能
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: namespace
 *         required: true
 *         schema:
 *           type: string
 *         description: 命名空间
 *       - in: path
 *         name: key
 *         required: true
 *         schema:
 *           type: string
 *         description: 键
 *     responses:
 *       200:
 *         description: 缓存数据
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 namespace:
 *                   type: string
 *                   description: 命名空间
 *                 key:
 *                   type: string
 *                   description: 键
 *                 data:
 *                   type: object
 *                   description: 缓存数据
 *                 source:
 *                   type: string
 *                   description: 数据来源
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: 缓存数据不存在
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/cache/:namespace/:key',
  authMiddleware.authenticate, // 认证用户
  exampleController.getCachedData
);

/**
 * @swagger
 * /api/examples/cache:
 *   post:
 *     summary: 设置缓存数据
 *     description: 设置缓存数据示例，展示多级缓存功能
 *     tags: [Example]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               namespace:
 *                 type: string
 *                 description: 命名空间
 *               key:
 *                 type: string
 *                 description: 键
 *               data:
 *                 type: object
 *                 description: 缓存数据
 *               ttl:
 *                 type: number
 *                 description: 过期时间（秒）
 *     responses:
 *       200:
 *         description: 缓存数据已设置
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 namespace:
 *                   type: string
 *                   description: 命名空间
 *                 key:
 *                   type: string
 *                   description: 键
 *                 ttl:
 *                   type: number
 *                   description: 过期时间（秒）
 *                 message:
 *                   type: string
 *                   description: 成功消息
 *       400:
 *         description: 参数错误
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/cache',
  authMiddleware.authenticate, // 认证用户
  exampleController.setCachedData
);

module.exports = router;
