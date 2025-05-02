import 'package:flutter/material.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/models/unified/holiday.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 使用StatefulWidget来正确处理BuildContext
  runApp(const TestHolidaysApp());
}

class TestHolidaysApp extends StatelessWidget {
  const TestHolidaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestHolidaysScreen(),
    );
  }
}

class TestHolidaysScreen extends StatefulWidget {
  const TestHolidaysScreen({super.key});

  @override
  State<TestHolidaysScreen> createState() => _TestHolidaysScreenState();
}

class _TestHolidaysScreenState extends State<TestHolidaysScreen> {
  bool _isLoading = true;
  String _resultText = '';
  final StringBuffer _buffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    if (!mounted) return;

    // 使用统一的数据库管理服务
    final dbManager = DatabaseManagerUnified();

    try {
      // 初始化数据库
      await dbManager.initialize(context);

      // 获取所有节日
      final holidays = await dbManager.getAllHolidays();

      // 按地区分组
      final Map<String, List<Holiday>> holidaysByRegion = {};

      for (final holiday in holidays) {
        for (final region in holiday.regions) {
          if (!holidaysByRegion.containsKey(region)) {
            holidaysByRegion[region] = [];
          }
          holidaysByRegion[region]!.add(holiday);
        }
      }

      // 收集节日统计信息
      _buffer.writeln('总节日数量: ${holidays.length}');
      _buffer.writeln('地区分布:');
      holidaysByRegion.forEach((region, regionHolidays) {
        _buffer.writeln('  $region: ${regionHolidays.length}个节日');
      });

      // 收集节日类型统计
      final Map<HolidayType, int> holidaysByType = {};
      for (final holiday in holidays) {
        if (!holidaysByType.containsKey(holiday.type)) {
          holidaysByType[holiday.type] = 0;
        }
        holidaysByType[holiday.type] = holidaysByType[holiday.type]! + 1;
      }

      _buffer.writeln('节日类型分布:');
      holidaysByType.forEach((type, count) {
        _buffer.writeln('  $type: $count个节日');
      });

      // 收集语言支持统计
      final Map<String, int> holidaysByLanguage = {};
      for (final holiday in holidays) {
        for (final language in holiday.names.keys) {
          if (!holidaysByLanguage.containsKey(language)) {
            holidaysByLanguage[language] = 0;
          }
          holidaysByLanguage[language] = holidaysByLanguage[language]! + 1;
        }
      }

      _buffer.writeln('语言支持分布:');
      holidaysByLanguage.forEach((language, count) {
        _buffer.writeln('  $language: $count个节日');
      });

      // 更新UI
      if (mounted) {
        setState(() {
          _resultText = _buffer.toString();
          _isLoading = false;
        });
      }

      // 同时打印到控制台
      debugPrint(_buffer.toString());
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultText = '加载节日数据失败: $e';
          _isLoading = false;
        });
      }
      debugPrint('加载节日数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('节日数据测试'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(_resultText),
            ),
    );
  }
}
