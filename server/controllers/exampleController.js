/**
 * 示例控制器
 *
 * 用于演示熔断器、服务降级和安全增强功能
 */
const logger = require('../utils/enhancedLogger');
const exampleService = require('../services/exampleService');
const { fallbackManager } = require('../utils/fallbackStrategy');
const { encryptionService } = require('../services/encryptionService');
const { asyncTaskService } = require('../services/asyncTaskService');
const { multiLevelCacheService } = require('../services/multiLevelCacheService');

/**
 * 获取天气信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getWeather = async (req, res) => {
  try {
    const { city } = req.query;

    if (!city) {
      return res.status(400).json({ error: '城市参数不能为空' });
    }

    const weather = await exampleService.getWeather(city);

    res.json({
      timestamp: Date.now(),
      data: weather
    });
  } catch (error) {
    logger.error('获取天气信息失败:', error);
    res.status(500).json({ error: '获取天气信息失败' });
  }
};

/**
 * 获取新闻
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getNews = async (req, res) => {
  try {
    const { category = 'general' } = req.query;

    const news = await exampleService.getNews(category);

    res.json({
      timestamp: Date.now(),
      data: news
    });
  } catch (error) {
    logger.error('获取新闻失败:', error);
    res.status(500).json({ error: '获取新闻失败' });
  }
};

/**
 * 获取用户信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getUserInfo = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ error: '用户ID参数不能为空' });
    }

    const userInfo = await exampleService.getUserInfo(userId);

    res.json({
      timestamp: Date.now(),
      data: userInfo
    });
  } catch (error) {
    logger.error('获取用户信息失败:', error);
    res.status(500).json({ error: '获取用户信息失败' });
  }
};

/**
 * 获取支付信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getPaymentInfo = async (req, res) => {
  try {
    const { paymentId } = req.params;

    if (!paymentId) {
      return res.status(400).json({ error: '支付ID参数不能为空' });
    }

    const paymentInfo = await exampleService.getPaymentInfo(paymentId);

    res.json({
      timestamp: Date.now(),
      data: paymentInfo
    });
  } catch (error) {
    logger.error('获取支付信息失败:', error);
    res.status(500).json({ error: '获取支付信息失败', message: error.message });
  }
};

/**
 * 模拟故障
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.simulateFailure = async (req, res) => {
  try {
    const { service, duration = 60 } = req.body;

    if (!service) {
      return res.status(400).json({ error: '服务参数不能为空' });
    }

    // 降级服务
    fallbackManager.degradeService(service);

    // 设置定时器，在指定时间后恢复服务
    setTimeout(() => {
      fallbackManager.restoreService(service);
      logger.info(`服务 ${service} 已自动恢复`);
    }, duration * 1000);

    res.json({
      timestamp: Date.now(),
      message: `服务 ${service} 已降级，将在 ${duration} 秒后自动恢复`,
      service,
      duration
    });
  } catch (error) {
    logger.error('模拟故障失败:', error);
    res.status(500).json({ error: '模拟故障失败' });
  }
};

/**
 * 恢复服务
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.restoreService = async (req, res) => {
  try {
    const { service } = req.params;

    if (!service) {
      return res.status(400).json({ error: '服务参数不能为空' });
    }

    // 恢复服务
    const result = fallbackManager.restoreService(service);

    if (result) {
      res.json({
        timestamp: Date.now(),
        message: `服务 ${service} 已恢复`,
        service
      });
    } else {
      res.status(404).json({
        error: `服务 ${service} 不存在或未降级`
      });
    }
  } catch (error) {
    logger.error('恢复服务失败:', error);
    res.status(500).json({ error: '恢复服务失败' });
  }
};

/**
 * 获取服务状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getServiceStatus = async (req, res) => {
  try {
    const systemState = fallbackManager.getSystemState();
    const serviceStates = fallbackManager.getAllServiceStates();
    const circuitBreakerState = exampleService.apiCircuitBreaker.getState();

    res.json({
      timestamp: Date.now(),
      system: systemState,
      services: serviceStates,
      circuitBreaker: circuitBreakerState
    });
  } catch (error) {
    logger.error('获取服务状态失败:', error);
    res.status(500).json({ error: '获取服务状态失败' });
  }
};

/**
 * 获取敏感数据
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getSensitiveData = async (req, res) => {
  try {
    // 获取当前用户
    const user = req.user;

    if (!user) {
      return res.status(401).json({ error: '未认证' });
    }

    // 创建包含敏感数据的对象
    const sensitiveData = {
      userId: user.id,
      username: user.username,
      email: user.email,
      personalInfo: {
        fullName: '张三',
        phoneNumber: '13800138000',
        address: '北京市海淀区中关村',
        idNumber: '110101199001011234',
        bankAccount: '6222020111122223333'
      },
      preferences: {
        language: 'zh-CN',
        theme: 'dark',
        notifications: true
      }
    };

    // 加密敏感字段
    const encryptedData = encryptionService.encryptObject(sensitiveData, 'users');

    // 返回加密后的数据
    res.json({
      timestamp: Date.now(),
      data: encryptedData,
      message: '敏感数据已加密，请使用适当的密钥解密'
    });
  } catch (error) {
    logger.error('获取敏感数据失败:', { error });
    res.status(500).json({ error: '获取敏感数据失败' });
  }
};

/**
 * 提交异步任务
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.submitAsyncTask = async (req, res) => {
  try {
    // 获取任务类型和数据
    const { type, data } = req.body;

    if (!type) {
      return res.status(400).json({ error: '缺少任务类型' });
    }

    // 检查任务类型是否有效
    const validTypes = ['send-email', 'sync-data', 'generate-report', 'send-notification'];

    if (!validTypes.includes(type)) {
      return res.status(400).json({ error: '无效的任务类型', validTypes });
    }

    // 提交异步任务
    const taskId = await asyncTaskService.addTask(type, data || {}, {
      priority: req.body.priority
    });

    // 返回任务ID
    res.json({
      timestamp: Date.now(),
      taskId,
      message: '任务已提交',
      type
    });
  } catch (error) {
    logger.error('提交异步任务失败:', { error });
    res.status(500).json({ error: '提交异步任务失败', message: error.message });
  }
};

/**
 * 获取任务状态
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getTaskStatus = async (req, res) => {
  try {
    // 获取任务ID
    const { taskId } = req.params;

    if (!taskId) {
      return res.status(400).json({ error: '缺少任务ID' });
    }

    // 获取任务
    const task = asyncTaskService.getTask(taskId);

    if (!task) {
      return res.status(404).json({ error: '任务不存在', taskId });
    }

    // 返回任务状态
    res.json({
      timestamp: Date.now(),
      taskId,
      status: task.status,
      type: task.type,
      createdAt: task.createdAt,
      startTime: task.startTime,
      endTime: task.endTime,
      result: task.result,
      error: task.error
    });
  } catch (error) {
    logger.error('获取任务状态失败:', { error });
    res.status(500).json({ error: '获取任务状态失败', message: error.message });
  }
};

/**
 * 获取缓存数据
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getCachedData = async (req, res) => {
  try {
    // 获取命名空间和键
    const { namespace, key } = req.params;

    if (!namespace || !key) {
      return res.status(400).json({ error: '缺少命名空间或键' });
    }

    // 从缓存获取数据
    const cachedData = await multiLevelCacheService.get(namespace, key);

    if (cachedData === null) {
      return res.status(404).json({ error: '缓存数据不存在', namespace, key });
    }

    // 返回缓存数据
    res.json({
      timestamp: Date.now(),
      namespace,
      key,
      data: cachedData,
      source: 'cache'
    });
  } catch (error) {
    logger.error('获取缓存数据失败:', { error });
    res.status(500).json({ error: '获取缓存数据失败', message: error.message });
  }
};

/**
 * 设置缓存数据
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.setCachedData = async (req, res) => {
  try {
    // 获取命名空间、键和数据
    const { namespace, key, data, ttl } = req.body;

    if (!namespace || !key || data === undefined) {
      return res.status(400).json({ error: '缺少命名空间、键或数据' });
    }

    // 设置缓存数据
    await multiLevelCacheService.set(namespace, key, data, ttl);

    // 返回成功消息
    res.json({
      timestamp: Date.now(),
      namespace,
      key,
      ttl,
      message: '缓存数据已设置'
    });
  } catch (error) {
    logger.error('设置缓存数据失败:', { error });
    res.status(500).json({ error: '设置缓存数据失败', message: error.message });
  }
};
