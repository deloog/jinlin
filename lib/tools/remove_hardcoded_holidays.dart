// 文件： lib/tools/remove_hardcoded_holidays.dart
import 'dart:io';
import 'package:path/path.dart' as path;

/// 硬编码节日数据清理工具
///
/// 此工具用于检测和清理项目中的硬编码节日数据，
/// 确保所有节日数据都通过数据库和JSON文件管理。
void main(List<String> args) async {
  // 检查命令行参数
  final bool dryRun = args.contains('--dry-run');
  // verbose参数目前未使用，但保留在帮助信息中
  final bool help = args.contains('--help') || args.contains('-h');

  if (help) {
    printUsage();
    return;
  }

  print('=== 硬编码节日数据清理工具 ===');
  if (dryRun) {
    print('运行模式: 干运行（不会修改任何文件）');
  } else {
    print('运行模式: 实际运行（将修改文件）');
    print('警告: 此操作将修改源代码文件，请确保已备份！');
    print('按 Enter 键继续，或按 Ctrl+C 取消...');
    stdin.readLineSync();
  }

  // 获取项目根目录
  final projectDir = Directory.current;
  print('项目目录: ${projectDir.path}');

  // 需要检查的文件列表
  final filesToCheck = [
    'lib/data/global_holidays.dart',
    'lib/services/holiday_init_service.dart',
    'lib/services/holiday_init_service_unified.dart',
    'lib/services/database_init_service_enhanced.dart',
    'lib/services/holiday_migration_service.dart',
    'lib/data/holidays/france_holidays.dart',
    'lib/tools/holiday_data_importer.dart',
  ];

  // 检查每个文件
  for (final filePath in filesToCheck) {
    final file = File(path.join(projectDir.path, filePath));
    if (!file.existsSync()) {
      print('文件不存在: $filePath');
      continue;
    }

    print('检查文件: $filePath');
    final content = await file.readAsString();

    // 检查是否包含硬编码节日数据
    final containsHardcodedHolidays = _checkForHardcodedHolidays(content);
    if (containsHardcodedHolidays) {
      print('  发现硬编码节日数据');

      if (!dryRun) {
        // 修改文件内容
        final newContent = _replaceHardcodedHolidays(content, filePath);
        if (newContent != content) {
          await file.writeAsString(newContent);
          print('  已修改文件');
        } else {
          print('  无需修改文件');
        }
      }
    } else {
      print('  未发现硬编码节日数据');
    }
  }

  print('=== 清理完成 ===');
  if (dryRun) {
    print('这是干运行，未修改任何文件');
  } else {
    print('已修改文件，请检查修改是否正确');
  }
}

/// 打印使用说明
void printUsage() {
  print('=== 硬编码节日数据清理工具 ===');
  print('用法: dart run lib/tools/remove_hardcoded_holidays.dart [选项]');
  print('');
  print('选项:');
  print('  --dry-run    干运行模式，不会修改任何文件');
  print('  --verbose    详细输出模式');
  print('  --help, -h   显示此帮助信息');
}

/// 检查文件内容是否包含硬编码节日数据
bool _checkForHardcodedHolidays(String content) {
  // 检查常见的硬编码节日数据模式
  final patterns = [
    'HolidayModel\\(\\s*id:\\s*[\'"]',
    'Holiday\\(\\s*id:\\s*[\'"]',
    'SpecialDate\\(\\s*id:\\s*[\'"]',
    'getGlobalHolidays\\(\\)',
    '_getGlobalHolidays\\(\\)',
    '_getRegionHolidays\\(',
    '_getChineseHolidays\\(\\)',
    '_getUSHolidays\\(\\)',
    '_getJapaneseHolidays\\(\\)',
    '_getKoreanHolidays\\(\\)',
    '_getFrenchHolidays\\(\\)',
    '_getGermanHolidays\\(\\)'
  ];

  for (final pattern in patterns) {
    final regex = RegExp(pattern);
    if (regex.hasMatch(content)) {
      return true;
    }
  }

  return false;
}

/// 替换硬编码节日数据
String _replaceHardcodedHolidays(String content, String filePath) {
  String newContent = content;

  // 根据文件路径选择不同的替换策略
  if (filePath.contains('global_holidays.dart')) {
    // 替换GlobalHolidays类的实现
    newContent = _replaceGlobalHolidaysImplementation(content);
  } else if (filePath.contains('holiday_init_service_unified.dart')) {
    // 替换HolidayInitServiceUnified类中的硬编码节日数据
    newContent = _replaceHolidayInitServiceUnifiedImplementation(content);
  } else if (filePath.contains('holiday_init_service.dart')) {
    // 替换HolidayInitService类中的硬编码节日数据
    newContent = _replaceHolidayInitServiceImplementation(content);
  } else if (filePath.contains('database_init_service_enhanced.dart')) {
    // 替换DatabaseInitServiceEnhanced类中的硬编码节日数据
    newContent = _replaceDatabaseInitServiceEnhancedImplementation(content);
  } else if (filePath.contains('holiday_migration_service.dart')) {
    // 替换HolidayMigrationService类中的硬编码节日数据
    newContent = _replaceHolidayMigrationServiceImplementation(content);
  } else if (filePath.contains('france_holidays.dart')) {
    // 替换FranceHolidays类中的硬编码节日数据
    newContent = _replaceFranceHolidaysImplementation(content);
  } else if (filePath.contains('holiday_data_importer.dart')) {
    // 替换HolidayDataImporter类中的硬编码节日数据
    newContent = _replaceHolidayDataImporterImplementation(content);
  }

  return newContent;
}

/// 替换GlobalHolidays类的实现
String _replaceGlobalHolidaysImplementation(String content) {
  // 替换为使用JSON文件的实现
  const newImplementation = '''
// 文件： lib/data/global_holidays.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/holiday_model.dart';

/// 全球重要节日数据
///
/// 包含全球性重要节日，这些节日在大多数国家/地区都有庆祝或认可
/// 注意：此类现在从JSON文件加载数据，不再使用硬编码数据
class GlobalHolidays {

  /// 获取全球重要节日列表
  static Future<List<HolidayModel>> getGlobalHolidays() async {
    try {
      // 从JSON文件加载节日数据
      final jsonString = await rootBundle.loadString('assets/data/preset_holidays.json');
      final jsonData = json.decode(jsonString);

      // 解析全球节日数据
      final List<dynamic> holidaysJson = jsonData['global_holidays'];
      final List<HolidayModel> holidays = [];

      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
        } catch (e) {
          debugPrint('解析节日数据失败: \$e');
        }
      }

      debugPrint('从JSON文件加载了 \${holidays.length} 个全球节日');
      return holidays;
    } catch (e) {
      debugPrint('加载全球节日数据失败: \$e');
      return [];
    }
  }

  /// 解析节日JSON数据
  static HolidayModel _parseHolidayJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'],
      name: json['names']['zh'],
      nameEn: json['names']['en'],
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculation_type']),
      calculationRule: json['calculation_rule'],
      description: json['descriptions']?['zh'],
      descriptionEn: json['descriptions']?['en'],
      importanceLevel: _parseImportanceLevel(json['importance_level']),
      userImportance: 0,
    );
  }

  /// 解析节日类型
  static HolidayType _parseHolidayType(String type) {
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
      default:
        return HolidayType.other;
    }
  }

  /// 解析日期计算类型
  static DateCalculationType _parseCalculationType(String type) {
    switch (type) {
      case 'fixed_gregorian':
        return DateCalculationType.fixedGregorian;
      case 'fixed_lunar':
        return DateCalculationType.fixedLunar;
      case 'variable_rule':
        return DateCalculationType.variableRule;
      case 'custom_rule':
        return DateCalculationType.custom;
      default:
        return DateCalculationType.fixedGregorian;
    }
  }

  /// 解析重要性级别
  static ImportanceLevel _parseImportanceLevel(String level) {
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
}
''';

  return newImplementation;
}

/// 替换HolidayInitServiceUnified类中的硬编码节日数据
String _replaceHolidayInitServiceUnifiedImplementation(String content) {
  // 使用正则表达式替换硬编码节日数据方法
  final methodPattern = RegExp(r'_getGlobalHolidays\(\)\s*\{[\s\S]*?\}');
  const newMethod = '''
  /// 获取全球通用节日
  Future<List<Holiday>> _getGlobalHolidays() async {
    try {
      // 从JSON文件加载全球节日数据
      final jsonString = await rootBundle.loadString('assets/data/preset_holidays.json');
      final jsonData = json.decode(jsonString);

      // 解析全球节日数据
      final List<dynamic> holidaysJson = jsonData['global_holidays'];
      final List<Holiday> holidays = [];

      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
        } catch (e) {
          debugPrint('解析节日数据失败: \$e');
        }
      }

      debugPrint('从JSON文件加载了 \${holidays.length} 个全球节日');
      return holidays;
    } catch (e) {
      debugPrint('加载全球节日数据失败: \$e');
      return [];
    }
  }''';

  return content.replaceAll(methodPattern, newMethod);
}

/// 替换其他文件中的硬编码节日数据
String _replaceHolidayInitServiceImplementation(String content) {
  // 实现替换逻辑
  return content;
}

String _replaceDatabaseInitServiceEnhancedImplementation(String content) {
  // 实现替换逻辑
  return content;
}

String _replaceHolidayMigrationServiceImplementation(String content) {
  // 实现替换逻辑
  return content;
}

String _replaceFranceHolidaysImplementation(String content) {
  // 实现替换逻辑
  return content;
}

String _replaceHolidayDataImporterImplementation(String content) {
  // 实现替换逻辑
  return content;
}
