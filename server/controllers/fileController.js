/**
 * 文件控制器
 */
const path = require('path');
const { validationResult } = require('express-validator');
const fileService = require('../services/fileService');
const logger = require('../utils/logger');
const { createError } = require('../utils/errorHandler');

/**
 * 上传文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.uploadFile = async (req, res, next) => {
  try {
    // 检查是否有文件
    if (!req.file) {
      return res.status(400).json({ error: '没有上传文件' });
    }
    
    const userId = req.user.id;
    const { originalname, filename, mimetype, size, path: filePath } = req.file;
    const { entity_type, entity_id } = req.body;
    
    // 保存文件记录
    const fileRecord = await fileService.saveFileRecord({
      user_id: userId,
      original_name: originalname,
      file_name: filename,
      file_path: filePath,
      mime_type: mimetype,
      size,
      entity_type,
      entity_id
    });
    
    // 构建文件URL
    const fileUrl = `/api/files/${fileRecord.id}`;
    
    res.status(201).json({
      data: {
        ...fileRecord,
        url: fileUrl
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 上传多个文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.uploadMultipleFiles = async (req, res, next) => {
  try {
    // 检查是否有文件
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: '没有上传文件' });
    }
    
    const userId = req.user.id;
    const { entity_type, entity_id } = req.body;
    
    // 保存文件记录
    const fileRecords = [];
    
    for (const file of req.files) {
      const { originalname, filename, mimetype, size, path: filePath } = file;
      
      const fileRecord = await fileService.saveFileRecord({
        user_id: userId,
        original_name: originalname,
        file_name: filename,
        file_path: filePath,
        mime_type: mimetype,
        size,
        entity_type,
        entity_id
      });
      
      // 构建文件URL
      const fileUrl = `/api/files/${fileRecord.id}`;
      
      fileRecords.push({
        ...fileRecord,
        url: fileUrl
      });
    }
    
    res.status(201).json({ data: fileRecords });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getFile = async (req, res, next) => {
  try {
    const { file_id } = req.params;
    
    // 获取文件记录
    const fileRecord = await fileService.getFileRecord(file_id);
    
    if (!fileRecord) {
      return res.status(404).json({ error: '文件不存在' });
    }
    
    // 发送文件
    res.sendFile(fileRecord.file_path);
  } catch (error) {
    next(error);
  }
};

/**
 * 获取文件信息
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getFileInfo = async (req, res, next) => {
  try {
    const { file_id } = req.params;
    const userId = req.user.id;
    
    // 获取文件记录
    const fileRecord = await fileService.getFileRecord(file_id);
    
    if (!fileRecord) {
      return res.status(404).json({ error: '文件不存在' });
    }
    
    // 检查权限
    if (fileRecord.user_id !== userId) {
      return res.status(403).json({ error: '无权访问此文件' });
    }
    
    // 构建文件URL
    const fileUrl = `/api/files/${fileRecord.id}`;
    
    res.json({
      data: {
        ...fileRecord,
        url: fileUrl
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * 获取用户的文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.getUserFiles = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { limit, offset, entity_type, entity_id } = req.query;
    
    // 获取用户的文件
    const files = await fileService.getUserFiles(userId, {
      limit: limit ? parseInt(limit) : 20,
      offset: offset ? parseInt(offset) : 0,
      entity_type,
      entity_id
    });
    
    // 构建文件URL
    const filesWithUrl = files.map(file => ({
      ...file,
      url: `/api/files/${file.id}`
    }));
    
    res.json({ data: filesWithUrl });
  } catch (error) {
    next(error);
  }
};

/**
 * 删除文件
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.deleteFile = async (req, res, next) => {
  try {
    const { file_id } = req.params;
    const userId = req.user.id;
    
    // 删除文件
    const success = await fileService.deleteFile(file_id, userId);
    
    if (success) {
      res.json({ message: '文件已删除' });
    } else {
      res.status(404).json({ error: '文件不存在' });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * 关联文件到实体
 * @param {Object} req - 请求对象
 * @param {Object} res - 响应对象
 */
exports.associateFileWithEntity = async (req, res, next) => {
  try {
    // 验证请求
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { file_id } = req.params;
    const { entity_type, entity_id } = req.body;
    const userId = req.user.id;
    
    // 关联文件到实体
    const success = await fileService.associateFileWithEntity(file_id, entity_type, entity_id, userId);
    
    if (success) {
      res.json({ message: '文件已关联到实体' });
    } else {
      res.status(404).json({ error: '文件不存在' });
    }
  } catch (error) {
    next(error);
  }
};
