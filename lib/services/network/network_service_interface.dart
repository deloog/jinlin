/// 网络连接类型
enum ConnectionType {
  none,
  wifi,
  mobile,
  ethernet,
  other,
}

/// 网络服务接口
///
/// 定义网络服务的方法
abstract class NetworkServiceInterface {
  /// 初始化网络服务
  Future<void> initialize();
  
  /// 检查网络连接
  Future<bool> checkConnection();
  
  /// 获取网络连接类型
  Future<ConnectionType> getConnectionType();
  
  /// 获取网络连接状态
  bool get isConnected;
  
  /// 获取网络连接类型
  ConnectionType get connectionType;
  
  /// 获取API服务器地址
  String get apiBaseUrl;
  
  /// 设置API服务器地址
  Future<void> setApiBaseUrl(String url);
  
  /// 获取网络延迟
  Future<Duration> getLatency();
  
  /// 获取网络统计信息
  Future<Map<String, dynamic>> getStats();
  
  /// 关闭网络服务
  Future<void> close();
  
  /// 添加网络状态变化监听器
  void addListener(void Function(bool isConnected, ConnectionType type) listener);
  
  /// 移除网络状态变化监听器
  void removeListener(void Function(bool isConnected, ConnectionType type) listener);
}
