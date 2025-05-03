import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/admin/holiday_edit_screen.dart';

/// 管理后台节日管理界面
class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();
  List<Holiday> _holidays = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRegion = 'ALL';
  HolidayType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  /// 加载节日数据
  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dbManager.initialize(null);
      final holidays = await _dbManager.getAllHolidays();

      setState(() {
        _holidays = holidays;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载节日数据失败: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载节日数据失败: $e')),
        );
      }
    }
  }

  /// 过滤节日数据
  List<Holiday> _getFilteredHolidays() {
    return _holidays.where((holiday) {
      // 搜索条件
      final searchMatch = _searchQuery.isEmpty ||
          holiday.names.values.any((name) =>
              name.toLowerCase().contains(_searchQuery.toLowerCase()));

      // 地区条件
      final regionMatch = _selectedRegion == 'ALL' ||
          holiday.regions.contains(_selectedRegion);

      // 类型条件
      final typeMatch = _selectedType == null ||
          holiday.type == _selectedType;

      return searchMatch && regionMatch && typeMatch;
    }).toList();
  }

  /// 删除节日
  Future<void> _deleteHoliday(Holiday holiday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除节日 "${holiday.names['zh'] ?? holiday.names['en'] ?? ''}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbManager.deleteHoliday(holiday.id);

        setState(() {
          _holidays.removeWhere((h) => h.id == holiday.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('节日已删除')),
          );
        }
      } catch (e) {
        debugPrint('删除节日失败: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除节日失败: $e')),
          );
        }
      }
    }
  }

  /// 编辑节日
  Future<void> _editHoliday(Holiday holiday) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HolidayEditScreen(holiday: holiday),
      ),
    );

    if (result == true) {
      _loadHolidays();
    }
  }

  /// 添加节日
  Future<void> _addHoliday() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HolidayEditScreen(),
      ),
    );

    if (result == true) {
      _loadHolidays();
    }
  }

  /// 导入节日数据
  Future<void> _importHolidays() async {
    // TODO: 实现节日数据导入功能
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('节日数据导入功能尚未实现')),
      );
    }
  }

  /// 导出节日数据
  Future<void> _exportHolidays() async {
    // TODO: 实现节日数据导出功能
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('节日数据导出功能尚未实现')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHolidays = _getFilteredHolidays();

    return Scaffold(
      appBar: AppBar(
        title: const Text('节日管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导入节日数据',
            onPressed: _importHolidays,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出节日数据',
            onPressed: _exportHolidays,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  decoration: const InputDecoration(
                    labelText: '搜索节日',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // 筛选选项
                Row(
                  children: [
                    // 地区筛选
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '地区',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRegion,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('所有地区')),
                          DropdownMenuItem(value: 'CN', child: Text('中国')),
                          DropdownMenuItem(value: 'US', child: Text('美国')),
                          DropdownMenuItem(value: 'JP', child: Text('日本')),
                          DropdownMenuItem(value: 'KR', child: Text('韩国')),
                          DropdownMenuItem(value: 'FR', child: Text('法国')),
                          DropdownMenuItem(value: 'DE', child: Text('德国')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRegion = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 类型筛选
                    Expanded(
                      child: DropdownButtonFormField<HolidayType?>(
                        decoration: const InputDecoration(
                          labelText: '类型',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedType,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('所有类型')),
                          DropdownMenuItem(value: HolidayType.statutory, child: Text('法定节日')),
                          DropdownMenuItem(value: HolidayType.traditional, child: Text('传统节日')),
                          DropdownMenuItem(value: HolidayType.memorial, child: Text('纪念日')),
                          DropdownMenuItem(value: HolidayType.religious, child: Text('宗教节日')),
                          DropdownMenuItem(value: HolidayType.professional, child: Text('行业节日')),
                          DropdownMenuItem(value: HolidayType.international, child: Text('国际节日')),
                          DropdownMenuItem(value: HolidayType.other, child: Text('其他')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 节日列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHolidays.isEmpty
                    ? const Center(child: Text('没有找到符合条件的节日'))
                    : ListView.builder(
                        itemCount: filteredHolidays.length,
                        itemBuilder: (context, index) {
                          final holiday = filteredHolidays[index];
                          return ListTile(
                            title: Text(holiday.names['zh'] ?? holiday.names['en'] ?? '未命名节日'),
                            subtitle: Text(
                              '${_getHolidayTypeText(holiday.type)} | ${holiday.regions.join(', ')}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editHoliday(holiday),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteHoliday(holiday),
                                ),
                              ],
                            ),
                            onTap: () => _editHoliday(holiday),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        tooltip: '添加节日',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 获取节日类型文本
  String _getHolidayTypeText(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return '法定节日';
      case HolidayType.traditional:
        return '传统节日';
      case HolidayType.memorial:
        return '纪念日';
      case HolidayType.religious:
        return '宗教节日';
      case HolidayType.professional:
        return '行业节日';
      case HolidayType.international:
        return '国际节日';
      case HolidayType.solarTerm:
        return '节气';
      case HolidayType.custom:
        return '自定义';
      case HolidayType.cultural:
        return '文化节日';
      case HolidayType.other:
        return '其他';
    }
  }
}
