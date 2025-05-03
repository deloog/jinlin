/// 缓存服务接口
///
/// 定义缓存服务的方法
abstract class CacheServiceInterface {
  /// 初始化缓存服务
  Future<void> initialize();
  
  /// 获取缓存项
  Future<T?> get<T>(String key);
  
  /// 设置缓存项
  Future<void> set<T>(String key, T value, {Duration? expiry});
  
  /// 删除缓存项
  Future<void> remove(String key);
  
  /// 清空缓存
  Future<void> clear();
  
  /// 检查缓存项是否存在
  Future<bool> exists(String key);
  
  /// 获取缓存项的过期时间
  Future<DateTime?> getExpiry(String key);
  
  /// 设置缓存项的过期时间
  Future<void> setExpiry(String key, Duration expiry);
  
  /// 获取所有缓存键
  Future<List<String>> getKeys();
  
  /// 获取缓存大小
  Future<int> getSize();
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getStats();
  
  /// 关闭缓存服务
  Future<void> close();
}
