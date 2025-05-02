import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 管理后台节日编辑界面
class HolidayEditScreen extends StatefulWidget {
  final Holiday? holiday;

  const HolidayEditScreen({super.key, this.holiday});

  @override
  State<HolidayEditScreen> createState() => _HolidayEditScreenState();
}

class _HolidayEditScreenState extends State<HolidayEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseManagerUnified _dbManager = DatabaseManagerUnified();

  // 表单字段
  late String _id;
  final Map<String, String> _names = {};
  final Map<String, String> _descriptions = {};
  final Map<String, String> _customs = {};
  final Map<String, String> _foods = {};
  final Map<String, String> _greetings = {};
  final Map<String, String> _activities = {};
  final Map<String, String> _history = {};
  final List<String> _regions = [];
  late HolidayType _type;
  late DateCalculationType _calculationType;
  late String _calculationRule;
  late ImportanceLevel _importanceLevel;
  late bool _isSystemHoliday;

  // 支持的语言
  final List<String> _supportedLanguages = ['zh', 'en', 'ja', 'ko', 'fr', 'de'];

  // 支持的地区
  final List<String> _availableRegions = ['ALL', 'CN', 'US', 'JP', 'KR', 'FR', 'DE'];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  /// 初始化表单数据
  void _initializeFormData() {
    if (widget.holiday != null) {
      // 编辑现有节日
      _id = widget.holiday!.id;
      _names.addAll(widget.holiday!.names);
      _descriptions.addAll(widget.holiday!.descriptions ?? {});
      _customs.addAll(widget.holiday!.customs ?? {});
      _foods.addAll(widget.holiday!.foods ?? {});
      _greetings.addAll(widget.holiday!.greetings ?? {});
      _activities.addAll(widget.holiday!.activities ?? {});
      _history.addAll(widget.holiday!.history ?? {});
      _regions.addAll(widget.holiday!.regions);
      _type = widget.holiday!.type;
      _calculationType = widget.holiday!.calculationType;
      _calculationRule = widget.holiday!.calculationRule;
      _importanceLevel = widget.holiday!.importanceLevel;
      _isSystemHoliday = widget.holiday!.isSystemHoliday;
    } else {
      // 创建新节日
      _id = 'holiday_${DateTime.now().millisecondsSinceEpoch}';
      _type = HolidayType.traditional;
      _calculationType = DateCalculationType.fixedGregorian;
      _calculationRule = '';
      _importanceLevel = ImportanceLevel.medium;
      _isSystemHoliday = true;
      _regions.add('ALL');
    }
  }

  /// 保存节日
  Future<void> _saveHoliday() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final holiday = Holiday(
        id: _id,
        names: _names,
        type: _type,
        regions: _regions,
        calculationType: _calculationType,
        calculationRule: _calculationRule,
        descriptions: _descriptions.isEmpty ? null : _descriptions,
        importanceLevel: _importanceLevel,
        customs: _customs.isEmpty ? null : _customs,
        foods: _foods.isEmpty ? null : _foods,
        greetings: _greetings.isEmpty ? null : _greetings,
        activities: _activities.isEmpty ? null : _activities,
        history: _history.isEmpty ? null : _history,
        isSystemHoliday: _isSystemHoliday,
        userImportance: 0,
      );

      await _dbManager.initialize(null);
      await _dbManager.saveHoliday(holiday);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('节日保存成功')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('保存节日失败: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存节日失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.holiday == null ? '添加节日' : '编辑节日'),
        actions: [
          TextButton(
            onPressed: _saveHoliday,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // ID
                      TextFormField(
                        initialValue: _id,
                        decoration: const InputDecoration(
                          labelText: '节日ID',
                          helperText: '唯一标识符，不可重复',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入节日ID';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _id = value!;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 系统节日
                      SwitchListTile(
                        title: const Text('系统节日'),
                        subtitle: const Text('系统节日对所有用户可见，非系统节日仅对创建者可见'),
                        value: _isSystemHoliday,
                        onChanged: (value) {
                          setState(() {
                            _isSystemHoliday = value;
                          });
                        },
                      ),

                      // 节日类型
                      DropdownButtonFormField<HolidayType>(
                        decoration: const InputDecoration(
                          labelText: '节日类型',
                          border: OutlineInputBorder(),
                        ),
                        value: _type,
                        items: HolidayType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getHolidayTypeText(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 重要性级别
                      DropdownButtonFormField<ImportanceLevel>(
                        decoration: const InputDecoration(
                          labelText: '重要性级别',
                          border: OutlineInputBorder(),
                        ),
                        value: _importanceLevel,
                        items: ImportanceLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(_getImportanceLevelText(level)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _importanceLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 日期计算类型
                      DropdownButtonFormField<DateCalculationType>(
                        decoration: const InputDecoration(
                          labelText: '日期计算类型',
                          border: OutlineInputBorder(),
                        ),
                        value: _calculationType,
                        items: DateCalculationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getCalculationTypeText(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _calculationType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 计算规则
                      TextFormField(
                        initialValue: _calculationRule,
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
                        onSaved: (value) {
                          _calculationRule = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 地区设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('地区设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 地区选择
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _availableRegions.map((region) {
                          final isSelected = _regions.contains(region);
                          return FilterChip(
                            label: Text(region),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _regions.add(region);
                                } else {
                                  _regions.remove(region);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 多语言名称
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('多语言名称', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 各语言名称输入
                      ..._supportedLanguages.map((lang) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            initialValue: _names[lang] ?? '',
                            decoration: InputDecoration(
                              labelText: '${_getLanguageName(lang)}名称',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (lang == 'zh' && (value == null || value.isEmpty)) {
                                return '请输入中文名称';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _names[lang] = value;
                              } else {
                                _names.remove(lang);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 多语言描述
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('多语言描述', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 各语言描述输入
                      ..._supportedLanguages.map((lang) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            initialValue: _descriptions[lang] ?? '',
                            decoration: InputDecoration(
                              labelText: '${_getLanguageName(lang)}描述',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _descriptions[lang] = value;
                              } else {
                                _descriptions.remove(lang);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
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

  /// 获取重要性级别文本
  String _getImportanceLevelText(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.high:
        return '高';
      case ImportanceLevel.medium:
        return '中';
      case ImportanceLevel.low:
        return '低';
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

  /// 获取计算规则帮助文本
  String _getCalculationRuleHelperText() {
    switch (_calculationType) {
      case DateCalculationType.fixedGregorian:
        return '格式：MM-DD，例如：01-01 表示1月1日';
      case DateCalculationType.fixedLunar:
        return '格式：LMM-DD，例如：L01-01 表示农历正月初一';
      case DateCalculationType.variableRule:
        return '格式：MM-W-D，例如：11-4-4 表示11月第4个星期四';
      case DateCalculationType.custom:
        return '自定义规则，请参考文档';
    }
  }

  /// 获取语言名称
  String _getLanguageName(String langCode) {
    switch (langCode) {
      case 'zh':
        return '中文';
      case 'en':
        return '英文';
      case 'ja':
        return '日文';
      case 'ko':
        return '韩文';
      case 'fr':
        return '法文';
      case 'de':
        return '德文';
      default:
        return langCode;
    }
  }
}
