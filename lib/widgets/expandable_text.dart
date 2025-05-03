import 'package:flutter/material.dart';

/// 可展开的文本组件
///
/// 当文本超过指定行数时，显示"展开"按钮
class ExpandableText extends StatefulWidget {
  /// 文本内容
  final String text;
  
  /// 最大行数
  final int maxLines;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 展开按钮文本
  final String expandText;
  
  /// 收起按钮文本
  final String collapseText;
  
  /// 链接样式
  final TextStyle? linkStyle;
  
  const ExpandableText(
    this.text, {
    Key? key,
    this.maxLines = 3,
    this.style,
    this.expandText = '展开',
    this.collapseText = '收起',
    this.linkStyle,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  bool _hasOverflow = false;
  
  @override
  void initState() {
    super.initState();
    // 在下一帧检查是否需要展开按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }
  
  /// 检查文本是否溢出
  void _checkOverflow() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style,
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: context.size?.width ?? 300);
    
    setState(() {
      _hasOverflow = textPainter.didExceedMaxLines;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final defaultLinkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    
    final linkStyle = widget.linkStyle ?? defaultLinkStyle;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (_hasOverflow || _expanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _expanded ? widget.collapseText : widget.expandText,
                style: linkStyle,
              ),
            ),
          ),
      ],
    );
  }
}
