import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/api_service_provider.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/services/holiday_data_sync_service.dart';

/// 节日数据加载服务
///
/// 负责从JSON文件加载预设节日数据并导入数据库
/// 只在应用首次安装或数据库重置时运行
class HolidayDataLoaderService {
  static final HolidayDataLoaderService _instance = HolidayDataLoaderService._internal();

  factory HolidayDataLoaderService() {
    return _instance;
  }

  HolidayDataLoaderService._internal();

  /// 数据库管理器
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();

  // 标记是否正在初始化，防止无限循环
  static bool _isInitializing = false;

  /// 初始化基础数据
  ///
  /// 初始化数据库并加载全球节日数据
  Future<void> initializeBasicData() async {
    // 防止无限循环
    if (_isInitializing) {
      debugPrint('HolidayDataLoaderService.initializeBasicData() 已经在执行中，跳过');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('HolidayDataLoaderService.initializeBasicData() 开始执行');

      // 初始化数据库，但不要在这里加载节日数据
      if (!_dbManager.isInitialized) {
        debugPrint('正在初始化数据库...');
        await _dbManager.initialize(null, skipHolidayLoading: true);
        debugPrint('数据库初始化完成');
      } else {
        debugPrint('数据库已初始化，跳过初始化步骤');
      }

      // 检查是否是首次启动
      debugPrint('正在检查是否是首次启动...');
      final isFirstLaunch = await _dbManager.isFirstLaunch();
      debugPrint('是否是首次启动: $isFirstLaunch');

      // 获取当前数据版本
      debugPrint('正在获取当前数据版本...');
      final dataVersion = await _dbManager.getDataVersion('GLOBAL');
      const currentDataVersion = 1; // 当前数据版本
      debugPrint('当前数据版本: $dataVersion, 目标数据版本: $currentDataVersion');

      // 首次启动或数据版本更新时加载全球节日数据
      if (isFirstLaunch || dataVersion < currentDataVersion) {
        debugPrint('首次启动或数据版本更新，加载全球节日数据');

        // 使用HolidayDataSyncService加载全球节日数据
        try {
          debugPrint('使用HolidayDataSyncService加载全球节日数据');

          // 获取HolidayDataSyncService实例
          final syncService = HolidayDataSyncService(
            _dbManager,
            ApiServiceProvider()
          );

          // 加载全球节日数据
          final success = await syncService.initialLoadHolidayData('GLOBAL', 'zh');

          if (success) {
            debugPrint('全球节日数据加载成功');
          } else {
            debugPrint('全球节日数据加载失败，尝试使用本地JSON文件');

            // 如果从服务器加载失败，尝试使用本地JSON文件
            final globalHolidays = await _loadGlobalHolidays();
            debugPrint('从本地JSON文件加载全球节日数据完成，共 ${globalHolidays.length} 条，开始保存到数据库');

            // 分批保存数据，每批最多5条
            const batchSize = 5;
            for (var i = 0; i < globalHolidays.length; i += batchSize) {
              final end = (i + batchSize < globalHolidays.length) ? i + batchSize : globalHolidays.length;
              final batch = globalHolidays.sublist(i, end);

              debugPrint('保存全球节日数据批次 ${i ~/ batchSize + 1}，数量: ${batch.length}');
              await _dbManager.saveHolidays(batch);

              // 添加短暂延迟，让系统有时间进行垃圾回收
              debugPrint('批次 ${i ~/ batchSize + 1} 保存完成，等待垃圾回收...');
              await Future.delayed(const Duration(milliseconds: 300));
            }

            debugPrint('全球节日数据保存完成，共 ${globalHolidays.length} 条');
          }
        } catch (e, stack) {
          debugPrint('加载全球节日数据失败: $e');
          debugPrint('堆栈: $stack');
        }

        // 标记首次启动完成
        if (isFirstLaunch) {
          debugPrint('正在标记首次启动完成...');
          await _dbManager.markFirstLaunchComplete();
          debugPrint('首次启动标记完成');
        }

        // 更新数据版本
        if (dataVersion < currentDataVersion) {
          debugPrint('正在更新数据版本...');
          await _dbManager.updateDataVersion('GLOBAL', currentDataVersion);
          debugPrint('数据版本更新完成');
        }

        debugPrint('基础节日数据加载完成');
      } else {
        debugPrint('非首次启动且数据版本最新，跳过基础节日数据加载');
      }

      debugPrint('HolidayDataLoaderService.initializeBasicData() 执行完成');
    } catch (e, stack) {
      debugPrint('初始化基础数据失败: $e');
      debugPrint('堆栈: $stack');
      // 不抛出异常，让应用继续运行
    } finally {
      _isInitializing = false;
    }
  }

  // 标记是否正在加载地区数据，防止无限循环
  static final Map<String, bool> _isLoadingRegion = {};

  /// 按需加载指定地区的节日数据
  ///
  /// 根据用户的语言和地区加载相应的节日数据
  Future<void> loadRegionDataOnDemand(String region, String languageCode) async {
    if (region.isEmpty) {
      debugPrint('地区代码为空，跳过加载');
      return;
    }

    // 将地区代码转换为小写
    final regionLower = region.toLowerCase();

    // 防止无限循环
    if (_isLoadingRegion[regionLower] == true) {
      debugPrint('$regionLower 地区数据正在加载中，跳过重复加载');
      return;
    }

    _isLoadingRegion[regionLower] = true;

    try {
      debugPrint('HolidayDataLoaderService.loadRegionDataOnDemand() 开始执行，地区: $region, 语言: $languageCode');

      // 确保数据库已初始化
      if (!_dbManager.isInitialized) {
        debugPrint('数据库未初始化，正在初始化...');
        await _dbManager.initialize(null, skipHolidayLoading: true);
        debugPrint('数据库初始化完成');
      } else {
        debugPrint('数据库已初始化，继续执行');
      }

      debugPrint('地区代码转换为小写: $regionLower');

      // 使用HolidayDataSyncService加载地区节日数据
      try {
        debugPrint('使用HolidayDataSyncService加载地区节日数据');

        // 获取HolidayDataSyncService实例
        final syncService = HolidayDataSyncService(
          _dbManager,
          ApiServiceProvider()
        );

        // 加载地区节日数据
        final success = await syncService.initialLoadHolidayData(regionLower, languageCode);

        if (success) {
          debugPrint('$regionLower 地区节日数据加载成功');
        } else {
          debugPrint('$regionLower 地区节日数据加载失败，尝试使用本地JSON文件');

          // 检查该地区的数据是否已加载
          final regionDataKey = 'region_data_loaded_$regionLower';
          debugPrint('正在检查地区数据是否已加载，键: $regionDataKey');
          final regionDataLoaded = await _dbManager.getAppSetting(regionDataKey) == '1';
          debugPrint('地区数据是否已加载: $regionDataLoaded');

          if (!regionDataLoaded) {
            debugPrint('开始从本地JSON文件加载 $regionLower 地区节日数据');
            try {
              debugPrint('正在加载 $regionLower 地区节日数据...');
              final regionalHolidays = await _loadRegionalHolidays(regionLower);
              debugPrint('$regionLower 地区节日数据加载完成，共 ${regionalHolidays.length} 条，开始保存到数据库');

              // 分批保存数据，每批最多5条
              const batchSize = 5;
              for (var i = 0; i < regionalHolidays.length; i += batchSize) {
                final end = (i + batchSize < regionalHolidays.length) ? i + batchSize : regionalHolidays.length;
                final batch = regionalHolidays.sublist(i, end);

                debugPrint('保存 $regionLower 地区节日数据批次 ${i ~/ batchSize + 1}，数量: ${batch.length}');
                await _dbManager.saveHolidays(batch);

                // 添加短暂延迟，让系统有时间进行垃圾回收
                debugPrint('批次 ${i ~/ batchSize + 1} 保存完成，等待垃圾回收...');
                await Future.delayed(const Duration(milliseconds: 300));
              }

              // 标记该地区数据已加载
              debugPrint('正在标记 $regionLower 地区数据已加载...');
              await _dbManager.setAppSetting(regionDataKey, '1');
              debugPrint('$regionLower 地区数据标记完成');

              debugPrint('$regionLower 地区节日数据加载和保存完成，共 ${regionalHolidays.length} 条');
            } catch (e, stack) {
              debugPrint('加载 $regionLower 地区节日数据失败: $e');
              debugPrint('堆栈: $stack');
            }
          } else {
            debugPrint('$regionLower 地区节日数据已加载，跳过');
          }
        }
      } catch (e, stack) {
        debugPrint('使用HolidayDataSyncService加载地区节日数据失败: $e');
        debugPrint('堆栈: $stack');

        // 如果使用HolidayDataSyncService失败，尝试使用本地JSON文件
        debugPrint('尝试使用本地JSON文件加载地区节日数据');

        // 检查该地区的数据是否已加载
        final regionDataKey = 'region_data_loaded_$regionLower';
        debugPrint('正在检查地区数据是否已加载，键: $regionDataKey');
        final regionDataLoaded = await _dbManager.getAppSetting(regionDataKey) == '1';
        debugPrint('地区数据是否已加载: $regionDataLoaded');

        if (!regionDataLoaded) {
          debugPrint('开始从本地JSON文件加载 $regionLower 地区节日数据');
          try {
            debugPrint('正在加载 $regionLower 地区节日数据...');
            final regionalHolidays = await _loadRegionalHolidays(regionLower);
            debugPrint('$regionLower 地区节日数据加载完成，共 ${regionalHolidays.length} 条，开始保存到数据库');

            // 分批保存数据，每批最多5条
            const batchSize = 5;
            for (var i = 0; i < regionalHolidays.length; i += batchSize) {
              final end = (i + batchSize < regionalHolidays.length) ? i + batchSize : regionalHolidays.length;
              final batch = regionalHolidays.sublist(i, end);

              debugPrint('保存 $regionLower 地区节日数据批次 ${i ~/ batchSize + 1}，数量: ${batch.length}');
              await _dbManager.saveHolidays(batch);

              // 添加短暂延迟，让系统有时间进行垃圾回收
              debugPrint('批次 ${i ~/ batchSize + 1} 保存完成，等待垃圾回收...');
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // 标记该地区数据已加载
            debugPrint('正在标记 $regionLower 地区数据已加载...');
            await _dbManager.setAppSetting(regionDataKey, '1');
            debugPrint('$regionLower 地区数据标记完成');

            debugPrint('$regionLower 地区节日数据加载和保存完成，共 ${regionalHolidays.length} 条');
          } catch (e, stack) {
            debugPrint('加载 $regionLower 地区节日数据失败: $e');
            debugPrint('堆栈: $stack');
          }
        } else {
          debugPrint('$regionLower 地区节日数据已加载，跳过');
        }
      }

      // 检查语言特定的节日数据是否已加载（如果语言与地区不同）
      final langLower = languageCode.toLowerCase();
      if (langLower != regionLower) {
        // 防止无限循环
        if (_isLoadingRegion[langLower] == true) {
          debugPrint('$langLower 语言数据正在加载中，跳过重复加载');
        } else {
          _isLoadingRegion[langLower] = true;

          debugPrint('语言代码 $langLower 与地区代码 $regionLower 不同，检查语言特定的节日数据');

          // 使用HolidayDataSyncService加载语言节日数据
          try {
            debugPrint('使用HolidayDataSyncService加载语言节日数据');

            // 获取HolidayDataSyncService实例
            final syncService = HolidayDataSyncService(
              _dbManager,
              ApiServiceProvider()
            );

            // 加载语言节日数据
            final success = await syncService.initialLoadHolidayData(langLower, languageCode);

            if (success) {
              debugPrint('$langLower 语言节日数据加载成功');
            } else {
              debugPrint('$langLower 语言节日数据加载失败，尝试使用本地JSON文件');

              // 如果从服务器加载失败，尝试使用本地JSON文件
              final langDataKey = 'region_data_loaded_$langLower';
              debugPrint('正在检查语言数据是否已加载，键: $langDataKey');
              final langDataLoaded = await _dbManager.getAppSetting(langDataKey) == '1';
              debugPrint('语言数据是否已加载: $langDataLoaded');

              if (!langDataLoaded) {
                debugPrint('开始从本地JSON文件加载 $langLower 语言相关的节日数据');
                try {
                  debugPrint('正在加载 $langLower 语言节日数据...');
                  final langHolidays = await _loadRegionalHolidays(langLower);
                  debugPrint('$langLower 语言节日数据加载完成，共 ${langHolidays.length} 条，开始保存到数据库');

                  // 分批保存数据，每批最多5条
                  const batchSize = 5;
                  for (var i = 0; i < langHolidays.length; i += batchSize) {
                    final end = (i + batchSize < langHolidays.length) ? i + batchSize : langHolidays.length;
                    final batch = langHolidays.sublist(i, end);

                    debugPrint('保存 $langLower 语言节日数据批次 ${i ~/ batchSize + 1}，数量: ${batch.length}');
                    await _dbManager.saveHolidays(batch);

                    // 添加短暂延迟，让系统有时间进行垃圾回收
                    debugPrint('批次 ${i ~/ batchSize + 1} 保存完成，等待垃圾回收...');
                    await Future.delayed(const Duration(milliseconds: 300));
                  }

                  // 标记该语言数据已加载
                  debugPrint('正在标记 $langLower 语言数据已加载...');
                  await _dbManager.setAppSetting(langDataKey, '1');
                  debugPrint('$langLower 语言数据标记完成');

                  debugPrint('$langLower 语言节日数据加载和保存完成，共 ${langHolidays.length} 条');
                } catch (e, stack) {
                  debugPrint('加载 $langLower 语言节日数据失败: $e');
                  debugPrint('堆栈: $stack');
                }
              } else {
                debugPrint('$langLower 语言节日数据已加载，跳过');
              }
            }
          } catch (e, stack) {
            debugPrint('使用HolidayDataSyncService加载语言节日数据失败: $e');
            debugPrint('堆栈: $stack');

            // 如果使用HolidayDataSyncService失败，尝试使用本地JSON文件
            debugPrint('尝试使用本地JSON文件加载语言节日数据');

            final langDataKey = 'region_data_loaded_$langLower';
            debugPrint('正在检查语言数据是否已加载，键: $langDataKey');
            final langDataLoaded = await _dbManager.getAppSetting(langDataKey) == '1';
            debugPrint('语言数据是否已加载: $langDataLoaded');

            if (!langDataLoaded) {
              debugPrint('开始从本地JSON文件加载 $langLower 语言相关的节日数据');
              try {
                debugPrint('正在加载 $langLower 语言节日数据...');
                final langHolidays = await _loadRegionalHolidays(langLower);
                debugPrint('$langLower 语言节日数据加载完成，共 ${langHolidays.length} 条，开始保存到数据库');

                // 分批保存数据，每批最多5条
                const batchSize = 5;
                for (var i = 0; i < langHolidays.length; i += batchSize) {
                  final end = (i + batchSize < langHolidays.length) ? i + batchSize : langHolidays.length;
                  final batch = langHolidays.sublist(i, end);

                  debugPrint('保存 $langLower 语言节日数据批次 ${i ~/ batchSize + 1}，数量: ${batch.length}');
                  await _dbManager.saveHolidays(batch);

                  // 添加短暂延迟，让系统有时间进行垃圾回收
                  debugPrint('批次 ${i ~/ batchSize + 1} 保存完成，等待垃圾回收...');
                  await Future.delayed(const Duration(milliseconds: 300));
                }

                // 标记该语言数据已加载
                debugPrint('正在标记 $langLower 语言数据已加载...');
                await _dbManager.setAppSetting(langDataKey, '1');
                debugPrint('$langLower 语言数据标记完成');

                debugPrint('$langLower 语言节日数据加载和保存完成，共 ${langHolidays.length} 条');
              } catch (e, stack) {
                debugPrint('加载 $langLower 语言节日数据失败: $e');
                debugPrint('堆栈: $stack');
              }
            } else {
              debugPrint('$langLower 语言节日数据已加载，跳过');
            }
          }

          _isLoadingRegion[langLower] = false;
        }
      } else {
        debugPrint('语言代码与地区代码相同，跳过语言特定的节日数据加载');
      }

      debugPrint('HolidayDataLoaderService.loadRegionDataOnDemand() 执行完成');
    } catch (e, stack) {
      debugPrint('按需加载地区数据失败: $e');
      debugPrint('堆栈: $stack');
      // 不抛出异常，让应用继续运行
    } finally {
      _isLoadingRegion[regionLower] = false;
    }
  }

  // 标记是否正在检查地区数据，防止无限循环
  static final Map<String, bool> _isCheckingRegion = {};

  /// 检查指定地区的节日数据是否已加载
  Future<bool> isRegionDataLoaded(String region) async {
    if (region.isEmpty) {
      debugPrint('地区代码为空，默认返回已加载');
      return true;
    }

    // 将地区代码转换为小写
    final regionLower = region.toLowerCase();

    // 防止无限循环
    if (_isCheckingRegion[regionLower] == true) {
      debugPrint('$regionLower 地区数据正在检查中，跳过重复检查，默认返回未加载');
      return false;
    }

    _isCheckingRegion[regionLower] = true;

    try {
      debugPrint('HolidayDataLoaderService.isRegionDataLoaded() 开始执行，地区: $region');

      // 确保数据库已初始化
      if (!_dbManager.isInitialized) {
        debugPrint('数据库未初始化，正在初始化...');
        await _dbManager.initialize(null, skipHolidayLoading: true);
        debugPrint('数据库初始化完成');
      } else {
        debugPrint('数据库已初始化，继续执行');
      }

      final regionDataKey = 'region_data_loaded_$regionLower';
      debugPrint('正在检查地区数据是否已加载，键: $regionDataKey');
      final result = await _dbManager.getAppSetting(regionDataKey) == '1';
      debugPrint('地区数据是否已加载: $result');
      return result;
    } catch (e, stack) {
      debugPrint('检查地区数据是否已加载失败: $e');
      debugPrint('堆栈: $stack');
      return false;
    } finally {
      _isCheckingRegion[regionLower] = false;
    }
  }

  /// 从JSON文件加载全球节日数据
  Future<List<Holiday>> _loadGlobalHolidays() async {
    try {
      debugPrint('HolidayDataLoaderService._loadGlobalHolidays() 开始执行');

      // 加载JSON文件
      debugPrint('正在加载全球节日数据文件...');
      final jsonString = await rootBundle.loadString('assets/data/preset_holidays.json');
      debugPrint('全球节日数据文件加载完成，长度: ${jsonString.length}');

      debugPrint('正在解析JSON数据...');
      final jsonData = json.decode(jsonString);
      debugPrint('JSON数据解析完成');

      // 解析全球节日数据
      debugPrint('正在提取全球节日数据...');
      final List<dynamic> holidaysJson = jsonData['global_holidays'];
      debugPrint('提取到 ${holidaysJson.length} 条全球节日记录');

      final List<Holiday> holidays = [];
      debugPrint('开始逐个解析节日数据...');

      int count = 0;
      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
          count++;
          if (count % 10 == 0) {
            debugPrint('已解析 $count/${holidaysJson.length} 条节日数据');
          }
        } catch (e, stack) {
          debugPrint('解析节日数据失败: $e');
          debugPrint('堆栈: $stack');
          // 继续处理下一条数据
        }
      }

      debugPrint('从JSON文件加载了 ${holidays.length} 个全球节日');
      debugPrint('HolidayDataLoaderService._loadGlobalHolidays() 执行完成');
      return holidays;
    } catch (e, stack) {
      debugPrint('加载全球节日数据失败: $e');
      debugPrint('堆栈: $stack');
      return [];
    }
  }

  /// 从JSON文件加载地区节日数据
  Future<List<Holiday>> _loadRegionalHolidays(String region) async {
    try {
      debugPrint('HolidayDataLoaderService._loadRegionalHolidays() 开始执行，地区: $region');

      // 加载JSON文件
      final filePath = 'assets/data/holidays_$region.json';
      debugPrint('正在加载地区节日数据文件: $filePath');
      final jsonString = await rootBundle.loadString(filePath);
      debugPrint('地区节日数据文件加载完成，长度: ${jsonString.length}');

      debugPrint('正在解析JSON数据...');
      final jsonData = json.decode(jsonString);
      debugPrint('JSON数据解析完成');

      // 解析地区节日数据
      debugPrint('正在提取地区节日数据...');
      final List<dynamic> holidaysJson = jsonData['holidays'];
      debugPrint('提取到 ${holidaysJson.length} 条地区节日记录');

      final List<Holiday> holidays = [];
      debugPrint('开始逐个解析节日数据...');

      int count = 0;
      for (final holidayJson in holidaysJson) {
        try {
          final holiday = _parseHolidayJson(holidayJson);
          holidays.add(holiday);
          count++;
          if (count % 10 == 0) {
            debugPrint('已解析 $count/${holidaysJson.length} 条节日数据');
          }
        } catch (e, stack) {
          debugPrint('解析节日数据失败: $e');
          debugPrint('堆栈: $stack');
          // 继续处理下一条数据
        }
      }

      debugPrint('从JSON文件加载了 ${holidays.length} 个 $region 地区节日');
      debugPrint('HolidayDataLoaderService._loadRegionalHolidays() 执行完成');
      return holidays;
    } catch (e, stack) {
      debugPrint('加载 $region 地区节日数据失败: $e');
      debugPrint('堆栈: $stack');
      return [];
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
    final Map<String, String> descriptions = {};
    if (json['descriptions'] != null) {
      (json['descriptions'] as Map<String, dynamic>).forEach((key, value) {
        descriptions[key] = value.toString();
      });
    }

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
      isSystemHoliday: true,
      names: names,
      type: _parseHolidayType(json['type']),
      regions: List<String>.from(json['regions']),
      calculationType: _parseCalculationType(json['calculation_type']),
      calculationRule: json['calculation_rule'],
      descriptions: descriptions,
      importanceLevel: _parseImportanceLevel(json['importance_level']),
      customs: customs,
      foods: foods,
      greetings: greetings,
      activities: activities,
      history: history,
      userImportance: 0,
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
      default:
        return HolidayType.other;
    }
  }

  /// 解析日期计算类型
  DateCalculationType _parseCalculationType(String type) {
    switch (type) {
      case 'fixed_gregorian':
        return DateCalculationType.fixedGregorian;
      case 'fixed_lunar':
        return DateCalculationType.fixedLunar;
      case 'variable_rule':
      case 'nth_weekday_of_month':
        return DateCalculationType.variableRule;
      case 'custom_rule':
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
}
