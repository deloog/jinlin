// 文件： lib/widgets/localization_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 本地化状态指示器
///
/// 用于在应用程序中显示当前语言的翻译完整性
class LocalizationStatusIndicator extends StatelessWidget {
  const LocalizationStatusIndicator({
    super.key,
    this.showInSettings = true,
  });

  /// 是否在设置页面显示
  final bool showInSettings;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final completeness = _getCompletenessForLocale(locale.languageCode);

    // 如果完整性为100%，则不显示指示器
    if (completeness >= 100) {
      return const SizedBox.shrink();
    }

    // 如果不是在设置页面，且完整性大于80%，则不显示指示器
    if (!showInSettings && completeness > 80) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorForCompleteness(completeness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _getMessageForCompleteness(context, completeness),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取指定语言的翻译完整性
  double _getCompletenessForLocale(String languageCode) {
    // 使用与completeness_report.json一致的值
    switch (languageCode) {
      case 'en':
        return 100.0;
      case 'zh':
        return 100.0;
      case 'ja':
        return 65.0;
      case 'ko':
        return 65.0;
      case 'fr':
        return 95.0;
      case 'de':
        return 95.0;
      default:
        return 0.0;
    }
  }

  /// 根据完整性获取颜色
  Color _getColorForCompleteness(double completeness) {
    if (completeness >= 80) {
      return Colors.green;
    } else if (completeness >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// 根据完整性获取消息
  String _getMessageForCompleteness(BuildContext context, double completeness) {
    final l10n = AppLocalizations.of(context);
    if (completeness >= 80) {
      // 翻译几乎完成
      return l10n.translationAlmostComplete;
    } else if (completeness >= 50) {
      // 翻译部分完成
      return l10n.translationPartiallyComplete;
    } else {
      // 翻译不完整
      return l10n.translationInProgress;
    }
  }
}
