// 文件： lib/holiday_simple_create_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/utils/ai_description_generator.dart';
import 'package:uuid/uuid.dart';

/// 简化版节日创建界面
///
/// 只需要用户输入最基本的信息，其他信息由AI自动生成
class HolidaySimpleCreateScreen extends StatefulWidget {
  const HolidaySimpleCreateScreen({super.key});

  @override
  State<HolidaySimpleCreateScreen> createState() => _HolidaySimpleCreateScreenState();
}

class _HolidaySimpleCreateScreenState extends State<HolidaySimpleCreateScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  HolidayType _selectedType = HolidayType.traditional;
  DateCalculationType _selectedCalculationType = DateCalculationType.fixedGregorian;
  final Set<String> _selectedRegions = {'CN'};

  bool _isLunarDate = false;
  bool _isLoading = false;
  bool _isGeneratingDescription = false;

  String? _generatedDescription;
  String? _generatedDescriptionEn;

  final _aiGenerator = AIDescriptionGenerator();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // 生成节日描述
  Future<void> _generateDescription() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).holidayNameRequired)),
      );
      return;
    }

    setState(() {
      _isGeneratingDescription = true;
    });

    try {
      // 生成中文描述
      final zhDescription = await _aiGenerator.generateDescription(
        title: _nameController.text.trim(),
        context: context,
        preferredLanguage: 'zh',
        additionalInfo: _dateController.text.trim(),
      );

      // 生成英文描述
      final enDescription = await _aiGenerator.generateDescription(
        title: _nameController.text.trim(),
        preferredLanguage: 'en',
        additionalInfo: _dateController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _generatedDescription = zhDescription;
          _generatedDescriptionEn = enDescription;
          _isGeneratingDescription = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成描述失败: $e')),
        );
        setState(() {
          _isGeneratingDescription = false;
        });
      }
    }
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

    if (_dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入节日日期')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 如果还没有生成描述，先生成描述
      if (_generatedDescription == null) {
        await _generateDescription();
      }

      // 生成唯一ID
      const uuid = Uuid();
      final id = 'CUSTOM_${uuid.v4().substring(0, 8)}';

      // 处理日期格式
      String calculationRule = _dateController.text.trim();
      if (_isLunarDate) {
        calculationRule += 'L';
      }

      // 创建新节日对象
      final newHoliday = HolidayModel(
        id: id,
        name: _nameController.text.trim(),
        type: _selectedType,
        regions: _selectedRegions.toList(),
        calculationType: _selectedCalculationType,
        calculationRule: calculationRule,
        description: _generatedDescription,
        descriptionEn: _generatedDescriptionEn,
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1, // 默认为重要
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
          SnackBar(content: Text('保存节日失败: $e')),
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
    final isChinese = LocalizationService.isChineseLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isChinese ? '添加节日' : 'Add Holiday'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 简短说明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isChinese ? '只需输入基本信息，AI将自动生成详细描述' : 'Just enter basic info, AI will generate details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isChinese
                              ? '输入节日名称和日期，其他信息将由AI自动生成。您也可以选择节日类型和地区。'
                              : 'Enter holiday name and date, other information will be generated by AI. You can also select holiday type and region.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 节日名称
                  Text(
                    isChinese ? '节日名称 *' : 'Holiday Name *',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: isChinese ? '例如：中秋节' : 'e.g. Mid-Autumn Festival',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 节日日期
                  Text(
                    isChinese ? '节日日期 *' : 'Holiday Date *',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            hintText: isChinese ? '格式：MM-DD（如08-15）' : 'Format: MM-DD (e.g. 08-15)',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(isChinese ? '农历' : 'Lunar'),
                          Switch(
                            value: _isLunarDate,
                            onChanged: (value) {
                              setState(() {
                                _isLunarDate = value;
                                _selectedCalculationType = value
                                  ? DateCalculationType.fixedLunar
                                  : DateCalculationType.fixedGregorian;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 节日类型
                  Text(
                    isChinese ? '节日类型' : 'Holiday Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButtonFormField<HolidayType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: HolidayType.traditional,
                        child: Text(isChinese ? '传统节日' : 'Traditional Holiday'),
                      ),
                      DropdownMenuItem(
                        value: HolidayType.statutory,
                        child: Text(isChinese ? '法定节日' : 'Statutory Holiday'),
                      ),
                      DropdownMenuItem(
                        value: HolidayType.memorial,
                        child: Text(isChinese ? '纪念日' : 'Memorial Day'),
                      ),
                      DropdownMenuItem(
                        value: HolidayType.custom,
                        child: Text(isChinese ? '自定义' : 'Custom'),
                      ),
                    ],
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
                  Text(
                    isChinese ? '地区' : 'Region',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(isChinese ? '中国' : 'China'),
                        selected: _selectedRegions.contains('CN'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRegions.add('CN');
                            } else {
                              _selectedRegions.remove('CN');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text(isChinese ? '国际' : 'International'),
                        selected: _selectedRegions.contains('INTL'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRegions.add('INTL');
                            } else {
                              _selectedRegions.remove('INTL');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text(isChinese ? '全球' : 'Global'),
                        selected: _selectedRegions.contains('ALL'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRegions.add('ALL');
                            } else {
                              _selectedRegions.remove('ALL');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 生成描述按钮 - 始终显示，但根据输入状态启用/禁用
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isChinese ? '点击使用AI生成节日描述' : 'Click to Generate with AI'),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ],
                      ),
                      onPressed: (_nameController.text.isNotEmpty && _dateController.text.isNotEmpty && !_isGeneratingDescription)
                          ? _generateDescription
                          : null,
                    ),
                  ),

                  // 生成中提示
                  if (_isGeneratingDescription)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('AI正在生成节日描述...'),
                          ],
                        ),
                      ),
                    ),

                  // 显示生成的描述
                  if (_generatedDescription != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isChinese ? 'AI生成的描述' : 'AI Generated Description',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _generatedDescription!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_generatedDescriptionEn != null) ...[
                                const Divider(),
                                Text(
                                  'English Description:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _generatedDescriptionEn!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      onPressed: (_nameController.text.isNotEmpty && _dateController.text.isNotEmpty)
                          ? _saveHoliday
                          : null,
                      child: Text(
                        isChinese ? '保存节日' : 'Save Holiday',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
