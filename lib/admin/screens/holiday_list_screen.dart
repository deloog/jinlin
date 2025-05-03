import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/admin/screens/holiday_edit_screen.dart';

/// 节日列表界面
class HolidayListScreen extends StatefulWidget {
  const HolidayListScreen({super.key});

  @override
  State<HolidayListScreen> createState() => _HolidayListScreenState();
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  List<Holiday> _holidays = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedRegion = 'ALL';

  // 地区列表
  final List<String> _regions = [
    'ALL', 'CN', 'US', 'JP', 'KR', 'FR', 'DE', 'GB',
  ];

  // 地区名称映射
  final Map<String, String> _regionNames = {
    'ALL': '全部地区',
    'CN': '中国',
    'US': '美国',
    'JP': '日本',
    'KR': '韩国',
    'FR': '法国',
    'DE': '德国',
    'GB': '英国',
  };

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  /// 加载节日数据
  Future<void> _loadHolidays() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbManager = Provider.of<DatabaseManagerUnified>(context, listen: false);
      await dbManager.initialize(context);

      List<Holiday> holidays;
      if (_selectedRegion == 'ALL') {
        final result = await dbManager.getAllHolidays();
        holidays = List<Holiday>.from(result);
      } else {
        final result = await dbManager.getHolidaysByRegion(_selectedRegion);
        holidays = List<Holiday>.from(result);
      }

      if (mounted) {
        setState(() {
          _holidays = holidays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载节日数据失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 删除节日
  Future<void> _deleteHoliday(Holiday holiday) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除节日 "${holiday.getLocalizedName('zh')}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 在异步操作前获取数据库管理器
      final dbManager = Provider.of<DatabaseManagerUnified>(context, listen: false);
      await dbManager.deleteHoliday(holiday.id);

      // 重新加载数据
      await _loadHolidays();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除节日 "${holiday.getLocalizedName('zh')}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '删除节日失败: $e';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除节日失败: $e')),
        );
      }
    }
  }

  /// 筛选节日
  List<Holiday> get _filteredHolidays {
    if (_searchQuery.isEmpty) {
      return _holidays;
    }

    final query = _searchQuery.toLowerCase();
    return _holidays.where((holiday) {
      // 搜索名称（所有语言）
      for (final name in holiday.names.values) {
        if (name.toLowerCase().contains(query)) {
          return true;
        }
      }

      // 搜索描述（所有语言）
      for (final description in holiday.descriptions.values) {
        if (description.toLowerCase().contains(query)) {
          return true;
        }
      }

      // 搜索ID
      if (holiday.id.toLowerCase().contains(query)) {
        return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('节日管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadHolidays,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedRegion,
                  items: _regions.map((region) {
                    return DropdownMenuItem<String>(
                      value: region,
                      child: Text(_regionNames[region] ?? region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedRegion) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _loadHolidays();
                    }
                  },
                ),
              ],
            ),
          ),

          // 错误信息
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // 节日列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildHolidayList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!mounted) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HolidayEditScreen(),
            ),
          );

          if (result == true && mounted) {
            _loadHolidays();
          }
        },
        tooltip: '添加节日',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建节日列表
  Widget _buildHolidayList() {
    final filteredHolidays = _filteredHolidays;

    if (filteredHolidays.isEmpty) {
      return const Center(
        child: Text('没有找到节日数据'),
      );
    }

    return ListView.builder(
      itemCount: filteredHolidays.length,
      itemBuilder: (context, index) {
        final holiday = filteredHolidays[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(holiday.getLocalizedName('zh')),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${holiday.id}'),
                Text('地区: ${holiday.regions.join(', ')}'),
                Text('类型: ${_getHolidayTypeText(holiday.type)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                  onPressed: () async {
                    if (!mounted) return;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HolidayEditScreen(holiday: holiday),
                      ),
                    );

                    if (result == true && mounted) {
                      _loadHolidays();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '删除',
                  onPressed: () => _deleteHoliday(holiday),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () async {
              if (!mounted) return;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HolidayEditScreen(holiday: holiday),
                ),
              );

              if (result == true && mounted) {
                _loadHolidays();
              }
            },
          ),
        );
      },
    );
  }

  /// 获取节日类型文本
  String _getHolidayTypeText(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return '法定节日';
      case HolidayType.traditional:
        return '传统节日';
      case HolidayType.solarTerm:
        return '节气';
      case HolidayType.memorial:
        return '纪念日';
      case HolidayType.custom:
        return '自定义';
      case HolidayType.religious:
        return '宗教节日';
      case HolidayType.international:
        return '国际节日';
      case HolidayType.professional:
        return '职业节日';
      case HolidayType.cultural:
        return '文化节日';
      case HolidayType.other:
        return '其他';
    }
  }
}
