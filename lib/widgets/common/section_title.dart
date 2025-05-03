import 'package:flutter/material.dart';

/// 分区标题组件
///
/// 用于在页面中显示分区标题
class SectionTitle extends StatelessWidget {
  /// 标题文本
  final String title;
  
  /// 标题样式
  final TextStyle? style;
  
  /// 操作按钮
  final List<Widget>? actions;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 构造函数
  const SectionTitle({
    super.key,
    required this.title,
    this.style,
    this.actions,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: style ?? theme.textTheme.titleLarge,
          ),
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}
