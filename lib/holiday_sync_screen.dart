// 文件： lib/holiday_sync_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HolidaySyncScreen extends StatefulWidget {
  const HolidaySyncScreen({super.key});

  @override
  State<HolidaySyncScreen> createState() => _HolidaySyncScreenState();
}

class _HolidaySyncScreenState extends State<HolidaySyncScreen> {
  bool _isLoading = false;
  String? _lastExportTime;

  @override
  void initState() {
    super.initState();
    _loadLastExportTime();
  }

  Future<void> _loadLastExportTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExportTime = prefs.getString('lastHolidayExportTime');

    if (mounted) {
      setState(() {
        _lastExportTime = lastExportTime;
      });
    }
  }

  Future<void> _saveLastExportTime() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timeString = formatter.format(now);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastHolidayExportTime', timeString);

    if (mounted) {
      setState(() {
        _lastExportTime = timeString;
      });
    }
  }

  // 导出节日数据
  Future<void> _exportHolidayData() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 获取所有节日
      final holidays = HiveDatabaseService.getAllHolidays();

      // 将节日转换为JSON
      final List<Map<String, dynamic>> holidaysJson = [];
      for (final holiday in holidays) {
        holidaysJson.add(holiday.toJson());
      }

      // 创建JSON字符串
      final jsonString = jsonEncode(holidaysJson);

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'holidays_${formatter.format(now)}.json';
      final filePath = '${directory.path}/$fileName';

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // 分享文件
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: l10n.exportHolidaysTitle,
      );

      // 保存最后导出时间
      await _saveLastExportTime();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 导入节日数据
  Future<void> _importHolidayData() async {
    final l10n = AppLocalizations.of(context);

    // 确认导入
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmImportTitle),
        content: Text(l10n.confirmImportMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.importButton),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      String jsonString;

      if (file.bytes != null) {
        // Web平台
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // 移动平台
        final fileObj = File(file.path!);
        jsonString = await fileObj.readAsString();
      } else {
        throw Exception('无法读取文件');
      }

      // 解析JSON
      final List<dynamic> holidaysJson = jsonDecode(jsonString);

      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 导入节日
      int importCount = 0;
      for (final holidayJson in holidaysJson) {
        final holiday = HolidayModel.fromJson(holidayJson);
        await HiveDatabaseService.saveHoliday(holiday);
        importCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importSuccess(importCount))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataSyncTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 导出卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.exportHolidaysTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isChinese
                                ? '将所有节日数据导出为JSON文件，可用于备份或分享'
                                : 'Export all holiday data as a JSON file for backup or sharing',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_lastExportTime != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.lastExportTime(_lastExportTime!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: Text(l10n.exportButton),
                              onPressed: _exportHolidayData,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 导入卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.importHolidaysTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isChinese
                                ? '从JSON文件导入节日数据，将覆盖现有数据'
                                : 'Import holiday data from a JSON file, will overwrite existing data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: Text(l10n.importButton),
                              onPressed: _importHolidayData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 警告信息
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.amber),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            isChinese
                                ? '导入操作将覆盖现有的节日数据，请确保已备份重要数据'
                                : 'Import operation will overwrite existing holiday data. Make sure you have backed up important data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
