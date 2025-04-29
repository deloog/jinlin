import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/logger.dart';

class AIDescriptionGenerator {
  // 单例模式
  static final AIDescriptionGenerator _instance = AIDescriptionGenerator._internal();
  factory AIDescriptionGenerator() => _instance;
  AIDescriptionGenerator._internal();

  // DeepSeek API 端点
  static const String _apiEndpoint = 'https://api.deepseek.com/v1/chat/completions';

  // 生成描述
  Future<String> generateDescription({
    required String title,
    required BuildContext context,
    String? additionalInfo,
    String? preferredLanguage,
  }) async {
    try {
      // 获取 API 密钥
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // 确定语言
      final locale = preferredLanguage ?? Localizations.localeOf(context).languageCode;

      // 构建提示词
      final prompt = _buildPrompt(title, locale, additionalInfo);

      // 发送请求
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else {
        Logger.error('API request failed with status: ${response.statusCode}', response.body);
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error generating description', e);
      final l10n = AppLocalizations.of(context);
      throw Exception(l10n.descGeneratedError(e.toString()));
    }
  }

  // 构建多语言提示词
  String _buildPrompt(String title, String languageCode, String? additionalInfo) {
    String basePrompt;

    switch (languageCode) {
      case 'zh':
        basePrompt = '''
        请为标题为"$title"的提醒事项生成一段简短但有用的描述。
        描述应该：
        - 不超过100个字
        - 使用中文
        - 语气友好自然
        - 提供与提醒相关的有用信息或建议
        - 不要重复标题内容
        - 如果是节日相关的提醒，可以包含该节日的传统习俗或文化背景
        - 如果是生日或纪念日，可以提供适合的祝福语或礼物建议
        ''';
        break;
      case 'es':
        basePrompt = '''
        Por favor, genera una descripción breve pero útil para un recordatorio titulado "$title".
        La descripción debe:
        - No exceder las 100 palabras
        - Estar en español
        - Tener un tono amigable y natural
        - Proporcionar información útil o consejos relacionados con el recordatorio
        - No repetir el contenido del título
        - Si es un recordatorio relacionado con una festividad, incluir tradiciones o contexto cultural
        - Si es un cumpleaños o aniversario, proporcionar felicitaciones o sugerencias de regalos apropiados
        ''';
        break;
      case 'fr':
        basePrompt = '''
        Veuillez générer une description courte mais utile pour un rappel intitulé "$title".
        La description devrait:
        - Ne pas dépasser 100 mots
        - Être en français
        - Avoir un ton amical et naturel
        - Fournir des informations utiles ou des conseils liés au rappel
        - Ne pas répéter le contenu du titre
        - S'il s'agit d'un rappel lié à une fête, inclure des traditions ou un contexte culturel
        - S'il s'agit d'un anniversaire, fournir des félicitations ou des suggestions de cadeaux appropriées
        ''';
        break;
      case 'de':
        basePrompt = '''
        Bitte erstellen Sie eine kurze, aber nützliche Beschreibung für eine Erinnerung mit dem Titel "$title".
        Die Beschreibung sollte:
        - 100 Wörter nicht überschreiten
        - Auf Deutsch sein
        - Einen freundlichen, natürlichen Ton haben
        - Nützliche Informationen oder Ratschläge im Zusammenhang mit der Erinnerung liefern
        - Den Inhalt des Titels nicht wiederholen
        - Bei einer Erinnerung an einen Feiertag Traditionen oder kulturellen Kontext einbeziehen
        - Bei einem Geburtstag oder Jubiläum passende Glückwünsche oder Geschenkvorschläge anbieten
        ''';
        break;
      default: // 默认英文
        basePrompt = '''
        Please generate a short but useful description for a reminder titled "$title".
        The description should:
        - Not exceed 100 words
        - Be in English
        - Have a friendly, natural tone
        - Provide useful information or advice related to the reminder
        - Not repeat the title content
        - If it's a holiday-related reminder, include traditions or cultural context
        - If it's a birthday or anniversary, provide appropriate congratulations or gift suggestions
        ''';
    }

    // 添加额外信息（如果有）
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      switch (languageCode) {
        case 'zh':
          basePrompt += '\n请考虑以下额外信息：$additionalInfo';
          break;
        case 'es':
          basePrompt += '\nPor favor considera esta información adicional: $additionalInfo';
          break;
        default:
          basePrompt += '\nPlease consider this additional information: $additionalInfo';
      }
    }

    return basePrompt;
  }

  // 批量生成描述
  Future<List<String>> generateBatchDescriptions({
    required List<String> titles,
    required BuildContext context,
    String? preferredLanguage,
  }) async {
    try {
      // 获取 API 密钥
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // 确定语言
      final locale = preferredLanguage ?? Localizations.localeOf(context).languageCode;

      // 构建批量提示词
      final prompt = _buildBatchPrompt(titles, locale);

      // 发送请求
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // 解析返回的 JSON 格式描述
        try {
          final Map<String, dynamic> parsedContent = jsonDecode(content);
          final List<String> descriptions = [];

          for (int i = 0; i < titles.length; i++) {
            final key = 'description_${i + 1}';
            if (parsedContent.containsKey(key)) {
              descriptions.add(parsedContent[key]);
            } else {
              // 如果找不到对应的描述，使用默认值
              descriptions.add('');
            }
          }

          return descriptions;
        } catch (e) {
          Logger.error('Error parsing batch descriptions', e);
          // 如果解析失败，返回空描述列表
          return List.filled(titles.length, '');
        }
      } else {
        Logger.error('API request failed with status: ${response.statusCode}', response.body);
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error generating batch descriptions', e);
      // 返回空描述列表
      return List.filled(titles.length, '');
    }
  }

  // 构建批量提示词
  String _buildBatchPrompt(List<String> titles, String languageCode) {
    String basePrompt;

    switch (languageCode) {
      case 'zh':
        basePrompt = '''
        请为以下${titles.length}个提醒事项标题生成简短但有用的描述。
        每个描述应该：
        - 不超过50个字
        - 使用中文
        - 语气友好自然
        - 提供与提醒相关的有用信息或建议
        - 不要重复标题内容
        - 如果是节日相关的提醒，可以包含该节日的传统习俗或文化背景
        - 如果是生日或纪念日，可以提供适合的祝福语或礼物建议

        请以JSON格式返回，格式如下：
        {
          "description_1": "第一个描述",
          "description_2": "第二个描述",
          ...
        }

        标题列表：
        ''';
        break;
      case 'es':
        basePrompt = '''
        Por favor, genera descripciones breves pero útiles para los siguientes ${titles.length} títulos de recordatorios.
        Cada descripción debe:
        - No exceder las 50 palabras
        - Estar en español
        - Tener un tono amigable y natural
        - Proporcionar información útil o consejos relacionados con el recordatorio
        - No repetir el contenido del título
        - Si es un recordatorio relacionado con una festividad, incluir tradiciones o contexto cultural
        - Si es un cumpleaños o aniversario, proporcionar felicitaciones o sugerencias de regalos apropiados

        Por favor, devuelve en formato JSON de la siguiente manera:
        {
          "description_1": "Primera descripción",
          "description_2": "Segunda descripción",
          ...
        }

        Lista de títulos:
        ''';
        break;
      case 'fr':
        basePrompt = '''
        Veuillez générer des descriptions courtes mais utiles pour les ${titles.length} titres de rappel suivants.
        Chaque description devrait:
        - Ne pas dépasser 50 mots
        - Être en français
        - Avoir un ton amical et naturel
        - Fournir des informations utiles ou des conseils liés au rappel
        - Ne pas répéter le contenu du titre
        - S'il s'agit d'un rappel lié à une fête, inclure des traditions ou un contexte culturel
        - S'il s'agit d'un anniversaire, fournir des félicitations ou des suggestions de cadeaux appropriées

        Veuillez retourner au format JSON comme suit:
        {
          "description_1": "Première description",
          "description_2": "Deuxième description",
          ...
        }

        Liste des titres:
        ''';
        break;
      case 'de':
        basePrompt = '''
        Bitte erstellen Sie kurze, aber nützliche Beschreibungen für die folgenden ${titles.length} Erinnerungstitel.
        Jede Beschreibung sollte:
        - 50 Wörter nicht überschreiten
        - Auf Deutsch sein
        - Einen freundlichen, natürlichen Ton haben
        - Nützliche Informationen oder Ratschläge im Zusammenhang mit der Erinnerung liefern
        - Den Inhalt des Titels nicht wiederholen
        - Bei einer Erinnerung an einen Feiertag Traditionen oder kulturellen Kontext einbeziehen
        - Bei einem Geburtstag oder Jubiläum passende Glückwünsche oder Geschenkvorschläge anbieten

        Bitte im JSON-Format wie folgt zurückgeben:
        {
          "description_1": "Erste Beschreibung",
          "description_2": "Zweite Beschreibung",
          ...
        }

        Titelliste:
        ''';
        break;
      default: // 默认英文
        basePrompt = '''
        Please generate short but useful descriptions for the following ${titles.length} reminder titles.
        Each description should:
        - Not exceed 50 words
        - Be in English
        - Have a friendly, natural tone
        - Provide useful information or advice related to the reminder
        - Not repeat the title content
        - If it's a holiday-related reminder, include traditions or cultural context
        - If it's a birthday or anniversary, provide appropriate congratulations or gift suggestions

        Please return in JSON format as follows:
        {
          "description_1": "First description",
          "description_2": "Second description",
          ...
        }

        Title list:
        ''';
    }

    // 添加标题列表
    for (int i = 0; i < titles.length; i++) {
      basePrompt += '\n${i + 1}. ${titles[i]}';
    }

    return basePrompt;
  }
}
