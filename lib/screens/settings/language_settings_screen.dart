import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/widgets/localization_status_indicator.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/providers/app_settings_provider.dart';

/// 语言设置页面
///
/// 用于设置应用程序的语言
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  /// 加载当前语言设置
  Future<void> _loadCurrentLanguage() async {
    final savedLanguage = await LocalizationService.getSavedLanguageCode();
    if (mounted) {
      setState(() {
        _selectedLanguageCode = savedLanguage;
      });
    }
  }

  /// 切换语言
  Future<void> _changeLanguage(String languageCode) async {
    if (_selectedLanguageCode == languageCode) return;

    final success = await LocalizationService.saveLanguagePreference(languageCode);
    if (success) {
      if (mounted) {
        setState(() {
          _selectedLanguageCode = languageCode;
        });

        // 手动切换语言时，关闭跟随系统语言
        final provider = Provider.of<AppSettingsProvider>(context, listen: false);
        provider.updateFollowSystemLanguage(false);
      }

      // 通知AppSettingsProvider更新语言设置
      if (mounted) {
        final provider = Provider.of<AppSettingsProvider>(context, listen: false);
        provider.updateLocale(Locale(languageCode));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).languageChangeError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appSettings = Provider.of<AppSettingsProvider>(context);

    // 如果跟随系统语言，则使用当前系统语言；否则使用用户设置的语言
    final currentLanguageCode = appSettings.followSystemLanguage
        ? LocalizationService.getCurrentLanguageCode(context)
        : (appSettings.locale?.languageCode ?? LocalizationService.getCurrentLanguageCode(context));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.selectLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // 跟随系统语言选项
          SwitchListTile(
            title: Text(l10n.followSystemLanguage),
            subtitle: Text(l10n.followSystemLanguageDescription),
            value: appSettings.followSystemLanguage,
            onChanged: (value) {
              final provider = Provider.of<AppSettingsProvider>(context, listen: false);
              provider.updateFollowSystemLanguage(value);
              setState(() {
                // 刷新UI
              });
            },
          ),

          const Divider(),
          _buildLanguageOption(
            languageCode: 'zh',
            languageName: '中文',
            isSelected: currentLanguageCode == 'zh',
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            languageCode: 'en',
            languageName: 'English',
            isSelected: currentLanguageCode == 'en',
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            languageCode: 'ja',
            languageName: '日本語',
            isSelected: currentLanguageCode == 'ja',
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            languageCode: 'ko',
            languageName: '한국어',
            isSelected: currentLanguageCode == 'ko',
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            languageCode: 'fr',
            languageName: 'Français',
            isSelected: currentLanguageCode == 'fr',
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            languageCode: 'de',
            languageName: 'Deutsch',
            isSelected: currentLanguageCode == 'de',
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              l10n.languageSettingsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建语言选项
  Widget _buildLanguageOption({
    required String languageCode,
    required String languageName,
    required bool isSelected,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Text(
            _getLanguageFlag(languageCode),
            style: const TextStyle(fontSize: 24),
          ),
          title: Row(
            children: [
              Text(languageName),
              const SizedBox(width: 8),
              if (languageCode != 'en' && languageCode != 'zh')
                const LocalizationStatusIndicator(showInSettings: true),
            ],
          ),
          subtitle: Text(_getLanguageRegion(languageCode)),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => _changeLanguage(languageCode),
        ),
      ],
    );
  }

  /// 获取语言对应的国旗表情
  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'zh': return '🇨🇳';
      case 'en': return '🇺🇸';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'fr': return '🇫🇷';
      case 'de': return '🇩🇪';
      default: return '🌐';
    }
  }

  /// 获取语言对应的地区名称
  String _getLanguageRegion(String languageCode) {
    final l10n = AppLocalizations.of(context);
    switch (languageCode) {
      case 'zh': return l10n.regionChina;
      case 'en': return l10n.regionUnitedStates;
      case 'ja': return l10n.regionJapan;
      case 'ko': return l10n.regionKorea;
      case 'fr': return l10n.regionFrance;
      case 'de': return l10n.regionGermany;
      default: return l10n.regionInternational;
    }
  }
}
