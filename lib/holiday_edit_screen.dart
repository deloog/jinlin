// 文件： lib/holiday_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/special_date.dart' as special_date;

class HolidayEditScreen extends StatefulWidget {
  final HolidayModel holiday;

  const HolidayEditScreen({
    super.key,
    required this.holiday,
  });

  @override
  State<HolidayEditScreen> createState() => _HolidayEditScreenState();
}

class _HolidayEditScreenState extends State<HolidayEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _calculationRuleController;
  late TextEditingController _customsController;
  late TextEditingController _taboosController;
  late HolidayType _selectedType;
  late DateCalculationType _selectedCalculationType;
  late int _selectedImportance;
  late Set<String> _selectedRegions;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.holiday.name);
    _nameEnController = TextEditingController(text: widget.holiday.nameEn ?? '');
    _descriptionController = TextEditingController(text: widget.holiday.description ?? '');
    _descriptionEnController = TextEditingController(text: widget.holiday.descriptionEn ?? '');
    _calculationRuleController = TextEditingController(text: widget.holiday.calculationRule);
    _customsController = TextEditingController(text: widget.holiday.customs ?? '');
    _taboosController = TextEditingController(text: widget.holiday.taboos ?? '');

    _selectedType = widget.holiday.type;
    _selectedCalculationType = widget.holiday.calculationType;
    _selectedImportance = widget.holiday.userImportance;
    _selectedRegions = Set<String>.from(widget.holiday.regions);

    // 添加监听器以检测变化
    _nameController.addListener(_onFieldChanged);
    _nameEnController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _descriptionEnController.addListener(_onFieldChanged);
    _calculationRuleController.addListener(_onFieldChanged);
    _customsController.addListener(_onFieldChanged);
    _taboosController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _descriptionEnController.dispose();
    _calculationRuleController.dispose();
    _customsController.dispose();
    _taboosController.dispose();
    super.dispose();
  }

  // 保存节日信息
  Future<void> _saveHoliday() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.getLocalizedText(
          context: context,
          textZh: '节日名称不能为空',
          textEn: 'Holiday name cannot be empty',
        ))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 处理习俗和禁忌
      String? customs = _customsController.text.trim().isEmpty
          ? null
          : _customsController.text.trim();

      String? taboos = _taboosController.text.trim().isEmpty
          ? null
          : _taboosController.text.trim();

      // 创建更新后的节日对象
      final updatedHoliday = HolidayModel(
        id: widget.holiday.id,
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
        type: _selectedType,
        regions: _selectedRegions.toList(),
        calculationType: _selectedCalculationType,
        calculationRule: _calculationRuleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty ? null : _descriptionEnController.text.trim(),
        importanceLevel: widget.holiday.importanceLevel,
        customs: customs,
        taboos: taboos,
        foods: widget.holiday.foods,
        greetings: widget.holiday.greetings,
        activities: widget.holiday.activities,
        history: widget.holiday.history,
        imageUrl: widget.holiday.imageUrl,
        userImportance: _selectedImportance,
      );

      // 保存到数据库
      await HiveDatabaseService.saveHoliday(updatedHoliday);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.getLocalizedText(
            context: context,
            textZh: '节日信息已保存',
            textEn: 'Holiday information saved',
          ))),
        );
        Navigator.pop(context, true); // 返回true表示已保存
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.getLocalizedText(
            context: context,
            textZh: '保存节日信息失败: $e',
            textEn: 'Failed to save holiday information: $e',
          ))),
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
        title: Text(isChinese ? '编辑节日' : 'Edit Holiday'),
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
                  // 节日ID（只读）
                  Text(
                    isChinese ? '节日ID：${widget.holiday.id}' : 'Holiday ID: ${widget.holiday.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // 节日类型
                  Text(
                    isChinese ? '节日类型' : 'Holiday Type',
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
                        child: Text(_getHolidayTypeText(type, isChinese)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 重要性
                  Text(
                    isChinese ? '重要性' : 'Importance',
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
                  const SizedBox(height: 24),

                  // 计算类型
                  Text(
                    isChinese ? '计算类型' : 'Calculation Type',
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
                        child: Text(_getCalculationTypeText(type, isChinese)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 计算规则
                  Text(
                    isChinese ? '计算规则' : 'Calculation Rule',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _calculationRuleController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '例如: MM-DD（固定公历）或 MM-DDL（固定农历）' : 'e.g. MM-DD (fixed Gregorian) or MM-DDL (fixed lunar)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 适用地区
                  Text(
                    isChinese ? '适用地区' : 'Regions',
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
                  const SizedBox(height: 24),

                  // 习俗
                  Text(
                    isChinese ? '习俗' : 'Customs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _customsController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入节日习俗' : 'Enter holiday customs',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 禁忌
                  Text(
                    isChinese ? '禁忌' : 'Taboos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _taboosController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '输入节日禁忌' : 'Enter holiday taboos',
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

  String _getHolidayTypeText(HolidayType type, bool isChinese) {
    switch (type) {
      case HolidayType.statutory:
        return isChinese ? '法定节日' : 'Statutory Holiday';
      case HolidayType.traditional:
        return isChinese ? '传统节日' : 'Traditional Holiday';
      case HolidayType.solarTerm:
        return isChinese ? '节气' : 'Solar Term';
      case HolidayType.memorial:
        return isChinese ? '纪念日' : 'Memorial Day';
      case HolidayType.custom:
        return isChinese ? '自定义' : 'Custom';
      case HolidayType.religious:
        return isChinese ? '宗教节日' : 'Religious Holiday';
      case HolidayType.international:
        return isChinese ? '国际节日' : 'International Holiday';
      case HolidayType.professional:
        return isChinese ? '职业节日' : 'Professional Holiday';
      case HolidayType.cultural:
        return isChinese ? '文化节日' : 'Cultural Holiday';
      case HolidayType.other:
        return isChinese ? '其他' : 'Other';
    }
  }

  String _getCalculationTypeText(DateCalculationType type, bool isChinese) {
    switch (type) {
      case DateCalculationType.fixedGregorian:
        return isChinese ? '固定公历日期' : 'Fixed Gregorian Date';
      case DateCalculationType.fixedLunar:
        return isChinese ? '固定农历日期' : 'Fixed Lunar Date';
      case DateCalculationType.nthWeekdayOfMonth:
        return isChinese ? '某月第n个星期几' : 'Nth Weekday of Month';
      case DateCalculationType.solarTermBased:
        return isChinese ? '基于节气' : 'Based on Solar Term';
      case DateCalculationType.relativeTo:
        return isChinese ? '相对日期' : 'Relative Date';
      case DateCalculationType.lastWeekdayOfMonth:
        return isChinese ? '某月最后一个星期几' : 'Last Weekday of Month';
      case DateCalculationType.easterBased:
        return isChinese ? '基于复活节' : 'Easter Based';
      case DateCalculationType.lunarPhase:
        return isChinese ? '基于月相' : 'Lunar Phase Based';
      case DateCalculationType.seasonBased:
        return isChinese ? '基于季节' : 'Season Based';
      case DateCalculationType.weekOfYear:
        return isChinese ? '基于年份周数' : 'Week of Year';
    }
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
