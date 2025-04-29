// 文件： jinlin_app/lib/deepseek_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class DeepseekService {
  final String? _apiKey = dotenv.env['DEEPSEEK_API_KEY'];
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  // --- processText (生成描述) 方法保持不变 ---
  Future<String> processText(String inputText) async {
  // inputText 预期格式："提醒标题 [日期：YYYY-MM-DD HH:MM]" 或仅 "提醒标题"
  if (_apiKey == null || _apiKey.isEmpty) {
    throw Exception('DeepSeek API 密钥未配置');
  }

  // --- 为描述生成设计的 Prompt ---
  final String systemPrompt = """
  You are a helpful assistant tasked with creating concise and useful reminder descriptions.
  Based on the provided reminder title and optional date/time, generate a short (1-2 sentences) description.
  The description should offer context, suggest preparation, mention related items, or provide a helpful tip.
  Focus on being practical and relevant to the reminder event.
  Examples:
  - Input: 'Buy birthday cake [Date: 2025-05-10 14:00]' -> Output: 'Remember to get candles and a lighter. Check preferred flavor!'
  - Input: 'Team Meeting [Date: Tomorrow 09:00]' -> Output: 'Prepare discussion points. Confirm conference room booking.'
  - Input: 'Call Mom' -> Output: 'Ask about her weekend plans.'
  - Input: 'Pay electricity bill' -> Output: 'Have the account number ready. Check the due date to avoid late fees.'
  Respond ONLY with the generated description text, nothing else. Keep it brief.
  """.trim();
  // --- Prompt 结束 ---

  final body = jsonEncode({
    "model": "deepseek-chat", // 或者 deepseek-coder 如果更适合这种任务
    "messages": [
      {"role": "system", "content": systemPrompt},
      // 将 inputText (标题和可选日期) 作为用户输入
      {"role": "user", "content": inputText}
    ],
    "temperature": 0.7, // 允许一定的创造性
    "max_tokens": 100, // 限制描述长度
    "stream": false,
  });

  print("发送给 DeepSeek (生成描述) 的内容: $inputText");

  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
      // 可以为描述生成设置不同的超时时间，例如 30 秒
    ).timeout(const Duration(seconds: 30));

    print("DeepSeek (生成描述) 响应状态码: ${response.statusCode}");

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (responseBody['choices'] != null &&
          responseBody['choices'].isNotEmpty &&
          responseBody['choices'][0]['message'] != null &&
          responseBody['choices'][0]['message']['content'] != null) {
        // 直接获取 AI 生成的文本内容
        String description = responseBody['choices'][0]['message']['content'].trim();
        print("DeepSeek 返回的描述: $description");
        // 可以进行一些简单的后处理，比如去掉可能的多余引号
        if (description.startsWith('"') && description.endsWith('"')) {
           description = description.substring(1, description.length - 1);
        }
        return description; // 返回描述字符串
      } else {
        throw Exception('DeepSeek (生成描述) 返回了无效的响应格式');
      }
    } else {
      // 尝试从错误响应中获取更多信息
      String errorBody = utf8.decode(response.bodyBytes);
      print("DeepSeek (生成描述) 错误响应体: $errorBody");
      throw Exception('DeepSeek API (生成描述) 请求失败 (${response.statusCode})');
    }
  } catch (e) {
    print('调用 DeepSeek API (生成描述) 时出错: $e');
    if (e is TimeoutException) {
      throw Exception('请求 DeepSeek (生成描述) 超时');
    }
    // 对于其他异常，可以考虑向上抛出，或者返回一个默认的错误信息
    // return "无法生成描述，请稍后重试。";
    throw Exception('与 DeepSeek (生成描述) 通信时发生错误');
  }
}
// --- processText 方法实现结束 ---

  // --- extractReminderInfo (提取信息和生成描述) 方法 ---
  Future<List<Map<String, String?>>> extractReminderInfo(String naturalInput) async {
    if (_apiKey == null || _apiKey.isEmpty) { throw Exception('DeepSeek API 密钥未配置'); }

    final now = DateTime.now();
    final String currentDate = DateFormat('yyyy-MM-dd').format(now);
    final String currentYear = now.year.toString();

    // 添加详细日志
    print("===== DeepSeek API 调试信息 =====");
    print("输入文本: $naturalInput");
    print("当前日期: $currentDate");
    print("当前年份: $currentYear");

    // --- 优化后的 Prompt 指令，增加描述生成功能 ---
final String systemPrompt = """
Context: Today is $currentDate. The current year is $currentYear.
Task: Analyze the user's input about reminders. Identify up to 10 distinct reminder events mentioned.
Output Format: Respond ONLY with a valid JSON **array**. Each element in the array should be a JSON object representing one reminder event, containing these keys:
[
  {
    "title": "event title",
    "due_date": "YYYY-MM-DD HH:MM:SS",
    "description": "detailed preparation notes"
  }
]
If no events are found, return an empty array [].
Rules:
- Extract a concise 'title' for each event.
- Extract the specific date and time as 'due_date' for each event (in 'YYYY-MM-DD HH:MM:SS' format).
- Generate a detailed and helpful 'description' that provides 2-3 specific preparation tips or reminders for the event.
- Format the description as a bulleted list, for example:
  * For a school visit: "若需演示或授课，提前准备好课件/工具\n穿着得体（如技校有服装要求需遵守）\n确认是否需要提前报备车牌号（校园停车限制）"
  * For a birthday: "提前订购生日蛋糕\n准备合适的生日礼物\n确认聚会地点和时间"
  * For a meeting: "准备相关文件和会议记录\n提前5-10分钟到达会议室\n准备好演示设备和材料"
  * For a doctor appointment: "带上医保卡和病历\n列出需要咨询的问题\n提前到达医院完成挂号"
- Use "\n" (single backslash) to separate each bullet point in the description.
- Support up to 10 events maximum.
- If a specific year is mentioned, use it. Otherwise, use the current year ($currentYear).
- Recognize common date formats like 'MM月DD日', 'YYYY年MM月DD日', '明天', '后天', '下周X', '晚上X点', '下午X点'.
- If only a date is mentioned (like '明天', '下周五', '4月18日') without a time, use 12:00:00 for the time of that event.
- If a relative date like '明天' or '后天' is used, calculate the absolute date based on today's date ($currentDate).
- If no specific date/time can be reliably extracted for an event, set its "due_date" to null.
- If no clear event title can be extracted for a segment, set its "title" to null or omit the event object.
- Ensure the output is ONLY the JSON array, nothing else before or after.
- Double-check that your JSON is valid and complete before returning it.
- IMPORTANT: Make sure each JSON object is properly closed with a closing brace and comma.
- IMPORTANT: Keep the total response length under 2000 characters.
""".trim();
// --- Prompt 替换结束 ---

    final body = jsonEncode({
      "model": "deepseek-chat",
      "messages": [ {"role": "system", "content": systemPrompt}, {"role": "user", "content": naturalInput} ],
      "temperature": 0.3, // 进一步降低 temperature 提高确定性
      "max_tokens": 4000, // 增加 token 限制，以支持更多事件和更详细的描述
      "stream": false,
      // "response_format": {"type": "json_object"} // 如果支持，启用 JSON 模式
    });

    print("发送给 DeepSeek (提取信息) 的内容: $naturalInput");

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey', },
        body: body,
      ).timeout(const Duration(seconds: 90));

      print("DeepSeek (提取信息) 响应状态码: ${response.statusCode}");
      print("DeepSeek 响应头: ${response.headers}");

      // 检查响应内容长度
      if (response.headers.containsKey('content-length')) {
        print("响应内容长度: ${response.headers['content-length']} 字节");
      }

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseBody['choices'] != null && responseBody['choices'].isNotEmpty &&
            responseBody['choices'][0]['message'] != null &&
            responseBody['choices'][0]['message']['content'] != null) {

          String rawContent = responseBody['choices'][0]['message']['content'].trim();
          print("DeepSeek 返回的原始内容: $rawContent");

          // --- 替换 try {...} catch (e) {...} 中解析 JSON 的部分 ---
try {
  // --- 在 jsonDecode(rawContent) 之前，插入下面这段清理代码 ---
String jsonContentToParse = rawContent; // 先复制一份原始内容
if (jsonContentToParse.startsWith("```json")) {
    jsonContentToParse = jsonContentToParse.substring(7); // 去掉开头的 ```json\n
}
if (jsonContentToParse.endsWith("```")) {
    jsonContentToParse = jsonContentToParse.substring(0, jsonContentToParse.length - 3); // 去掉结尾的 ```
}
jsonContentToParse = jsonContentToParse.trim(); // 去掉可能存在的前后空格或换行符
// --- 清理代码结束 ---

// 尝试修复可能的JSON格式问题
try {
  // 先尝试直接解析
  final List<dynamic> extractedList = jsonDecode(jsonContentToParse);

  // 创建一个列表来存储结果
  List<Map<String, String?>> results = [];

  // 遍历解析出的列表
  for (var item in extractedList) {
     // 确保列表中的每个元素都是一个 Map
     if (item is Map<String, dynamic>) {
        // 提取 title、due_date 和 description
        final String? title = item['title'] as String?;
        final String? dueDateStr = item['due_date'] as String?;
        final String? description = item['description'] as String?;
        // 可以添加更多检查，比如 title 和 dueDateStr 不能都为 null 才添加
        if (title != null || dueDateStr != null) {
           results.add({
             'title': title,
             'due_date': dueDateStr,
             'description': description,
           });
        }
     } else {
        print("警告：AI 返回的数组中包含非对象元素: $item");
     }
  }

  print("提取到的事件列表: $results");
  return results; // 返回包含多个事件 Map 的列表
} catch (jsonError) {
  // JSON解析失败，尝试手动修复常见问题
  print("JSON解析失败，尝试修复: $jsonError");

  // 尝试手动解析JSON
  List<Map<String, String?>> results = [];

  // 使用更强大的正则表达式提取每个事件对象
  // 首先尝试提取完整的JSON对象
  final RegExp eventRegex = RegExp(r'\{\s*"title":\s*"([^"]*)",\s*"due_date":\s*"([^"]*)",\s*"description":\s*"([^"]*)"\s*\}');
  var matches = eventRegex.allMatches(jsonContentToParse);

  // 如果没有匹配到完整的JSON对象，尝试提取不完整的对象
  if (matches.isEmpty) {
    // 更宽松的匹配，可以处理未终止的字符串和缺少某些字段的情况
    final RegExp fallbackRegex = RegExp(r'\{\s*"title":\s*"([^"]*)(?:"|\n|\r)?,\s*"due_date":\s*"([^"]*)(?:"|\n|\r)?(?:,\s*"description":\s*"([^"]*)(?:"|\n|\r)?)?');
    matches = fallbackRegex.allMatches(jsonContentToParse);
  }

  // 如果仍然没有匹配到，尝试提取单个字段
  if (matches.isEmpty) {
    // 尝试单独提取标题和日期
    final RegExp titleRegex = RegExp(r'"title":\s*"([^"]*)"');
    final RegExp dateRegex = RegExp(r'"due_date":\s*"([^"]*)"');
    final RegExp descRegex = RegExp(r'"description":\s*"([^"]*)"');

    final titleMatches = titleRegex.allMatches(jsonContentToParse);
    final dateMatches = dateRegex.allMatches(jsonContentToParse);
    final descMatches = descRegex.allMatches(jsonContentToParse);

    // 如果找到了标题和日期，手动构建结果
    if (titleMatches.isNotEmpty && dateMatches.isNotEmpty) {
      for (int i = 0; i < titleMatches.length && i < 10; i++) {
        final title = titleMatches.elementAt(i).group(1);
        final date = i < dateMatches.length ? dateMatches.elementAt(i).group(1) : null;
        final desc = i < descMatches.length ? descMatches.elementAt(i).group(1) : null;

        results.add({
          'title': title,
          'due_date': date,
          'description': desc,
        });
      }

      if (results.isNotEmpty) {
        print("使用单独字段匹配成功，提取到 ${results.length} 个事件");
        return results;
      }
    }
  }

  for (final match in matches) {
    if (match.groupCount >= 2) {
      final title = match.group(1);
      final dueDate = match.group(2);
      final description = match.groupCount >= 3 ? match.group(3) : null;

      results.add({
        'title': title,
        'due_date': dueDate,
        'description': description,
      });
    }
  }

  if (results.isNotEmpty) {
    print("手动解析成功，提取到 ${results.length} 个事件");
    print("提取到的事件列表: $results");
    return results;
  }

  // 如果手动解析也失败，则抛出异常
  throw Exception("无法解析 AI 返回的数据（预期为 JSON 数组）");
}

} catch (e) {
  print("错误：解析 AI 返回的 JSON 数组失败: $e");
  print("原始返回内容: $rawContent");
  // 如果解析失败，可以返回一个空列表或者重新抛出异常
  // return []; // 或者
  throw Exception("与 DeepSeek 通信时发生错误");
}
// --- 解析逻辑修改结束 ---
        } else { throw Exception('DeepSeek (提取信息) 返回了无效的响应格式'); }
      } else { throw Exception('DeepSeek API (提取信息) 请求失败 (${response.statusCode})'); }
    } catch (e) {
      print('调用 DeepSeek API (提取信息) 时出错: $e');
      if (e is TimeoutException) { throw Exception('请求 DeepSeek 超时'); }
      throw Exception('与 DeepSeek 通信时发生错误');
    }
  }
}