import 'package:flutter/material.dart';

/// 空状态组件
///
/// 显示空状态的组件
class EmptyState extends StatelessWidget {
  /// 空状态标题
  final String title;
  
  /// 空状态消息
  final String message;
  
  /// 空状态图标
  final IconData icon;
  
  /// 操作按钮文本
  final String? actionButtonText;
  
  /// 操作按钮回调
  final VoidCallback? onAction;
  
  /// 构造函数
  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox,
    this.actionButtonText,
    this.onAction,
  }) : super(key: key);
  
  /// 创建空列表状态
  factory EmptyState.emptyList({
    Key? key,
    String title = '暂无数据',
    String message = '列表为空，请稍后再试',
    String? actionButtonText,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      title: title,
      message: message,
      icon: Icons.inbox,
      actionButtonText: actionButtonText,
      onAction: onAction,
    );
  }
  
  /// 创建搜索结果为空状态
  factory EmptyState.emptySearch({
    Key? key,
    String title = '未找到结果',
    String message = '没有找到匹配的搜索结果',
    String? actionButtonText,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      title: title,
      message: message,
      icon: Icons.search,
      actionButtonText: actionButtonText,
      onAction: onAction,
    );
  }
  
  /// 创建网络错误状态
  factory EmptyState.networkError({
    Key? key,
    String title = '网络错误',
    String message = '无法连接到网络，请检查网络连接',
    String? actionButtonText = '重试',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      title: title,
      message: message,
      icon: Icons.wifi_off,
      actionButtonText: actionButtonText,
      onAction: onAction,
    );
  }
  
  /// 创建服务器错误状态
  factory EmptyState.serverError({
    Key? key,
    String title = '服务器错误',
    String message = '服务器出现错误，请稍后再试',
    String? actionButtonText = '重试',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      title: title,
      message: message,
      icon: Icons.cloud_off,
      actionButtonText: actionButtonText,
      onAction: onAction,
    );
  }
  
  /// 创建权限错误状态
  factory EmptyState.permissionError({
    Key? key,
    String title = '权限错误',
    String message = '没有足够的权限执行此操作',
    String? actionButtonText = '请求权限',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      key: key,
      title: title,
      message: message,
      icon: Icons.no_accounts,
      actionButtonText: actionButtonText,
      onAction: onAction,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButtonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionButtonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
