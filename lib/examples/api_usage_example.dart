import 'package:flutter/material.dart';
import 'package:jinlin_app/services/api_service_provider.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/services/holiday_data_sync_service.dart';

/// API使用示例
///
/// 展示如何在应用程序中使用API服务
class ApiUsageExample extends StatefulWidget {
  const ApiUsageExample({Key? key}) : super(key: key);

  @override
  State<ApiUsageExample> createState() => _ApiUsageExampleState();
}

class _ApiUsageExampleState extends State<ApiUsageExample> {
  final _apiServiceProvider = ApiServiceProvider();
  late final HolidayDataSyncService _syncService;
  final _dbManager = DatabaseManagerUnified();

  bool _isLoading = false;
  String _statusMessage = '';
  bool _useMockData = false; // 默认使用真实服务器

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在初始化服务...';
    });

    try {
      // 初始化数据库
      await _dbManager.initialize(null, skipHolidayLoading: true);

      // 设置API服务提供者的模拟数据设置
      await _apiServiceProvider.setUseMock(_useMockData);

      // 创建同步服务
      _syncService = HolidayDataSyncService(
        _dbManager,
        _apiServiceProvider
      );

      setState(() {
        _isLoading = false;
        _statusMessage = '服务初始化完成，使用${_useMockData ? "模拟数据" : "真实服务器"}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '服务初始化失败: $e';
      });
    }
  }

  Future<void> _loadHolidayData(String regionCode, String languageCode) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在加载 $regionCode 地区的节日数据...';
    });

    try {
      await _syncService.initialLoadHolidayData(regionCode, languageCode);

      setState(() {
        _isLoading = false;
        _statusMessage = '$regionCode 地区节日数据加载完成';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '加载节日数据失败: $e';
      });
    }
  }

  Future<void> _syncHolidayData(String regionCode, String languageCode) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在同步 $regionCode 地区的节日数据...';
    });

    try {
      await _syncService.syncHolidayData(regionCode, languageCode);

      setState(() {
        _isLoading = false;
        _statusMessage = '$regionCode 地区节日数据同步完成';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '同步节日数据失败: $e';
      });
    }
  }

  // 切换数据源
  Future<void> _toggleDataSource() async {
    setState(() {
      _useMockData = !_useMockData;
      _isLoading = true;
      _statusMessage = '正在切换到${_useMockData ? "模拟数据" : "真实服务器"}...';
    });

    try {
      // 设置API服务提供者的模拟数据设置
      await _apiServiceProvider.setUseMock(_useMockData);

      // 重新创建同步服务
      _syncService = HolidayDataSyncService(
        _dbManager,
        _apiServiceProvider
      );

      setState(() {
        _isLoading = false;
        _statusMessage = '已切换到${_useMockData ? "模拟数据" : "真实服务器"}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '切换数据源失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API使用示例'),
        actions: [
          // 添加切换按钮
          IconButton(
            icon: Icon(_useMockData ? Icons.cloud_off : Icons.cloud),
            onPressed: _toggleDataSource,
            tooltip: _useMockData ? '切换到真实服务器' : '切换到模拟数据',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 数据源信息
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: _useMockData ? Colors.amber.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _useMockData ? Icons.cloud_off : Icons.cloud,
                              color: _useMockData ? Colors.amber.shade800 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '当前使用: ${_useMockData ? "模拟数据" : "真实服务器"}',
                              style: TextStyle(
                                color: _useMockData ? Colors.amber.shade800 : Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_statusMessage),
                      const SizedBox(height: 24),

                      // 加载数据部分
                      const Text(
                        '加载节日数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _loadHolidayData('CN', 'zh'),
                        child: const Text('加载中国节日数据'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _loadHolidayData('US', 'en'),
                        child: const Text('加载美国节日数据'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _loadHolidayData('GLOBAL', 'zh'),
                        child: const Text('加载全球节日数据'),
                      ),
                      const SizedBox(height: 24),

                      // 同步数据部分
                      const Text(
                        '同步节日数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _syncHolidayData('CN', 'zh'),
                        child: const Text('同步中国节日数据'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _syncHolidayData('US', 'en'),
                        child: const Text('同步美国节日数据'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _syncHolidayData('GLOBAL', 'zh'),
                        child: const Text('同步全球节日数据'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
