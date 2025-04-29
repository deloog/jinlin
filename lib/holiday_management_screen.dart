// 文件： lib/holiday_management_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:jinlin_app/services/holiday_storage_service.dart';

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

    // 获取用户所在地区
    final String userRegion = HolidayStorageService.getUserRegion(context);

    // 获取用户所在地区的节日
    if (mounted) {
      _allHolidays = HolidayStorageService.getHolidaysForRegion(context, userRegion);
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
      final importanceMap = await HolidayStorageService.getHolidayImportance();

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
      // 保存到本地存储
      final success = await HolidayStorageService.saveHolidayImportance(_holidayImportance);

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

    // 更新本地存储
    await HolidayStorageService.updateHolidayImportance(holidayId, importance);

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
