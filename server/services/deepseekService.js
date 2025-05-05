/**
 * Deepseek服务
 * 提供Deepseek AI生成描述和处理功能
 */
const axios = require('axios');
const logger = require('../utils/logger');
const { app: appConfig } = require('../config/app');

// Deepseek API端点
const DEEPSEEK_API_ENDPOINT = 'https://api.deepseek.com/v1/chat/completions';

// 默认模型
const DEFAULT_MODEL = 'deepseek-chat';

// 默认温度
const DEFAULT_TEMPERATURE = 0.7;

// 默认最大令牌数
const DEFAULT_MAX_TOKENS = 500;

/**
 * 生成提醒事项描述
 * @param {string} inputText - 用户输入
 * @param {string} language - 语言代码
 * @param {Object} options - 选项
 * @returns {string} 生成的描述
 */
exports.processText = async (inputText, language = 'zh', options = {}) => {
  try {
    // 获取API密钥
    const apiKey = appConfig.deepseek?.apiKey || process.env.DEEPSEEK_API_KEY;
    
    if (!apiKey) {
      throw new Error('缺少Deepseek API密钥');
    }
    
    // 构建系统提示
    let systemPrompt = '';
    
    // 根据语言选择不同的提示
    if (language === 'zh') {
      systemPrompt = `你是一个专业的提醒事项助手，可以帮助用户生成详细的提醒事项描述。
请根据用户提供的提醒事项标题和日期（如果有），生成一个有用的、详细的描述。
描述应该包括：
- 需要准备的物品或信息
- 需要注意的事项
- 可能的时间安排建议
- 其他相关的有用提示

例如：
- 输入: '医生预约 [日期：2023-05-10 14:30]' -> 输出: '准备好医保卡和身份证。提前15分钟到达医院。记录下您想咨询的问题和症状。如有既往病史，请带上相关资料。'
- 输入: '缴纳电费' -> 输出: '准备好账号信息。检查截止日期以避免滞纳金。考虑设置自动缴费以避免未来忘记。'

只返回生成的描述文本，不要包含其他内容。保持简洁。`;
    } else if (language === 'en') {
      systemPrompt = `You are a professional reminder assistant who can help users generate detailed reminder descriptions.
Based on the reminder title and date (if provided) from the user, generate a useful and detailed description.
The description should include:
- Items or information to prepare
- Things to note
- Possible time arrangement suggestions
- Other relevant useful tips

Examples:
- Input: 'Doctor appointment [Date: 2023-05-10 14:30]' -> Output: 'Prepare your insurance card and ID. Arrive 15 minutes early. Note down questions and symptoms you want to discuss. Bring relevant medical history if applicable.'
- Input: 'Pay electricity bill' -> Output: 'Have the account number ready. Check the due date to avoid late fees. Consider setting up automatic payments to avoid forgetting in the future.'

Respond ONLY with the generated description text, nothing else. Keep it brief.`;
    } else {
      // 默认使用英文提示
      systemPrompt = `You are a professional reminder assistant who can help users generate detailed reminder descriptions.
Based on the reminder title and date (if provided) from the user, generate a useful and detailed description.
The description should include:
- Items or information to prepare
- Things to note
- Possible time arrangement suggestions
- Other relevant useful tips

Examples:
- Input: 'Doctor appointment [Date: 2023-05-10 14:30]' -> Output: 'Prepare your insurance card and ID. Arrive 15 minutes early. Note down questions and symptoms you want to discuss. Bring relevant medical history if applicable.'
- Input: 'Pay electricity bill' -> Output: 'Have the account number ready. Check the due date to avoid late fees. Consider setting up automatic payments to avoid forgetting in the future.'

Respond ONLY with the generated description text, nothing else. Keep it brief.`;
    }
    
    // 构建请求体
    const body = {
      model: options.model || DEFAULT_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: inputText }
      ],
      temperature: options.temperature || DEFAULT_TEMPERATURE,
      max_tokens: options.max_tokens || DEFAULT_MAX_TOKENS,
      stream: false
    };
    
    // 发送请求
    const response = await axios.post(DEEPSEEK_API_ENDPOINT, body, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      timeout: 30000 // 30秒超时
    });
    
    // 处理响应
    if (response.status === 200) {
      const responseBody = response.data;
      if (responseBody.choices && 
          responseBody.choices.length > 0 && 
          responseBody.choices[0].message && 
          responseBody.choices[0].message.content) {
        
        // 获取生成的描述
        let description = responseBody.choices[0].message.content.trim();
        
        // 简单的后处理
        if (description.startsWith('"') && description.endsWith('"')) {
          description = description.substring(1, description.length - 1);
        }
        
        return description;
      } else {
        throw new Error('Deepseek返回了无效的响应格式');
      }
    } else {
      throw new Error(`Deepseek API请求失败 (${response.status})`);
    }
  } catch (error) {
    logger.error('生成提醒事项描述失败:', error);
    
    if (error.code === 'ECONNABORTED') {
      throw new Error('请求Deepseek超时');
    }
    
    throw error;
  }
};

/**
 * 解析自然语言输入
 * @param {string} naturalInput - 自然语言输入
 * @param {string} language - 语言代码
 * @param {Object} options - 选项
 * @returns {Array} 解析结果
 */
exports.extractEventsFromText = async (naturalInput, language = 'zh', options = {}) => {
  try {
    // 获取API密钥
    const apiKey = appConfig.deepseek?.apiKey || process.env.DEEPSEEK_API_KEY;
    
    if (!apiKey) {
      throw new Error('缺少Deepseek API密钥');
    }
    
    // 构建系统提示
    let systemPrompt = '';
    
    // 根据语言选择不同的提示
    if (language === 'zh') {
      systemPrompt = `你是一个专业的日程提取助手，可以从用户的自然语言输入中提取多个事件。
请从用户输入中提取所有可能的事件，并以JSON数组格式返回，每个事件包含以下字段：
- title: 事件标题
- due_date: 事件日期和时间（格式：YYYY-MM-DD HH:MM，如果没有具体时间则为YYYY-MM-DD）
- description: 事件描述（可选）

如果用户没有明确指定日期，请尝试从上下文推断，或者将due_date留空。
如果用户提到"明天"、"后天"、"下周"等相对日期，请转换为具体日期。
今天是${new Date().toISOString().split('T')[0]}。

示例输入：
"明天下午3点去医院复诊，后天上午10点开会讨论项目进度"

示例输出：
[
  {
    "title": "医院复诊",
    "due_date": "2023-05-06 15:00",
    "description": "去医院进行复诊"
  },
  {
    "title": "项目进度会议",
    "due_date": "2023-05-07 10:00",
    "description": "开会讨论项目进度"
  }
]

请确保：
- 每个JSON对象都正确闭合
- 保持响应简洁，总长度不超过2000字符`;
    } else {
      // 默认使用英文提示
      systemPrompt = `You are a professional schedule extraction assistant who can extract multiple events from user's natural language input.
Please extract all possible events from the user input and return them in a JSON array format, with each event containing the following fields:
- title: Event title
- due_date: Event date and time (format: YYYY-MM-DD HH:MM, or YYYY-MM-DD if no specific time)
- description: Event description (optional)

If the user doesn't specify a date explicitly, try to infer from context, or leave due_date empty.
If the user mentions relative dates like "tomorrow", "day after tomorrow", "next week", etc., please convert them to specific dates.
Today is ${new Date().toISOString().split('T')[0]}.

Example input:
"Go to hospital for follow-up tomorrow at 3pm, and have a meeting to discuss project progress the day after tomorrow at 10am"

Example output:
[
  {
    "title": "Hospital follow-up",
    "due_date": "2023-05-06 15:00",
    "description": "Go to hospital for follow-up"
  },
  {
    "title": "Project progress meeting",
    "due_date": "2023-05-07 10:00",
    "description": "Meeting to discuss project progress"
  }
]

Please ensure:
- Each JSON object is properly closed
- Keep the response concise, with total length under 2000 characters`;
    }
    
    // 构建请求体
    const body = {
      model: options.model || DEFAULT_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: naturalInput }
      ],
      temperature: options.temperature || 0.3, // 降低温度以提高确定性
      max_tokens: options.max_tokens || 4000, // 增加token限制以支持更多事件
      stream: false
    };
    
    // 发送请求
    const response = await axios.post(DEEPSEEK_API_ENDPOINT, body, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      timeout: 90000 // 90秒超时
    });
    
    // 处理响应
    if (response.status === 200) {
      const responseBody = response.data;
      if (responseBody.choices && 
          responseBody.choices.length > 0 && 
          responseBody.choices[0].message && 
          responseBody.choices[0].message.content) {
        
        // 获取原始内容
        const rawContent = responseBody.choices[0].message.content.trim();
        
        // 清理和解析JSON
        let jsonContentToParse = rawContent;
        
        // 处理可能的Markdown代码块
        if (jsonContentToParse.startsWith("```json")) {
          jsonContentToParse = jsonContentToParse.substring(7);
        }
        if (jsonContentToParse.startsWith("```")) {
          jsonContentToParse = jsonContentToParse.substring(3);
        }
        if (jsonContentToParse.endsWith("```")) {
          jsonContentToParse = jsonContentToParse.substring(0, jsonContentToParse.length - 3);
        }
        
        // 去除前后空白
        jsonContentToParse = jsonContentToParse.trim();
        
        try {
          // 尝试解析JSON
          const extractedList = JSON.parse(jsonContentToParse);
          
          // 验证结果是否为数组
          if (!Array.isArray(extractedList)) {
            throw new Error('解析结果不是数组');
          }
          
          // 处理结果
          const results = [];
          
          for (const item of extractedList) {
            if (typeof item === 'object' && item !== null) {
              const title = item.title;
              const dueDate = item.due_date;
              const description = item.description;
              
              if (title || dueDate) {
                results.push({
                  title,
                  due_date: dueDate,
                  description
                });
              }
            }
          }
          
          return results;
        } catch (jsonError) {
          logger.warning('JSON解析失败，尝试使用正则表达式提取:', jsonError);
          
          // 使用正则表达式提取
          const results = [];
          
          // 尝试提取完整的JSON对象
          const eventRegex = /\{\s*"title":\s*"([^"]*)"\s*,\s*"due_date":\s*"([^"]*)"\s*(?:,\s*"description":\s*"([^"]*)"\s*)?\}/g;
          const matches = [...jsonContentToParse.matchAll(eventRegex)];
          
          for (const match of matches) {
            if (match.length >= 3) {
              results.push({
                title: match[1],
                due_date: match[2],
                description: match[3] || null
              });
            }
          }
          
          if (results.length > 0) {
            return results;
          }
          
          throw new Error('无法解析Deepseek返回的数据');
        }
      } else {
        throw new Error('Deepseek返回了无效的响应格式');
      }
    } else {
      throw new Error(`Deepseek API请求失败 (${response.status})`);
    }
  } catch (error) {
    logger.error('解析自然语言输入失败:', error);
    
    if (error.code === 'ECONNABORTED') {
      throw new Error('请求Deepseek超时');
    }
    
    throw error;
  }
};
