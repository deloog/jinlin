import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 文件工具类
///
/// 提供文件相关的工具方法
class FileUtils {
  /// 私有构造函数，防止实例化
  FileUtils._();

  /// 获取应用文档目录
  static Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取应用临时目录
  static Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }

  /// 获取应用支持目录
  static Future<Directory> getSupportDirectory() async {
    return await getApplicationSupportDirectory();
  }

  /// 获取应用缓存目录
  static Future<Directory> getCacheDirectory() async {
    return await getApplicationCacheDirectory();
  }

  /// 获取应用外部存储目录（仅Android）
  static Future<List<Directory>?> getExternalStorageDirectories() async {
    if (!Platform.isAndroid) return null;
    return await getExternalStorageDirectories();
  }

  /// 获取应用外部缓存目录（仅Android）
  static Future<Directory?> getExternalCacheDirectory() async {
    if (!Platform.isAndroid) return null;
    return await getExternalCacheDirectory();
  }

  /// 创建目录
  static Future<Directory> createDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (await dir.exists()) return dir;
    return await dir.create(recursive: true);
  }

  /// 删除目录
  static Future<void> deleteDirectory(String dirPath, {bool recursive = true}) async {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: recursive);
    }
  }

  /// 创建文件
  static Future<File> createFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) return file;

    // 创建父目录
    final dir = Directory(path.dirname(filePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return await file.create(recursive: true);
  }

  /// 删除文件
  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 读取文件内容为字符串
  static Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }

  /// 读取文件内容为字节
  static Future<List<int>> readFileAsBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  /// 读取文件内容为行
  static Future<List<String>> readFileAsLines(String filePath) async {
    final file = File(filePath);
    return await file.readAsLines();
  }

  /// 写入字符串到文件
  static Future<File> writeStringToFile(String filePath, String content) async {
    final file = await createFile(filePath);
    return await file.writeAsString(content);
  }

  /// 写入字节到文件
  static Future<File> writeBytesToFile(String filePath, List<int> bytes) async {
    final file = await createFile(filePath);
    return await file.writeAsBytes(bytes);
  }

  /// 追加字符串到文件
  static Future<File> appendStringToFile(String filePath, String content) async {
    final file = await createFile(filePath);
    return await file.writeAsString(content, mode: FileMode.append);
  }

  /// 追加字节到文件
  static Future<File> appendBytesToFile(String filePath, List<int> bytes) async {
    final file = await createFile(filePath);
    return await file.writeAsBytes(bytes, mode: FileMode.append);
  }

  /// 复制文件
  static Future<File> copyFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    return await sourceFile.copy(targetPath);
  }

  /// 移动文件
  static Future<File> moveFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    return await sourceFile.rename(targetPath);
  }

  /// 获取文件大小
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  /// 获取文件最后修改时间
  static Future<DateTime> getFileLastModified(String filePath) async {
    final file = File(filePath);
    return await file.lastModified();
  }

  /// 检查文件是否存在
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// 检查目录是否存在
  static Future<bool> directoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    return await dir.exists();
  }

  /// 列出目录中的文件
  static Future<List<FileSystemEntity>> listFiles(String dirPath) async {
    final dir = Directory(dirPath);
    return await dir.list().toList();
  }

  /// 列出目录中的文件（递归）
  static Future<List<FileSystemEntity>> listFilesRecursive(String dirPath) async {
    final dir = Directory(dirPath);
    return await dir.list(recursive: true).toList();
  }

  /// 获取文件扩展名
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// 获取文件名（不包含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取文件名（包含扩展名）
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// 获取文件所在目录
  static String getFileDirectory(String filePath) {
    return path.dirname(filePath);
  }

  /// 读取JSON文件
  static Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    final content = await readFileAsString(filePath);
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// 写入JSON文件
  static Future<File> writeJsonFile(String filePath, Map<String, dynamic> json) async {
    final content = jsonEncode(json);
    return await writeStringToFile(filePath, content);
  }

  /// 获取目录大小
  static Future<int> getDirectorySize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    int size = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }

    return size;
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 创建临时文件
  static Future<File> createTempFile({String? prefix, String? suffix}) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${prefix ?? ''}${DateTime.now().millisecondsSinceEpoch}${suffix ?? ''}';
    return await createFile(path.join(tempDir.path, fileName));
  }

  /// 创建临时目录
  static Future<Directory> createTempDirectory({String? prefix}) async {
    final tempDir = await getTemporaryDirectory();
    final dirName = '${prefix ?? ''}${DateTime.now().millisecondsSinceEpoch}';
    return await createDirectory(path.join(tempDir.path, dirName));
  }

  /// 清空目录
  static Future<void> clearDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }
    }
  }
}
