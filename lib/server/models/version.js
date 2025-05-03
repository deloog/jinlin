// 数据版本模型
const db = require('../database/db');

class Version {
  // 获取指定地区的数据版本
  static async getByRegion(regionCode) {
    try {
      // 尝试从数据库获取数据
      const sql = 'SELECT version FROM data_versions WHERE region_code = ?';
      const rows = await db.query(sql, [regionCode]);

      if (rows.length === 0) {
        console.log(`数据库中没有找到 ${regionCode} 地区的版本数据，返回模拟数据`);
        return this._getMockVersion(regionCode);
      }

      return rows[0].version;
    } catch (error) {
      console.error('从数据库获取版本数据失败:', error);
      // 返回模拟数据
      return this._getMockVersion(regionCode);
    }
  }

  // 获取模拟版本数据
  static _getMockVersion(regionCode) {
    // 为不同地区返回不同的版本号
    const versionMap = {
      'CN': 1,
      'US': 1,
      'JP': 1,
      'KR': 1,
      'GLOBAL': 1
    };

    return versionMap[regionCode] || 1;
  }

  // 获取多个地区的数据版本
  static async getByRegions(regionCodes) {
    if (!regionCodes || regionCodes.length === 0) {
      return {};
    }

    try {
      // 尝试从数据库获取数据
      const placeholders = regionCodes.map(() => '?').join(',');
      const sql = `SELECT region_code, version FROM data_versions WHERE region_code IN (${placeholders})`;

      const rows = await db.query(sql, regionCodes);

      // 转换为对象格式 {regionCode: version}
      const versions = {};
      for (const row of rows) {
        versions[row.region_code] = row.version;
      }

      // 如果某些地区没有数据，使用模拟数据
      for (const regionCode of regionCodes) {
        if (!versions[regionCode]) {
          console.log(`数据库中没有找到 ${regionCode} 地区的版本数据，返回模拟数据`);
          versions[regionCode] = this._getMockVersion(regionCode);
        }
      }

      return versions;
    } catch (error) {
      console.error('从数据库获取多个地区版本数据失败:', error);
      // 返回模拟数据
      const versions = {};
      for (const regionCode of regionCodes) {
        versions[regionCode] = this._getMockVersion(regionCode);
      }
      return versions;
    }
  }

  // 更新数据版本
  static async updateVersion(regionCode, newVersion) {
    try {
      // 尝试更新数据库
      const sql = 'UPDATE data_versions SET version = ? WHERE region_code = ?';
      await db.query(sql, [newVersion, regionCode]);
      return true;
    } catch (error) {
      console.error('更新版本数据失败:', error);
      // 这里我们不返回模拟数据，因为更新操作应该成功或失败
      throw error;
    }
  }
}

module.exports = Version;
