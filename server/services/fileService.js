/**
 * 文件服务
 * 提供文件上传和管理功能
 */
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const logger = require('../utils/logger');
const { createError } = require('../utils/errorHandler');

// 上传目录
const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');

// 确保上传目录存在
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// 配置存储
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // 根据用户ID创建目录
    const userId = req.user.id;
    const userDir = path.join(UPLOAD_DIR, userId);
    
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }
    
    cb(null, userDir);
  },
  filename: (req, file, cb) => {
    // 生成唯一文件名
    const fileId = uuidv4();
    const extname = path.extname(file.originalname);
    cb(null, `${fileId}${extname}`);
  }
});

// 文件过滤器
const fileFilter = (req, file, cb) => {
  // 允许的文件类型
  const allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ];
  
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(createError('validation', '不支持的文件类型', 'UNSUPPORTED_FILE_TYPE'), false);
  }
};

// 创建上传中间件
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 5 // 最多5个文件
  }
});

/**
 * 创建文件表
 */
async function createTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS files (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        original_name VARCHAR(255) NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_path VARCHAR(255) NOT NULL,
        mime_type VARCHAR(100) NOT NULL,
        size BIGINT NOT NULL,
        entity_type VARCHAR(50),
        entity_id VARCHAR(36),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        INDEX idx_files_user_id (user_id),
        INDEX idx_files_entity (entity_type, entity_id)
      )
    `);
    
    logger.info('文件表创建成功');
  } catch (error) {
    logger.error('创建文件表失败:', error);
    throw error;
  }
}

/**
 * 保存文件记录
 * @param {Object} fileData - 文件数据
 * @returns {Object} 保存的文件记录
 */
async function saveFileRecord(fileData) {
  try {
    const { user_id, original_name, file_name, file_path, mime_type, size, entity_type, entity_id } = fileData;
    
    const id = uuidv4();
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    await pool.query(
      `INSERT INTO files (
        id, user_id, original_name, file_name, file_path, mime_type, size,
        entity_type, entity_id, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        user_id,
        original_name,
        file_name,
        file_path,
        mime_type,
        size,
        entity_type || null,
        entity_id || null,
        now,
        now
      ]
    );
    
    return {
      id,
      user_id,
      original_name,
      file_name,
      file_path,
      mime_type,
      size,
      entity_type,
      entity_id,
      created_at: now,
      updated_at: now
    };
  } catch (error) {
    logger.error('保存文件记录失败:', error);
    throw createError('database', '保存文件记录失败', 'saveFileRecord', error);
  }
}

/**
 * 获取文件记录
 * @param {string} fileId - 文件ID
 * @returns {Object} 文件记录
 */
async function getFileRecord(fileId) {
  try {
    const [files] = await pool.query(
      'SELECT * FROM files WHERE id = ?',
      [fileId]
    );
    
    if (files.length === 0) {
      return null;
    }
    
    return files[0];
  } catch (error) {
    logger.error('获取文件记录失败:', error);
    throw createError('database', '获取文件记录失败', 'getFileRecord', error);
  }
}

/**
 * 获取用户的文件记录
 * @param {string} userId - 用户ID
 * @param {Object} options - 选项
 * @returns {Array} 文件记录列表
 */
async function getUserFiles(userId, options = {}) {
  try {
    const { limit = 20, offset = 0, entity_type, entity_id } = options;
    
    let query = 'SELECT * FROM files WHERE user_id = ?';
    const params = [userId];
    
    if (entity_type) {
      query += ' AND entity_type = ?';
      params.push(entity_type);
    }
    
    if (entity_id) {
      query += ' AND entity_id = ?';
      params.push(entity_id);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const [files] = await pool.query(query, params);
    
    return files;
  } catch (error) {
    logger.error('获取用户文件记录失败:', error);
    throw createError('database', '获取用户文件记录失败', 'getUserFiles', error);
  }
}

/**
 * 删除文件
 * @param {string} fileId - 文件ID
 * @param {string} userId - 用户ID
 * @returns {boolean} 是否成功
 */
async function deleteFile(fileId, userId) {
  try {
    // 获取文件记录
    const file = await getFileRecord(fileId);
    
    if (!file) {
      return false;
    }
    
    // 检查权限
    if (file.user_id !== userId) {
      throw createError('forbidden', '无权删除此文件');
    }
    
    // 删除文件
    const filePath = file.file_path;
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    
    // 删除记录
    const [result] = await pool.query(
      'DELETE FROM files WHERE id = ?',
      [fileId]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('删除文件失败:', error);
    throw error;
  }
}

/**
 * 关联文件到实体
 * @param {string} fileId - 文件ID
 * @param {string} entityType - 实体类型
 * @param {string} entityId - 实体ID
 * @param {string} userId - 用户ID
 * @returns {boolean} 是否成功
 */
async function associateFileWithEntity(fileId, entityType, entityId, userId) {
  try {
    // 获取文件记录
    const file = await getFileRecord(fileId);
    
    if (!file) {
      return false;
    }
    
    // 检查权限
    if (file.user_id !== userId) {
      throw createError('forbidden', '无权修改此文件');
    }
    
    // 更新记录
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const [result] = await pool.query(
      'UPDATE files SET entity_type = ?, entity_id = ?, updated_at = ? WHERE id = ?',
      [entityType, entityId, now, fileId]
    );
    
    return result.affectedRows > 0;
  } catch (error) {
    logger.error('关联文件到实体失败:', error);
    throw error;
  }
}

module.exports = {
  createTable,
  upload,
  saveFileRecord,
  getFileRecord,
  getUserFiles,
  deleteFile,
  associateFileWithEntity,
  UPLOAD_DIR
};
