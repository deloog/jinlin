import 'package:jinlin_app/utils/logger.dart';

/// 缓存项
class CacheItem<T> {
  /// 缓存数据
  final T data;

  /// 过期时间
  final DateTime expireTime;

  /// 最后访问时间
  DateTime lastAccessTime;

  /// 访问次数
  int accessCount;

  /// 构造函数
  CacheItem({
    required this.data,
    required this.expireTime,
  }) : lastAccessTime = DateTime.now(),
       accessCount = 0;

  /// 是否已过期
  bool get isExpired => DateTime.now().isAfter(expireTime);

  /// 访问缓存项
  T access() {
    lastAccessTime = DateTime.now();
    accessCount++;
    return data;
  }
}

/// 缓存策略
enum CacheStrategy {
  /// 最近最少使用
  leastRecentlyUsed,

  /// 最少使用
  leastFrequentlyUsed,

  /// 先进先出
  firstInFirstOut,
}

/// 缓存管理器
///
/// 提供内存缓存功能，支持不同的缓存策略和过期时间
class CacheManager {
  // 单例模式
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  // 日志标签
  static const String _tag = 'CacheManager';

  // 缓存数据
  final Map<String, Map<String, CacheItem>> _caches = {};

  // 缓存创建时间
  final Map<String, DateTime> _cacheCreationTimes = {};

  // 缓存访问次数
  final Map<String, int> _cacheAccessCounts = {};

  // 缓存容量
  final Map<String, int> _cacheCapacities = {};

  // 缓存策略
  final Map<String, CacheStrategy> _cacheStrategies = {};

  // 默认过期时间（毫秒）
  static const int _defaultExpireTime = 5 * 60 * 1000; // 5分钟

  // 默认缓存容量
  static const int _defaultCapacity = 100;

  // 默认缓存策略
  static const CacheStrategy _defaultStrategy = CacheStrategy.leastRecentlyUsed;

  /// 创建缓存
  void createCache(
    String cacheName, {
    int? capacity,
    CacheStrategy? strategy,
  }) {
    if (_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 已存在');
      return;
    }

    _caches[cacheName] = {};
    _cacheCreationTimes[cacheName] = DateTime.now();
    _cacheAccessCounts[cacheName] = 0;
    _cacheCapacities[cacheName] = capacity ?? _defaultCapacity;
    _cacheStrategies[cacheName] = strategy ?? _defaultStrategy;

    logger.i(_tag, '创建缓存 $cacheName (容量: ${_cacheCapacities[cacheName]}, 策略: ${_cacheStrategies[cacheName]})');
  }

  /// 删除缓存
  void removeCache(String cacheName) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      return;
    }

    _caches.remove(cacheName);
    _cacheCreationTimes.remove(cacheName);
    _cacheAccessCounts.remove(cacheName);
    _cacheCapacities.remove(cacheName);
    _cacheStrategies.remove(cacheName);

    logger.i(_tag, '删除缓存 $cacheName');
  }

  /// 清空缓存
  void clearCache(String cacheName) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      return;
    }

    _caches[cacheName]?.clear();
    _cacheAccessCounts[cacheName] = 0;

    logger.i(_tag, '清空缓存 $cacheName');
  }

  /// 清空所有缓存
  void clearAllCaches() {
    for (final cacheName in _caches.keys) {
      clearCache(cacheName);
    }

    logger.i(_tag, '清空所有缓存');
  }

  /// 获取缓存项
  T? get<T>(String cacheName, String key) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      return null;
    }

    final cache = _caches[cacheName]!;
    final cacheItem = cache[key];

    if (cacheItem == null) {
      logger.d(_tag, '缓存未命中: $cacheName/$key');
      return null;
    }

    if (cacheItem.isExpired) {
      logger.d(_tag, '缓存已过期: $cacheName/$key');
      cache.remove(key);
      return null;
    }

    _cacheAccessCounts[cacheName] = (_cacheAccessCounts[cacheName] ?? 0) + 1;

    logger.d(_tag, '缓存命中: $cacheName/$key');
    return cacheItem.access() as T?;
  }

  /// 设置缓存项
  void set<T>(String cacheName, String key, T value, {int? expireTimeMs}) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      createCache(cacheName);
    }

    final cache = _caches[cacheName]!;
    final capacity = _cacheCapacities[cacheName] ?? _defaultCapacity;

    // 如果缓存已满，需要根据策略移除一些缓存项
    if (cache.length >= capacity && !cache.containsKey(key)) {
      _evictCache(cacheName);
    }

    // 计算过期时间
    final expireTime = DateTime.now().add(
      Duration(milliseconds: expireTimeMs ?? _defaultExpireTime)
    );

    // 创建缓存项
    final cacheItem = CacheItem<T>(
      data: value,
      expireTime: expireTime,
    );

    // 添加到缓存
    cache[key] = cacheItem;

    logger.d(_tag, '设置缓存: $cacheName/$key (过期时间: $expireTime)');
  }

  /// 移除缓存项
  void remove(String cacheName, String key) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      return;
    }

    final cache = _caches[cacheName]!;

    if (cache.containsKey(key)) {
      cache.remove(key);
      logger.d(_tag, '移除缓存项: $cacheName/$key');
    }
  }

  /// 缓存项是否存在
  bool contains(String cacheName, String key) {
    if (!_caches.containsKey(cacheName)) {
      return false;
    }

    final cache = _caches[cacheName]!;
    final cacheItem = cache[key];

    if (cacheItem == null) {
      return false;
    }

    if (cacheItem.isExpired) {
      cache.remove(key);
      return false;
    }

    return true;
  }

  /// 获取JSON缓存
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final data = get<Map<String, dynamic>>('json_cache', key);
      return data;
    } catch (e) {
      logger.e(_tag, '获取JSON缓存失败: $e');
      return null;
    }
  }

  /// 设置JSON缓存
  Future<void> setJson(String key, Map<String, dynamic> value, {int? expireTimeMs}) async {
    try {
      set<Map<String, dynamic>>('json_cache', key, value, expireTimeMs: expireTimeMs);
    } catch (e) {
      logger.e(_tag, '设置JSON缓存失败: $e');
    }
  }

  /// 获取缓存大小
  int size(String cacheName) {
    if (!_caches.containsKey(cacheName)) {
      return 0;
    }

    return _caches[cacheName]!.length;
  }

  /// 获取缓存容量
  int capacity(String cacheName) {
    return _cacheCapacities[cacheName] ?? _defaultCapacity;
  }

  /// 设置缓存容量
  void setCapacity(String cacheName, int capacity) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      createCache(cacheName, capacity: capacity);
      return;
    }

    _cacheCapacities[cacheName] = capacity;

    // 如果当前缓存大小超过新容量，需要移除一些缓存项
    final cache = _caches[cacheName]!;
    while (cache.length > capacity) {
      _evictCache(cacheName);
    }

    logger.i(_tag, '设置缓存容量: $cacheName -> $capacity');
  }

  /// 设置缓存策略
  void setStrategy(String cacheName, CacheStrategy strategy) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      createCache(cacheName, strategy: strategy);
      return;
    }

    _cacheStrategies[cacheName] = strategy;

    logger.i(_tag, '设置缓存策略: $cacheName -> $strategy');
  }

  /// 清理过期缓存
  void cleanExpiredCache(String cacheName) {
    if (!_caches.containsKey(cacheName)) {
      logger.w(_tag, '缓存 $cacheName 不存在');
      return;
    }

    final cache = _caches[cacheName]!;
    final expiredKeys = <String>[];

    // 找出所有过期的缓存项
    for (final entry in cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    // 移除过期的缓存项
    for (final key in expiredKeys) {
      cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      logger.d(_tag, '清理过期缓存: $cacheName (${expiredKeys.length} 项)');
    }
  }

  /// 清理所有过期缓存
  void cleanAllExpiredCaches() {
    for (final cacheName in _caches.keys) {
      cleanExpiredCache(cacheName);
    }
  }

  /// 根据策略移除缓存项
  void _evictCache(String cacheName) {
    final cache = _caches[cacheName]!;
    final strategy = _cacheStrategies[cacheName] ?? _defaultStrategy;

    if (cache.isEmpty) {
      return;
    }

    String? keyToRemove;

    switch (strategy) {
      case CacheStrategy.leastRecentlyUsed:
        // 找出最近最少使用的缓存项
        DateTime? oldestAccessTime;
        for (final entry in cache.entries) {
          if (oldestAccessTime == null || entry.value.lastAccessTime.isBefore(oldestAccessTime)) {
            oldestAccessTime = entry.value.lastAccessTime;
            keyToRemove = entry.key;
          }
        }
        break;

      case CacheStrategy.leastFrequentlyUsed:
        // 找出最少使用的缓存项
        int? lowestAccessCount;
        for (final entry in cache.entries) {
          if (lowestAccessCount == null || entry.value.accessCount < lowestAccessCount) {
            lowestAccessCount = entry.value.accessCount;
            keyToRemove = entry.key;
          }
        }
        break;

      case CacheStrategy.firstInFirstOut:
        // 找出最早添加的缓存项（简单实现，使用Map的第一个键）
        keyToRemove = cache.keys.first;
        break;
    }

    if (keyToRemove != null) {
      cache.remove(keyToRemove);
      logger.d(_tag, '移除缓存项 (策略: $strategy): $cacheName/$keyToRemove');
    }
  }
}

/// 全局缓存管理器实例
final cacheManager = CacheManager();
