/**
 * 多语言支持服务
 * 提供多语言内容管理和翻译功能
 */
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

// 支持的语言列表
const SUPPORTED_LANGUAGES = ['zh', 'en', 'ja', 'ko', 'fr', 'de', 'es', 'ru'];

// 语言名称映射
const LANGUAGE_NAMES = {
  zh: {
    zh: '中文',
    en: 'Chinese',
    ja: '中国語',
    ko: '중국어',
    fr: 'Chinois',
    de: 'Chinesisch',
    es: 'Chino',
    ru: 'Китайский'
  },
  en: {
    zh: '英文',
    en: 'English',
    ja: '英語',
    ko: '영어',
    fr: 'Anglais',
    de: 'Englisch',
    es: 'Inglés',
    ru: 'Английский'
  },
  ja: {
    zh: '日文',
    en: 'Japanese',
    ja: '日本語',
    ko: '일본어',
    fr: 'Japonais',
    de: 'Japanisch',
    es: 'Japonés',
    ru: 'Японский'
  },
  ko: {
    zh: '韩文',
    en: 'Korean',
    ja: '韓国語',
    ko: '한국어',
    fr: 'Coréen',
    de: 'Koreanisch',
    es: 'Coreano',
    ru: 'Корейский'
  },
  fr: {
    zh: '法文',
    en: 'French',
    ja: 'フランス語',
    ko: '프랑스어',
    fr: 'Français',
    de: 'Französisch',
    es: 'Francés',
    ru: 'Французский'
  },
  de: {
    zh: '德文',
    en: 'German',
    ja: 'ドイツ語',
    ko: '독일어',
    fr: 'Allemand',
    de: 'Deutsch',
    es: 'Alemán',
    ru: 'Немецкий'
  },
  es: {
    zh: '西班牙文',
    en: 'Spanish',
    ja: 'スペイン語',
    ko: '스페인어',
    fr: 'Espagnol',
    de: 'Spanisch',
    es: 'Español',
    ru: 'Испанский'
  },
  ru: {
    zh: '俄文',
    en: 'Russian',
    ja: 'ロシア語',
    ko: '러시아어',
    fr: 'Russe',
    de: 'Russisch',
    es: 'Ruso',
    ru: 'Русский'
  }
};

// 地区名称映射
const REGION_NAMES = {
  CN: {
    zh: '中国',
    en: 'China',
    ja: '中国',
    ko: '중국',
    fr: 'Chine',
    de: 'China',
    es: 'China',
    ru: 'Китай'
  },
  TW: {
    zh: '台湾',
    en: 'Taiwan',
    ja: '台湾',
    ko: '대만',
    fr: 'Taïwan',
    de: 'Taiwan',
    es: 'Taiwán',
    ru: 'Тайвань'
  },
  HK: {
    zh: '香港',
    en: 'Hong Kong',
    ja: '香港',
    ko: '홍콩',
    fr: 'Hong Kong',
    de: 'Hongkong',
    es: 'Hong Kong',
    ru: 'Гонконг'
  },
  JP: {
    zh: '日本',
    en: 'Japan',
    ja: '日本',
    ko: '일본',
    fr: 'Japon',
    de: 'Japan',
    es: 'Japón',
    ru: 'Япония'
  },
  KR: {
    zh: '韩国',
    en: 'Korea',
    ja: '韓国',
    ko: '한국',
    fr: 'Corée',
    de: 'Korea',
    es: 'Corea',
    ru: 'Корея'
  },
  US: {
    zh: '美国',
    en: 'United States',
    ja: 'アメリカ',
    ko: '미국',
    fr: 'États-Unis',
    de: 'Vereinigte Staaten',
    es: 'Estados Unidos',
    ru: 'США'
  },
  GLOBAL: {
    zh: '全球',
    en: 'Global',
    ja: 'グローバル',
    ko: '글로벌',
    fr: 'Mondial',
    de: 'Global',
    es: 'Global',
    ru: 'Глобальный'
  }
};

/**
 * 创建翻译表
 */
exports.createTranslationTable = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS translations (
        id VARCHAR(36) PRIMARY KEY,
        key VARCHAR(255) NOT NULL,
        context VARCHAR(255),
        zh TEXT,
        en TEXT,
        ja TEXT,
        ko TEXT,
        fr TEXT,
        de TEXT,
        es TEXT,
        ru TEXT,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        UNIQUE KEY unique_key_context (key, context)
      )
    `);
    logger.info('翻译表创建成功');
  } catch (error) {
    logger.error('创建翻译表失败:', error);
    throw error;
  }
};

/**
 * 获取支持的语言列表
 * @returns {Array} 支持的语言列表
 */
exports.getSupportedLanguages = () => {
  return SUPPORTED_LANGUAGES;
};

/**
 * 获取语言名称
 * @param {string} language - 语言代码
 * @param {string} targetLanguage - 目标语言代码
 * @returns {string} 语言名称
 */
exports.getLanguageName = (language, targetLanguage = 'en') => {
  if (!LANGUAGE_NAMES[language]) {
    return language;
  }
  
  return LANGUAGE_NAMES[language][targetLanguage] || LANGUAGE_NAMES[language].en;
};

/**
 * 获取地区名称
 * @param {string} region - 地区代码
 * @param {string} language - 语言代码
 * @returns {string} 地区名称
 */
exports.getRegionName = (region, language = 'en') => {
  if (!REGION_NAMES[region]) {
    return region;
  }
  
  return REGION_NAMES[region][language] || REGION_NAMES[region].en;
};

/**
 * 获取翻译
 * @param {string} key - 翻译键
 * @param {string} context - 上下文
 * @param {string} language - 语言代码
 * @returns {string} 翻译文本
 */
exports.getTranslation = async (key, context = null, language = 'en') => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM translations WHERE `key` = ? AND (`context` = ? OR `context` IS NULL) LIMIT 1',
      [key, context]
    );
    
    if (rows.length === 0) {
      return key;
    }
    
    const translation = rows[0];
    
    // 如果指定语言的翻译不存在，则返回英文翻译或键名
    return translation[language] || translation.en || key;
  } catch (error) {
    logger.error('获取翻译失败:', error);
    return key;
  }
};

/**
 * 设置翻译
 * @param {string} key - 翻译键
 * @param {Object} translations - 翻译对象
 * @param {string} context - 上下文
 * @returns {Object} 翻译对象
 */
exports.setTranslation = async (key, translations, context = null) => {
  try {
    // 检查翻译是否已存在
    const [existingRows] = await pool.query(
      'SELECT * FROM translations WHERE `key` = ? AND (`context` = ? OR `context` IS NULL) LIMIT 1',
      [key, context]
    );
    
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    if (existingRows.length > 0) {
      // 更新现有翻译
      const existingTranslation = existingRows[0];
      
      // 构建更新语句
      const updates = [];
      const params = [];
      
      for (const lang of SUPPORTED_LANGUAGES) {
        if (translations[lang] !== undefined) {
          updates.push(`${lang} = ?`);
          params.push(translations[lang]);
        }
      }
      
      updates.push('updated_at = ?');
      params.push(now);
      
      // 添加ID作为WHERE条件的参数
      params.push(existingTranslation.id);
      
      await pool.query(
        `UPDATE translations SET ${updates.join(', ')} WHERE id = ?`,
        params
      );
      
      return { ...existingTranslation, ...translations, updated_at: now };
    } else {
      // 创建新翻译
      const id = uuidv4();
      
      const columns = ['id', 'key', 'context', 'created_at', 'updated_at'];
      const placeholders = ['?', '?', '?', '?', '?'];
      const values = [id, key, context, now, now];
      
      for (const lang of SUPPORTED_LANGUAGES) {
        if (translations[lang] !== undefined) {
          columns.push(lang);
          placeholders.push('?');
          values.push(translations[lang]);
        }
      }
      
      await pool.query(
        `INSERT INTO translations (${columns.join(', ')}) VALUES (${placeholders.join(', ')})`,
        values
      );
      
      return { id, key, context, ...translations, created_at: now, updated_at: now };
    }
  } catch (error) {
    logger.error('设置翻译失败:', error);
    throw error;
  }
};

/**
 * 获取所有翻译
 * @param {string} language - 语言代码
 * @returns {Object} 翻译对象
 */
exports.getAllTranslations = async (language = null) => {
  try {
    let query = 'SELECT * FROM translations';
    const params = [];
    
    if (language) {
      query += ' WHERE ' + language + ' IS NOT NULL';
    }
    
    const [rows] = await pool.query(query, params);
    
    // 如果指定了语言，则只返回该语言的翻译
    if (language) {
      const translations = {};
      
      for (const row of rows) {
        if (row.context) {
          if (!translations[row.context]) {
            translations[row.context] = {};
          }
          translations[row.context][row.key] = row[language];
        } else {
          translations[row.key] = row[language];
        }
      }
      
      return translations;
    }
    
    return rows;
  } catch (error) {
    logger.error('获取所有翻译失败:', error);
    throw error;
  }
};

/**
 * 删除翻译
 * @param {string} key - 翻译键
 * @param {string} context - 上下文
 * @returns {boolean} 是否成功
 */
exports.deleteTranslation = async (key, context = null) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM translations WHERE `key` = ? AND (`context` = ? OR `context` IS NULL)',
      [key, context]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('删除翻译失败:', error);
    throw error;
  }
};
