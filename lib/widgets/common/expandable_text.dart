import 'package:flutter/material.dart';

/// 可展开文本组件
///
/// 显示可展开/折叠的文本
class ExpandableText extends StatefulWidget {
  /// 文本内容
  final String text;
  
  /// 最大行数
  final int maxLines;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 展开按钮文本
  final String expandText;
  
  /// 折叠按钮文本
  final String collapseText;
  
  /// 展开/折叠按钮样式
  final TextStyle? linkStyle;
  
  /// 是否默认展开
  final bool expanded;
  
  /// 展开/折叠回调
  final ValueChanged<bool>? onExpandedChanged;
  
  /// 构造函数
  const ExpandableText({
    Key? key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.expandText = '展开',
    this.collapseText = '收起',
    this.linkStyle,
    this.expanded = false,
    this.onExpandedChanged,
  }) : super(key: key);
  
  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late bool _expanded;
  
  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded;
  }
  
  @override
  void didUpdateWidget(ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _expanded = widget.expanded;
    }
  }
  
  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (widget.onExpandedChanged != null) {
        widget.onExpandedChanged!(_expanded);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLinkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
    );
    final linkStyle = widget.linkStyle ?? defaultLinkStyle;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: widget.style,
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        );
        
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        final isTextOverflowing = textPainter.didExceedMaxLines;
        
        if (!isTextOverflowing) {
          return Text(
            widget.text,
            style: widget.style,
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: _toggleExpanded,
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
      },
    );
  }
}
