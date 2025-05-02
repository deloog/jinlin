import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/providers/database_provider_enhanced.dart';
import 'package:jinlin_app/services/database/error/database_error_handler.dart';
import 'package:jinlin_app/services/database_manager_enhanced.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 数据库性能测试页面
///
/// 用于测试数据库性能和监控功能
class DatabasePerformancePage extends StatefulWidget {
  const DatabasePerformancePage({super.key});

  @override
  State<DatabasePerformancePage> createState() => DatabasePerformancePageState();
}

class DatabasePerformancePageState extends State<DatabasePerformancePage> {
  // 日志标签
  final String _tag = 'DatabasePerformancePage';

  // 日志记录器
  final logger = Logger();

  // 性能报告
  String _performanceReport = '尚未生成性能报告';

  // 错误报告
  String _errorReport = '尚未生成错误报告';

  // 是否正在测试
  bool _isTesting = false;

  // 测试结果
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    // 不在 initState 中启用数据库监控，因为 context 可能还没有准备好
    // 改为在 didChangeDependencies 中启用
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 启用数据库监控
    _enableMonitoring();
  }

  // 启用数据库监控
  void _enableMonitoring() {
    try {
      DatabaseProviderEnhanced.enableDatabaseMonitoring(context);
      logger.i(_tag, '数据库监控已启用');
    } catch (e) {
      logger.e(_tag, '启用数据库监控失败: $e');
    }
  }

  // 禁用数据库监控
  void _disableMonitoring() {
    try {
      DatabaseProviderEnhanced.disableDatabaseMonitoring(context);
      logger.i(_tag, '数据库监控已禁用');
    } catch (e) {
      logger.e(_tag, '禁用数据库监控失败: $e');
    }
  }

  // 获取性能报告
  void _getPerformanceReport() {
    try {
      final report = DatabaseProviderEnhanced.getDatabasePerformanceReport(context);
      setState(() {
        _performanceReport = report;
      });
      logger.i(_tag, '获取性能报告成功');
    } catch (e) {
      logger.e(_tag, '获取性能报告失败: $e');
    }
  }

  // 获取错误报告
  void _getErrorReport() {
    try {
      final report = DatabaseErrorHandler.getErrorReport();
      setState(() {
        _errorReport = report;
      });
      logger.i(_tag, '获取错误报告成功');
    } catch (e) {
      logger.e(_tag, '获取错误报告失败: $e');
    }
  }

  // 清除监控数据
  void _clearMonitoringData() {
    try {
      DatabaseProviderEnhanced.clearDatabaseMonitoringData(context);
      DatabaseErrorHandler.clearErrors();
      setState(() {
        _performanceReport = '监控数据已清除';
        _errorReport = '错误数据已清除';
      });
      logger.i(_tag, '监控数据已清除');
    } catch (e) {
      logger.e(_tag, '清除监控数据失败: $e');
    }
  }

  // 运行性能测试
  Future<void> _runPerformanceTest() async {
    setState(() {
      _isTesting = true;
      _testResult = '正在进行性能测试...';
    });

    try {
      // 清除监控数据
      DatabaseProviderEnhanced.clearDatabaseMonitoringData(context);
      DatabaseErrorHandler.clearErrors();

      // 获取数据库管理器
      final dbManager = Provider.of<DatabaseManagerEnhanced>(context, listen: false);
      final db = dbManager.getDatabase();

      // 记录测试开始时间
      final startTime = DateTime.now();

      // 测试1：获取所有节日
      await db.getAllHolidays();

      // 测试2：获取所有联系人
      await db.getAllContacts();

      // 测试3：获取所有提醒事件
      await db.getAllReminderEvents();

      // 测试4：获取即将到来的提醒事件
      await db.getUpcomingReminderEvents(30);

      // 测试5：获取已过期的提醒事件
      await db.getExpiredReminderEvents();

      // 测试6：搜索提醒事件
      await db.searchReminderEvents('测试');

      // 测试7：搜索节日
      await db.searchHolidays('节日');

      // 测试8：搜索联系人
      await db.searchContacts('联系人');

      // 记录测试结束时间
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // 更新测试结果
      setState(() {
        _testResult = '性能测试完成，耗时: ${duration.inMilliseconds} 毫秒';
      });

      // 获取性能报告
      _getPerformanceReport();

      // 获取错误报告
      _getErrorReport();
    } catch (e) {
      setState(() {
        _testResult = '性能测试失败: $e';
      });
      logger.e(_tag, '性能测试失败: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库性能测试'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 控制按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '数据库监控控制',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0, // 水平间距
                      runSpacing: 8.0, // 垂直间距
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _enableMonitoring,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('启用监控'),
                        ),
                        ElevatedButton(
                          onPressed: _disableMonitoring,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('禁用监控'),
                        ),
                        ElevatedButton(
                          onPressed: _clearMonitoringData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('清除数据'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 性能测试
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '性能测试',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _isTesting
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _runPerformanceTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('运行性能测试'),
                            ),
                    ),
                    if (_testResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _testResult,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 性能报告
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '性能报告',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _getPerformanceReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('刷新'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      _performanceReport,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 错误报告
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '错误报告',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _getErrorReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('刷新'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      _errorReport,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
