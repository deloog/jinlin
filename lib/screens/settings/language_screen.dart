import 'package:flutter/material.dart';
import 'package:jinlin_app/models/language/language.dart';
import 'package:jinlin_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// 语言选择屏幕
///
/// 用于选择应用程序的语言
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语言设置'),
      ),
      body: Column(
        children: [
          // 使用系统语言
          SwitchListTile(
            title: const Text('使用系统语言'),
            subtitle: const Text('跟随系统语言设置'),
            secondary: const Icon(Icons.language),
            value: localeProvider.useSystemLocale,
            onChanged: (value) => localeProvider.setUseSystemLocale(value),
          ),

          const Divider(),

          // 语言列表
          Expanded(
            child: ListView.builder(
              itemCount: Language.supportedLanguages.length,
              itemBuilder: (context, index) {
                final language = Language.supportedLanguages[index];
                final locale = language.toLocale();
                final isSelected = !localeProvider.useSystemLocale &&
                    localeProvider.locale?.languageCode == locale.languageCode &&
                    localeProvider.locale?.countryCode == locale.countryCode;

                return RadioListTile<Locale>(
                  title: Text(language.nameLocal),
                  subtitle: Text(language.nameEn),
                  secondary: Icon(language.icon ?? Icons.language),
                  value: locale,
                  groupValue: isSelected ? localeProvider.locale : null,
                  onChanged: localeProvider.useSystemLocale
                      ? null
                      : (value) {
                          if (value != null) {
                            localeProvider.setLocale(value);
                          }
                        },
                );
              },
            ),
          ),

          // 系统语言信息
          if (localeProvider.useSystemLocale) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前系统语言',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localeProvider.getLanguageName(localeProvider.getSystemLocale() ?? const Locale('zh', 'CN')),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
