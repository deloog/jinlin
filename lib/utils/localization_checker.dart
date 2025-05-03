// 文件： lib/utils/localization_checker.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 本地化文件检查工具
///
/// 用于检查本地化文件的完整性和一致性，帮助开发者发现和修复本地化问题
class LocalizationChecker {
  // 单例模式
  static final LocalizationChecker _instance = LocalizationChecker._internal();
  factory LocalizationChecker() => _instance;
  LocalizationChecker._internal();

  /// 检查本地化文件的完整性
  ///
  /// 返回一个包含每种语言缺失的键的Map
  Future<Map<String, List<String>>> checkCompleteness() async {
    if (kIsWeb) {
      Logger.warning('Web平台不支持本地化文件检查');
      return {};
    }

    try {
      // 获取本地化文件目录
      final directory = Directory('lib/l10n');
      if (!await directory.exists()) {
        Logger.error('本地化文件目录不存在: lib/l10n');
        return {};
      }

      // 读取模板文件（英文）
      final templateFile = File('${directory.path}/app_localizations_en.arb');
      if (!await templateFile.exists()) {
        Logger.error('模板文件不存在: app_localizations_en.arb');
        return {};
      }

      // 解析模板文件
      final templateContent = await templateFile.readAsString();
      final templateJson = jsonDecode(templateContent) as Map<String, dynamic>;

      // 获取所有键（排除以@开头的元数据键）
      final templateKeys = templateJson.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toList();

      // 检查每种语言的文件
      final result = <String, List<String>>{};

      for (final locale in LocalizationService.supportedLocales) {
        final languageCode = locale.languageCode;
        if (languageCode == 'en') continue; // 跳过英文（模板文件）

        // 读取语言文件
        final langFile = File('${directory.path}/app_localizations_$languageCode.arb');
        if (!await langFile.exists()) {
          Logger.warning('语言文件不存在: app_localizations_$languageCode.arb');
          result[languageCode] = templateKeys;
          continue;
        }

        // 解析语言文件
        final langContent = await langFile.readAsString();
        final langJson = jsonDecode(langContent) as Map<String, dynamic>;

        // 检查缺失的键
        final missingKeys = <String>[];
        for (final key in templateKeys) {
          if (!langJson.containsKey(key)) {
            missingKeys.add(key);
          }
        }

        if (missingKeys.isNotEmpty) {
          result[languageCode] = missingKeys;
        }
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('检查本地化文件完整性失败', e, stackTrace);
      return {};
    }
  }

  /// 生成本地化完整性报告
  ///
  /// 返回一个包含每种语言完整性百分比的Map
  Future<Map<String, double>> generateCompletenessReport() async {
    final missingKeysMap = await checkCompleteness();
    if (missingKeysMap.isEmpty) return {};

    try {
      // 读取模板文件（英文）
      final templateFile = File('lib/l10n/app_localizations_en.arb');
      final templateContent = await templateFile.readAsString();
      final templateJson = jsonDecode(templateContent) as Map<String, dynamic>;

      // 获取所有键（排除以@开头的元数据键）
      final templateKeys = templateJson.keys
          .where((key) => !key.startsWith('@') && key != '@@locale')
          .toList();

      final totalKeys = templateKeys.length;
      final result = <String, double>{};

      // 计算每种语言的完整性百分比
      for (final locale in LocalizationService.supportedLocales) {
        final languageCode = locale.languageCode;
        if (languageCode == 'en') {
          result[languageCode] = 100.0; // 英文（模板文件）完整性为100%
          continue;
        }

        final missingKeys = missingKeysMap[languageCode] ?? [];
        final completedKeys = totalKeys - missingKeys.length;
        final completenessPercentage = (completedKeys / totalKeys) * 100;

        result[languageCode] = completenessPercentage;
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('生成本地化完整性报告失败', e, stackTrace);
      return {};
    }
  }

  /// 生成未翻译消息的JSON文件
  ///
  /// 为每种语言生成一个包含未翻译消息的JSON文件
  Future<bool> generateUntranslatedMessagesFiles() async {
    if (kIsWeb) {
      Logger.warning('Web平台不支持生成未翻译消息文件');
      return false;
    }

    try {
      final missingKeysMap = await checkCompleteness();
      if (missingKeysMap.isEmpty) return true;

      // 读取模板文件（英文）
      final templateFile = File('lib/l10n/app_localizations_en.arb');
      final templateContent = await templateFile.readAsString();
      final templateJson = jsonDecode(templateContent) as Map<String, dynamic>;

      // 为每种语言生成未翻译消息文件
      for (final entry in missingKeysMap.entries) {
        final languageCode = entry.key;
        final missingKeys = entry.value;

        if (missingKeys.isEmpty) continue;

        // 创建未翻译消息的JSON对象
        final untranslatedJson = <String, dynamic>{
          '@@locale': languageCode,
        };

        // 添加缺失的键和值（从模板文件中获取）
        for (final key in missingKeys) {
          untranslatedJson[key] = templateJson[key];

          // 如果有元数据，也添加
          final metadataKey = '@$key';
          if (templateJson.containsKey(metadataKey)) {
            untranslatedJson[metadataKey] = templateJson[metadataKey];
          }
        }

        // 写入文件
        final outputFile = File('lib/l10n/untranslated_$languageCode.arb');
        await outputFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(untranslatedJson),
        );

        Logger.info('已生成未翻译消息文件: untranslated_$languageCode.arb，包含 ${missingKeys.length} 个未翻译的键');
      }

      return true;
    } catch (e, stackTrace) {
      Logger.error('生成未翻译消息文件失败', e, stackTrace);
      return false;
    }
  }

  /// 检查本地化文件中的占位符一致性
  ///
  /// 确保所有语言的占位符与模板文件一致
  Future<Map<String, List<String>>> checkPlaceholderConsistency() async {
    if (kIsWeb) {
      Logger.warning('Web平台不支持检查占位符一致性');
      return {};
    }

    try {
      // 读取模板文件（英文）
      final templateFile = File('lib/l10n/app_localizations_en.arb');
      final templateContent = await templateFile.readAsString();
      final templateJson = jsonDecode(templateContent) as Map<String, dynamic>;

      // 提取模板文件中的占位符
      final templatePlaceholders = <String, Set<String>>{};
      for (final key in templateJson.keys) {
        if (key.startsWith('@') || key == '@@locale') continue;

        final value = templateJson[key] as String;
        final placeholders = _extractPlaceholders(value);
        if (placeholders.isNotEmpty) {
          templatePlaceholders[key] = placeholders;
        }
      }

      // 检查每种语言的占位符
      final result = <String, List<String>>{};

      for (final locale in LocalizationService.supportedLocales) {
        final languageCode = locale.languageCode;
        if (languageCode == 'en') continue; // 跳过英文（模板文件）

        // 读取语言文件
        final langFile = File('lib/l10n/app_localizations_$languageCode.arb');
        if (!await langFile.exists()) continue;

        // 解析语言文件
        final langContent = await langFile.readAsString();
        final langJson = jsonDecode(langContent) as Map<String, dynamic>;

        // 检查占位符一致性
        final inconsistentKeys = <String>[];

        for (final entry in templatePlaceholders.entries) {
          final key = entry.key;
          final expectedPlaceholders = entry.value;

          if (!langJson.containsKey(key)) continue; // 跳过缺失的键

          final value = langJson[key] as String;
          final actualPlaceholders = _extractPlaceholders(value);

          // 检查占位符是否一致
          if (!_arePlaceholdersConsistent(expectedPlaceholders, actualPlaceholders)) {
            inconsistentKeys.add(key);
          }
        }

        if (inconsistentKeys.isNotEmpty) {
          result[languageCode] = inconsistentKeys;
        }
      }

      return result;
    } catch (e, stackTrace) {
      Logger.error('检查占位符一致性失败', e, stackTrace);
      return {};
    }
  }

  /// 从文本中提取占位符
  Set<String> _extractPlaceholders(String text) {
    final placeholders = <String>{};
    final regex = RegExp(r'\{([^{}]+)\}');

    for (final match in regex.allMatches(text)) {
      placeholders.add(match.group(1)!);
    }

    return placeholders;
  }

  /// 检查两组占位符是否一致
  bool _arePlaceholdersConsistent(Set<String> expected, Set<String> actual) {
    return expected.length == actual.length && expected.containsAll(actual);
  }
}
