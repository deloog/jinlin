// 文件： lib/widgets/card_icon.dart
import 'package:flutter/material.dart';
import 'package:jinlin_app/services/layout_service.dart';

/// 卡片图标组件
///
/// 根据用户设置显示不同形状和大小的图标
class CardIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double? size;

  const CardIcon({
    Key? key,
    required this.icon,
    required this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取布局服务
    final layoutService = LayoutService();
    
    // 获取图标形状
    final iconShapeType = layoutService.iconShapeType;
    
    // 获取图标大小
    final iconSize = size ?? layoutService.iconSize;
    
    // 获取颜色饱和度
    final colorSaturation = layoutService.colorSaturation;
    
    // 调整颜色饱和度
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color adjustedColor = hslColor.withSaturation(colorSaturation).toColor();
    
    // 根据图标形状创建不同的容器
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: adjustedColor,
        borderRadius: BorderRadius.circular(
          iconShapeType == IconShapeType.circle ? iconSize / 2 : 8.0,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize * 0.6,
      ),
    );
  }
}
