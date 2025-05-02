import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

class AIDescriptionGenerator {
  // 单例模式
  static final AIDescriptionGenerator _instance = AIDescriptionGenerator._internal();
  factory AIDescriptionGenerator() => _instance;
  AIDescriptionGenerator._internal();

  // DeepSeek API 端点
  static const String _apiEndpoint = 'https://api.deepseek.com/v1/chat/completions';

  // 生成自定义响应
  Future<String> generateCustomResponse({
    required String prompt,
    BuildContext? context,
    String? preferredLanguage,
    double temperature = 0.7,
    int maxTokens = 300,
  }) async {
    try {
      // 获取 API 密钥
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // 确定语言 (虽然这里不直接使用locale，但保留这个变量以保持代码一致性)

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
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        return content;
      } else {
        Logger.error('API request failed with status: ${response.statusCode}', response.body);
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error generating custom response', e);
      throw Exception('Failed to generate response: $e');
    }
  }

  // 生成描述
  Future<String> generateDescription({
    required String title,
    BuildContext? context,
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
      final locale = preferredLanguage ?? (context != null ? Localizations.localeOf(context).languageCode : 'en');

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
      throw Exception('Failed to generate description: $e');
    }
  }

  // 构建多语言提示词
  String _buildPrompt(String title, String languageCode, String? additionalInfo) {
    String basePrompt;

    switch (languageCode) {
      case 'zh':
        basePrompt = '''
        请为节日"$title"生成一段简短的描述，包括其起源、习俗和文化意义。
        描述应该：
        - 不超过200字
        - 必须完全使用简体中文，严格禁止混入任何其他语言文字（包括但不限于英文、彝文、藏文等少数民族文字）
        - 即使描述少数民族节日，也必须只使用简体中文描述，不要使用少数民族文字
        - 语气友好自然
        - 信息准确，内容丰富
        - 如果是传统节日，重点描述其文化意义和传统习俗
        - 如果是国际节日，说明其在中国的庆祝方式

        重要提醒：无论如何，输出必须100%是简体中文，不允许出现任何其他文字系统。
        ''';
        break;
      case 'es':
        basePrompt = '''
        Por favor, genera una descripción breve para la festividad "$title", incluyendo su origen, costumbres y significado cultural.
        La descripción debe:
        - No exceder las 200 palabras
        - Estar completamente en español, sin mezclar con otros idiomas
        - Tener un tono amigable y natural
        - Ser precisa e informativa
        - Si es una festividad tradicional, enfatizar su significado cultural y costumbres tradicionales
        - Si es una festividad internacional, explicar cómo se celebra en países hispanohablantes
        ''';
        break;
      case 'fr':
        basePrompt = '''
        Veuillez générer une brève description pour la fête "$title", y compris son origine, ses coutumes et sa signification culturelle.
        La description devrait:
        - Ne pas dépasser 200 mots
        - Être entièrement en français, sans mélanger avec d'autres langues
        - Avoir un ton amical et naturel
        - Être précise et informative
        - S'il s'agit d'une fête traditionnelle, mettre l'accent sur sa signification culturelle et ses coutumes traditionnelles
        - S'il s'agit d'une fête internationale, expliquer comment elle est célébrée dans les pays francophones
        ''';
        break;
      case 'de':
        basePrompt = '''
        Bitte erstellen Sie eine kurze Beschreibung für den Feiertag "$title", einschließlich seiner Herkunft, Bräuche und kulturellen Bedeutung.
        Die Beschreibung sollte:
        - 200 Wörter nicht überschreiten
        - Vollständig auf Deutsch sein, ohne Vermischung mit anderen Sprachen
        - Einen freundlichen, natürlichen Ton haben
        - Präzise und informativ sein
        - Bei einem traditionellen Feiertag die kulturelle Bedeutung und traditionelle Bräuche hervorheben
        - Bei einem internationalen Feiertag erklären, wie er in deutschsprachigen Ländern gefeiert wird
        ''';
        break;
      default: // 默认英文
        basePrompt = '''
        Please generate a short description for the holiday "$title", including its origin, customs, and cultural significance.
        The description should:
        - Not exceed 200 words
        - Be entirely in English, without mixing in any other languages
        - Have a friendly, natural tone
        - Be accurate and informative
        - If it's a traditional holiday, emphasize its cultural significance and traditional customs
        - If it's an international holiday, explain how it's celebrated in English-speaking countries
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
    BuildContext? context,
    String? preferredLanguage,
  }) async {
    try {
      // 获取 API 密钥
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // 确定语言
      final locale = preferredLanguage ?? (context != null ? Localizations.localeOf(context).languageCode : 'en');

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
