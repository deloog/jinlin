/**
 * 用户路由
 *
 * @swagger
 * tags:
 *   name: Users
 *   description: 用户管理API
 */
const express = require('express');
const { body } = require('express-validator');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimitMiddleware');

const router = express.Router();

// 注册用户
router.post('/register',
  authLimiter, // 应用认证速率限制
  [
    // 验证请求体
    body('username').notEmpty().withMessage('用户名不能为空')
      .isLength({ min: 3, max: 20 }).withMessage('用户名长度应为3-20个字符'),
    body('email').notEmpty().withMessage('电子邮件不能为空')
      .isEmail().withMessage('电子邮件格式无效'),
    body('password').notEmpty().withMessage('密码不能为空')
      .isLength({ min: 8, max: 64 }).withMessage('密码长度应为8-64个字符')
      .matches(/[a-z]/).withMessage('密码应包含小写字母')
      .matches(/[A-Z]/).withMessage('密码应包含大写字母')
      .matches(/[0-9]/).withMessage('密码应包含数字')
      .matches(/[^a-zA-Z0-9]/).withMessage('密码应包含特殊字符')
      .not().matches(/^123|password|qwerty|admin|letmein|welcome/i).withMessage('密码不应包含常见的密码模式')
      .not().matches(/(.)\1{2,}/).withMessage('密码不应包含连续重复的字符'),
    body('display_name').optional()
  ],
  userController.register
);

// 用户登录
router.post('/login',
  authLimiter, // 应用认证速率限制
  [
    // 验证请求体
    body('email').notEmpty().withMessage('电子邮件不能为空')
      .isEmail().withMessage('电子邮件格式无效'),
    body('password').notEmpty().withMessage('密码不能为空')
  ],
  userController.login
);

// 刷新令牌
router.post('/refresh-token',
  authLimiter, // 应用认证速率限制
  [
    // 验证请求体
    body('refresh_token').notEmpty().withMessage('刷新令牌不能为空')
  ],
  userController.refreshToken
);

// 获取当前用户信息
router.get('/me',
  authMiddleware.isAuthenticated,
  userController.getCurrentUser
);

// 更新用户信息
router.put('/me',
  authMiddleware.isAuthenticated,
  [
    // 验证请求体
    body('username').optional()
      .isLength({ min: 3, max: 20 }).withMessage('用户名长度应为3-20个字符'),
    body('email').optional()
      .isEmail().withMessage('电子邮件格式无效'),
    body('display_name').optional(),
    body('avatar_url').optional()
  ],
  userController.updateUser
);

// 更改密码
router.put('/me/password',
  authMiddleware.isAuthenticated,
  [
    // 验证请求体
    body('current_password').notEmpty().withMessage('当前密码不能为空'),
    body('new_password').notEmpty().withMessage('新密码不能为空')
      .isLength({ min: 8, max: 64 }).withMessage('新密码长度应为8-64个字符')
      .matches(/[a-z]/).withMessage('新密码应包含小写字母')
      .matches(/[A-Z]/).withMessage('新密码应包含大写字母')
      .matches(/[0-9]/).withMessage('新密码应包含数字')
      .matches(/[^a-zA-Z0-9]/).withMessage('新密码应包含特殊字符')
      .not().matches(/^123|password|qwerty|admin|letmein|welcome/i).withMessage('新密码不应包含常见的密码模式')
      .not().matches(/(.)\1{2,}/).withMessage('新密码不应包含连续重复的字符')
  ],
  userController.changePassword
);

// 获取用户列表（仅管理员）
router.get('/',
  authMiddleware.isAdmin,
  userController.getUsers
);

// 用户登出
router.post('/logout',
  authMiddleware.isAuthenticated,
  userController.logout
);

// 撤销所有会话
router.post('/revoke-all-sessions',
  authMiddleware.isAuthenticated,
  userController.revokeAllSessions
);

module.exports = router;
