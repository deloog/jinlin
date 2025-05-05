/**
 * 认证路由
 */
const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { globalLimiter, authLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 应用全局速率限制
router.use(globalLimiter);

/**
 * @swagger
 * /api/auth/oauth/{provider}:
 *   get:
 *     summary: 获取OAuth授权URL
 *     description: 获取指定提供商的OAuth授权URL
 *     tags: [Auth]
 *     parameters:
 *       - in: path
 *         name: provider
 *         required: true
 *         schema:
 *           type: string
 *           enum: [google, facebook, apple, wechat, qq, weibo, tiktok]
 *         description: OAuth提供商
 *     responses:
 *       200:
 *         description: 成功获取授权URL
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 url:
 *                   type: string
 *                   description: 授权URL
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/oauth/:provider',
  authLimiter,
  authController.getOAuthUrl
);

/**
 * @swagger
 * /api/auth/callback/{provider}:
 *   get:
 *     summary: 处理OAuth回调
 *     description: 处理OAuth提供商的回调请求
 *     tags: [Auth]
 *     parameters:
 *       - in: path
 *         name: provider
 *         required: true
 *         schema:
 *           type: string
 *           enum: [google, facebook, apple, wechat, qq, weibo, tiktok]
 *         description: OAuth提供商
 *       - in: query
 *         name: code
 *         required: true
 *         schema:
 *           type: string
 *         description: 授权码
 *       - in: query
 *         name: state
 *         required: true
 *         schema:
 *           type: string
 *         description: 状态参数
 *     responses:
 *       200:
 *         description: 登录成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: 登录成功
 *                 data:
 *                   type: object
 *                   properties:
 *                     user:
 *                       $ref: '#/components/schemas/User'
 *                     access_token:
 *                       type: string
 *                     refresh_token:
 *                       type: string
 *                     expires_in:
 *                       type: integer
 *                       example: 3600
 *       400:
 *         description: 请求错误
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/callback/:provider',
  authController.handleOAuthCallback
);

/**
 * @swagger
 * /api/auth/login/{provider}:
 *   post:
 *     summary: 第三方登录
 *     description: 使用第三方提供商登录
 *     tags: [Auth]
 *     parameters:
 *       - in: path
 *         name: provider
 *         required: true
 *         schema:
 *           type: string
 *           enum: [google, facebook, apple, wechat, qq, weibo, tiktok]
 *         description: OAuth提供商
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - userData
 *             properties:
 *               token:
 *                 type: string
 *                 description: 第三方提供商的访问令牌
 *               userData:
 *                 type: object
 *                 description: 第三方提供商的用户数据
 *                 required:
 *                   - id
 *                 properties:
 *                   id:
 *                     type: string
 *                     description: 用户ID
 *                   email:
 *                     type: string
 *                     description: 电子邮件
 *                   name:
 *                     type: string
 *                     description: 用户名称
 *                   picture:
 *                     type: string
 *                     description: 用户头像URL
 *     responses:
 *       200:
 *         description: 登录成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: 登录成功
 *                 data:
 *                   type: object
 *                   properties:
 *                     user:
 *                       $ref: '#/components/schemas/User'
 *                     access_token:
 *                       type: string
 *                     refresh_token:
 *                       type: string
 *                     expires_in:
 *                       type: integer
 *                       example: 3600
 *       400:
 *         description: 请求错误
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.post('/login/:provider',
  authLimiter,
  [
    body('token').notEmpty().withMessage('令牌不能为空'),
    body('userData').notEmpty().withMessage('用户数据不能为空'),
    body('userData.id').notEmpty().withMessage('用户ID不能为空')
  ],
  authController.thirdPartyLogin
);

module.exports = router;
