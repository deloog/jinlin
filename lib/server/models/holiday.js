// 节日数据模型
const db = require('../database/db');

class Holiday {
  // 获取特定地区和语言的节日
  static async getByRegionAndLanguage(regionCode, languageCode) {
    try {
      // 尝试从数据库获取数据
      const sql = `
        SELECT
          h.id,
          ht.name,
          ht.description,
          h.type,
          h.calculation_type AS calculationType,
          h.calculation_rule AS calculationRule,
          h.importance_level AS importanceLevel,
          ht.customs,
          ht.foods,
          ht.greetings,
          h.created_at AS createdAt
        FROM
          holidays h
        JOIN
          holiday_translations ht ON h.id = ht.holiday_id
        JOIN
          holiday_regions hr ON h.id = hr.holiday_id
        WHERE
          hr.region_code = ? AND ht.language_code = ?
      `;

      const holidays = await db.query(sql, [regionCode, languageCode]);

      // 如果数据库中没有数据，返回模拟数据
      if (holidays.length === 0) {
        console.log(`数据库中没有找到 ${regionCode} 地区的节日数据，返回模拟数据`);
        return this._getMockHolidays(regionCode, languageCode);
      }

      return holidays;
    } catch (error) {
      console.error('从数据库获取节日数据失败:', error);
      // 返回模拟数据
      return this._getMockHolidays(regionCode, languageCode);
    }
  }

  // 获取全球节日
  static async getGlobalHolidays(languageCode) {
    try {
      // 尝试从数据库获取数据
      const sql = `
        SELECT
          h.id,
          ht.name,
          ht.description,
          h.type,
          h.calculation_type AS calculationType,
          h.calculation_rule AS calculationRule,
          h.importance_level AS importanceLevel,
          ht.customs,
          ht.foods,
          ht.greetings,
          h.created_at AS createdAt
        FROM
          holidays h
        JOIN
          holiday_translations ht ON h.id = ht.holiday_id
        JOIN
          holiday_regions hr ON h.id = hr.holiday_id
        WHERE
          hr.region_code = 'GLOBAL' AND ht.language_code = ?
      `;

      const holidays = await db.query(sql, [languageCode]);

      // 如果数据库中没有数据，返回模拟数据
      if (holidays.length === 0) {
        console.log(`数据库中没有找到全球节日数据，返回模拟数据`);
        return this._getMockGlobalHolidays(languageCode);
      }

      return holidays;
    } catch (error) {
      console.error('从数据库获取全球节日数据失败:', error);
      // 返回模拟数据
      return this._getMockGlobalHolidays(languageCode);
    }
  }

  // 获取模拟节日数据
  static _getMockHolidays(regionCode, languageCode) {
    // 根据地区和语言返回不同的模拟数据
    if (regionCode === 'CN' && languageCode === 'zh') {
      return [
        {
          id: 'spring-festival',
          name: '春节',
          description: '春节是中国最重要的传统节日，标志着农历新年的开始。',
          type: 1, // 传统节日
          calculationType: 1, // 农历
          calculationRule: '1-1', // 正月初一
          importanceLevel: 5,
          customs: '贴春联、放鞭炮、吃团圆饭',
          foods: '饺子、年糕、鱼',
          greetings: '新年快乐、恭喜发财',
          createdAt: new Date().toISOString()
        },
        {
          id: 'mid-autumn',
          name: '中秋节',
          description: '中秋节是中国传统的团圆节日，人们会赏月、吃月饼。',
          type: 1, // 传统节日
          calculationType: 1, // 农历
          calculationRule: '8-15', // 八月十五
          importanceLevel: 4,
          customs: '赏月、吃月饼、团圆',
          foods: '月饼、柚子',
          greetings: '中秋快乐',
          createdAt: new Date().toISOString()
        },
        {
          id: 'national-day',
          name: '国庆节',
          description: '国庆节是庆祝中华人民共和国成立的节日。',
          type: 2, // 法定节日
          calculationType: 0, // 公历
          calculationRule: '10-1', // 10月1日
          importanceLevel: 5,
          customs: '升国旗、看阅兵、旅游',
          foods: '',
          greetings: '国庆快乐',
          createdAt: new Date().toISOString()
        }
      ];
    } else if (regionCode === 'US' && languageCode === 'en') {
      return [
        {
          id: 'independence-day',
          name: 'Independence Day',
          description: 'Independence Day is a federal holiday in the United States commemorating the Declaration of Independence.',
          type: 2, // 法定节日
          calculationType: 0, // 公历
          calculationRule: '7-4', // 7月4日
          importanceLevel: 5,
          customs: 'Fireworks, parades, barbecues',
          foods: 'Barbecue, hot dogs, hamburgers',
          greetings: 'Happy Fourth of July',
          createdAt: new Date().toISOString()
        },
        {
          id: 'thanksgiving',
          name: 'Thanksgiving',
          description: 'Thanksgiving is a national holiday celebrated on various dates in the United States, Canada, and other countries.',
          type: 2, // 法定节日
          calculationType: 2, // 特殊规则
          calculationRule: '11-4-4', // 11月第4个星期四
          importanceLevel: 5,
          customs: 'Family gatherings, turkey dinner',
          foods: 'Turkey, stuffing, cranberry sauce, pumpkin pie',
          greetings: 'Happy Thanksgiving',
          createdAt: new Date().toISOString()
        }
      ];
    } else {
      // 默认返回空数组
      return [];
    }
  }

  // 获取模拟全球节日数据
  static _getMockGlobalHolidays(languageCode) {
    if (languageCode === 'zh') {
      return [
        {
          id: 'new-year',
          name: '元旦',
          description: '元旦是公历新年的第一天，全球许多国家都会庆祝这一节日。',
          type: 2, // 法定节日
          calculationType: 0, // 公历
          calculationRule: '1-1', // 1月1日
          importanceLevel: 4,
          customs: '跨年倒计时、烟花、新年愿望',
          foods: '',
          greetings: '新年快乐',
          createdAt: new Date().toISOString()
        },
        {
          id: 'christmas',
          name: '圣诞节',
          description: '圣诞节是基督教纪念耶稣诞生的节日，也是一个重要的文化节日。',
          type: 3, // 宗教节日
          calculationType: 0, // 公历
          calculationRule: '12-25', // 12月25日
          importanceLevel: 4,
          customs: '圣诞树、圣诞老人、交换礼物',
          foods: '火鸡、姜饼、圣诞布丁',
          greetings: '圣诞快乐',
          createdAt: new Date().toISOString()
        }
      ];
    } else if (languageCode === 'en') {
      return [
        {
          id: 'new-year',
          name: 'New Year\'s Day',
          description: 'New Year\'s Day is the first day of the year in the Gregorian calendar.',
          type: 2, // 法定节日
          calculationType: 0, // 公历
          calculationRule: '1-1', // 1月1日
          importanceLevel: 4,
          customs: 'Countdown, fireworks, resolutions',
          foods: '',
          greetings: 'Happy New Year',
          createdAt: new Date().toISOString()
        },
        {
          id: 'christmas',
          name: 'Christmas',
          description: 'Christmas is an annual festival commemorating the birth of Jesus Christ.',
          type: 3, // 宗教节日
          calculationType: 0, // 公历
          calculationRule: '12-25', // 12月25日
          importanceLevel: 4,
          customs: 'Christmas tree, Santa Claus, gift exchange',
          foods: 'Turkey, gingerbread, Christmas pudding',
          greetings: 'Merry Christmas',
          createdAt: new Date().toISOString()
        }
      ];
    } else {
      // 默认返回空数组
      return [];
    }
  }

  // 获取自上次版本以来的更新
  static async getUpdatesSince(regionCode, sinceVersion, languageCode) {
    // 获取添加的节日
    const addedSql = `
      SELECT
        h.id,
        ht.name,
        ht.description,
        h.type,
        h.calculation_type AS calculationType,
        h.calculation_rule AS calculationRule,
        h.importance_level AS importanceLevel,
        ht.customs,
        ht.foods,
        ht.greetings,
        h.created_at AS createdAt
      FROM
        holidays h
      JOIN
        holiday_translations ht ON h.id = ht.holiday_id
      JOIN
        holiday_regions hr ON h.id = hr.holiday_id
      WHERE
        hr.region_code = ? AND ht.language_code = ?
        AND h.created_at > (
          SELECT updated_at FROM data_versions WHERE region_code = ? AND version = ?
        )
    `;

    // 获取更新的节日
    const updatedSql = `
      SELECT
        h.id,
        ht.name,
        ht.description,
        h.type,
        h.calculation_type AS calculationType,
        h.calculation_rule AS calculationRule,
        h.importance_level AS importanceLevel,
        ht.customs,
        ht.foods,
        ht.greetings,
        h.created_at AS createdAt
      FROM
        holidays h
      JOIN
        holiday_translations ht ON h.id = ht.holiday_id
      JOIN
        holiday_regions hr ON h.id = hr.holiday_id
      WHERE
        hr.region_code = ? AND ht.language_code = ?
        AND h.updated_at > (
          SELECT updated_at FROM data_versions WHERE region_code = ? AND version = ?
        )
        AND h.created_at <= (
          SELECT updated_at FROM data_versions WHERE region_code = ? AND version = ?
        )
    `;

    // 获取删除的节日ID
    const deletedSql = `
      SELECT id FROM deleted_holidays
      WHERE region_code = ? AND deleted_at > (
        SELECT updated_at FROM data_versions WHERE region_code = ? AND version = ?
      )
    `;

    const added = await db.query(addedSql, [regionCode, languageCode, regionCode, sinceVersion]);
    const updated = await db.query(updatedSql, [regionCode, languageCode, regionCode, sinceVersion, regionCode, sinceVersion]);
    const deletedRows = await db.query(deletedSql, [regionCode, regionCode, sinceVersion]);
    const deleted = deletedRows.map(row => row.id);

    return { added, updated, deleted };
  }

  // 添加新节日
  static async add(holiday, translations, regions) {
    const conn = await db.pool.getConnection();
    try {
      await conn.beginTransaction();

      // 插入节日基本信息
      await conn.query(
        'INSERT INTO holidays (id, type, calculation_type, calculation_rule, importance_level) VALUES (?, ?, ?, ?, ?)',
        [holiday.id, holiday.type, holiday.calculationType, holiday.calculationRule, holiday.importanceLevel]
      );

      // 插入翻译
      for (const [langCode, translation] of Object.entries(translations)) {
        await conn.query(
          'INSERT INTO holiday_translations (holiday_id, language_code, name, description, customs, foods, greetings) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [holiday.id, langCode, translation.name, translation.description, translation.customs, translation.foods, translation.greetings]
        );
      }

      // 插入地区关联
      for (const regionCode of regions) {
        await conn.query(
          'INSERT INTO holiday_regions (holiday_id, region_code) VALUES (?, ?)',
          [holiday.id, regionCode]
        );

        // 更新地区数据版本
        await conn.query(
          'UPDATE data_versions SET version = version + 1 WHERE region_code = ?',
          [regionCode]
        );
      }

      await conn.commit();
      return true;
    } catch (error) {
      await conn.rollback();
      throw error;
    } finally {
      conn.release();
    }
  }
}

module.exports = Holiday;
