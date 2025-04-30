import 'package:flutter/material.dart';
import 'package:jinlin_app/services/localization_service.dart';

/// 多语言文本组件
///
/// 用于显示多语言文本，自动根据当前语言环境选择合适的文本
class MultilingualText extends StatelessWidget {
  /// 多语言文本Map
  final Map<String, String>? textMap;
  
  /// 备用文本，当textMap为空或不包含当前语言时显示
  final String fallbackText;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 文本对齐方式
  final TextAlign? textAlign;
  
  /// 文本溢出处理方式
  final TextOverflow? overflow;
  
  /// 最大行数
  final int? maxLines;
  
  /// 软换行
  final bool? softWrap;
  
  const MultilingualText({
    super.key,
    required this.textMap,
    this.fallbackText = '',
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  });
  
  @override
  Widget build(BuildContext context) {
    final String displayText = textMap != null && textMap!.isNotEmpty
        ? LocalizationService.getTextFromMultilingualMap(textMap, context)
        : fallbackText;
    
    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

/// 多语言富文本组件
///
/// 用于显示多语言富文本，自动根据当前语言环境选择合适的文本
class MultilingualRichText extends StatelessWidget {
  /// 多语言文本Map
  final Map<String, String>? textMap;
  
  /// 备用文本，当textMap为空或不包含当前语言时显示
  final String fallbackText;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 文本对齐方式
  final TextAlign? textAlign;
  
  /// 文本溢出处理方式
  final TextOverflow? overflow;
  
  /// 最大行数
  final int? maxLines;
  
  /// 软换行
  final bool? softWrap;
  
  /// 文本构建器，用于将文本转换为InlineSpan
  final InlineSpan Function(String text, TextStyle? style) textBuilder;
  
  const MultilingualRichText({
    super.key,
    required this.textMap,
    this.fallbackText = '',
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    required this.textBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    final String displayText = textMap != null && textMap!.isNotEmpty
        ? LocalizationService.getTextFromMultilingualMap(textMap, context)
        : fallbackText;
    
    return RichText(
      text: textBuilder(displayText, style),
      textAlign: textAlign ?? TextAlign.start,
      overflow: overflow ?? TextOverflow.clip,
      maxLines: maxLines,
      softWrap: softWrap ?? true,
    );
  }
}

/// 多语言文本表单字段
///
/// 用于编辑多语言文本，自动根据当前语言环境选择合适的文本
class MultilingualTextField extends StatefulWidget {
  /// 多语言文本Map
  final Map<String, String>? initialTextMap;
  
  /// 当文本变化时的回调
  final void Function(Map<String, String> textMap) onChanged;
  
  /// 装饰
  final InputDecoration? decoration;
  
  /// 最大行数
  final int? maxLines;
  
  /// 最小行数
  final int? minLines;
  
  /// 键盘类型
  final TextInputType? keyboardType;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 是否自动获取焦点
  final bool autofocus;
  
  /// 是否启用
  final bool enabled;
  
  /// 当前编辑的语言代码
  final String? currentLanguageCode;
  
  const MultilingualTextField({
    super.key,
    this.initialTextMap,
    required this.onChanged,
    this.decoration,
    this.maxLines,
    this.minLines,
    this.keyboardType,
    this.style,
    this.autofocus = false,
    this.enabled = true,
    this.currentLanguageCode,
  });
  
  @override
  State<MultilingualTextField> createState() => _MultilingualTextFieldState();
}

class _MultilingualTextFieldState extends State<MultilingualTextField> {
  late TextEditingController _controller;
  late String _currentLanguageCode;
  late Map<String, String> _textMap;
  
  @override
  void initState() {
    super.initState();
    _textMap = widget.initialTextMap != null 
        ? Map<String, String>.from(widget.initialTextMap!) 
        : {};
    _currentLanguageCode = widget.currentLanguageCode ?? 'zh';
    _controller = TextEditingController(
      text: _textMap[_currentLanguageCode] ?? '',
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.currentLanguageCode == null) {
      // 如果没有指定语言代码，则使用当前语言环境
      final newLanguageCode = LocalizationService.getCurrentLanguageCode(context);
      if (newLanguageCode != _currentLanguageCode) {
        setState(() {
          _currentLanguageCode = newLanguageCode;
          _controller.text = _textMap[_currentLanguageCode] ?? '';
        });
      }
    }
  }
  
  @override
  void didUpdateWidget(MultilingualTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果初始文本Map发生变化，更新内部状态
    if (widget.initialTextMap != oldWidget.initialTextMap) {
      _textMap = widget.initialTextMap != null 
          ? Map<String, String>.from(widget.initialTextMap!) 
          : {};
    }
    
    // 如果当前语言代码发生变化，更新控制器文本
    final newLanguageCode = widget.currentLanguageCode ?? 
        LocalizationService.getCurrentLanguageCode(context);
    if (newLanguageCode != _currentLanguageCode) {
      setState(() {
        _currentLanguageCode = newLanguageCode;
        _controller.text = _textMap[_currentLanguageCode] ?? '';
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      style: widget.style,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onChanged: (value) {
        _textMap[_currentLanguageCode] = value;
        widget.onChanged(_textMap);
      },
    );
  }
}

/// 多语言下拉菜单
///
/// 用于选择语言
class LanguageDropdown extends StatelessWidget {
  /// 当前选择的语言代码
  final String currentLanguageCode;
  
  /// 当语言变化时的回调
  final void Function(String languageCode) onChanged;
  
  /// 是否显示语言名称
  final bool showLanguageName;
  
  /// 下拉菜单宽度
  final double? width;
  
  /// 下拉菜单高度
  final double? height;
  
  /// 下拉菜单装饰
  final BoxDecoration? decoration;
  
  const LanguageDropdown({
    super.key,
    required this.currentLanguageCode,
    required this.onChanged,
    this.showLanguageName = true,
    this.width,
    this.height,
    this.decoration,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: decoration ?? BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguageCode,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: LocalizationService.supportedLocales
              .map<DropdownMenuItem<String>>((Locale locale) {
            return DropdownMenuItem<String>(
              value: locale.languageCode,
              child: Row(
                children: [
                  Text(
                    _getLanguageFlag(locale.languageCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  if (showLanguageName)
                    Text(
                      LocalizationService.languageNames[locale.languageCode] ?? locale.languageCode,
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  /// 获取语言对应的国旗表情
  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'zh': return '🇨🇳';
      case 'en': return '🇺🇸';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'fr': return '🇫🇷';
      case 'de': return '🇩🇪';
      default: return '🌐';
    }
  }
}

/// 多语言编辑器
///
/// 用于编辑多语言文本，支持切换语言
class MultilingualEditor extends StatefulWidget {
  /// 多语言文本Map
  final Map<String, String>? initialTextMap;
  
  /// 当文本变化时的回调
  final void Function(Map<String, String> textMap) onChanged;
  
  /// 标签
  final String? label;
  
  /// 提示文本
  final String? hintText;
  
  /// 最大行数
  final int? maxLines;
  
  /// 最小行数
  final int? minLines;
  
  /// 键盘类型
  final TextInputType? keyboardType;
  
  const MultilingualEditor({
    super.key,
    this.initialTextMap,
    required this.onChanged,
    this.label,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.keyboardType,
  });
  
  @override
  State<MultilingualEditor> createState() => _MultilingualEditorState();
}

class _MultilingualEditorState extends State<MultilingualEditor> {
  late String _currentLanguageCode;
  late Map<String, String> _textMap;
  
  @override
  void initState() {
    super.initState();
    _textMap = widget.initialTextMap != null 
        ? Map<String, String>.from(widget.initialTextMap!) 
        : {};
    _currentLanguageCode = 'zh'; // 默认使用中文
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 使用当前语言环境
    final newLanguageCode = LocalizationService.getCurrentLanguageCode(context);
    if (newLanguageCode != _currentLanguageCode) {
      setState(() {
        _currentLanguageCode = newLanguageCode;
      });
    }
  }
  
  @override
  void didUpdateWidget(MultilingualEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果初始文本Map发生变化，更新内部状态
    if (widget.initialTextMap != oldWidget.initialTextMap) {
      _textMap = widget.initialTextMap != null 
          ? Map<String, String>.from(widget.initialTextMap!) 
          : {};
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: MultilingualTextField(
                initialTextMap: _textMap,
                onChanged: (textMap) {
                  _textMap = textMap;
                  widget.onChanged(_textMap);
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                keyboardType: widget.keyboardType,
                currentLanguageCode: _currentLanguageCode,
              ),
            ),
            const SizedBox(width: 8),
            LanguageDropdown(
              currentLanguageCode: _currentLanguageCode,
              onChanged: (languageCode) {
                setState(() {
                  _currentLanguageCode = languageCode;
                });
              },
              showLanguageName: false,
              width: 60,
              height: 48,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildLanguageCompletionIndicator(),
      ],
    );
  }
  
  /// 构建语言完成度指示器
  Widget _buildLanguageCompletionIndicator() {
    final completionPercentage = LocalizationService.getMultilingualCompletionPercentage(_textMap);
    final availableLanguages = LocalizationService.getAvailableLanguages(_textMap);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: completionPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            completionPercentage >= 100 ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '已完成 ${completionPercentage.toStringAsFixed(0)}%: ${availableLanguages.join(", ")}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
