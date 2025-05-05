/**
 * 同步服务
 * 提供数据同步和冲突解决功能
 */
const SyncRecord = require('../models/SyncRecord');
const Holiday = require('../models/Holiday');
const Reminder = require('../models/Reminder');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const transactionManager = require('../utils/transactionManager');

/**
 * 获取同步记录
 * @param {string} userId - 用户ID
 * @param {Object} filters - 过滤条件
 * @returns {Array} 同步记录列表
 */
exports.getSyncRecords = async (userId, filters = {}) => {
  try {
    return await SyncRecord.getByUserId(userId, filters);
  } catch (error) {
    logger.error('获取同步记录失败:', error);
    throw error;
  }
};

/**
 * 获取设备的同步记录
 * @param {string} userId - 用户ID
 * @param {string} deviceId - 设备ID
 * @param {Object} filters - 过滤条件
 * @returns {Array} 同步记录列表
 */
exports.getDeviceSyncRecords = async (userId, deviceId, filters = {}) => {
  try {
    return await SyncRecord.getByDeviceId(userId, deviceId, filters);
  } catch (error) {
    logger.error('获取设备同步记录失败:', error);
    throw error;
  }
};

/**
 * 获取最后同步时间
 * @param {string} userId - 用户ID
 * @param {string} deviceId - 设备ID
 * @returns {Date} 最后同步时间
 */
exports.getLastSyncTime = async (userId, deviceId) => {
  try {
    return await SyncRecord.getLastSyncTime(userId, deviceId);
  } catch (error) {
    logger.error('获取最后同步时间失败:', error);
    throw error;
  }
};

/**
 * 创建同步记录
 * @param {Object} recordData - 同步记录数据
 * @returns {Object} 创建的同步记录
 */
exports.createSyncRecord = async (recordData) => {
  try {
    return await SyncRecord.create(recordData);
  } catch (error) {
    logger.error('创建同步记录失败:', error);
    throw error;
  }
};

/**
 * 更新同步记录
 * @param {string} id - 同步记录ID
 * @param {Object} recordData - 同步记录数据
 * @returns {Object} 更新的同步记录
 */
exports.updateSyncRecord = async (id, recordData) => {
  try {
    return await SyncRecord.update(id, recordData);
  } catch (error) {
    logger.error('更新同步记录失败:', error);
    throw error;
  }
};

/**
 * 处理同步操作
 * @param {string} userId - 用户ID
 * @param {string} deviceId - 设备ID
 * @param {Array} operations - 同步操作数组
 * @param {string} lastSyncTime - 最后同步时间
 * @returns {Object} 处理结果
 */
exports.processSyncOperations = async (userId, deviceId, operations, lastSyncTime) => {
  const results = {
    success: [],
    failed: [],
    conflicts: []
  };

  // 创建批处理事务
  const batchOperations = [];
  const syncRecords = [];

  // 第一阶段：验证和准备
  for (const operation of operations) {
    try {
      // 验证操作
      if (!operation.entity_type || !operation.operation_type || !operation.entity_id) {
        results.failed.push({
          operation_id: operation.id,
          error: '缺少必要参数'
        });
        continue;
      }

      // 检查版本冲突
      const conflict = await this.checkVersionConflict(userId, operation);

      if (conflict) {
        // 记录冲突
        results.conflicts.push({
          operation_id: operation.id,
          entity_id: operation.entity_id,
          conflict_data: conflict
        });

        // 创建冲突同步记录
        const syncRecord = {
          id: uuidv4(),
          user_id: userId,
          device_id: deviceId,
          entity_type: operation.entity_type,
          operation_type: operation.operation_type,
          entity_id: operation.entity_id,
          entity_data: operation.entity_data,
          version: operation.version || 1,
          status: 'conflict',
          conflict_data: conflict,
          sync_time: new Date().toISOString(),
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        };

        syncRecords.push(syncRecord);
        continue;
      }

      // 准备批处理操作
      batchOperations.push({
        operation,
        syncRecordId: uuidv4()
      });

      // 创建同步记录
      const syncRecord = {
        id: batchOperations[batchOperations.length - 1].syncRecordId,
        user_id: userId,
        device_id: deviceId,
        entity_type: operation.entity_type,
        operation_type: operation.operation_type,
        entity_id: operation.entity_id,
        entity_data: operation.entity_data,
        version: operation.version || 1,
        status: 'pending',
        sync_time: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      syncRecords.push(syncRecord);
    } catch (error) {
      logger.error('处理同步操作失败:', error);

      results.failed.push({
        operation_id: operation.id,
        error: error.message
      });
    }
  }

  // 第二阶段和第三阶段：在事务中批量创建同步记录和执行批处理操作
  if (syncRecords.length > 0 || batchOperations.length > 0) {
    try {
      // 使用事务管理器执行事务
      await transactionManager.executeTransaction(async (connection) => {
        // 批量创建同步记录
        if (syncRecords.length > 0) {
          // 准备批量插入数据
          const columns = ['id', 'user_id', 'device_id', 'entity_type', 'operation_type',
                          'entity_id', 'entity_data', 'version', 'status', 'sync_time',
                          'created_at', 'updated_at'];

          const values = syncRecords.map(record => [
            record.id,
            record.user_id,
            record.device_id,
            record.entity_type,
            record.operation_type,
            record.entity_id,
            JSON.stringify(record.entity_data),
            record.version,
            record.status,
            record.sync_time,
            record.created_at,
            record.updated_at
          ]);

          // 执行批量插入
          await connection.query(
            `INSERT INTO sync_records (${columns.join(', ')}) VALUES ?`,
            [values]
          );
        }

        // 执行批处理操作
        for (const { operation, syncRecordId } of batchOperations) {
          try {
            // 处理操作
            let result;
            switch (operation.entity_type) {
              case 'holiday':
                result = await this.processHolidayOperationWithTransaction(userId, operation, connection);
                break;
              case 'reminder':
                result = await this.processReminderOperationWithTransaction(userId, operation, connection);
                break;
              default:
                throw new Error(`不支持的实体类型: ${operation.entity_type}`);
            }

            // 更新同步记录
            if (result.success) {
              await connection.query(
                `UPDATE sync_records SET status = ?, sync_time = ?, updated_at = ? WHERE id = ?`,
                ['completed', new Date().toISOString(), new Date().toISOString(), syncRecordId]
              );

              results.success.push({
                operation_id: operation.id,
                entity_id: result.entity_id
              });
            } else {
              await connection.query(
                `UPDATE sync_records SET status = ?, error_message = ?, sync_time = ?, updated_at = ? WHERE id = ?`,
                ['failed', result.error, new Date().toISOString(), new Date().toISOString(), syncRecordId]
              );

              results.failed.push({
                operation_id: operation.id,
                error: result.error
              });
            }
          } catch (error) {
            logger.error('执行批处理操作失败:', error);

            // 更新同步记录为失败状态
            await connection.query(
              `UPDATE sync_records SET status = ?, error_message = ?, sync_time = ?, updated_at = ? WHERE id = ?`,
              ['failed', error.message, new Date().toISOString(), new Date().toISOString(), syncRecordId]
            );

            results.failed.push({
              operation_id: operation.id,
              error: error.message
            });
          }
        }
      });
    } catch (error) {
      logger.error('事务执行失败:', error);

      // 将所有未处理的操作标记为失败
      for (const { operation } of batchOperations) {
        if (!results.success.some(s => s.operation_id === operation.id) &&
            !results.failed.some(f => f.operation_id === operation.id)) {
          results.failed.push({
            operation_id: operation.id,
            error: '事务执行失败: ' + error.message
          });
        }
      }
    }
  }

  return results;
};

/**
 * 检查版本冲突
 * @param {string} userId - 用户ID
 * @param {Object} operation - 同步操作
 * @returns {Object|null} 冲突数据或null
 */
exports.checkVersionConflict = async (userId, operation) => {
  try {
    // 获取最新的同步记录
    const latestSyncRecords = await SyncRecord.getByEntityId(operation.entity_id, {
      limit: 1,
      orderBy: 'sync_time',
      orderDirection: 'DESC'
    });

    if (latestSyncRecords.length === 0) {
      // 没有同步记录，不存在冲突
      return null;
    }

    const latestSyncRecord = latestSyncRecords[0];

    // 检查版本
    if (operation.version && latestSyncRecord.version >= operation.version) {
      // 版本冲突
      let serverEntity;

      // 获取服务器端实体
      if (operation.entity_type === 'reminder') {
        serverEntity = await Reminder.getById(operation.entity_id);
      } else if (operation.entity_type === 'holiday') {
        serverEntity = await Holiday.getById(operation.entity_id);
      }

      return {
        server_version: latestSyncRecord.version,
        client_version: operation.version,
        server_entity: serverEntity,
        client_entity: operation.entity_data
      };
    }

    return null;
  } catch (error) {
    logger.error('检查版本冲突失败:', error);
    return null;
  }
};

/**
 * 处理节日操作
 * @param {string} userId - 用户ID
 * @param {Object} operation - 同步操作
 * @returns {Object} 处理结果
 */
exports.processHolidayOperation = async (userId, operation) => {
  try {
    return await transactionManager.executeTransaction(async (connection) => {
      return await this.processHolidayOperationWithTransaction(userId, operation, connection);
    });
  } catch (error) {
    logger.error('处理节日操作失败:', error);

    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * 使用事务处理节日操作
 * @param {string} userId - 用户ID
 * @param {Object} operation - 同步操作
 * @param {Object} connection - 数据库连接
 * @returns {Object} 处理结果
 */
exports.processHolidayOperationWithTransaction = async (userId, operation, connection) => {
  try {
    switch (operation.operation_type) {
      case 'create':
        // 准备数据
        const holidayData = {
          ...operation.entity_data,
          id: operation.entity_id
        };

        // 确保JSON字段正确序列化
        if (typeof holidayData.name === 'object') {
          holidayData.name = JSON.stringify(holidayData.name);
        }
        if (typeof holidayData.description === 'object') {
          holidayData.description = JSON.stringify(holidayData.description);
        }
        if (typeof holidayData.regions === 'object') {
          holidayData.regions = JSON.stringify(holidayData.regions);
        }
        if (typeof holidayData.calculation_rule === 'object') {
          holidayData.calculation_rule = JSON.stringify(holidayData.calculation_rule);
        }

        // 创建节日
        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
        await connection.query(
          `INSERT INTO holidays (
            id, name, description, date, type, regions, calculation_type,
            calculation_rule, importance_level, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            holidayData.id,
            holidayData.name,
            holidayData.description,
            holidayData.date,
            holidayData.type,
            holidayData.regions,
            holidayData.calculation_type,
            holidayData.calculation_rule,
            holidayData.importance_level,
            now,
            now
          ]
        );

        return {
          success: true,
          entity_id: holidayData.id
        };

      case 'update':
        // 检查节日是否存在
        const [existingHolidays] = await connection.query(
          'SELECT * FROM holidays WHERE id = ?',
          [operation.entity_id]
        );

        if (existingHolidays.length === 0) {
          return {
            success: false,
            error: '节日不存在'
          };
        }

        // 准备更新数据
        const updateData = { ...operation.entity_data };
        const updateFields = [];
        const updateValues = [];

        // 处理各个字段
        if (updateData.name !== undefined) {
          if (typeof updateData.name === 'object') {
            updateData.name = JSON.stringify(updateData.name);
          }
          updateFields.push('name = ?');
          updateValues.push(updateData.name);
        }

        if (updateData.description !== undefined) {
          if (typeof updateData.description === 'object') {
            updateData.description = JSON.stringify(updateData.description);
          }
          updateFields.push('description = ?');
          updateValues.push(updateData.description);
        }

        if (updateData.date !== undefined) {
          updateFields.push('date = ?');
          updateValues.push(updateData.date);
        }

        if (updateData.type !== undefined) {
          updateFields.push('type = ?');
          updateValues.push(updateData.type);
        }

        if (updateData.regions !== undefined) {
          if (typeof updateData.regions === 'object') {
            updateData.regions = JSON.stringify(updateData.regions);
          }
          updateFields.push('regions = ?');
          updateValues.push(updateData.regions);
        }

        if (updateData.calculation_type !== undefined) {
          updateFields.push('calculation_type = ?');
          updateValues.push(updateData.calculation_type);
        }

        if (updateData.calculation_rule !== undefined) {
          if (typeof updateData.calculation_rule === 'object') {
            updateData.calculation_rule = JSON.stringify(updateData.calculation_rule);
          }
          updateFields.push('calculation_rule = ?');
          updateValues.push(updateData.calculation_rule);
        }

        if (updateData.importance_level !== undefined) {
          updateFields.push('importance_level = ?');
          updateValues.push(updateData.importance_level);
        }

        // 添加更新时间
        updateFields.push('updated_at = ?');
        updateValues.push(new Date().toISOString().slice(0, 19).replace('T', ' '));

        // 添加ID
        updateValues.push(operation.entity_id);

        // 执行更新
        if (updateFields.length > 0) {
          await connection.query(
            `UPDATE holidays SET ${updateFields.join(', ')} WHERE id = ?`,
            updateValues
          );
        }

        return {
          success: true,
          entity_id: operation.entity_id
        };

      case 'delete':
        // 删除节日
        const [deleteResult] = await connection.query(
          'DELETE FROM holidays WHERE id = ?',
          [operation.entity_id]
        );

        if (deleteResult.affectedRows === 0) {
          return {
            success: false,
            error: '节日不存在'
          };
        }

        return {
          success: true,
          entity_id: operation.entity_id
        };

      default:
        return {
          success: false,
          error: `不支持的操作类型: ${operation.operation_type}`
        };
    }
  } catch (error) {
    logger.error('处理节日操作失败:', error);

    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * 处理提醒事项操作
 * @param {string} userId - 用户ID
 * @param {Object} operation - 同步操作
 * @returns {Object} 处理结果
 */
exports.processReminderOperation = async (userId, operation) => {
  try {
    return await transactionManager.executeTransaction(async (connection) => {
      return await this.processReminderOperationWithTransaction(userId, operation, connection);
    });
  } catch (error) {
    logger.error('处理提醒事项操作失败:', error);

    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * 使用事务处理提醒事项操作
 * @param {string} userId - 用户ID
 * @param {Object} operation - 同步操作
 * @param {Object} connection - 数据库连接
 * @returns {Object} 处理结果
 */
exports.processReminderOperationWithTransaction = async (userId, operation, connection) => {
  try {
    switch (operation.operation_type) {
      case 'create':
        // 准备数据
        const reminderData = {
          ...operation.entity_data,
          id: operation.entity_id,
          user_id: userId
        };

        // 确保JSON字段正确序列化
        if (typeof reminderData.tags === 'object') {
          reminderData.tags = JSON.stringify(reminderData.tags);
        }
        if (typeof reminderData.attachments === 'object') {
          reminderData.attachments = JSON.stringify(reminderData.attachments);
        }
        if (typeof reminderData.custom_fields === 'object') {
          reminderData.custom_fields = JSON.stringify(reminderData.custom_fields);
        }

        // 创建提醒事项
        const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
        await connection.query(
          `INSERT INTO reminders (
            id, user_id, title, description, due_date, priority, is_completed,
            tags, attachments, custom_fields, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            reminderData.id,
            reminderData.user_id,
            reminderData.title,
            reminderData.description || null,
            reminderData.due_date || null,
            reminderData.priority || 'medium',
            reminderData.is_completed || false,
            reminderData.tags || null,
            reminderData.attachments || null,
            reminderData.custom_fields || null,
            now,
            now
          ]
        );

        return {
          success: true,
          entity_id: reminderData.id
        };

      case 'update':
        // 获取提醒事项
        const [existingReminders] = await connection.query(
          'SELECT * FROM reminders WHERE id = ?',
          [operation.entity_id]
        );

        if (existingReminders.length === 0) {
          return {
            success: false,
            error: '提醒事项不存在'
          };
        }

        const existingReminder = existingReminders[0];

        // 检查权限
        if (existingReminder.user_id && existingReminder.user_id !== userId) {
          return {
            success: false,
            error: '无权更新此提醒事项'
          };
        }

        // 准备更新数据
        const updateData = { ...operation.entity_data };
        const updateFields = [];
        const updateValues = [];

        // 处理各个字段
        if (updateData.title !== undefined) {
          updateFields.push('title = ?');
          updateValues.push(updateData.title);
        }

        if (updateData.description !== undefined) {
          updateFields.push('description = ?');
          updateValues.push(updateData.description);
        }

        if (updateData.due_date !== undefined) {
          updateFields.push('due_date = ?');
          updateValues.push(updateData.due_date);
        }

        if (updateData.priority !== undefined) {
          updateFields.push('priority = ?');
          updateValues.push(updateData.priority);
        }

        if (updateData.is_completed !== undefined) {
          updateFields.push('is_completed = ?');
          updateValues.push(updateData.is_completed);
        }

        if (updateData.tags !== undefined) {
          if (typeof updateData.tags === 'object') {
            updateData.tags = JSON.stringify(updateData.tags);
          }
          updateFields.push('tags = ?');
          updateValues.push(updateData.tags);
        }

        if (updateData.attachments !== undefined) {
          if (typeof updateData.attachments === 'object') {
            updateData.attachments = JSON.stringify(updateData.attachments);
          }
          updateFields.push('attachments = ?');
          updateValues.push(updateData.attachments);
        }

        if (updateData.custom_fields !== undefined) {
          if (typeof updateData.custom_fields === 'object') {
            updateData.custom_fields = JSON.stringify(updateData.custom_fields);
          }
          updateFields.push('custom_fields = ?');
          updateValues.push(updateData.custom_fields);
        }

        // 添加更新时间
        updateFields.push('updated_at = ?');
        updateValues.push(new Date().toISOString().slice(0, 19).replace('T', ' '));

        // 添加ID
        updateValues.push(operation.entity_id);

        // 执行更新
        if (updateFields.length > 0) {
          await connection.query(
            `UPDATE reminders SET ${updateFields.join(', ')} WHERE id = ?`,
            updateValues
          );
        }

        return {
          success: true,
          entity_id: operation.entity_id
        };

      case 'delete':
        // 获取提醒事项
        const [remindersToDelete] = await connection.query(
          'SELECT * FROM reminders WHERE id = ?',
          [operation.entity_id]
        );

        if (remindersToDelete.length === 0) {
          return {
            success: false,
            error: '提醒事项不存在'
          };
        }

        const reminderToDelete = remindersToDelete[0];

        // 检查权限
        if (reminderToDelete.user_id && reminderToDelete.user_id !== userId) {
          return {
            success: false,
            error: '无权删除此提醒事项'
          };
        }

        // 删除提醒事项
        const [deleteResult] = await connection.query(
          'DELETE FROM reminders WHERE id = ?',
          [operation.entity_id]
        );

        if (deleteResult.affectedRows === 0) {
          return {
            success: false,
            error: '提醒事项不存在'
          };
        }

        return {
          success: true,
          entity_id: operation.entity_id
        };

      default:
        return {
          success: false,
          error: `不支持的操作类型: ${operation.operation_type}`
        };
    }
  } catch (error) {
    logger.error('处理提醒事项操作失败:', error);

    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * 获取服务器端更新
 * @param {string} userId - 用户ID
 * @param {string} lastSyncTime - 最后同步时间
 * @param {Object} options - 选项
 * @returns {Object} 服务器端更新
 */
exports.getServerUpdates = async (userId, lastSyncTime, options = {}) => {
  const updates = {
    holidays: [],
    reminders: [],
    deleted_entities: []
  };

  try {
    // 获取节日更新
    const holidays = await Holiday.getAll({
      updatedAfter: lastSyncTime
    });

    // 处理节日数据
    for (const holiday of holidays) {
      // 解析JSON字段
      if (holiday.name) {
        try {
          holiday.name = JSON.parse(holiday.name);
        } catch (e) {
          // 保持原样
        }
      }

      if (holiday.description) {
        try {
          holiday.description = JSON.parse(holiday.description);
        } catch (e) {
          // 保持原样
        }
      }

      if (holiday.regions) {
        try {
          holiday.regions = JSON.parse(holiday.regions);
        } catch (e) {
          // 保持原样
        }
      }

      if (holiday.calculation_rule) {
        try {
          holiday.calculation_rule = JSON.parse(holiday.calculation_rule);
        } catch (e) {
          // 保持原样
        }
      }
    }

    updates.holidays = holidays;

    // 获取提醒事项更新
    const reminders = await Reminder.getAll({
      userId,
      updatedAfter: lastSyncTime
    });

    // 处理提醒事项数据
    for (const reminder of reminders) {
      if (reminder.tags) {
        try {
          reminder.tags = JSON.parse(reminder.tags);
        } catch (e) {
          // 保持原样
        }
      }
    }

    updates.reminders = reminders;

    // 获取删除的实体
    const deletedEntities = await SyncRecord.getAll({
      operation_type: 'delete',
      status: 'completed',
      syncTimeAfter: lastSyncTime
    });

    // 处理删除的实体
    for (const entity of deletedEntities) {
      updates.deleted_entities.push({
        entity_type: entity.entity_type,
        entity_id: entity.entity_id
      });
    }

    // 添加分页信息
    if (options.page_size) {
      const pageSize = parseInt(options.page_size);
      const page = parseInt(options.page || 1);

      // 分页处理
      updates.holidays = updates.holidays.slice((page - 1) * pageSize, page * pageSize);
      updates.reminders = updates.reminders.slice((page - 1) * pageSize, page * pageSize);
      updates.deleted_entities = updates.deleted_entities.slice((page - 1) * pageSize, page * pageSize);

      // 添加分页元数据
      updates.pagination = {
        page,
        page_size: pageSize,
        total_holidays: holidays.length,
        total_reminders: reminders.length,
        total_deleted: deletedEntities.length
      };
    }

    return updates;
  } catch (error) {
    logger.error('获取服务器端更新失败:', error);
    throw error;
  }
};

/**
 * 解决同步冲突
 * @param {string} userId - 用户ID
 * @param {string} syncRecordId - 同步记录ID
 * @param {string} resolution - 解决方式 ('client', 'server', 'merge')
 * @param {Object} mergedData - 合并后的数据（如果resolution为'merge'）
 * @returns {Object} 解决结果
 */
exports.resolveSyncConflict = async (userId, syncRecordId, resolution, mergedData = null) => {
  try {
    // 获取同步记录
    const syncRecord = await SyncRecord.getById(syncRecordId);

    if (!syncRecord) {
      throw new Error('同步记录不存在');
    }

    if (syncRecord.user_id !== userId) {
      throw new Error('无权解决此冲突');
    }

    if (syncRecord.status !== 'conflict') {
      throw new Error('此记录不是冲突状态');
    }

    let result;

    // 根据解决方式处理冲突
    switch (resolution) {
      case 'client':
        // 使用客户端数据
        result = await this.applyClientResolution(syncRecord);
        break;

      case 'server':
        // 使用服务器端数据
        result = await this.applyServerResolution(syncRecord);
        break;

      case 'merge':
        // 使用合并数据
        if (!mergedData) {
          throw new Error('合并解决方式需要提供合并后的数据');
        }

        result = await this.applyMergeResolution(syncRecord, mergedData);
        break;

      default:
        throw new Error(`不支持的解决方式: ${resolution}`);
    }

    // 更新同步记录
    await SyncRecord.update(syncRecordId, {
      status: 'resolved',
      resolution,
      resolved_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    return {
      success: true,
      entity_id: syncRecord.entity_id,
      resolution
    };
  } catch (error) {
    logger.error('解决同步冲突失败:', error);
    throw error;
  }
};

/**
 * 应用客户端解决方案
 * @param {Object} syncRecord - 同步记录
 * @returns {Object} 处理结果
 */
exports.applyClientResolution = async (syncRecord) => {
  try {
    // 创建一个新的操作
    const operation = {
      entity_type: syncRecord.entity_type,
      operation_type: syncRecord.operation_type,
      entity_id: syncRecord.entity_id,
      entity_data: syncRecord.entity_data,
      // 使用更高的版本号
      version: syncRecord.conflict_data.server_version + 1
    };

    // 处理操作
    let result;
    if (syncRecord.entity_type === 'holiday') {
      result = await this.processHolidayOperation(syncRecord.user_id, operation);
    } else if (syncRecord.entity_type === 'reminder') {
      result = await this.processReminderOperation(syncRecord.user_id, operation);
    } else {
      throw new Error(`不支持的实体类型: ${syncRecord.entity_type}`);
    }

    return result;
  } catch (error) {
    logger.error('应用客户端解决方案失败:', error);
    throw error;
  }
};

/**
 * 应用服务器端解决方案
 * @param {Object} syncRecord - 同步记录
 * @returns {Object} 处理结果
 */
exports.applyServerResolution = async (syncRecord) => {
  // 服务器端数据已经是最新的，不需要做任何操作
  return {
    success: true,
    entity_id: syncRecord.entity_id
  };
};

/**
 * 应用合并解决方案
 * @param {Object} syncRecord - 同步记录
 * @param {Object} mergedData - 合并后的数据
 * @returns {Object} 处理结果
 */
exports.applyMergeResolution = async (syncRecord, mergedData) => {
  try {
    // 创建一个新的操作
    const operation = {
      entity_type: syncRecord.entity_type,
      operation_type: 'update',
      entity_id: syncRecord.entity_id,
      entity_data: mergedData,
      // 使用更高的版本号
      version: syncRecord.conflict_data.server_version + 1
    };

    // 处理操作
    let result;
    if (syncRecord.entity_type === 'holiday') {
      result = await this.processHolidayOperation(syncRecord.user_id, operation);
    } else if (syncRecord.entity_type === 'reminder') {
      result = await this.processReminderOperation(syncRecord.user_id, operation);
    } else {
      throw new Error(`不支持的实体类型: ${syncRecord.entity_type}`);
    }

    return result;
  } catch (error) {
    logger.error('应用合并解决方案失败:', error);
    throw error;
  }
};
