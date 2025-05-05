/**
 * OAuth服务测试
 */
const axios = require('axios');
const querystring = require('querystring');
const oauthConfig = require('../../config/oauth');
const User = require('../../models/User');
const { generateToken, generateRefreshToken } = require('../../middleware/auth');
const { getAuthorizationUrl, handleCallback } = require('../../services/oauthService');

// 模拟依赖
jest.mock('axios');
jest.mock('../../config/oauth', () => ({
  callbackUrl: 'http://localhost:3000/api/auth/callback',
  google: {
    enabled: true,
    clientId: 'google_client_id',
    clientSecret: 'google_client_secret',
    scope: ['profile', 'email'],
  },
  facebook: {
    enabled: true,
    clientId: 'facebook_client_id',
    clientSecret: 'facebook_client_secret',
    scope: ['email', 'public_profile'],
  },
}));
jest.mock('../../models/User');
jest.mock('../../middleware/auth', () => ({
  generateToken: jest.fn().mockReturnValue('mock_token'),
  generateRefreshToken: jest.fn().mockReturnValue('mock_refresh_token'),
}));

describe('OAuthService', () => {
  beforeEach(() => {
    // 重置所有模拟
    jest.clearAllMocks();
  });

  describe('getAuthorizationUrl', () => {
    it('应该返回Google授权URL', () => {
      const url = getAuthorizationUrl('google', { state: 'test_state' });
      
      expect(url).toContain('https://accounts.google.com/o/oauth2/v2/auth');
      expect(url).toContain('client_id=google_client_id');
      expect(url).toContain(`redirect_uri=${encodeURIComponent('http://localhost:3000/api/auth/callback/google')}`);
      expect(url).toContain('response_type=code');
      expect(url).toContain('state=test_state');
    });

    it('应该返回Facebook授权URL', () => {
      const url = getAuthorizationUrl('facebook', { state: 'test_state' });
      
      expect(url).toContain('https://www.facebook.com/v12.0/dialog/oauth');
      expect(url).toContain('client_id=facebook_client_id');
      expect(url).toContain(`redirect_uri=${encodeURIComponent('http://localhost:3000/api/auth/callback/facebook')}`);
      expect(url).toContain('response_type=code');
      expect(url).toContain('state=test_state');
    });

    it('应该在提供商未启用时抛出错误', () => {
      // 临时修改配置
      const originalEnabled = oauthConfig.google.enabled;
      oauthConfig.google.enabled = false;

      expect(() => getAuthorizationUrl('google')).toThrow('Google OAuth未启用');

      // 恢复配置
      oauthConfig.google.enabled = originalEnabled;
    });

    it('应该在不支持的提供商时抛出错误', () => {
      expect(() => getAuthorizationUrl('unsupported')).toThrow('不支持的OAuth提供商: unsupported');
    });
  });

  describe('handleCallback', () => {
    it('应该处理Google回调', async () => {
      // 模拟getAccessToken
      axios.post.mockResolvedValueOnce({
        data: {
          access_token: 'google_access_token',
          refresh_token: 'google_refresh_token',
          expires_in: 3600,
        },
      });

      // 模拟getUserInfo
      axios.get.mockResolvedValueOnce({
        data: {
          sub: 'google_user_id',
          email: 'test@example.com',
          name: 'Test User',
          picture: 'https://example.com/avatar.jpg',
        },
      });

      // 模拟findByProviderIdAndType
      User.findByProviderIdAndType.mockResolvedValueOnce(null);

      // 模拟getByEmail
      User.getByEmail.mockResolvedValueOnce(null);

      // 模拟create
      User.create.mockResolvedValueOnce({
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        display_name: 'Test User',
        avatar_url: 'https://example.com/avatar.jpg',
        provider_id: 'google_user_id',
        provider_type: 'google',
        provider_data: JSON.stringify({
          google: {
            id: 'google_user_id',
            email: 'test@example.com',
            name: 'Test User',
            picture: 'https://example.com/avatar.jpg',
          },
        }),
      });

      const result = await handleCallback('google', 'code123', 'state123');

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('accessToken', 'mock_token');
      expect(result).toHaveProperty('refreshToken', 'mock_refresh_token');
      expect(result).toHaveProperty('expiresIn', 3600);

      expect(axios.post).toHaveBeenCalledWith('https://oauth2.googleapis.com/token', expect.any(Object));
      expect(axios.get).toHaveBeenCalledWith('https://www.googleapis.com/oauth2/v3/userinfo', expect.any(Object));
      expect(User.findByProviderIdAndType).toHaveBeenCalledWith('google_user_id', 'google');
      expect(User.create).toHaveBeenCalled();
      expect(generateToken).toHaveBeenCalled();
      expect(generateRefreshToken).toHaveBeenCalled();
    });

    it('应该处理现有用户', async () => {
      // 模拟getAccessToken
      axios.post.mockResolvedValueOnce({
        data: {
          access_token: 'google_access_token',
          refresh_token: 'google_refresh_token',
          expires_in: 3600,
        },
      });

      // 模拟getUserInfo
      axios.get.mockResolvedValueOnce({
        data: {
          sub: 'google_user_id',
          email: 'test@example.com',
          name: 'Test User',
          picture: 'https://example.com/avatar.jpg',
        },
      });

      // 模拟findByProviderIdAndType
      User.findByProviderIdAndType.mockResolvedValueOnce({
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        display_name: 'Existing User',
        avatar_url: 'https://example.com/old_avatar.jpg',
        provider_id: 'google_user_id',
        provider_type: 'google',
        provider_data: JSON.stringify({
          google: {
            id: 'google_user_id',
            email: 'test@example.com',
            name: 'Existing User',
            picture: 'https://example.com/old_avatar.jpg',
          },
        }),
      });

      // 模拟update
      User.update.mockResolvedValueOnce({
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        display_name: 'Test User',
        avatar_url: 'https://example.com/avatar.jpg',
        provider_id: 'google_user_id',
        provider_type: 'google',
        provider_data: JSON.stringify({
          google: {
            id: 'google_user_id',
            email: 'test@example.com',
            name: 'Test User',
            picture: 'https://example.com/avatar.jpg',
          },
        }),
      });

      const result = await handleCallback('google', 'code123', 'state123');

      expect(result).toHaveProperty('user');
      expect(result).toHaveProperty('accessToken', 'mock_token');
      expect(result).toHaveProperty('refreshToken', 'mock_refresh_token');
      expect(result).toHaveProperty('expiresIn', 3600);

      expect(User.findByProviderIdAndType).toHaveBeenCalledWith('google_user_id', 'google');
      expect(User.update).toHaveBeenCalled();
      expect(generateToken).toHaveBeenCalled();
      expect(generateRefreshToken).toHaveBeenCalled();
    });

    it('应该处理错误', async () => {
      // 模拟getAccessToken抛出错误
      axios.post.mockRejectedValueOnce(new Error('测试错误'));

      await expect(handleCallback('google', 'code123', 'state123')).rejects.toThrow();
    });
  });
});
