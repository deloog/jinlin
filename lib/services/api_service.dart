import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jinlin_app/models/unified/holiday.dart';

/// API服务
///
/// 负责与服务器通信，获取节日数据
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService(this.baseUrl, this._client);

  /// 获取特定地区和语言的节日
  Future<HolidayResponse> getHolidays(String regionCode, String languageCode) async {
    try {
      debugPrint('ApiService: 获取 $regionCode 地区的节日数据，语言: $languageCode');
      final response = await _client.get(
        Uri.parse('$baseUrl/api/holidays?region=$regionCode&language=$languageCode')
      );

      if (response.statusCode == 200) {
        debugPrint('ApiService: 成功获取 $regionCode 地区的节日数据');
        return HolidayResponse.fromJson(json.decode(response.body));
      } else {
        debugPrint('ApiService: 获取节日数据失败，状态码: ${response.statusCode}');
        throw Exception('Failed to load holidays: ${response.statusCode}, ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('ApiService: 获取节日数据失败: $e');
      debugPrint('ApiService: 堆栈: $stack');
      rethrow;
    }
  }

  /// 获取全球节日
  Future<HolidayResponse> getGlobalHolidays(String languageCode) async {
    try {
      debugPrint('ApiService: 获取全球节日数据，语言: $languageCode');
      final response = await _client.get(
        Uri.parse('$baseUrl/api/holidays/global?language=$languageCode')
      );

      if (response.statusCode == 200) {
        debugPrint('ApiService: 成功获取全球节日数据');
        return HolidayResponse.fromJson(json.decode(response.body));
      } else {
        debugPrint('ApiService: 获取全球节日数据失败，状态码: ${response.statusCode}');
        throw Exception('Failed to load global holidays: ${response.statusCode}, ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('ApiService: 获取全球节日数据失败: $e');
      debugPrint('ApiService: 堆栈: $stack');
      rethrow;
    }
  }

  /// 获取数据版本信息
  Future<Map<String, int>> getVersions(List<String> regionCodes) async {
    try {
      debugPrint('ApiService: 获取版本信息，地区: ${regionCodes.join(", ")}');
      final regions = regionCodes.join(',');
      final response = await _client.get(
        Uri.parse('$baseUrl/api/versions?regions=$regions')
      );

      if (response.statusCode == 200) {
        debugPrint('ApiService: 成功获取版本信息');
        final data = json.decode(response.body);
        return Map<String, int>.from(data['versions']);
      } else {
        debugPrint('ApiService: 获取版本信息失败，状态码: ${response.statusCode}');
        throw Exception('Failed to load versions: ${response.statusCode}, ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('ApiService: 获取版本信息失败: $e');
      debugPrint('ApiService: 堆栈: $stack');
      rethrow;
    }
  }

  /// 获取节日数据更新
  Future<HolidayUpdates> getHolidayUpdates(
    String regionCode,
    int sinceVersion,
    String languageCode
  ) async {
    try {
      debugPrint('ApiService: 获取节日更新，地区: $regionCode，版本: $sinceVersion，语言: $languageCode');
      final response = await _client.get(
        Uri.parse('$baseUrl/api/holidays/updates?region=$regionCode&since_version=$sinceVersion&language=$languageCode')
      );

      if (response.statusCode == 200) {
        debugPrint('ApiService: 成功获取节日更新');
        return HolidayUpdates.fromJson(json.decode(response.body));
      } else {
        debugPrint('ApiService: 获取节日更新失败，状态码: ${response.statusCode}');
        throw Exception('Failed to load holiday updates: ${response.statusCode}, ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('ApiService: 获取节日更新失败: $e');
      debugPrint('ApiService: 堆栈: $stack');
      rethrow;
    }
  }

  /// 添加新节日（需要管理员权限）
  Future<bool> addHoliday(Holiday holiday, Map<String, String> translations, List<String> regions) async {
    try {
      debugPrint('ApiService: 添加新节日，ID: ${holiday.id}');

      // 准备请求数据
      final requestData = {
        'holiday': {
          'id': holiday.id,
          'type': holiday.type.toString().split('.').last,
          'calculationType': holiday.calculationType.toString().split('.').last,
          'calculationRule': holiday.calculationRule,
          'importanceLevel': holiday.importanceLevel.toString().split('.').last,
        },
        'translations': translations,
        'regions': regions,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/api/holidays'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        debugPrint('ApiService: 成功添加新节日');
        return true;
      } else {
        debugPrint('ApiService: 添加新节日失败，状态码: ${response.statusCode}');
        throw Exception('Failed to add holiday: ${response.statusCode}, ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('ApiService: 添加新节日失败: $e');
      debugPrint('ApiService: 堆栈: $stack');
      rethrow;
    }
  }

  /// 检查服务器连接
  Future<bool> checkConnection() async {
    try {
      debugPrint('ApiService: 检查服务器连接');
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('ApiService: 服务器连接正常');
        return true;
      } else {
        debugPrint('ApiService: 服务器连接异常，状态码: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ApiService: 服务器连接失败: $e');
      return false;
    }
  }
}

/// 节日响应
class HolidayResponse {
  final int version;
  final List<Holiday> holidays;

  HolidayResponse({required this.version, required this.holidays});

  factory HolidayResponse.fromJson(Map<String, dynamic> json) {
    return HolidayResponse(
      version: json['version'],
      holidays: (json['holidays'] as List)
        .map((item) => Holiday.fromApiJson(item))
        .toList()
    );
  }
}

/// 节日更新
class HolidayUpdates {
  final int newVersion;
  final List<Holiday> added;
  final List<Holiday> updated;
  final List<String> deleted;

  HolidayUpdates({
    required this.newVersion,
    required this.added,
    required this.updated,
    required this.deleted
  });

  factory HolidayUpdates.fromJson(Map<String, dynamic> json) {
    return HolidayUpdates(
      newVersion: json['new_version'],
      added: (json['added'] as List).map((item) => Holiday.fromApiJson(item)).toList(),
      updated: (json['updated'] as List).map((item) => Holiday.fromApiJson(item)).toList(),
      deleted: (json['deleted'] as List).map((id) => id as String).toList()
    );
  }
}
