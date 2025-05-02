// 文件： lib/holiday_create_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class HolidayCreateScreen extends StatefulWidget {
  const HolidayCreateScreen({super.key});

  @override
  State<HolidayCreateScreen> createState() => _HolidayCreateScreenState();
}

class _HolidayCreateScreenState extends State<HolidayCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _descriptionEnController = TextEditingController();
  final TextEditingController _calculationRuleController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  HolidayType _selectedType = HolidayType.custom;
  DateCalculationType _selectedCalculationType = DateCalculationType.fixedGregorian;
  int _selectedImportance = 0;
  final Set<String> _selectedRegions = {'INTL'};

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isGeneratingId = true;

  @override
  void initState() {
    super.initState();
    _generateId();

    // 添加监听器以检测变化
    _nameController.addListener(_onFieldChanged);
    _nameEnController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _descriptionEnController.addListener(_onFieldChanged);
    _calculationRuleController.addListener(_onFieldChanged);
    _idController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _generateId() {
    if (_isGeneratingId) {
      final uuid = const Uuid().v4().substring(0, 8);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10);
      _idController.text = 'CUSTOM_${uuid}_$timestamp';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _descriptionEnController.dispose();
    _calculationRuleController.dispose();
    _idController.dispose();
    super.dispose();
  }

  // 保存节日信息
  Future<void> _saveHoliday() async {
    final l10n = AppLocalizations.of(context);

    // 验证必填字段
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holidayNameRequired)),
      );
      return;
    }

    if (_selectedRegions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holidayRegionRequired)),
      );
      return;
    }

    if (_calculationRuleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holidayCalculationRuleRequired)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 创建新节日对象
      final newHoliday = HolidayModel(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
        type: _selectedType,
        regions: _selectedRegions.toList(),
        calculationType: _selectedCalculationType,
        calculationRule: _calculationRuleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty ? null : _descriptionEnController.text.trim(),
        importanceLevel: ImportanceLevel.low,
        userImportance: _selectedImportance,
      );

      // 保存到数据库
      await HiveDatabaseService.saveHoliday(newHoliday);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holidaySaveSuccess)),
        );
        Navigator.pop(context, true); // 返回true表示已保存
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holidaySaveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createHolidayTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: l10n.saveButton,
              onPressed: _isLoading ? null : _saveHoliday,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 节日ID
                  Text(
                    l10n.holidayIdLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            hintText: 'CUSTOM_XXXX_XXXXXXXXXX',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isGeneratingId,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isGeneratingId,
                        onChanged: (value) {
                          setState(() {
                            _isGeneratingId = value;
                            if (_isGeneratingId) {
                              _generateId();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 节日类型
                  Text(
                    l10n.holidayTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButton<HolidayType>(
                    value: _selectedType,
                    isExpanded: true,
                    onChanged: (HolidayType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                          _hasChanges = true;
                        });
                      }
                    },
                    items: HolidayType.values.map<DropdownMenuItem<HolidayType>>((HolidayType type) {
                      return DropdownMenuItem<HolidayType>(
                        value: type,
                        child: Text(LocalizationService.getLocalizedHolidayType(context, type.toString().split('.').last)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 适用地区
                  Text(
                    l10n.holidayRegionsLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildRegionChip('INTL', isChinese ? '国际' : 'International'),
                      _buildRegionChip('CN', isChinese ? '中国' : 'China'),
                      _buildRegionChip('US', isChinese ? '美国' : 'USA'),
                      _buildRegionChip('JP', isChinese ? '日本' : 'Japan'),
                      _buildRegionChip('KR', isChinese ? '韩国' : 'Korea'),
                      _buildRegionChip('UK', isChinese ? '英国' : 'UK'),
                      _buildRegionChip('ALL', isChinese ? '所有地区' : 'All Regions'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 日期计算类型
                  Text(
                    l10n.holidayCalculationTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButton<DateCalculationType>(
                    value: _selectedCalculationType,
                    isExpanded: true,
                    onChanged: (DateCalculationType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCalculationType = newValue;
                          _hasChanges = true;

                          // 根据计算类型提供默认的计算规则示例
                          switch (newValue) {
                            case DateCalculationType.fixedGregorian:
                              _calculationRuleController.text = '01-01'; // MM-DD
                              break;
                            case DateCalculationType.fixedLunar:
                              _calculationRuleController.text = '01-01L'; // MM-DDL
                              break;
                            case DateCalculationType.nthWeekdayOfMonth:
                              _calculationRuleController.text = '05,2,0'; // 5月第2个星期日
                              break;
                            case DateCalculationType.solarTermBased:
                              _calculationRuleController.text = 'QingMing'; // 清明节
                              break;
                            case DateCalculationType.relativeTo:
                              _calculationRuleController.text = 'INTL_Easter,+1'; // 复活节后1天
                              break;
                            case DateCalculationType.lastWeekdayOfMonth:
                              _calculationRuleController.text = '12,0'; // 12月最后一个星期日
                              break;
                            case DateCalculationType.easterBased:
                              _calculationRuleController.text = 'Easter,-2'; // 复活节前2天
                              break;
                            case DateCalculationType.lunarPhase:
                              _calculationRuleController.text = 'FullMoon,01'; // 1月的满月
                              break;
                            case DateCalculationType.seasonBased:
                              _calculationRuleController.text = 'Spring,1'; // 春季第1天
                              break;
                            case DateCalculationType.weekOfYear:
                              _calculationRuleController.text = '01,1'; // 第1周的星期一
                              break;
                          }
                        });
                      }
                    },
                    items: DateCalculationType.values.map<DropdownMenuItem<DateCalculationType>>((DateCalculationType type) {
                      return DropdownMenuItem<DateCalculationType>(
                        value: type,
                        child: Text(LocalizationService.getLocalizedCalculationType(context, type.toString().split('.').last)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 计算规则
                  Text(
                    l10n.holidayCalculationRuleLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _calculationRuleController,
                    decoration: InputDecoration(
                      hintText: l10n.holidayCalculationRuleHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 重要性
                  Text(
                    l10n.holidayImportanceLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButton<int>(
                    value: _selectedImportance,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedImportance = newValue;
                          _hasChanges = true;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(l10n.importanceNormal),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(l10n.importanceHigh),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(l10n.importanceVeryHigh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 中文名称
                  Text(
                    isChinese ? '中文名称' : 'Chinese Name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入中文名称' : 'Enter Chinese name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 英文名称
                  Text(
                    isChinese ? '英文名称' : 'English Name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入英文名称' : 'Enter English name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 中文描述
                  Text(
                    isChinese ? '中文描述' : 'Chinese Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入中文描述' : 'Enter Chinese description',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 英文描述
                  Text(
                    isChinese ? '英文描述' : 'English Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _descriptionEnController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入英文描述' : 'Enter English description',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveHoliday,
                      child: Text(l10n.saveButton),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRegionChip(String region, String label) {
    final isSelected = _selectedRegions.contains(region);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedRegions.add(region);
          } else {
            _selectedRegions.remove(region);
          }
          _hasChanges = true;
        });
      },
    );
  }
}
