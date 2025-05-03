// 文件： lib/services/holiday_import_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';

/// 节日数据导入导出服务
///
/// 负责节日数据的导入和导出功能
class HolidayImportExportService {
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();

  /// 从JSON文件导入节日数据
  Future<ImportResult> importFromJson(BuildContext context) async {
    try {
      // 初始化数据库
      await _dbManager.initialize(context);

      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: '未选择文件',
          importedCount: 0,
          failedCount: 0,
        );
      }

      // 读取文件内容
      final file = result.files.first;
      String jsonString;

      if (file.bytes != null) {
        // Web平台
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // 移动平台和桌面平台
        final fileObj = File(file.path!);
        jsonString = await fileObj.readAsString();
      } else {
        return ImportResult(
          success: false,
          message: '无法读取文件',
          importedCount: 0,
          failedCount: 0,
        );
      }

      // 解析JSON
      final jsonData = json.decode(jsonString);

      if (!jsonData.containsKey('holidays') || jsonData['holidays'] is! List) {
        return ImportResult(
          success: false,
          message: '无效的JSON格式，缺少holidays数组',
          importedCount: 0,
          failedCount: 0,
        );
      }

      // 解析节日数据
      final List<dynamic> holidaysJson = jsonData['holidays'];
      final List<Holiday> holidays = [];
      int failedCount = 0;

      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
        } catch (e) {
          debugPrint('解析节日数据失败: $e');
          failedCount++;
        }
      }

      // 保存到数据库
      int importedCount = 0;
      for (final holiday in holidays) {
        try {
          await _dbManager.saveHoliday(holiday);
          importedCount++;
        } catch (e) {
          debugPrint('保存节日数据失败: $e');
          failedCount++;
        }
      }

      return ImportResult(
        success: true,
        message: '成功导入 $importedCount 个节日，失败 $failedCount 个',
        importedCount: importedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      debugPrint('导入节日数据失败: $e');
      return ImportResult(
        success: false,
        message: '导入失败: $e',
        importedCount: 0,
        failedCount: 0,
      );
    }
  }

  /// 导出节日数据到JSON文件
  Future<ExportResult> exportToJson(BuildContext context, {List<String>? regions}) async {
    try {
      // 初始化数据库
      await _dbManager.initialize(context);

      // 获取节日数据
      List<Holiday> holidays;
      if (regions != null && regions.isNotEmpty) {
        // 按地区筛选节日
        final allHolidays = await _dbManager.getAllHolidays();
        holidays = allHolidays.where((holiday) {
          return holiday.regions.any((region) => regions.contains(region));
        }).toList();
      } else {
        holidays = await _dbManager.getAllHolidays();
      }

      if (holidays.isEmpty) {
        return ExportResult(
          success: false,
          message: '没有可导出的节日数据',
          exportedCount: 0,
        );
      }

      // 转换为JSON
      final List<Map<String, dynamic>> holidaysJson = holidays.map((holiday) => _holidayToJson(holiday)).toList();
      final Map<String, dynamic> jsonData = {
        'holidays': holidaysJson,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = json.encode(jsonData);

      // 保存文件
      final fileName = 'holidays_export_${DateTime.now().millisecondsSinceEpoch}.json';

      if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台：使用Share功能
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '节日数据导出',
        );
      } else {
        // 桌面平台：使用FilePicker保存
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '保存节日数据',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);
        } else {
          return ExportResult(
            success: false,
            message: '用户取消了保存操作',
            exportedCount: 0,
          );
        }
      }

      return ExportResult(
        success: true,
        message: '成功导出 ${holidays.length} 个节日',
        exportedCount: holidays.length,
      );
    } catch (e) {
      debugPrint('导出节日数据失败: $e');
      return ExportResult(
        success: false,
        message: '导出失败: $e',
        exportedCount: 0,
      );
    }
  }

  /// 解析节日JSON数据
  Holiday _parseHolidayJson(Map<String, dynamic> json) {
    // 解析多语言名称
    final Map<String, String> names = {};
    (json['names'] as Map<String, dynamic>).forEach((key, value) {
      names[key] = value.toString();
    });

    // 解析多语言描述
    final Map<String, String>? descriptions = json['descriptions'] != null
        ? (json['descriptions'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言习俗
    final Map<String, String>? customs = json['customs'] != null
        ? (json['customs'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言食物
    final Map<String, String>? foods = json['foods'] != null
        ? (json['foods'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言祝福语
    final Map<String, String>? greetings = json['greetings'] != null
        ? (json['greetings'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言活动
    final Map<String, String>? activities = json['activities'] != null
        ? (json['activities'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 解析多语言历史
    final Map<String, String>? history = json['history'] != null
        ? (json['history'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()))
        : null;

    // 创建节日对象
    return Holiday(
      id: json['id'],
      isSystemHoliday: json['isSystemHoliday'] ?? true,
      names: names,
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculationType']),
      calculationRule: json['calculationRule'],
      descriptions: descriptions,
      importanceLevel: _parseImportanceLevel(json['importanceLevel']),
      customs: customs,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
      userImportance: json['userImportance'] ?? 0,
    );
  }

  /// 解析节日类型
  HolidayType _parseHolidayType(String type) {
    switch (type) {
      case 'statutory':
        return HolidayType.statutory;
      case 'traditional':
        return HolidayType.traditional;
      case 'memorial':
        return HolidayType.memorial;
      case 'religious':
        return HolidayType.religious;
      case 'professional':
        return HolidayType.professional;
      case 'international':
        return HolidayType.international;
      case 'solarTerm':
        return HolidayType.solarTerm;
      case 'custom':
        return HolidayType.custom;
      case 'cultural':
        return HolidayType.cultural;
      default:
        return HolidayType.other;
    }
  }

  /// 解析日期计算类型
  DateCalculationType _parseCalculationType(String type) {
    switch (type) {
      case 'fixedGregorian':
        return DateCalculationType.fixedGregorian;
      case 'fixedLunar':
        return DateCalculationType.fixedLunar;
      case 'variableRule':
        return DateCalculationType.variableRule;
      case 'custom':
        return DateCalculationType.custom;
      default:
        return DateCalculationType.fixedGregorian;
    }
  }

  /// 解析重要性级别
  ImportanceLevel _parseImportanceLevel(String level) {
    switch (level) {
      case 'high':
        return ImportanceLevel.high;
      case 'medium':
        return ImportanceLevel.medium;
      case 'low':
        return ImportanceLevel.low;
      default:
        return ImportanceLevel.medium;
    }
  }

  /// 将Holiday对象转换为JSON
  Map<String, dynamic> _holidayToJson(Holiday holiday) {
    return {
      'id': holiday.id,
      'isSystemHoliday': holiday.isSystemHoliday,
      'names': holiday.names,
      'type': _holidayTypeToString(holiday.type),
      'regions': holiday.regions,
      'calculationType': _calculationTypeToString(holiday.calculationType),
      'calculationRule': holiday.calculationRule,
      'descriptions': holiday.descriptions,
      'importanceLevel': _importanceLevelToString(holiday.importanceLevel),
      'customs': holiday.customs,
      'foods': holiday.foods,
      'greetings': holiday.greetings,
      'activities': holiday.activities,
      'history': holiday.history,
      'userImportance': holiday.userImportance,
    };
  }

  /// 将节日类型转换为字符串
  String _holidayTypeToString(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return 'statutory';
      case HolidayType.traditional:
        return 'traditional';
      case HolidayType.memorial:
        return 'memorial';
      case HolidayType.religious:
        return 'religious';
      case HolidayType.professional:
        return 'professional';
      case HolidayType.international:
        return 'international';
      case HolidayType.solarTerm:
        return 'solarTerm';
      case HolidayType.custom:
        return 'custom';
      case HolidayType.cultural:
        return 'cultural';
      case HolidayType.other:
        return 'other';
    }
  }

  /// 将日期计算类型转换为字符串
  String _calculationTypeToString(DateCalculationType type) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        return 'fixedGregorian';
      case DateCalculationType.fixedLunar:
        return 'fixedLunar';
      case DateCalculationType.variableRule:
        return 'variableRule';
      case DateCalculationType.custom:
        return 'custom';
    }
  }

  /// 将重要性级别转换为字符串
  String _importanceLevelToString(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.high:
        return 'high';
      case ImportanceLevel.medium:
        return 'medium';
      case ImportanceLevel.low:
        return 'low';
    }
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int failedCount;

  ImportResult({
    required this.success,
    required this.message,
    required this.importedCount,
    required this.failedCount,
  });
}

/// 导出结果
class ExportResult {
  final bool success;
  final String message;
  final int exportedCount;

  ExportResult({
    required this.success,
    required this.message,
    required this.exportedCount,
  });
}
