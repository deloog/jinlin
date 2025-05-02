import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jinlin_app/utils/logger.dart';

// 导入日志记录器
final logger = Logger();

/// 加密服务
///
/// 提供数据加密和解密功能
class EncryptionService {
  // 单例模式
  static final EncryptionService _instance = EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  EncryptionService._internal();

  // 日志标签
  static const String _tag = 'EncryptionService';

  // 安全存储
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 密钥存储键
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _encryptionIvKey = 'encryption_iv';

  // 加密器
  Encrypter? _encrypter;
  IV? _iv;

  // 是否已初始化
  bool _initialized = false;

  /// 初始化加密服务
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      logger.i(_tag, '初始化加密服务');

      // 获取或生成密钥
      final encryptionKey = await _getOrGenerateEncryptionKey();

      // 获取或生成IV
      final iv = await _getOrGenerateIV();

      // 创建加密器
      _encrypter = Encrypter(AES(encryptionKey));
      _iv = iv;

      _initialized = true;
      logger.i(_tag, '加密服务初始化成功');
    } catch (e, stackTrace) {
      logger.e(_tag, '初始化加密服务失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取或生成加密密钥
  Future<Key> _getOrGenerateEncryptionKey() async {
    try {
      // 尝试从安全存储中获取密钥
      String? storedKey = await _secureStorage.read(key: _encryptionKeyKey);

      if (storedKey != null) {
        logger.d(_tag, '从安全存储中获取密钥');
        return Key(base64.decode(storedKey));
      }

      // 生成新密钥
      logger.d(_tag, '生成新密钥');
      final key = Key.fromSecureRandom(32);

      // 存储密钥
      await _secureStorage.write(
        key: _encryptionKeyKey,
        value: base64.encode(key.bytes),
      );

      return key;
    } catch (e, stackTrace) {
      logger.e(_tag, '获取或生成加密密钥失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取或生成IV
  Future<IV> _getOrGenerateIV() async {
    try {
      // 尝试从安全存储中获取IV
      String? storedIV = await _secureStorage.read(key: _encryptionIvKey);

      if (storedIV != null) {
        logger.d(_tag, '从安全存储中获取IV');
        return IV(base64.decode(storedIV));
      }

      // 生成新IV
      logger.d(_tag, '生成新IV');
      final iv = IV.fromSecureRandom(16);

      // 存储IV
      await _secureStorage.write(
        key: _encryptionIvKey,
        value: base64.encode(iv.bytes),
      );

      return iv;
    } catch (e, stackTrace) {
      logger.e(_tag, '获取或生成IV失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_initialized || _encrypter == null || _iv == null) {
      throw Exception('加密服务未初始化');
    }
  }

  /// 加密字符串
  String encrypt(String plainText) {
    _checkInitialized();

    try {
      logger.d(_tag, '加密字符串');
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e, stackTrace) {
      logger.e(_tag, '加密字符串失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 解密字符串
  String decrypt(String encryptedText) {
    _checkInitialized();

    try {
      logger.d(_tag, '解密字符串');
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e, stackTrace) {
      logger.e(_tag, '解密字符串失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 加密Map
  String encryptMap(Map<String, dynamic> data) {
    _checkInitialized();

    try {
      logger.d(_tag, '加密Map');
      final jsonString = jsonEncode(data);
      return encrypt(jsonString);
    } catch (e, stackTrace) {
      logger.e(_tag, '加密Map失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 解密Map
  Map<String, dynamic> decryptMap(String encryptedText) {
    _checkInitialized();

    try {
      logger.d(_tag, '解密Map');
      final jsonString = decrypt(encryptedText);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      logger.e(_tag, '解密Map失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 加密List
  String encryptList(List<dynamic> data) {
    _checkInitialized();

    try {
      logger.d(_tag, '加密List');
      final jsonString = jsonEncode(data);
      return encrypt(jsonString);
    } catch (e, stackTrace) {
      logger.e(_tag, '加密List失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 解密List
  List<dynamic> decryptList(String encryptedText) {
    _checkInitialized();

    try {
      logger.d(_tag, '解密List');
      final jsonString = decrypt(encryptedText);
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e, stackTrace) {
      logger.e(_tag, '解密List失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 计算哈希值
  String hash(String data) {
    try {
      logger.d(_tag, '计算哈希值');
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      logger.e(_tag, '计算哈希值失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 重置加密服务
  Future<void> reset() async {
    try {
      logger.i(_tag, '重置加密服务');

      // 删除存储的密钥和IV
      await _secureStorage.delete(key: _encryptionKeyKey);
      await _secureStorage.delete(key: _encryptionIvKey);

      // 重置加密器
      _encrypter = null;
      _iv = null;
      _initialized = false;

      // 重新初始化
      await initialize();

      logger.i(_tag, '加密服务重置成功');
    } catch (e, stackTrace) {
      logger.e(_tag, '重置加密服务失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 全局加密服务实例
final encryptionService = EncryptionService();
