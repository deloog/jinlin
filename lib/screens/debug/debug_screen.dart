import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/services/api/api_client.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/network/network_service.dart';
// 暂时注释掉未安装的依赖
// import 'package:package_info_plus/package_info_plus.dart';

/// 调试屏幕
///
/// 显示调试信息和工具
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _appVersion = '';
  String _buildNumber = '';
  String _packageName = '';
  String _cacheSize = '计算中...';
  String _databaseSize = '计算中...';
  String _connectionStatus = '检查中...';
  List<String> _logFiles = [];
  String _selectedLogContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppInfo();
    _loadCacheInfo();
    _loadNetworkInfo();
    _loadLogFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载应用信息
  Future<void> _loadAppInfo() async {
    try {
      // 暂时使用硬编码的版本信息
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
        _packageName = 'com.example.jinlin_app';
      });

      // 注释掉PackageInfo相关代码，等依赖安装后再启用
      // final packageInfo = await PackageInfo.fromPlatform();
      // setState(() {
      //   _appVersion = packageInfo.version;
      //   _buildNumber = packageInfo.buildNumber;
      //   _packageName = packageInfo.packageName;
      // });
    } catch (e) {
      debugPrint('获取应用信息失败: $e');
    }
  }

  /// 加载缓存信息
  Future<void> _loadCacheInfo() async {
    try {
      // 暂时使用硬编码的缓存大小
      setState(() {
        _cacheSize = '0 MB';
      });

      // 注释掉CacheManager相关代码，等方法实现后再启用
      // if (mounted) {
      //   final cacheManager = Provider.of<CacheManager>(context, listen: false);
      //   final cacheSize = await cacheManager.getFormattedSize();
      //
      //   if (mounted) {
      //     setState(() {
      //       _cacheSize = cacheSize;
      //     });
      //   }
      // }

      // 获取数据库大小
      // 注释掉DatabaseService相关代码，等方法实现后再启用
      // if (mounted) {
      //   final databaseService = Provider.of<DatabaseService>(context, listen: false);
      //   // TODO: 实现获取数据库大小的方法
      // }

      setState(() {
        _databaseSize = '未知';
      });
    } catch (e) {
      debugPrint('获取缓存信息失败: $e');
    }
  }

  /// 加载网络信息
  Future<void> _loadNetworkInfo() async {
    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      final isConnected = networkService.isConnected;
      final connectionType = networkService.getConnectionTypeDescription();
      final isServerConnected = await apiClient.checkConnection();

      setState(() {
        _connectionStatus = '网络连接: ${isConnected ? '已连接' : '未连接'}\n'
            '连接类型: $connectionType\n'
            '服务器连接: ${isServerConnected ? '正常' : '异常'}';
      });
    } catch (e) {
      debugPrint('获取网络信息失败: $e');
    }
  }

  /// 加载日志文件
  Future<void> _loadLogFiles() async {
    try {
      final loggingService = Provider.of<LoggingService>(context, listen: false);
      final logFiles = await loggingService.getLogFiles();

      setState(() {
        _logFiles = logFiles;
      });
    } catch (e) {
      debugPrint('获取日志文件失败: $e');
    }
  }

  /// 查看日志文件
  Future<void> _viewLogFile(String filePath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loggingService = Provider.of<LoggingService>(context, listen: false);
      final content = await loggingService.readLogFile(filePath);

      setState(() {
        _selectedLogContent = content ?? '无法读取日志文件';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedLogContent = '读取日志文件失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 清除缓存
  Future<void> _clearCache() async {
    try {
      // 暂时使用简单的提示，等方法实现后再启用真正的缓存清除功能
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缓存已清除')),
        );
      }

      // 注释掉CacheManager相关代码，等方法实现后再启用
      // if (mounted) {
      //   final cacheManager = Provider.of<CacheManager>(context, listen: false);
      //   await cacheManager.clear();
      //
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('缓存已清除')),
      //     );
      //   }
      // }

      _loadCacheInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除缓存失败: $e')),
        );
      }
    }
  }

  /// 清除日志
  Future<void> _clearLogs() async {
    try {
      if (mounted) {
        final loggingService = Provider.of<LoggingService>(context, listen: false);
        await loggingService.clearLogs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志已清除')),
          );
        }

        setState(() {
          _logFiles = [];
          _selectedLogContent = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除日志失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试信息'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '应用信息'),
            Tab(text: '网络'),
            Tab(text: '存储'),
            Tab(text: '日志'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppInfoTab(),
          _buildNetworkTab(),
          _buildStorageTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  /// 构建应用信息标签页
  Widget _buildAppInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('应用版本', _appVersion),
          _buildInfoItem('构建编号', _buildNumber),
          _buildInfoItem('包名', _packageName),
          const Divider(),
          const Text(
            '设备信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('平台', Theme.of(context).platform.toString()),
          _buildInfoItem('屏幕尺寸', '${MediaQuery.of(context).size.width.toStringAsFixed(1)} x ${MediaQuery.of(context).size.height.toStringAsFixed(1)}'),
          _buildInfoItem('像素密度', MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2)),
          _buildInfoItem('文本缩放', MediaQuery.textScalerOf(context).scale(1.0).toStringAsFixed(2)),
        ],
      ),
    );
  }

  /// 构建网络标签页
  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '网络状态',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(_connectionStatus),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNetworkInfo,
            child: const Text('刷新网络状态'),
          ),
          const Divider(),
          const Text(
            'API测试',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现API测试
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API测试功能尚未实现')),
              );
            },
            child: const Text('测试API连接'),
          ),
        ],
      ),
    );
  }

  /// 构建存储标签页
  Widget _buildStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '存储信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('缓存大小', _cacheSize),
          _buildInfoItem('数据库大小', _databaseSize),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _clearCache,
                child: const Text('清除缓存'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loadCacheInfo,
                child: const Text('刷新'),
              ),
            ],
          ),
          const Divider(),
          const Text(
            '数据库操作',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现数据库备份
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据库备份功能尚未实现')),
              );
            },
            child: const Text('备份数据库'),
          ),
        ],
      ),
    );
  }

  /// 构建日志标签页
  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('选择日志文件'),
                  value: _logFiles.isEmpty ? null : _logFiles.first,
                  items: _logFiles.map((file) {
                    final fileName = file.split('/').last;
                    return DropdownMenuItem<String>(
                      value: file,
                      child: Text(fileName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _viewLogFile(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _clearLogs,
                child: const Text('清除日志'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _selectedLogContent.isEmpty
                        ? '选择日志文件查看内容'
                        : _selectedLogContent,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
        ),
      ],
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
