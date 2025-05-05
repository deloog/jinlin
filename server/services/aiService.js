/**
 * AI服务
 * 提供AI生成描述和处理功能
 */
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const { app: appConfig } = require('../config/app');

// 支持的AI模型
const SUPPORTED_MODELS = {
  GPT_3_5_TURBO: 'gpt-3.5-turbo',
  GPT_4: 'gpt-4',
  GPT_4_TURBO: 'gpt-4-turbo-preview'
};

// 默认模型
const DEFAULT_MODEL = SUPPORTED_MODELS.GPT_3_5_TURBO;

// 默认温度
const DEFAULT_TEMPERATURE = 0.7;

// 默认最大令牌数
const DEFAULT_MAX_TOKENS = 500;

// 默认系统提示
const DEFAULT_SYSTEM_PROMPT = {
  zh: '你是一个专业的提醒事项助手，可以帮助用户生成详细的提醒事项描述。请根据用户的输入，生成一个详细、有用的提醒事项描述。',
  en: 'You are a professional reminder assistant who can help users generate detailed reminder descriptions. Based on the user\'s input, please generate a detailed and useful reminder description.',
  ja: 'あなたは、ユーザーが詳細なリマインダーの説明を生成するのを手伝うプロフェッショナルなリマインダーアシスタントです。ユーザーの入力に基づいて、詳細で役立つリマインダーの説明を生成してください。',
  ko: '당신은 사용자가 상세한 알림 설명을 생성하는 데 도움을 줄 수 있는 전문 알림 도우미입니다. 사용자의 입력을 바탕으로 상세하고 유용한 알림 설명을 생성해 주세요.'
};

/**
 * 生成提醒事项描述
 * @param {string} input - 用户输入
 * @param {string} language - 语言代码
 * @param {Object} options - 选项
 * @returns {string} 生成的描述
 */
exports.generateReminderDescription = async (input, language = 'zh', options = {}) => {
  try {
    // 构建提示
    const systemPrompt = DEFAULT_SYSTEM_PROMPT[language] || DEFAULT_SYSTEM_PROMPT.en;
    
    // 构建消息
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: input }
    ];
    
    // 调用AI模型
    const response = await this.callAIModel(messages, options);
    
    return response;
  } catch (error) {
    logger.error('生成提醒事项描述失败:', error);
    throw error;
  }
};

/**
 * 生成节日描述
 * @param {Object} holiday - 节日对象
 * @param {string} language - 语言代码
 * @param {Object} options - 选项
 * @returns {string} 生成的描述
 */
exports.generateHolidayDescription = async (holiday, language = 'zh', options = {}) => {
  try {
    // 解析节日名称
    let holidayName;
    try {
      const nameObj = JSON.parse(holiday.name);
      holidayName = nameObj[language] || nameObj.en || Object.values(nameObj)[0];
    } catch (e) {
      holidayName = holiday.name;
    }
    
    // 构建系统提示
    let systemPrompt;
    if (language === 'zh') {
      systemPrompt = `你是一个专业的节日文化专家，可以提供关于各种节日的详细信息。请为"${holidayName}"生成一个详细的描述，包括其起源、历史、传统习俗、食物、活动等方面的信息。`;
    } else if (language === 'en') {
      systemPrompt = `You are a professional holiday culture expert who can provide detailed information about various holidays. Please generate a detailed description for "${holidayName}", including its origin, history, traditional customs, food, activities, and other aspects.`;
    } else if (language === 'ja') {
      systemPrompt = `あなたは様々な祝日について詳細な情報を提供できる専門の祝日文化の専門家です。「${holidayName}」について、その起源、歴史、伝統的な習慣、食べ物、活動などの側面を含む詳細な説明を生成してください。`;
    } else if (language === 'ko') {
      systemPrompt = `당신은 다양한 휴일에 대한 상세한 정보를 제공할 수 있는 전문 휴일 문화 전문가입니다. "${holidayName}"에 대한 상세한 설명을 생성해 주세요. 그 기원, 역사, 전통적인 관습, 음식, 활동 등의 측면을 포함해 주세요.`;
    } else {
      systemPrompt = `You are a professional holiday culture expert who can provide detailed information about various holidays. Please generate a detailed description for "${holidayName}" in ${language} language, including its origin, history, traditional customs, food, activities, and other aspects.`;
    }
    
    // 构建消息
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: `请为${holidayName}生成一个详细的描述。` }
    ];
    
    // 调用AI模型
    const response = await this.callAIModel(messages, { ...options, max_tokens: 1000 });
    
    return response;
  } catch (error) {
    logger.error('生成节日描述失败:', error);
    throw error;
  }
};

/**
 * 生成多语言翻译
 * @param {string} text - 原文
 * @param {string} sourceLanguage - 源语言代码
 * @param {string} targetLanguage - 目标语言代码
 * @param {Object} options - 选项
 * @returns {string} 翻译结果
 */
exports.generateTranslation = async (text, sourceLanguage = 'zh', targetLanguage = 'en', options = {}) => {
  try {
    // 构建系统提示
    const systemPrompt = `你是一个专业的翻译专家，精通多种语言。请将以下${sourceLanguage}文本翻译成${targetLanguage}，保持原文的意思、风格和语气。只返回翻译结果，不要添加任何解释或注释。`;
    
    // 构建消息
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: text }
    ];
    
    // 调用AI模型
    const response = await this.callAIModel(messages, options);
    
    return response;
  } catch (error) {
    logger.error('生成翻译失败:', error);
    throw error;
  }
};

/**
 * 解析一句话提醒
 * @param {string} input - 用户输入
 * @param {string} language - 语言代码
 * @param {Object} options - 选项
 * @returns {Object} 解析结果
 */
exports.parseOneSentenceReminder = async (input, language = 'zh', options = {}) => {
  try {
    // 构建系统提示
    let systemPrompt;
    if (language === 'zh') {
      systemPrompt = '你是一个专业的提醒事项助手，可以从用户的一句话中提取关键信息，生成结构化的提醒事项。请从用户输入中提取标题、日期、时间、地点、优先级等信息，并以JSON格式返回。';
    } else if (language === 'en') {
      systemPrompt = 'You are a professional reminder assistant who can extract key information from a user\'s sentence to generate structured reminders. Please extract title, date, time, location, priority, and other information from the user\'s input and return it in JSON format.';
    } else if (language === 'ja') {
      systemPrompt = 'あなたはユーザーの一文から重要な情報を抽出し、構造化されたリマインダーを生成できるプロフェッショナルなリマインダーアシスタントです。ユーザーの入力からタイトル、日付、時間、場所、優先度などの情報を抽出し、JSON形式で返してください。';
    } else if (language === 'ko') {
      systemPrompt = '당신은 사용자의 한 문장에서 핵심 정보를 추출하여 구조화된 알림을 생성할 수 있는 전문 알림 도우미입니다. 사용자 입력에서 제목, 날짜, 시간, 위치, 우선순위 등의 정보를 추출하여 JSON 형식으로 반환해 주세요.';
    } else {
      systemPrompt = 'You are a professional reminder assistant who can extract key information from a user\'s sentence to generate structured reminders. Please extract title, date, time, location, priority, and other information from the user\'s input and return it in JSON format.';
    }
    
    // 构建消息
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: input }
    ];
    
    // 调用AI模型
    const response = await this.callAIModel(messages, { ...options, response_format: { type: 'json_object' } });
    
    // 解析JSON
    try {
      return JSON.parse(response);
    } catch (e) {
      logger.error('解析JSON失败:', e);
      throw new Error('解析JSON失败');
    }
  } catch (error) {
    logger.error('解析一句话提醒失败:', error);
    throw error;
  }
};

/**
 * 调用AI模型
 * @param {Array} messages - 消息数组
 * @param {Object} options - 选项
 * @returns {string} 模型响应
 */
exports.callAIModel = async (messages, options = {}) => {
  try {
    // 获取API密钥
    const apiKey = appConfig.openai?.apiKey || process.env.OPENAI_API_KEY;
    
    if (!apiKey) {
      throw new Error('缺少OpenAI API密钥');
    }
    
    // 构建请求参数
    const model = options.model || DEFAULT_MODEL;
    const temperature = options.temperature || DEFAULT_TEMPERATURE;
    const max_tokens = options.max_tokens || DEFAULT_MAX_TOKENS;
    
    // 构建请求体
    const requestBody = {
      model,
      messages,
      temperature,
      max_tokens,
      n: 1
    };
    
    // 添加响应格式（如果指定）
    if (options.response_format) {
      requestBody.response_format = options.response_format;
    }
    
    // 发送请求
    const response = await axios.post('https://api.openai.com/v1/chat/completions', requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      }
    });
    
    // 返回响应
    return response.data.choices[0].message.content.trim();
  } catch (error) {
    logger.error('调用AI模型失败:', error);
    throw error;
  }
};

/**
 * 获取支持的AI模型
 * @returns {Object} 支持的模型
 */
exports.getSupportedModels = () => {
  return SUPPORTED_MODELS;
};
