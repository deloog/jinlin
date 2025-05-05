/**
 * 用户控制器
 */
const User = require('../models/User');
const { validationResult } = require('express-validator');
const { generateToken, generateRefreshToken, revokeToken, revokeAllUserTokens } = require('../middleware/auth');
const logger = require('../utils/logger');

/**
 * 注册用户
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 *
 * @swagger
 * /api/users/register:
 *   post:
 *     summary: 注册新用户
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: 用户名
 *               email:
 *                 type: string
 *                 format: email
 *                 description: 电子邮件
 *               password:
 *                 type: string
 *                 format: password
 *                 description: 密码
 *               display_name:
 *                 type: string
 *                 description: 显示名称
 *     responses:
 *       201:
 *         description: 用户注册成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: 注册成功
 *                 data:
 *                   type: object
 *                   properties:
 *                     user:
 *                       $ref: '#/components/schemas/User'
 *                     access_token:
 *                       type: string
 *                       description: JWT访问令牌
 *                     refresh_token:
 *                       type: string
 *                       description: JWT刷新令牌
 *                     expires_in:
 *                       type: integer
 *                       description: 访问令牌过期时间（秒）
 *       400:
 *         description: 请求参数无效
 *         content:
 *           application/json:
 *             schema:
 *               oneOf:
 *                 - $ref: '#/components/responses/ValidationError'
 *                 - type: object
 *                   properties:
 *                     error:
 *                       type: string
 *                       example: 用户名已存在
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
exports.register = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, email, password, display_name } = req.body;

    // 验证密码强度
    const { validatePasswordStrength } = require('../utils/validator');
    const passwordValidation = validatePasswordStrength(password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({ error: passwordValidation.message });
    }

    // 创建用户
    const user = await User.create({
      username,
      email,
      password,
      display_name
    });

    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    res.status(201).json({
      message: '注册成功',
      data: {
        user,
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: 3600 // 1小时
      }
    });
  } catch (error) {
    logger.error('注册用户失败:', error);

    if (error.message === '用户名已存在' || error.message === '电子邮件已存在') {
      return res.status(400).json({ error: error.message });
    }

    res.status(500).json({ error: '注册用户失败' });
  }
};

/**
 * 用户登录
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 *
 * @swagger
 * /api/users/login:
 *   post:
 *     summary: 用户登录
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: 电子邮件
 *               password:
 *                 type: string
 *                 format: password
 *                 description: 密码
 *     responses:
 *       200:
 *         description: 用户登录成功
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
 *                       description: JWT访问令牌
 *                     refresh_token:
 *                       type: string
 *                       description: JWT刷新令牌
 *                     expires_in:
 *                       type: integer
 *                       description: 访问令牌过期时间（秒）
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         description: 认证失败
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: 电子邮件或密码无效
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
exports.login = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // 验证用户凭据
    const user = await User.verifyCredentials(email, password);
    if (!user) {
      return res.status(401).json({ error: '电子邮件或密码无效' });
    }

    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    res.json({
      message: '登录成功',
      data: {
        user,
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: 3600 // 1小时
      }
    });
  } catch (error) {
    logger.error('用户登录失败:', error);
    res.status(500).json({ error: '用户登录失败' });
  }
};

/**
 * 刷新令牌
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.refreshToken = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { refresh_token } = req.body;

    // 验证刷新令牌
    const jwt = require('jsonwebtoken');
    const { jwt: jwtConfig } = require('../config/app');

    try {
      const decoded = jwt.verify(refresh_token, jwtConfig.secret);

      // 检查令牌类型
      if (decoded.type !== 'refresh') {
        return res.status(401).json({ error: '无效的刷新令牌' });
      }

      // 获取用户
      const user = await User.getById(decoded.id);
      if (!user) {
        return res.status(401).json({ error: '用户不存在' });
      }

      // 生成新令牌
      const accessToken = generateToken(user);
      const refreshToken = generateRefreshToken(user);

      res.json({
        message: '令牌刷新成功',
        data: {
          access_token: accessToken,
          refresh_token: refreshToken,
          expires_in: 3600 // 1小时
        }
      });
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ error: '刷新令牌已过期' });
      }

      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({ error: '刷新令牌无效' });
      }

      throw error;
    }
  } catch (error) {
    logger.error('刷新令牌失败:', error);
    res.status(500).json({ error: '刷新令牌失败' });
  }
};

/**
 * 获取当前用户信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 *
 * @swagger
 * /api/users/me:
 *   get:
 *     summary: 获取当前用户信息
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 成功获取用户信息
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
exports.getCurrentUser = async (req, res) => {
  try {
    res.json({
      data: req.user
    });
  } catch (error) {
    logger.error('获取当前用户信息失败:', error);
    res.status(500).json({ error: '获取当前用户信息失败' });
  }
};

/**
 * 更新用户信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.updateUser = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, email, display_name, avatar_url } = req.body;

    // 更新用户
    const updatedUser = await User.update(req.user.id, {
      username,
      email,
      display_name,
      avatar_url
    });

    res.json({
      message: '用户信息更新成功',
      data: updatedUser
    });
  } catch (error) {
    logger.error('更新用户信息失败:', error);

    if (error.message === '用户名已存在' || error.message === '电子邮件已存在') {
      return res.status(400).json({ error: error.message });
    }

    res.status(500).json({ error: '更新用户信息失败' });
  }
};

/**
 * 更改密码
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.changePassword = async (req, res) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { current_password, new_password } = req.body;

    // 验证当前密码
    const user = await User.getByEmail(req.user.email);
    const bcrypt = require('bcrypt');
    const isValid = await bcrypt.compare(current_password, user.password);

    if (!isValid) {
      return res.status(400).json({ error: '当前密码无效' });
    }

    // 验证密码强度
    const { validatePasswordStrength } = require('../utils/validator');
    const passwordValidation = validatePasswordStrength(new_password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({ error: passwordValidation.message });
    }

    // 检查新密码是否与当前密码相同
    if (current_password === new_password) {
      return res.status(400).json({ error: '新密码不能与当前密码相同' });
    }

    try {
      // 更新密码
      await User.update(req.user.id, {
        password: new_password,
        checkPasswordHistory: true,
        addToPasswordHistory: true
      });
    } catch (error) {
      if (error.message === '新密码不能与最近5次使用的密码相同') {
        return res.status(400).json({ error: error.message });
      }
      throw error;
    }

    // 撤销用户所有令牌（安全措施）
    await revokeAllUserTokens(req.user.id, 'password_changed');

    // 生成新令牌
    const accessToken = generateToken(req.user);
    const refreshToken = generateRefreshToken(req.user);

    res.json({
      message: '密码更改成功',
      data: {
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: 3600 // 1小时
      }
    });
  } catch (error) {
    logger.error('更改密码失败:', error);
    res.status(500).json({ error: '更改密码失败' });
  }
};

/**
 * 获取用户列表（仅管理员）
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getUsers = async (req, res) => {
  try {
    const { role } = req.query;

    // 构建过滤条件
    const filters = {};
    if (role) {
      filters.role = role;
    }

    const users = await User.getAll(filters);

    res.json({
      data: users
    });
  } catch (error) {
    logger.error('获取用户列表失败:', error);
    res.status(500).json({ error: '获取用户列表失败' });
  }
};

/**
 * 用户登出
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 *
 * @swagger
 * /api/users/logout:
 *   post:
 *     summary: 用户登出
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 用户登出成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: 登出成功
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
exports.logout = async (req, res) => {
  try {
    // 获取当前令牌
    const token = req.token;

    if (!token) {
      return res.status(400).json({ error: '未提供令牌' });
    }

    // 将令牌加入黑名单
    const success = await revokeToken(token, 'user_logout');

    if (success) {
      res.json({
        message: '登出成功'
      });
    } else {
      res.status(500).json({ error: '登出失败' });
    }
  } catch (error) {
    logger.error('用户登出失败:', error);
    res.status(500).json({ error: '用户登出失败' });
  }
};

/**
 * 撤销所有会话
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 *
 * @swagger
 * /api/users/revoke-all-sessions:
 *   post:
 *     summary: 撤销用户所有会话
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 所有会话撤销成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: 所有会话已撤销
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
exports.revokeAllSessions = async (req, res) => {
  try {
    // 获取当前用户ID
    const userId = req.user.id;

    // 撤销用户所有令牌
    const success = await revokeAllUserTokens(userId, 'user_revoked_all_sessions');

    if (success) {
      res.json({
        message: '所有会话已撤销'
      });
    } else {
      res.status(500).json({ error: '撤销所有会话失败' });
    }
  } catch (error) {
    logger.error('撤销所有会话失败:', error);
    res.status(500).json({ error: '撤销所有会话失败' });
  }
};
