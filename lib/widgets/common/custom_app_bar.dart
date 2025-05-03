import 'package:flutter/material.dart';

/// 自定义应用栏组件
///
/// 提供统一的应用栏样式
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题
  final String title;
  
  /// 操作按钮
  final List<Widget>? actions;
  
  /// 是否显示返回按钮
  final bool showBackButton;
  
  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 标题样式
  final TextStyle? titleStyle;
  
  /// 底部组件
  final PreferredSizeWidget? bottom;
  
  /// 高度
  final double? height;
  
  /// 构造函数
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleStyle,
    this.bottom,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: titleStyle ?? theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      actions: actions,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      bottom: bottom,
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
