// 文件： lib/holiday_management_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:jinlin_app/services/holiday_storage_service.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/holiday_migration_service.dart';
import 'package:jinlin_app/models/holiday_model.dart' hide DateCalculationType, ImportanceLevel;
import 'package:jinlin_app/adapters/holiday_adapter.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  // 用户自定义节日重要性
  Map<String, int> _holidayImportance = {};
  List<SpecialDate> _allHolidays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHolidayImportance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHolidays();
  }

  // 加载所有节日
  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });

    // 初始化Hive数据库
    await HiveDatabaseService.initialize();

    // 检查数据库迁移是否完成
    final migrationComplete = HiveDatabaseService.isMigrationComplete();

    // 如果数据库迁移未完成，则执行迁移
    if (!migrationComplete && mounted) {
      try {
        // 执行数据迁移
        await HolidayMigrationService.migrateHolidays(context);
        debugPrint("数据迁移成功完成");
      } catch (e) {
        debugPrint("数据迁移失败: $e");
      }
    }

    // 获取用户所在地区
    final String userRegion;
    if (mounted) {
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'zh') {
        userRegion = 'CN'; // 中文环境
      } else if (locale.languageCode == 'ja') {
        userRegion = 'JP'; // 日语环境
      } else if (locale.languageCode == 'ko') {
        userRegion = 'KR'; // 韩语环境
      } else {
        userRegion = 'INTL'; // 其他语言环境
      }
    } else {
      userRegion = 'INTL'; // 默认国际节日
    }

    // 获取用户所在地区的节日
    if (mounted) {
      if (migrationComplete) {
        // 如果数据库迁移已完成，从数据库获取节日
        final holidayModels = HiveDatabaseService.getHolidaysByRegion(userRegion);

        // 将HolidayModel转换为SpecialDate
        _allHolidays = HolidayAdapter.toSpecialDateList(holidayModels);
        debugPrint("从Hive数据库加载了 ${_allHolidays.length} 个节日");
      } else {
        // 如果数据库迁移未完成，使用本地存储服务获取节日
        _allHolidays = HolidayStorageService.getHolidaysForRegion(context, userRegion);
        debugPrint("从本地存储服务加载了 ${_allHolidays.length} 个节日");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载用户自定义节日重要性
  Future<void> _loadHolidayImportance() async {
    try {
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 检查数据库迁移是否完成
      final migrationComplete = HiveDatabaseService.isMigrationComplete();

      Map<String, int> importanceMap;

      // 如果数据库迁移已完成，从数据库获取节日重要性
      if (migrationComplete) {
        importanceMap = HiveDatabaseService.getHolidayImportance();
        debugPrint("从Hive数据库加载了节日重要性");
      } else {
        // 如果数据库迁移未完成，使用本地存储服务获取节日重要性
        importanceMap = await HolidayStorageService.getHolidayImportance();
        debugPrint("从本地存储服务加载了节日重要性");
      }

      if (mounted) {
        setState(() {
          _holidayImportance = importanceMap;
        });
      }
    } catch (e) {
      debugPrint("加载节日重要性失败: $e");
    }
  }

  // 保存用户自定义节日重要性
  Future<void> _saveHolidayImportance() async {
    try {
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 检查数据库迁移是否完成
      final migrationComplete = HiveDatabaseService.isMigrationComplete();

      bool success = false;

      // 如果数据库迁移已完成，保存到数据库
      if (migrationComplete) {
        await HiveDatabaseService.saveHolidayImportance(_holidayImportance);
        success = true;
        debugPrint("节日重要性已保存到Hive数据库");
      } else {
        // 如果数据库迁移未完成，保存到本地存储
        success = await HolidayStorageService.saveHolidayImportance(_holidayImportance);
        debugPrint("节日重要性已保存到本地存储");
      }

      // 通知主页面刷新特殊纪念日显示
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('节日重要性设置已保存')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存节日重要性失败，请重试')),
          );
        }
      }
    } catch (e) {
      debugPrint("保存节日重要性失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存节日重要性失败: $e')),
        );
      }
    }
  }

  // 设置节日重要性
  Future<void> _setHolidayImportance(String holidayId, int importance) async {
    setState(() {
      _holidayImportance[holidayId] = importance;
    });

    try {
      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 检查数据库迁移是否完成
      final migrationComplete = HiveDatabaseService.isMigrationComplete();

      // 如果数据库迁移已完成，更新数据库
      if (migrationComplete) {
        await HiveDatabaseService.updateHolidayImportance(holidayId, importance);
        debugPrint("节日重要性已更新到Hive数据库");
      } else {
        // 如果数据库迁移未完成，更新本地存储
        await HolidayStorageService.updateHolidayImportance(holidayId, importance);
        debugPrint("节日重要性已更新到本地存储");
      }
    } catch (e) {
      debugPrint("更新节日重要性失败: $e");
    }

    // 保存所有节日重要性
    await _saveHolidayImportance();
  }

  // 获取节日重要性
  int _getHolidayImportance(String holidayId) {
    return _holidayImportance[holidayId] ?? 0; // 默认为0（普通重要性）
  }

  @override
  Widget build(BuildContext context) {
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(isChinese ? '节日管理' : 'Holiday Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isChinese
                      ? '设置节日的重要性，重要的节日将始终显示在时间线上'
                      : 'Set the importance of holidays. Important holidays will always be displayed on the timeline.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Divider(),
                ..._buildHolidayList(),
              ],
            ),
    );
  }

  List<Widget> _buildHolidayList() {
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';

    // 按类型分组节日
    final Map<SpecialDateType, List<SpecialDate>> groupedHolidays = {};

    for (final holiday in _allHolidays) {
      if (!groupedHolidays.containsKey(holiday.type)) {
        groupedHolidays[holiday.type] = [];
      }
      groupedHolidays[holiday.type]!.add(holiday);
    }

    final List<Widget> widgets = [];

    // 为每个类型创建一个组
    groupedHolidays.forEach((type, holidays) {
      // 添加类型标题
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            _getHolidayTypeTitle(type, isChinese),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // 添加该类型的所有节日
      for (final holiday in holidays) {
        widgets.add(
          ListTile(
            title: Text(holiday.name),
            subtitle: Text(_getImportanceText(_getHolidayImportance(holiday.id), isChinese)),
            trailing: DropdownButton<int>(
              value: _getHolidayImportance(holiday.id),
              onChanged: (int? newValue) async {
                if (newValue != null) {
                  await _setHolidayImportance(holiday.id, newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(isChinese ? '普通' : 'Normal'),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(isChinese ? '重要' : 'Important'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(isChinese ? '非常重要' : 'Very Important'),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(const Divider());
    });

    return widgets;
  }

  String _getHolidayTypeTitle(SpecialDateType type, bool isChinese) {
    switch (type) {
      case SpecialDateType.statutory:
        return isChinese ? '法定节日' : 'Statutory Holiday';
      case SpecialDateType.traditional:
        return isChinese ? '传统节日' : 'Traditional Holiday';
      case SpecialDateType.memorial:
        return isChinese ? '纪念日' : 'Memorial Day';
      case SpecialDateType.solarTerm:
        return isChinese ? '节气' : 'Solar Term';
      default:
        return isChinese ? '其他节日' : 'Other Holiday';
    }
  }

  String _getImportanceText(int importance, bool isChinese) {
    switch (importance) {
      case 1:
        return isChinese ? '重要' : 'Important';
      case 2:
        return isChinese ? '非常重要' : 'Very Important';
      default:
        return isChinese ? '普通' : 'Normal';
    }
  }
}
