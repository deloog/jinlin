import 'package:flutter/material.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/tools/holiday_data_importer.dart';

/// 节日数据导入运行器
///
/// 用于运行节日数据导入工具
class HolidayDataImportRunner extends StatefulWidget {
  const HolidayDataImportRunner({super.key});

  @override
  State<HolidayDataImportRunner> createState() => _HolidayDataImportRunnerState();
}

class _HolidayDataImportRunnerState extends State<HolidayDataImportRunner> {
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();
  late HolidayDataImporter _importer;

  bool _isLoading = false;
  String _statusMessage = '准备导入节日数据';
  final List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _importer = HolidayDataImporter(_dbManager);
  }

  Future<void> _importFranceHolidays() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在导入法国节日数据...';
      _logMessages.add('开始导入法国节日数据');
    });

    try {
      await _importer.importFranceHolidays(context);
      setState(() {
        _logMessages.add('法国节日数据导入成功');
      });
    } catch (e) {
      setState(() {
        _logMessages.add('法国节日数据导入失败: $e');
      });
    }

    setState(() {
      _isLoading = false;
      _statusMessage = '法国节日数据导入完成';
    });
  }

  Future<void> _importGermanyHolidays() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在导入德国节日数据...';
      _logMessages.add('开始导入德国节日数据');
    });

    try {
      await _importer.importGermanyHolidays(context);
      setState(() {
        _logMessages.add('德国节日数据导入成功');
      });
    } catch (e) {
      setState(() {
        _logMessages.add('德国节日数据导入失败: $e');
      });
    }

    setState(() {
      _isLoading = false;
      _statusMessage = '德国节日数据导入完成';
    });
  }

  Future<void> _importUKHolidays() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在导入英国节日数据...';
      _logMessages.add('开始导入英国节日数据');
    });

    try {
      await _importer.importUKHolidays(context);
      setState(() {
        _logMessages.add('英国节日数据导入成功');
      });
    } catch (e) {
      setState(() {
        _logMessages.add('英国节日数据导入失败: $e');
      });
    }

    setState(() {
      _isLoading = false;
      _statusMessage = '英国节日数据导入完成';
    });
  }

  Future<void> _checkHolidaysCount() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在查询节日数量...';
    });

    try {
      await _dbManager.initialize(context);
      final holidays = await _dbManager.getAllHolidays();

      // 按地区分组
      final Map<String, List<String>> holidaysByRegion = {};

      for (final holiday in holidays) {
        for (final region in holiday.regions) {
          if (!holidaysByRegion.containsKey(region)) {
            holidaysByRegion[region] = [];
          }
          holidaysByRegion[region]!.add(holiday.id);
        }
      }

      setState(() {
        _logMessages.add('总节日数量: ${holidays.length}');
        _logMessages.add('地区分布:');
        holidaysByRegion.forEach((region, regionHolidays) {
          _logMessages.add('  $region: ${regionHolidays.length}个节日');
        });
      });
    } catch (e) {
      setState(() {
        _logMessages.add('查询节日数量失败: $e');
      });
    }

    setState(() {
      _isLoading = false;
      _statusMessage = '查询节日数量完成';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('节日数据导入工具'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _importFranceHolidays,
                  child: const Text('导入法国节日'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _importGermanyHolidays,
                  child: const Text('导入德国节日'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _importUKHolidays,
                  child: const Text('导入英国节日'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkHolidaysCount,
                  child: const Text('查询节日数量'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              '日志:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _logMessages.length,
                itemBuilder: (context, index) {
                  return Text(_logMessages[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
