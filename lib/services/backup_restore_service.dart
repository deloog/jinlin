import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// FileSystemEntity类型来自dart:io包
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/hive_database_service_enhanced.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// 数据备份和恢复服务
///
/// 负责备份和恢复用户数据
class BackupRestoreService {
  // 单例模式
  static final BackupRestoreService _instance = BackupRestoreService._internal();
  factory BackupRestoreService() => _instance;
  BackupRestoreService._internal();

  // 数据库服务
  final _dbService = HiveDatabaseServiceEnhanced();

  // 备份文件名前缀
  static const String _backupFilePrefix = 'jinlin_backup_';

  // 备份文件扩展名
  static const String _backupFileExtension = '.jlbak';

  // 备份文件版本
  static const int _backupFileVersion = 1;

  /// 创建备份
  Future<String?> createBackup({String? password}) async {
    try {
      // 检查权限
      if (!await _checkPermissions()) {
        return null;
      }

      // 获取备份数据
      final backupData = await _getBackupData();

      // 序列化备份数据
      final jsonData = jsonEncode(backupData);

      // 压缩数据
      final compressedData = _compressData(jsonData);

      // 如果提供了密码，则加密数据
      final finalData = password != null && password.isNotEmpty
          ? _encryptData(compressedData, password)
          : compressedData;

      // 创建备份文件
      final backupFilePath = await _createBackupFile(finalData);

      // 更新最后备份时间
      await _updateLastBackupTime();

      return backupFilePath;
    } catch (e) {
      debugPrint('创建备份失败: $e');
      return null;
    }
  }

  /// 恢复备份
  Future<bool> restoreBackup(String backupFilePath, {String? password}) async {
    try {
      // 读取备份文件
      final file = File(backupFilePath);
      if (!await file.exists()) {
        debugPrint('备份文件不存在: $backupFilePath');
        return false;
      }

      // 读取文件数据
      final fileData = await file.readAsBytes();

      // 如果提供了密码，则解密数据
      final decryptedData = password != null && password.isNotEmpty
          ? _decryptData(fileData, password)
          : fileData;

      // 解压数据
      final decompressedData = _decompressData(decryptedData);

      // 反序列化备份数据
      final jsonData = utf8.decode(decompressedData);
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      // 验证备份数据
      if (!_validateBackupData(backupData)) {
        debugPrint('备份数据验证失败');
        return false;
      }

      // 恢复数据
      await _restoreBackupData(backupData);

      return true;
    } catch (e) {
      debugPrint('恢复备份失败: $e');
      return false;
    }
  }

  /// 获取备份文件列表
  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      // 如果备份目录不存在，则创建
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 获取备份文件列表
      final files = await backupDir
          .list()
          .where((entity) =>
              entity is File &&
              entity.path.contains(_backupFilePrefix) &&
              entity.path.endsWith(_backupFileExtension))
          .toList();

      // 按修改时间排序
      files.sort((a, b) {
        return File(b.path)
            .lastModifiedSync()
            .compareTo(File(a.path).lastModifiedSync());
      });

      return files;
    } catch (e) {
      debugPrint('获取备份文件列表失败: $e');
      return [];
    }
  }

  /// 删除备份文件
  Future<bool> deleteBackupFile(String backupFilePath) async {
    try {
      final file = File(backupFilePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除备份文件失败: $e');
      return false;
    }
  }

  /// 导出备份到自定义位置
  Future<String?> exportBackup({String? password}) async {
    try {
      // 创建备份
      final backupFilePath = await createBackup(password: password);
      if (backupFilePath == null) {
        return null;
      }

      // 选择导出位置
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        return null;
      }

      // 复制备份文件到选择的位置
      final backupFile = File(backupFilePath);
      final fileName = backupFile.path.split('/').last;
      final exportPath = '$result/$fileName';
      await backupFile.copy(exportPath);

      return exportPath;
    } catch (e) {
      debugPrint('导出备份失败: $e');
      return null;
    }
  }

  /// 从自定义位置导入备份
  Future<bool> importBackup({String? password}) async {
    try {
      // 选择备份文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_backupFileExtension.substring(1)],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return false;
      }

      // 恢复备份
      return await restoreBackup(filePath, password: password);
    } catch (e) {
      debugPrint('导入备份失败: $e');
      return false;
    }
  }

  /// 获取最后备份时间
  Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_backup_time');
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('获取最后备份时间失败: $e');
      return null;
    }
  }

  /// 检查是否需要备份
  Future<bool> shouldBackup(int backupFrequencyDays) async {
    try {
      final lastBackupTime = await getLastBackupTime();
      if (lastBackupTime == null) {
        return true;
      }

      final now = DateTime.now();
      final difference = now.difference(lastBackupTime).inDays;
      return difference >= backupFrequencyDays;
    } catch (e) {
      debugPrint('检查是否需要备份失败: $e');
      return false;
    }
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    // 检查存储权限
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  /// 获取备份数据
  Future<Map<String, dynamic>> _getBackupData() async {
    // 获取所有数据
    final holidays = _dbService.getAllHolidays();
    final contacts = _dbService.getAllContacts();
    final settings = _dbService.getUserSettings();
    final events = _dbService.getAllReminderEvents();

    // 创建备份数据
    return {
      'version': _backupFileVersion,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'holidays': holidays.map((holiday) => holiday.toJson()).toList(),
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
      'settings': settings?.toJson(),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  /// 压缩数据
  List<int> _compressData(String jsonData) {
    final encoder = ZipEncoder();
    final archive = Archive();

    // 添加数据文件
    final dataBytes = utf8.encode(jsonData);
    final dataFile = ArchiveFile('data.json', dataBytes.length, dataBytes);
    archive.addFile(dataFile);

    // 压缩
    return encoder.encode(archive)!;
  }

  /// 解压数据
  List<int> _decompressData(List<int> compressedData) {
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(compressedData);

    // 获取数据文件
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw Exception('备份文件格式错误');
    }

    return dataFile.content as List<int>;
  }

  /// 加密数据
  List<int> _encryptData(List<int> data, String password) {
    // 生成密钥 - 在TODO实现后会使用
    final _ = _generateKey(password);

    // TODO: 实现真正的加密逻辑
    // 这里只是一个简单的示例，实际应用中应该使用更安全的加密算法
    return data;
  }

  /// 解密数据
  List<int> _decryptData(List<int> encryptedData, String password) {
    // 生成密钥 - 在TODO实现后会使用
    final _ = _generateKey(password);

    // TODO: 实现真正的解密逻辑
    // 这里只是一个简单的示例，实际应用中应该使用更安全的解密算法
    return encryptedData;
  }

  /// 生成密钥
  List<int> _generateKey(String password) {
    // 使用SHA-256生成密钥
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  /// 创建备份文件
  Future<String> _createBackupFile(List<int> data) async {
    // 获取应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');

    // 如果备份目录不存在，则创建
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // 创建备份文件名
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$_backupFilePrefix$timestamp$_backupFileExtension';
    final filePath = '${backupDir.path}/$fileName';

    // 写入数据
    final file = File(filePath);
    await file.writeAsBytes(data);

    return filePath;
  }

  /// 更新最后备份时间
  Future<void> _updateLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_backup_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('更新最后备份时间失败: $e');
    }
  }

  /// 验证备份数据
  bool _validateBackupData(Map<String, dynamic> backupData) {
    // 检查版本
    if (!backupData.containsKey('version') ||
        backupData['version'] != _backupFileVersion) {
      debugPrint('备份文件版本不匹配');
      return false;
    }

    // 检查时间戳
    if (!backupData.containsKey('timestamp')) {
      debugPrint('备份文件缺少时间戳');
      return false;
    }

    // 检查数据
    if (!backupData.containsKey('holidays') ||
        !backupData.containsKey('contacts') ||
        !backupData.containsKey('settings') ||
        !backupData.containsKey('events')) {
      debugPrint('备份文件缺少数据');
      return false;
    }

    return true;
  }

  /// 恢复备份数据
  Future<void> _restoreBackupData(Map<String, dynamic> backupData) async {
    // 恢复节日数据
    if (backupData.containsKey('holidays') && backupData['holidays'] is List) {
      final holidaysJson = backupData['holidays'] as List;
      final holidays = holidaysJson
          .map((json) => HolidayModelExtended.fromJson(json))
          .toList();
      await _dbService.saveHolidays(holidays);
    }

    // 恢复联系人数据
    if (backupData.containsKey('contacts') && backupData['contacts'] is List) {
      final contactsJson = backupData['contacts'] as List;
      final contacts = contactsJson
          .map((json) => ContactModel.fromJson(json))
          .toList();
      await _dbService.saveContacts(contacts);
    }

    // 恢复用户设置
    if (backupData.containsKey('settings') &&
        backupData['settings'] is Map<String, dynamic>) {
      final settingsJson = backupData['settings'] as Map<String, dynamic>;
      final settings = UserSettingsModel.fromJson(settingsJson);
      await _dbService.saveUserSettings(settings);
    }

    // 恢复提醒事件数据
    if (backupData.containsKey('events') && backupData['events'] is List) {
      final eventsJson = backupData['events'] as List;
      final events = eventsJson
          .map((json) => ReminderEventModel.fromJson(json))
          .toList();
      await _dbService.saveReminderEvents(events);
    }
  }
}
