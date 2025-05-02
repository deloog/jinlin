import 'dart:collection';
import 'package:jinlin_app/utils/logger.dart';

/// 数据库监控类
///
/// 用于监控数据库性能，收集查询执行时间、缓存命中率等指标
class DatabaseMonitor {
  // 单例实例
  static final DatabaseMonitor _instance = DatabaseMonitor._internal();

  // 工厂构造函数
  factory DatabaseMonitor() => _instance;

  // 内部构造函数
  DatabaseMonitor._internal();

  // 日志标签
  final String _tag = 'DatabaseMonitor';

  // 日志记录器
  final logger = Logger();

  // 是否启用监控
  bool _enabled = false;

  // 查询执行时间记录
  final Map<String, List<int>> _queryExecutionTimes = {};

  // 缓存命中记录
  final Map<String, int> _cacheHits = {};

  // 缓存未命中记录
  final Map<String, int> _cacheMisses = {};

  // 查询计数
  final Map<String, int> _queryCount = {};

  // 最近的查询记录（最多保存100条）
  final Queue<Map<String, dynamic>> _recentQueries = Queue();

  // 最大记录数
  static const int _maxRecentQueries = 100;

  // 性能阈值（毫秒）
  static const int _performanceThreshold = 100;

  /// 启用监控
  void enable() {
    _enabled = true;
    logger.i(_tag, '数据库监控已启用');
  }

  /// 禁用监控
  void disable() {
    _enabled = false;
    logger.i(_tag, '数据库监控已禁用');
  }

  /// 清除所有监控数据
  void clear() {
    _queryExecutionTimes.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
    _queryCount.clear();
    _recentQueries.clear();
    logger.i(_tag, '数据库监控数据已清除');
  }

  /// 记录查询执行时间
  void recordQueryExecutionTime(String queryName, int executionTimeMs) {
    if (!_enabled) return;

    // 记录查询执行时间
    if (!_queryExecutionTimes.containsKey(queryName)) {
      _queryExecutionTimes[queryName] = [];
    }
    _queryExecutionTimes[queryName]!.add(executionTimeMs);

    // 记录查询计数
    _queryCount[queryName] = (_queryCount[queryName] ?? 0) + 1;

    // 记录最近的查询
    final queryInfo = {
      'name': queryName,
      'time': executionTimeMs,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _recentQueries.add(queryInfo);

    // 如果超过最大记录数，移除最早的记录
    if (_recentQueries.length > _maxRecentQueries) {
      _recentQueries.removeFirst();
    }

    // 如果执行时间超过阈值，记录警告日志
    if (executionTimeMs > _performanceThreshold) {
      logger.w(_tag, '查询执行时间过长: $queryName, ${executionTimeMs}ms');
    }
  }

  /// 记录缓存命中
  void recordCacheHit(String cacheName) {
    if (!_enabled) return;

    _cacheHits[cacheName] = (_cacheHits[cacheName] ?? 0) + 1;
  }

  /// 记录缓存未命中
  void recordCacheMiss(String cacheName) {
    if (!_enabled) return;

    _cacheMisses[cacheName] = (_cacheMisses[cacheName] ?? 0) + 1;
  }

  /// 获取查询执行时间统计
  Map<String, Map<String, dynamic>> getQueryExecutionTimeStats() {
    final stats = <String, Map<String, dynamic>>{};

    _queryExecutionTimes.forEach((queryName, times) {
      if (times.isEmpty) return;

      // 计算平均值
      final avg = times.reduce((a, b) => a + b) / times.length;

      // 计算最大值
      final max = times.reduce((a, b) => a > b ? a : b);

      // 计算最小值
      final min = times.reduce((a, b) => a < b ? a : b);

      // 计算中位数
      final sortedTimes = List<int>.from(times)..sort();
      final median = sortedTimes.length.isOdd
          ? sortedTimes[sortedTimes.length ~/ 2]
          : (sortedTimes[sortedTimes.length ~/ 2 - 1] + sortedTimes[sortedTimes.length ~/ 2]) / 2;

      // 计算95%分位数
      final p95Index = (sortedTimes.length * 0.95).floor();
      final p95 = sortedTimes[p95Index];

      stats[queryName] = {
        'count': times.length,
        'avg': avg,
        'max': max,
        'min': min,
        'median': median,
        'p95': p95,
      };
    });

    return stats;
  }

  /// 获取缓存命中率统计
  Map<String, Map<String, dynamic>> getCacheHitRateStats() {
    final stats = <String, Map<String, dynamic>>{};

    // 合并缓存命中和未命中的键
    final allCacheNames = <String>{};
    allCacheNames.addAll(_cacheHits.keys);
    allCacheNames.addAll(_cacheMisses.keys);

    for (final cacheName in allCacheNames) {
      final hits = _cacheHits[cacheName] ?? 0;
      final misses = _cacheMisses[cacheName] ?? 0;
      final total = hits + misses;

      if (total > 0) {
        final hitRate = hits / total;
        stats[cacheName] = {
          'hits': hits,
          'misses': misses,
          'total': total,
          'hitRate': hitRate,
        };
      }
    }

    return stats;
  }

  /// 获取最近的查询记录
  List<Map<String, dynamic>> getRecentQueries() {
    return List<Map<String, dynamic>>.from(_recentQueries.toList().reversed);
  }

  /// 获取查询计数统计
  Map<String, int> getQueryCountStats() {
    return Map<String, int>.from(_queryCount);
  }

  /// 获取性能报告
  String getPerformanceReport() {
    if (!_enabled) {
      return '数据库监控未启用';
    }

    final buffer = StringBuffer();
    buffer.writeln('数据库性能报告');
    buffer.writeln('=================');

    // 查询执行时间统计
    buffer.writeln('\n查询执行时间统计:');
    final timeStats = getQueryExecutionTimeStats();
    timeStats.forEach((queryName, stats) {
      buffer.writeln('  $queryName:');
      buffer.writeln('    次数: ${stats['count']}');
      buffer.writeln('    平均: ${stats['avg'].toStringAsFixed(2)}ms');
      buffer.writeln('    最大: ${stats['max']}ms');
      buffer.writeln('    最小: ${stats['min']}ms');
      buffer.writeln('    中位数: ${stats['median']}ms');
      buffer.writeln('    95%分位: ${stats['p95']}ms');
    });

    // 缓存命中率统计
    buffer.writeln('\n缓存命中率统计:');
    final cacheStats = getCacheHitRateStats();
    cacheStats.forEach((cacheName, stats) {
      buffer.writeln('  $cacheName:');
      buffer.writeln('    命中: ${stats['hits']}');
      buffer.writeln('    未命中: ${stats['misses']}');
      buffer.writeln('    总计: ${stats['total']}');
      buffer.writeln('    命中率: ${(stats['hitRate'] * 100).toStringAsFixed(2)}%');
    });

    // 查询计数统计
    buffer.writeln('\n查询计数统计:');
    final countStats = getQueryCountStats();
    final sortedQueries = countStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedQueries) {
      buffer.writeln('  ${entry.key}: ${entry.value}次');
    }

    return buffer.toString();
  }
}
