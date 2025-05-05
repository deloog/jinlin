/**
 * 系统路由
 *
 * @swagger
 * tags:
 *   name: System
 *   description: 系统管理API
 */
const express = require('express');
const systemController = require('../controllers/systemController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * /api/system/status:
 *   get:
 *     summary: 获取系统状态
 *     description: 获取系统状态信息，包括熔断器状态、服务降级状态、缓存状态和资源使用情况
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 系统状态信息
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
 *                   description: 系统信息
 *                 node:
 *                   type: object
 *                   description: Node.js信息
 *                 metrics:
 *                   type: object
 *                   description: 系统指标
 *                 circuitBreakers:
 *                   type: array
 *                   description: 熔断器状态
 *                 fallback:
 *                   type: object
 *                   description: 服务降级状态
 *                 cache:
 *                   type: object
 *                   description: 缓存状态
 *                 tokenBlacklist:
 *                   type: object
 *                   description: 令牌黑名单状态
 *                 resources:
 *                   type: object
 *                   description: 资源使用情况
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/status',
  authMiddleware.isAdmin,
  systemController.getSystemStatus
);

/**
 * @swagger
 * /api/system/circuit-breakers:
 *   get:
 *     summary: 获取熔断器状态
 *     description: 获取所有熔断器的状态信息
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 熔断器状态信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 circuitBreakers:
 *                   type: array
 *                   description: 熔断器状态
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/circuit-breakers',
  authMiddleware.isAdmin,
  systemController.getCircuitBreakerStatus
);

/**
 * @swagger
 * /api/system/circuit-breakers/{name}/reset:
 *   post:
 *     summary: 重置熔断器
 *     description: 重置指定熔断器的状态
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: name
 *         required: true
 *         schema:
 *           type: string
 *         description: 熔断器名称
 *     responses:
 *       200:
 *         description: 熔断器重置成功
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
 *                 state:
 *                   type: object
 *                   description: 熔断器状态
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         description: 熔断器不存在
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/circuit-breakers/:name/reset',
  authMiddleware.isAdmin,
  systemController.resetCircuitBreaker
);

/**
 * @swagger
 * /api/system/fallback:
 *   get:
 *     summary: 获取服务降级状态
 *     description: 获取服务降级状态信息
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 服务降级状态信息
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/fallback',
  authMiddleware.isAdmin,
  systemController.getFallbackStatus
);

/**
 * @swagger
 * /api/system/cache:
 *   get:
 *     summary: 获取缓存状态
 *     description: 获取缓存状态信息
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 缓存状态信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 cache:
 *                   type: object
 *                   description: 缓存状态
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/cache',
  authMiddleware.isAdmin,
  systemController.getCacheStatus
);

/**
 * @swagger
 * /api/system/cache/clear:
 *   post:
 *     summary: 清空缓存
 *     description: 清空所有缓存或指定命名空间的缓存
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: namespace
 *         schema:
 *           type: string
 *         description: 命名空间（可选）
 *     responses:
 *       200:
 *         description: 缓存清空成功
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
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/cache/clear',
  authMiddleware.isAdmin,
  systemController.clearCache
);

/**
 * @swagger
 * /api/system/token-blacklist:
 *   get:
 *     summary: 获取令牌黑名单状态
 *     description: 获取令牌黑名单状态信息
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 令牌黑名单状态信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 tokenBlacklist:
 *                   type: object
 *                   description: 令牌黑名单状态
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/token-blacklist',
  authMiddleware.isAdmin,
  systemController.getTokenBlacklistStatus
);

/**
 * @swagger
 * /api/system/resources:
 *   get:
 *     summary: 获取资源使用情况
 *     description: 获取资源使用情况信息
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 资源使用情况信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: number
 *                   description: 时间戳
 *                 resources:
 *                   type: object
 *                   description: 资源使用情况
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/resources',
  authMiddleware.isAdmin,
  systemController.getResourceUsage
);

/**
 * @swagger
 * /api/system/gc:
 *   post:
 *     summary: 强制执行垃圾回收
 *     description: 强制执行垃圾回收
 *     tags: [System]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 垃圾回收成功
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
 *                 memoryBefore:
 *                   type: object
 *                   description: 垃圾回收前的内存使用情况
 *                 memoryAfter:
 *                   type: object
 *                   description: 垃圾回收后的内存使用情况
 *                 freed:
 *                   type: object
 *                   description: 释放的内存
 *       400:
 *         description: 无法强制执行垃圾回收
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/gc',
  authMiddleware.isAdmin,
  systemController.forceGarbageCollection
);

module.exports = router;
