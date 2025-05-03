import 'package:flutter/material.dart';

/// 错误显示组件
///
/// 显示错误信息的组件
class ErrorDisplay extends StatelessWidget {
  /// 错误标题
  final String title;

  /// 错误消息
  final String message;

  /// 错误图标
  final IconData icon;

  /// 重试按钮文本
  final String? retryButtonText;

  /// 重试按钮回调
  final VoidCallback? onRetry;

  /// 关闭按钮文本
  final String? closeButtonText;

  /// 关闭按钮回调
  final VoidCallback? onClose;

  /// 是否显示堆栈跟踪
  final bool showStackTrace;

  /// 堆栈跟踪
  final String? stackTrace;

  /// 构造函数
  const ErrorDisplay({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.retryButtonText,
    this.onRetry,
    this.closeButtonText,
    this.onClose,
    this.showStackTrace = false,
    this.stackTrace,
  }) : super(key: key);

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
              color: theme.colorScheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showStackTrace && stackTrace != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    stackTrace!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton(
                    onPressed: onRetry,
                    child: Text(retryButtonText ?? '重试'),
                  ),
                ],
                if (onRetry != null && onClose != null) ...[
                  const SizedBox(width: 16),
                ],
                if (onClose != null) ...[
                  OutlinedButton(
                    onPressed: onClose,
                    child: Text(closeButtonText ?? '关闭'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
