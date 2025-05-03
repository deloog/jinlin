import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/api_service.dart';

/// 模拟API服务
///
/// 用于开发阶段，模拟服务器响应
class MockApiService implements ApiService {
  @override
  final String baseUrl = 'mock://localhost';

  @override
  Future<HolidayResponse> getHolidays(String regionCode, String languageCode) async {
    try {
      debugPrint('MockApiService: 模拟获取 $regionCode 地区的节日数据，语言: $languageCode');

      // 从本地JSON文件加载数据
      final jsonString = await rootBundle.loadString('assets/data/holidays_$regionCode.json');
      final jsonData = json.decode(jsonString);

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('MockApiService: 成功模拟获取 $regionCode 地区的节日数据');
      return HolidayResponse.fromJson({
        'version': 1,
        'holidays': jsonData['holidays']
      });
    } catch (e, stack) {
      debugPrint('MockApiService: 模拟获取节日数据失败: $e');
      debugPrint('MockApiService: 堆栈: $stack');
      // 如果找不到特定地区的文件，返回空列表
      return HolidayResponse(version: 1, holidays: []);
    }
  }

  @override
  Future<HolidayResponse> getGlobalHolidays(String languageCode) async {
    try {
      debugPrint('MockApiService: 模拟获取全球节日数据，语言: $languageCode');

      // 从本地JSON文件加载数据
      final jsonString = await rootBundle.loadString('assets/data/holidays_global.json');
      final jsonData = json.decode(jsonString);

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('MockApiService: 成功模拟获取全球节日数据');
      return HolidayResponse.fromJson({
        'version': 1,
        'holidays': jsonData['holidays']
      });
    } catch (e, stack) {
      debugPrint('MockApiService: 模拟获取全球节日数据失败: $e');
      debugPrint('MockApiService: 堆栈: $stack');
      // 如果找不到文件，返回空列表
      return HolidayResponse(version: 1, holidays: []);
    }
  }

  @override
  Future<Map<String, int>> getVersions(List<String> regionCodes) async {
    debugPrint('MockApiService: 模拟获取版本信息，地区: ${regionCodes.join(", ")}');

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    // 返回所有地区版本为1
    final result = {for (var region in regionCodes) region: 1};
    debugPrint('MockApiService: 成功模拟获取版本信息: $result');
    return result;
  }

  @override
  Future<HolidayUpdates> getHolidayUpdates(
    String regionCode,
    int sinceVersion,
    String languageCode
  ) async {
    debugPrint('MockApiService: 模拟获取节日更新，地区: $regionCode，版本: $sinceVersion，语言: $languageCode');

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 模拟没有更新
    debugPrint('MockApiService: 成功模拟获取节日更新，无更新内容');
    return HolidayUpdates(
      newVersion: sinceVersion,
      added: [],
      updated: [],
      deleted: []
    );
  }

  @override
  Future<bool> addHoliday(Holiday holiday, Map<String, String> translations, List<String> regions) async {
    try {
      debugPrint('MockApiService: 模拟添加新节日，ID: ${holiday.id}');

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 800));

      // 模拟成功添加
      debugPrint('MockApiService: 成功模拟添加新节日');
      return true;
    } catch (e, stack) {
      debugPrint('MockApiService: 模拟添加新节日失败: $e');
      debugPrint('MockApiService: 堆栈: $stack');
      return false;
    }
  }

  @override
  Future<bool> checkConnection() async {
    debugPrint('MockApiService: 模拟检查服务器连接');

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    // 模拟连接成功
    debugPrint('MockApiService: 模拟服务器连接正常');
    return true;
  }
}
