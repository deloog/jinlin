import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';

/// 节日编辑界面
class HolidayEditScreen extends StatefulWidget {
  final Holiday? holiday;

  const HolidayEditScreen({super.key, this.holiday});

  @override
  State<HolidayEditScreen> createState() => _HolidayEditScreenState();
}

class _HolidayEditScreenState extends State<HolidayEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // 表单控制器
  late TextEditingController _idController;
  late TextEditingController _nameZhController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionZhController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _calculationRuleController;

  // 表单数据
  late bool _isSystemHoliday;
  late HolidayType _selectedType;
  late DateCalculationType _selectedCalculationType;
  late ImportanceLevel _selectedImportanceLevel;
  late List<String> _selectedRegions;

  // 多语言数据
  late Map<String, String> _names;
  late Map<String, String> _descriptions;
  late Map<String, String>? _customs;
  late Map<String, String>? _foods;
  late Map<String, String>? _greetings;

  // 地区列表
  final List<String> _availableRegions = [
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
    _initFormData();
  }

  /// 初始化表单数据
  void _initFormData() {
    final holiday = widget.holiday;

    // 初始化控制器
    _idController = TextEditingController(text: holiday?.id ?? '');
    _nameZhController = TextEditingController(text: holiday?.names['zh'] ?? '');
    _nameEnController = TextEditingController(text: holiday?.names['en'] ?? '');
    _descriptionZhController = TextEditingController(text: holiday?.descriptions['zh'] ?? '');
    _descriptionEnController = TextEditingController(text: holiday?.descriptions['en'] ?? '');
    _calculationRuleController = TextEditingController(text: holiday?.calculationRule ?? '');

    // 初始化表单数据
    _isSystemHoliday = holiday?.isSystemHoliday ?? false;
    _selectedType = holiday?.type ?? HolidayType.custom;
    _selectedCalculationType = holiday?.calculationType ?? DateCalculationType.fixedGregorian;
    _selectedImportanceLevel = holiday?.importanceLevel ?? ImportanceLevel.medium;
    _selectedRegions = holiday?.regions.toList() ?? ['ALL'];

    // 初始化多语言数据
    _names = Map<String, String>.from(holiday?.names ?? {'zh': '', 'en': ''});
    _descriptions = Map<String, String>.from(holiday?.descriptions ?? {'zh': '', 'en': ''});
    _customs = holiday?.customs != null ? Map<String, String>.from(holiday!.customs!) : null;
    _foods = holiday?.foods != null ? Map<String, String>.from(holiday!.foods!) : null;
    _greetings = holiday?.greetings != null ? Map<String, String>.from(holiday!.greetings!) : null;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameZhController.dispose();
    _nameEnController.dispose();
    _descriptionZhController.dispose();
    _descriptionEnController.dispose();
    _calculationRuleController.dispose();
    super.dispose();
  }

  /// 保存节日数据
  Future<void> _saveHoliday() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 更新多语言数据
      _names['zh'] = _nameZhController.text.trim();
      _names['en'] = _nameEnController.text.trim();
      _descriptions['zh'] = _descriptionZhController.text.trim();
      _descriptions['en'] = _descriptionEnController.text.trim();

      // 创建或更新节日对象
      final holiday = Holiday(
        id: _idController.text.trim().isEmpty
            ? 'holiday_${const Uuid().v4()}'
            : _idController.text.trim(),
        isSystemHoliday: _isSystemHoliday,
        names: _names,
        type: _selectedType,
        regions: _selectedRegions,
        calculationType: _selectedCalculationType,
        calculationRule: _calculationRuleController.text.trim(),
        descriptions: _descriptions,
        importanceLevel: _selectedImportanceLevel,
        customs: _customs,
        foods: _foods,
        greetings: _greetings,
        userImportance: 0,
      );

      // 保存到数据库
      final dbManager = Provider.of<DatabaseManagerUnified>(context, listen: false);
      await dbManager.saveHoliday(holiday);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '保存节日失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.holiday == null ? '添加节日' : '编辑节日'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('保存'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _isLoading ? null : _saveHoliday,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 错误信息
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // 基本信息
                    const Text(
                      '基本信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ID
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'ID',
                        helperText: '留空将自动生成',
                        border: OutlineInputBorder(),
                      ),
                      enabled: widget.holiday == null, // 只有新建时才能编辑ID
                    ),
                    const SizedBox(height: 16),

                    // 系统预设节日
                    SwitchListTile(
                      title: const Text('系统预设节日'),
                      value: _isSystemHoliday,
                      onChanged: (value) {
                        setState(() {
                          _isSystemHoliday = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 中文名称
                    TextFormField(
                      controller: _nameZhController,
                      decoration: const InputDecoration(
                        labelText: '中文名称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入中文名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 英文名称
                    TextFormField(
                      controller: _nameEnController,
                      decoration: const InputDecoration(
                        labelText: '英文名称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入英文名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 节日类型
                    DropdownButtonFormField<HolidayType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: '节日类型',
                        border: OutlineInputBorder(),
                      ),
                      items: HolidayType.values.map((type) {
                        return DropdownMenuItem<HolidayType>(
                          value: type,
                          child: Text(_getHolidayTypeText(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 地区选择
                    const Text('适用地区'),
                    Wrap(
                      spacing: 8,
                      children: _availableRegions.map((region) {
                        final isSelected = _selectedRegions.contains(region);
                        return FilterChip(
                          label: Text(_regionNames[region] ?? region),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRegions.add(region);
                              } else {
                                _selectedRegions.remove(region);
                              }

                              // 确保至少选择一个地区
                              if (_selectedRegions.isEmpty) {
                                _selectedRegions.add('ALL');
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 日期计算类型
                    DropdownButtonFormField<DateCalculationType>(
                      value: _selectedCalculationType,
                      decoration: const InputDecoration(
                        labelText: '日期计算类型',
                        border: OutlineInputBorder(),
                      ),
                      items: DateCalculationType.values.map((type) {
                        return DropdownMenuItem<DateCalculationType>(
                          value: type,
                          child: Text(_getCalculationTypeText(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCalculationType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 计算规则
                    TextFormField(
                      controller: _calculationRuleController,
                      decoration: InputDecoration(
                        labelText: '计算规则',
                        helperText: _getCalculationRuleHelperText(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入计算规则';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 重要性级别
                    DropdownButtonFormField<ImportanceLevel>(
                      value: _selectedImportanceLevel,
                      decoration: const InputDecoration(
                        labelText: '重要性级别',
                        border: OutlineInputBorder(),
                      ),
                      items: ImportanceLevel.values.map((level) {
                        return DropdownMenuItem<ImportanceLevel>(
                          value: level,
                          child: Text(_getImportanceLevelText(level)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedImportanceLevel = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 描述信息
                    const Text(
                      '描述信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 中文描述
                    TextFormField(
                      controller: _descriptionZhController,
                      decoration: const InputDecoration(
                        labelText: '中文描述',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // 英文描述
                    TextFormField(
                      controller: _descriptionEnController,
                      decoration: const InputDecoration(
                        labelText: '英文描述',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveHoliday,
                        child: Text(widget.holiday == null ? '添加节日' : '保存修改'),
                      ),
                    ),
                  ],
                ),
              ),
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

  /// 获取计算类型文本
  String _getCalculationTypeText(DateCalculationType type) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        return '固定公历日期';
      case DateCalculationType.fixedLunar:
        return '固定农历日期';
      case DateCalculationType.variableRule:
        return '可变规则';
      case DateCalculationType.custom:
        return '自定义规则';
    }
  }

  /// 获取重要性级别文本
  String _getImportanceLevelText(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.low:
        return '低';
      case ImportanceLevel.medium:
        return '中';
      case ImportanceLevel.high:
        return '高';
    }
  }

  /// 获取计算规则帮助文本
  String _getCalculationRuleHelperText() {
    switch (_selectedCalculationType) {
      case DateCalculationType.fixedGregorian:
        return '格式: MM-DD (例如: 01-01 表示1月1日)';
      case DateCalculationType.fixedLunar:
        return '格式: LMM-DD (例如: L01-01 表示农历正月初一)';
      case DateCalculationType.variableRule:
        return '格式: MM-W-D (例如: 11-4-4 表示11月第4个星期四)';
      case DateCalculationType.custom:
        return '自定义规则格式';
    }
  }
}
