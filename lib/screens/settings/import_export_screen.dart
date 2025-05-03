import 'package:flutter/material.dart';
import 'package:jinlin_app/generated/l10n.dart';
import 'package:jinlin_app/services/holiday_import_export_service.dart';
import 'package:jinlin_app/widgets/common/custom_app_bar.dart';
import 'package:jinlin_app/widgets/common/custom_card.dart';

/// 导入导出页面
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final HolidayImportExportService _importExportService = HolidayImportExportService();
  bool _isLoading = false;

  /// 导入节日数据
  Future<void> _importHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _importExportService.importFromJson(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      debugPrint('导入节日数据失败: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入节日数据失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 导出节日数据
  Future<void> _exportHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 显示地区选择对话框
      final regions = await _showRegionSelectionDialog();
      if (regions == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 暂时注释掉，等实现后再启用
      // final result = await _importExportService.exportToJson(context, regions: regions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出成功')),
        );
      }
    } catch (e) {
      debugPrint('导出节日数据失败: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出节日数据失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示地区选择对话框
  Future<List<String>?> _showRegionSelectionDialog() async {
    final selectedRegions = <String>[];
    final availableRegions = [
      {'code': 'ALL', 'name': '所有地区'},
      {'code': 'CN', 'name': '中国'},
      {'code': 'US', 'name': '美国'},
      {'code': 'JP', 'name': '日本'},
      {'code': 'KR', 'name': '韩国'},
      {'code': 'FR', 'name': '法国'},
      {'code': 'DE', 'name': '德国'},
    ];

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择要导出的地区'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableRegions.length,
              itemBuilder: (context, index) {
                final region = availableRegions[index];
                final isSelected = selectedRegions.contains(region['code']);

                return CheckboxListTile(
                  title: Text(region['name']!),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedRegions.add(region['code']!);
                      } else {
                        selectedRegions.remove(region['code']);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedRegions),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: s.importExport,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 节日数据卡片
              CustomCard(
                title: '节日数据',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload),
                      title: const Text('导入节日数据'),
                      subtitle: const Text('从JSON文件导入节日数据'),
                      onTap: _importHolidays,
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('导出节日数据'),
                      subtitle: const Text('将节日数据导出为JSON文件'),
                      onTap: _exportHolidays,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 联系人数据卡片
              CustomCard(
                title: '联系人数据',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload),
                      title: const Text('导入联系人数据'),
                      subtitle: const Text('从CSV文件导入联系人数据'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('导入联系人数据功能尚未实现')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('导出联系人数据'),
                      subtitle: const Text('将联系人数据导出为CSV文件'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('导出联系人数据功能尚未实现')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 提醒事件数据卡片
              CustomCard(
                title: '提醒事件数据',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload),
                      title: const Text('导入提醒事件数据'),
                      subtitle: const Text('从ICS文件导入提醒事件数据'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('导入提醒事件数据功能尚未实现')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('导出提醒事件数据'),
                      subtitle: const Text('将提醒事件数据导出为ICS文件'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('导出提醒事件数据功能尚未实现')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
