import 'package:flutter/material.dart';

/// 自定义卡片组件
///
/// 提供统一的卡片样式，支持标题、操作按钮等
class CustomCard extends StatelessWidget {
  /// 卡片标题
  final String? title;
  
  /// 卡片内容
  final Widget child;
  
  /// 操作按钮
  final List<Widget>? actions;
  
  /// 标题样式
  final TextStyle? titleStyle;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 外边距
  final EdgeInsetsGeometry? margin;
  
  /// 卡片高度
  final double? height;
  
  /// 卡片宽度
  final double? width;
  
  /// 卡片背景颜色
  final Color? backgroundColor;
  
  /// 卡片阴影高度
  final double? elevation;
  
  /// 卡片形状
  final ShapeBorder? shape;
  
  /// 构造函数
  const CustomCard({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.titleStyle,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.backgroundColor,
    this.elevation,
    this.shape,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      elevation: elevation ?? 2.0,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: backgroundColor ?? theme.cardColor,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: titleStyle ?? theme.textTheme.titleLarge,
                  ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
