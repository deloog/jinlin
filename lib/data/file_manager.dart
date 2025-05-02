import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('FileManager');

class FileManager {
  // 单例模式
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  // 选择文件
  Future<String?> pickFile({
    List<String> allowedExtensions = const ['json'],
    String dialogTitle = 'Select a file',
  }) async {
    try {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        logger.warning('Storage permission denied');
        return null;
      }

      // 打开文件选择器
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      );

      // 如果用户取消了选择，返回 null
      if (result == null || result.files.isEmpty) {
        logger.info('File picking cancelled');
        return null;
      }

      // 返回选择的文件路径
      final file = result.files.first;
      logger.info('File picked: ${file.path}');
      return file.path;
    } catch (e) {
      logger.warning('Error picking file: $e');
      return null;
    }
  }

  // 分享文件
  Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        logger.warning('File does not exist: $filePath');
        return false;
      }

      // 分享文件
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
      );

      logger.info('File shared: $filePath');
      return true;
    } catch (e) {
      logger.warning('Error sharing file: $e');
      return false;
    }
  }

  // 保存文件到下载目录
  Future<String?> saveFileToDownloads(String sourceFilePath, String fileName) async {
    try {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        logger.warning('Storage permission denied');
        return null;
      }

      // 获取下载目录
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        // 对于其他平台，使用应用文档目录
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // 确保目录存在
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // 构建目标文件路径
      final targetFilePath = '${downloadsDir.path}/$fileName';

      // 复制文件
      final sourceFile = File(sourceFilePath);
      await sourceFile.copy(targetFilePath);

      logger.info('File saved to: $targetFilePath');
      return targetFilePath;
    } catch (e) {
      logger.warning('Error saving file: $e');
      return null;
    }
  }

  // 删除文件
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.info('File deleted: $filePath');
        return true;
      } else {
        logger.warning('File does not exist: $filePath');
        return false;
      }
    } catch (e) {
      logger.warning('Error deleting file: $e');
      return false;
    }
  }
}
