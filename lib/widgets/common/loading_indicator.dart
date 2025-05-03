import 'package:flutter/material.dart';

/// 加载指示器类型
enum LoadingIndicatorType {
  /// 圆形进度指示器
  circular,
  
  /// 线性进度指示器
  linear,
  
  /// 自定义加载指示器
  custom,
}

/// 加载指示器组件
///
/// 显示加载状态的指示器
class LoadingIndicator extends StatelessWidget {
  /// 加载指示器类型
  final LoadingIndicatorType type;
  
  /// 加载指示器颜色
  final Color? color;
  
  /// 加载指示器背景颜色
  final Color? backgroundColor;
  
  /// 加载指示器大小
  final double? size;
  
  /// 加载指示器线宽
  final double? strokeWidth;
  
  /// 加载指示器值（0.0 - 1.0）
  final double? value;
  
  /// 加载指示器文本
  final String? text;
  
  /// 加载指示器文本样式
  final TextStyle? textStyle;
  
  /// 自定义加载指示器组件
  final Widget? customIndicator;
  
  /// 构造函数
  const LoadingIndicator({
    Key? key,
    this.type = LoadingIndicatorType.circular,
    this.color,
    this.backgroundColor,
    this.size,
    this.strokeWidth,
    this.value,
    this.text,
    this.textStyle,
    this.customIndicator,
  }) : super(key: key);
  
  /// 创建圆形加载指示器
  factory LoadingIndicator.circular({
    Key? key,
    Color? color,
    Color? backgroundColor,
    double? size,
    double? strokeWidth,
    double? value,
    String? text,
    TextStyle? textStyle,
  }) {
    return LoadingIndicator(
      key: key,
      type: LoadingIndicatorType.circular,
      color: color,
      backgroundColor: backgroundColor,
      size: size,
      strokeWidth: strokeWidth,
      value: value,
      text: text,
      textStyle: textStyle,
    );
  }
  
  /// 创建线性加载指示器
  factory LoadingIndicator.linear({
    Key? key,
    Color? color,
    Color? backgroundColor,
    double? strokeWidth,
    double? value,
    String? text,
    TextStyle? textStyle,
  }) {
    return LoadingIndicator(
      key: key,
      type: LoadingIndicatorType.linear,
      color: color,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      value: value,
      text: text,
      textStyle: textStyle,
    );
  }
  
  /// 创建自定义加载指示器
  factory LoadingIndicator.custom({
    Key? key,
    required Widget customIndicator,
    String? text,
    TextStyle? textStyle,
  }) {
    return LoadingIndicator(
      key: key,
      type: LoadingIndicatorType.custom,
      customIndicator: customIndicator,
      text: text,
      textStyle: textStyle,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;
    final indicatorBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final indicatorTextStyle = textStyle ?? theme.textTheme.bodyMedium;
    
    Widget indicator;
    
    switch (type) {
      case LoadingIndicatorType.circular:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            color: indicatorColor,
            backgroundColor: indicatorBackgroundColor,
            strokeWidth: strokeWidth ?? 4.0,
          ),
        );
        break;
      case LoadingIndicatorType.linear:
        indicator = LinearProgressIndicator(
          value: value,
          color: indicatorColor,
          backgroundColor: indicatorBackgroundColor,
          minHeight: strokeWidth,
        );
        break;
      case LoadingIndicatorType.custom:
        indicator = customIndicator ?? const SizedBox.shrink();
        break;
    }
    
    if (text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            text!,
            style: indicatorTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return indicator;
    }
  }
}
