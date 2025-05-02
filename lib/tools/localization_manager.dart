// 文件： lib/tools/localization_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:jinlin_app/utils/localization_checker.dart';

/// 本地化管理工具
///
/// 用于管理本地化文件，包括生成报告、更新翻译等
void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  final command = args[0];
  switch (command) {
    case 'check':
      await checkLocalization();
      break;
    case 'report':
      await generateReport();
      break;
    case 'generate':
      await generateUntranslatedFiles();
      break;
    case 'check-placeholders':
      await checkPlaceholders();
      break;
    default:
      print('未知命令: $command');
      printUsage();
  }
}

/// 打印使用说明
void printUsage() {
  print('本地化管理工具');
  print('用法: dart run lib/tools/localization_manager.dart <命令>');
  print('');
  print('可用命令:');
  print('  check              检查本地化文件的完整性');
  print('  report             生成本地化完整性报告');
  print('  generate           生成未翻译消息的文件');
  print('  check-placeholders 检查占位符一致性');
}

/// 检查本地化文件的完整性
Future<void> checkLocalization() async {
  print('正在检查本地化文件的完整性...');
  
  final checker = LocalizationChecker();
  final missingKeysMap = await checker.checkCompleteness();
  
  if (missingKeysMap.isEmpty) {
    print('所有语言的本地化文件都是完整的！');
    return;
  }
  
  print('本地化文件完整性检查结果:');
  for (final entry in missingKeysMap.entries) {
    final languageCode = entry.key;
    final missingKeys = entry.value;
    
    print('$languageCode: 缺少 ${missingKeys.length} 个键');
    if (missingKeys.length <= 10) {
      for (final key in missingKeys) {
        print('  - $key');
      }
    } else {
      for (final key in missingKeys.take(5)) {
        print('  - $key');
      }
      print('  - ... 以及 ${missingKeys.length - 5} 个其他键');
    }
  }
}

/// 生成本地化完整性报告
Future<void> generateReport() async {
  print('正在生成本地化完整性报告...');
  
  final checker = LocalizationChecker();
  final report = await checker.generateCompletenessReport();
  
  if (report.isEmpty) {
    print('无法生成报告，请检查本地化文件是否存在。');
    return;
  }
  
  print('本地化完整性报告:');
  for (final entry in report.entries) {
    final languageCode = entry.key;
    final percentage = entry.value.toStringAsFixed(2);
    
    print('$languageCode: $percentage%');
  }
  
  // 将报告保存到文件
  final reportJson = jsonEncode(report);
  final reportFile = File('lib/l10n/completeness_report.json');
  await reportFile.writeAsString(reportJson);
  
  print('报告已保存到: lib/l10n/completeness_report.json');
}

/// 生成未翻译消息的文件
Future<void> generateUntranslatedFiles() async {
  print('正在生成未翻译消息的文件...');
  
  final checker = LocalizationChecker();
  final success = await checker.generateUntranslatedMessagesFiles();
  
  if (success) {
    print('未翻译消息的文件已生成到 lib/l10n/ 目录下。');
  } else {
    print('生成未翻译消息的文件失败，请检查错误日志。');
  }
}

/// 检查占位符一致性
Future<void> checkPlaceholders() async {
  print('正在检查占位符一致性...');
  
  final checker = LocalizationChecker();
  final inconsistentKeysMap = await checker.checkPlaceholderConsistency();
  
  if (inconsistentKeysMap.isEmpty) {
    print('所有语言的占位符都是一致的！');
    return;
  }
  
  print('占位符一致性检查结果:');
  for (final entry in inconsistentKeysMap.entries) {
    final languageCode = entry.key;
    final inconsistentKeys = entry.value;
    
    print('$languageCode: 有 ${inconsistentKeys.length} 个键的占位符不一致');
    if (inconsistentKeys.length <= 10) {
      for (final key in inconsistentKeys) {
        print('  - $key');
      }
    } else {
      for (final key in inconsistentKeys.take(5)) {
        print('  - $key');
      }
      print('  - ... 以及 ${inconsistentKeys.length - 5} 个其他键');
    }
  }
}
