/**
 * 认证控制器测试
 */
const request = require('supertest');
const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const { body } = require('express-validator');
const authController = require('../../controllers/authController');
const oauthService = require('../../services/oauthService');
const User = require('../../models/User');

// 模拟依赖
jest.mock('../../services/oauthService');
jest.mock('../../models/User');
jest.mock('../../middleware/auth', () => ({
  generateToken: jest.fn().mockReturnValue('mock_token'),
  generateRefreshToken: jest.fn().mockReturnValue('mock_refresh_token'),
}));

describe('AuthController', () => {
  let app;

  beforeEach(() => {
    // 创建Express应用
    app = express();
    app.use(bodyParser.json());
    app.use(session({
      secret: 'test_secret',
      resave: false,
      saveUninitialized: false,
    }));

    // 设置路由
    app.get('/api/auth/oauth/:provider', authController.getOAuthUrl);
    app.get('/api/auth/callback/:provider', authController.handleOAuthCallback);
    app.post('/api/auth/login/:provider', [
      body('token').notEmpty(),
      body('userData').notEmpty(),
      body('userData.id').notEmpty(),
    ], authController.thirdPartyLogin);

    // 重置所有模拟
    jest.clearAllMocks();
  });

  describe('getOAuthUrl', () => {
    it('应该返回授权URL', async () => {
      // 模拟getAuthorizationUrl
      oauthService.getAuthorizationUrl.mockResolvedValue('https://example.com/auth');

      const res = await request(app)
        .get('/api/auth/oauth/google')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(res.body).toHaveProperty('url', 'https://example.com/auth');
      expect(oauthService.getAuthorizationUrl).toHaveBeenCalledWith('google', expect.any(Object));
    });

    it('应该处理错误', async () => {
      // 模拟getAuthorizationUrl抛出错误
      oauthService.getAuthorizationUrl.mockRejectedValue(new Error('测试错误'));

      const res = await request(app)
        .get('/api/auth/oauth/google')
        .expect('Content-Type', /json/)
        .expect(500);

      expect(res.body).toHaveProperty('error', '测试错误');
    });
  });

  describe('handleOAuthCallback', () => {
    it('应该处理回调并返回用户和令牌', async () => {
      // 模拟会话状态
      const agent = request.agent(app);
      await agent
        .get('/api/auth/oauth/google')
        .expect(200);

      // 模拟handleCallback
      oauthService.handleCallback.mockResolvedValue({
        user: { id: 'user123', username: 'testuser' },
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        expiresIn: 3600,
      });

      const res = await agent
        .get('/api/auth/callback/google?code=code123&state=' + agent.jar.getCookie('connect.sid', { path: '/' }).value)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(res.body).toHaveProperty('message', '登录成功');
      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data).toHaveProperty('access_token');
      expect(res.body.data).toHaveProperty('refresh_token');
      expect(res.body.data).toHaveProperty('expires_in');
    });

    it('应该处理无效的状态参数', async () => {
      const res = await request(app)
        .get('/api/auth/callback/google?code=code123&state=invalid_state')
        .expect('Content-Type', /json/)
        .expect(400);

      expect(res.body).toHaveProperty('error', '无效的状态参数');
    });

    it('应该处理错误', async () => {
      // 模拟会话状态
      const agent = request.agent(app);
      await agent
        .get('/api/auth/oauth/google')
        .expect(200);

      // 模拟handleCallback抛出错误
      oauthService.handleCallback.mockRejectedValue(new Error('测试错误'));

      const res = await agent
        .get('/api/auth/callback/google?code=code123&state=' + agent.jar.getCookie('connect.sid', { path: '/' }).value)
        .expect('Content-Type', /json/)
        .expect(500);

      expect(res.body).toHaveProperty('error', '测试错误');
    });
  });

  describe('thirdPartyLogin', () => {
    it('应该处理第三方登录并返回用户和令牌', async () => {
      // 模拟findByProviderIdAndType
      User.findByProviderIdAndType.mockResolvedValue(null);

      // 模拟getByEmail
      User.getByEmail.mockResolvedValue(null);

      // 模拟create
      User.create.mockResolvedValue({
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
      });

      const res = await request(app)
        .post('/api/auth/login/google')
        .send({
          token: 'token123',
          userData: {
            id: 'user123',
            email: 'test@example.com',
            name: 'Test User',
            picture: 'https://example.com/avatar.jpg',
          },
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(res.body).toHaveProperty('message', '登录成功');
      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data).toHaveProperty('access_token');
      expect(res.body.data).toHaveProperty('refresh_token');
      expect(res.body.data).toHaveProperty('expires_in');
    });

    it('应该处理验证错误', async () => {
      const res = await request(app)
        .post('/api/auth/login/google')
        .send({
          // 缺少token和userData
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(res.body).toHaveProperty('errors');
    });

    it('应该处理不支持的提供商', async () => {
      const res = await request(app)
        .post('/api/auth/login/unsupported')
        .send({
          token: 'token123',
          userData: {
            id: 'user123',
            email: 'test@example.com',
            name: 'Test User',
            picture: 'https://example.com/avatar.jpg',
          },
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(res.body).toHaveProperty('error', '不支持的提供商: unsupported');
    });

    it('应该处理错误', async () => {
      // 模拟findByProviderIdAndType抛出错误
      User.findByProviderIdAndType.mockRejectedValue(new Error('测试错误'));

      const res = await request(app)
        .post('/api/auth/login/google')
        .send({
          token: 'token123',
          userData: {
            id: 'user123',
            email: 'test@example.com',
            name: 'Test User',
            picture: 'https://example.com/avatar.jpg',
          },
        })
        .expect('Content-Type', /json/)
        .expect(500);

      expect(res.body).toHaveProperty('error', '测试错误');
    });
  });
});
