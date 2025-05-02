// 文件： lib/holiday_one_step_create_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/utils/ai_description_generator.dart';
import 'package:jinlin_app/utils/event_bus.dart';
import 'package:uuid/uuid.dart';

/// 一步式节日创建界面
///
/// 用户只需输入节日名称，其他所有信息由AI自动推断和生成
class HolidayOneStepCreateScreen extends StatefulWidget {
  const HolidayOneStepCreateScreen({super.key});

  @override
  State<HolidayOneStepCreateScreen> createState() => _HolidayOneStepCreateScreenState();
}

class _HolidayOneStepCreateScreenState extends State<HolidayOneStepCreateScreen> {
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isGeneratingInfo = false;

  String? _generatedDescription;
  String? _generatedDescriptionEn;
  String? _inferredDate;
  bool _isLunarDate = false;
  HolidayType _inferredType = HolidayType.traditional;
  final Set<String> _inferredRegions = {'CN'};

  final _aiGenerator = AIDescriptionGenerator();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 生成节日所有信息
  Future<void> _generateAllInfo() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).holidayNameRequired)),
      );
      return;
    }

    setState(() {
      _isGeneratingInfo = true;
    });

    try {
      // 获取当前语言环境
      final isChinese = LocalizationService.isChineseLocale(context);
      final languageCode = isChinese ? 'zh' : 'en';

      // 构建提示词，要求AI推断节日日期、类型和地区
      final inferPrompt = '''
      请根据节日名称"${_nameController.text.trim()}"推断以下信息：
      1. 节日日期（格式：MM-DD，如01-01表示1月1日）
      2. 是否为农历日期（是/否）
      3. 节日类型（法定节日/传统节日/纪念日/节气/自定义）
      4. 适用地区（CN=中国，INTL=国际，ALL=全球）

      请直接返回JSON格式，不要使用任何代码块标记（如```json），不要有任何其他文字：
      {"date":"MM-DD","isLunar":true/false,"type":"statutory/traditional/memorial/solarTerm/custom","regions":["CN","INTL","ALL"]}
      ''';

      // 发送请求推断节日信息
      final inferResponse = await _aiGenerator.generateCustomResponse(
        prompt: inferPrompt,
        context: context,
        preferredLanguage: languageCode,
      );

      // 解析返回的JSON
      try {
        final Map<String, dynamic> inferData = jsonDecode(inferResponse);

        // 设置推断的日期
        _inferredDate = inferData['date'];

        // 设置是否为农历
        _isLunarDate = inferData['isLunar'] ?? false;

        // 设置推断的节日类型
        final typeStr = inferData['type'];
        if (typeStr == 'statutory') {
          _inferredType = HolidayType.statutory;
        } else if (typeStr == 'traditional') {
          _inferredType = HolidayType.traditional;
        } else if (typeStr == 'memorial') {
          _inferredType = HolidayType.memorial;
        } else if (typeStr == 'solarTerm') {
          _inferredType = HolidayType.solarTerm;
        } else {
          _inferredType = HolidayType.custom;
        }

        // 设置推断的地区
        _inferredRegions.clear();
        final regions = inferData['regions'];
        if (regions is List) {
          for (final region in regions) {
            _inferredRegions.add(region);
          }
        }

        // 如果地区为空，默认添加当前用户所在地区
        if (_inferredRegions.isEmpty) {
          _inferredRegions.add(isChinese ? 'CN' : 'INTL');
        }
      } catch (e) {
        debugPrint('解析推断信息失败: $e');
        // 设置默认值
        _inferredDate = '01-01';
        _isLunarDate = false;
        _inferredType = HolidayType.traditional;
        _inferredRegions.clear();
        _inferredRegions.add(isChinese ? 'CN' : 'INTL');
      }

      // 生成中文描述
      String? zhDescription;
      String? enDescription;

      if (mounted) {
        zhDescription = await _aiGenerator.generateDescription(
          title: _nameController.text.trim(),
          context: context,
          preferredLanguage: 'zh',
          additionalInfo: '$_inferredDate${_isLunarDate ? '(农历)' : ''}',
        );
      }

      // 生成英文描述
      if (mounted) {
        enDescription = await _aiGenerator.generateDescription(
          title: _nameController.text.trim(),
          context: context,
          preferredLanguage: 'en',
          additionalInfo: '$_inferredDate${_isLunarDate ? '(lunar)' : ''}',
        );
      }

      if (mounted) {
        setState(() {
          _generatedDescription = zhDescription;
          _generatedDescriptionEn = enDescription;
          _isGeneratingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成节日信息失败: $e')),
        );
        setState(() {
          _isGeneratingInfo = false;
        });
      }
    }
  }

  // 保存节日信息
  Future<void> _saveHoliday() async {
    // 验证必填字段
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        final isChinese = LocalizationService.isChineseLocale(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isChinese ? '请输入节日名称' : 'Please enter holiday name')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 如果还没有生成信息，先生成信息
      if (_generatedDescription == null || _inferredDate == null) {
        await _generateAllInfo();
      }

      // 生成唯一ID
      const uuid = Uuid();
      final id = 'CUSTOM_${uuid.v4().substring(0, 8)}';

      // 处理日期格式
      String calculationRule = _inferredDate ?? '01-01';
      if (_isLunarDate) {
        calculationRule += 'L';
      }

      // 创建新节日对象
      final newHoliday = HolidayModel(
        id: id,
        name: _nameController.text.trim(),
        type: _inferredType,
        regions: _inferredRegions.toList(),
        calculationType: _isLunarDate ? DateCalculationType.fixedLunar : DateCalculationType.fixedGregorian,
        calculationRule: calculationRule,
        description: _generatedDescription,
        descriptionEn: _generatedDescriptionEn,
        importanceLevel: ImportanceLevel.high,
        userImportance: 2, // 设置为非常重要，确保显示在首页
      );

      // 保存到数据库
      await HiveDatabaseService.saveHoliday(newHoliday);

      if (mounted) {
        final isChinese = LocalizationService.isChineseLocale(context);

        // 通知首页立即刷新节日列表
        // 使用全局事件总线通知首页刷新
        EventBus.instance.fire(RefreshTimelineEvent(newHoliday.id));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isChinese ? '节日保存成功' : 'Holiday saved successfully')),
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
                            isChinese ? '只需输入节日名称，AI将自动完成所有工作' : 'Just enter the holiday name, AI will do all the work',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isChinese
                              ? '输入节日名称后，AI将自动推断节日日期、类型、地区，并生成详细描述。'
                              : 'After entering the holiday name, AI will automatically infer the date, type, region, and generate detailed descriptions.',
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
                      hintText: isChinese ? '例如：中秋节、端午节、圣诞节' : 'e.g. Christmas, Easter, Thanksgiving',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  // 生成信息按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isChinese ? '点击使用AI生成节日信息' : 'Click to Generate with AI'),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ],
                      ),
                      onPressed: (_nameController.text.isNotEmpty && !_isGeneratingInfo)
                          ? _generateAllInfo
                          : null,
                    ),
                  ),

                  // 生成中提示
                  if (_isGeneratingInfo)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('AI正在生成节日信息...'),
                          ],
                        ),
                      ),
                    ),

                  // 显示生成的信息
                  if (_generatedDescription != null && _inferredDate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isChinese ? 'AI推断的节日信息' : 'AI Inferred Holiday Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 节日日期
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isChinese
                                      ? '日期: $_inferredDate ${_isLunarDate ? '(农历)' : '(公历)'}'
                                      : 'Date: $_inferredDate ${_isLunarDate ? '(Lunar)' : '(Gregorian)'}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 节日类型
                              Row(
                                children: [
                                  Icon(Icons.category,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isChinese
                                      ? '类型: ${_getTypeNameChinese(_inferredType)}'
                                      : 'Type: ${_getTypeNameEnglish(_inferredType)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 适用地区
                              Row(
                                children: [
                                  Icon(Icons.public,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isChinese
                                      ? '地区: ${_getRegionsNameChinese(_inferredRegions)}'
                                      : 'Regions: ${_getRegionsNameEnglish(_inferredRegions)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 节日描述
                              Text(
                                isChinese ? 'AI生成的描述:' : 'AI Generated Description:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isChinese ? _generatedDescription! : (_generatedDescriptionEn ?? _generatedDescription!),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
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
                      onPressed: (_nameController.text.isNotEmpty)
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

  // 获取节日类型的中文名称
  String _getTypeNameChinese(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return '法定节日';
      case HolidayType.traditional:
        return '传统节日';
      case HolidayType.memorial:
        return '纪念日';
      case HolidayType.solarTerm:
        return '节气';
      case HolidayType.custom:
        return '自定义';
      default:
        return '其他';
    }
  }

  // 获取节日类型的英文名称
  String _getTypeNameEnglish(HolidayType type) {
    switch (type) {
      case HolidayType.statutory:
        return 'Statutory Holiday';
      case HolidayType.traditional:
        return 'Traditional Holiday';
      case HolidayType.memorial:
        return 'Memorial Day';
      case HolidayType.solarTerm:
        return 'Solar Term';
      case HolidayType.custom:
        return 'Custom';
      default:
        return 'Other';
    }
  }

  // 获取地区的中文名称
  String _getRegionsNameChinese(Set<String> regions) {
    final List<String> names = [];
    for (final region in regions) {
      switch (region) {
        case 'CN':
          names.add('中国');
          break;
        case 'INTL':
          names.add('国际');
          break;
        case 'ALL':
          names.add('全球');
          break;
        default:
          names.add(region);
      }
    }
    return names.join('、');
  }

  // 获取地区的英文名称
  String _getRegionsNameEnglish(Set<String> regions) {
    final List<String> names = [];
    for (final region in regions) {
      switch (region) {
        case 'CN':
          names.add('China');
          break;
        case 'INTL':
          names.add('International');
          break;
        case 'ALL':
          names.add('Global');
          break;
        default:
          names.add(region);
      }
    }
    return names.join(', ');
  }
}
