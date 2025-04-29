// 文件： lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'holiday_management_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();



}
@override
class _SettingsScreenState extends State<SettingsScreen> {
  String _currentNickname = '';
  int _specialDaysRange = 10; // 默认显示10天内的特殊纪念日

  @override
  void initState() {
    super.initState();
    _loadNickname(); // 加载已保存的昵称
    _loadSpecialDaysRange(); // 加载特殊纪念日显示范围
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { // 检查 widget 是否还在屏幕上
      setState(() {
        _currentNickname = prefs.getString('userNickname') ?? ''; // 如果没存过，默认为空字符串
      });
    }
  }

  // 加载特殊纪念日显示范围
  Future<void> _loadSpecialDaysRange() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _specialDaysRange = prefs.getInt('specialDaysRange') ?? 10; // 默认为10天
      });
    }
  }
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle), // TODO: 本地化
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: <Widget>[
          // --- 用户信息 ---
          _buildSectionTitle(context, l10n.settingsSectionPersonal), // TODO: 本地化
          ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l10n.settingsNicknameTitle),
          // --- 修改 subtitle ---
          subtitle: Text(_currentNickname.isEmpty
              ? l10n.settingsNicknameSubtitle // 昵称为空时显示默认提示
              : _currentNickname), // 否则显示当前昵称
          // --- 修改结束 ---
          trailing: const Icon(Icons.chevron_right),
          // --- 修改 onTap ---
          onTap: () {
            // 直接调用同在 State 类里的方法
            _showNicknameDialog(context);
          },
          // --- 修改结束 ---
        ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.settingsAvatarTitle), // TODO: 本地化
            subtitle: Text(l10n.settingsAvatarSubtitle), // TODO: 本地化
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到头像管理页面
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsAvatarTitle))),
              );
            },
          ),

          // --- 功能设置 ---
          _buildSectionTitle(context, l10n.settingsSectionFunction), // TODO: 本地化
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguageTitle), // TODO: 本地化
            subtitle: Text(l10n.settingsLanguageSubtitle(Localizations.localeOf(context).toLanguageTag())),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguagePicker(context);
            },
          ),
          // 特殊纪念日显示范围设置
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(l10n.specialDaysRangeTitle),
            subtitle: Text(l10n.specialDaysRangeSubtitle(_specialDaysRange)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSpecialDaysRangePicker(context);
            },
          ),

           ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsNotificationTitle), // TODO: 本地化
            subtitle: Text(l10n.settingsNotificationSubtitle), // TODO: 本地化
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到通知设置页面
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsNotificationTitle))),
              );
            },
          ),

          // --- 数据管理 ---
           _buildSectionTitle(context, l10n.settingsSectionData), // TODO: 本地化
           ListTile(
            leading: const Icon(Icons.festival_outlined),
            title: Text(l10n.holidayManagementTitle ?? '节日管理'),
            subtitle: Text(l10n.holidayManagementDescription ?? '管理节日显示和重要性'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HolidayManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(l10n.settingsImportExportTitle), // TODO: 本地化
             subtitle: Text(l10n.settingsImportExportSubtitle), // TODO: 本地化
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现导入/导出逻辑 (需处理权限)
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsImportExportTitle))),
              );
            },
          ),

           // --- 关于 ---
           _buildSectionTitle(context, l10n.settingsSectionAbout), // TODO: 本地化
           ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutAppTitle), // TODO: 本地化
            onTap: () {
              // TODO: 显示关于信息对话框或页面
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsAboutAppTitle))),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacyPolicyTitle), // TODO: 本地化
            onTap: () {
              // TODO: 打开隐私政策链接
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsPrivacyPolicyTitle))),
              );
            },
          ),

        ],
      ),
    );
  }
  // 辅助方法：构建分组标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  // --- 添加编辑昵称的对话框方法 ---
  Future<void> _showNicknameDialog(BuildContext context) async {
    // 注意: 因为这个方法在 State 类内部，可以直接访问 context 和 l10n (如果在 build 中定义了)
    // 但为了清晰，我们在方法开头重新获取 l10n
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    // 创建文本控制器，用当前昵称初始化
    final nicknameController = TextEditingController(text: _currentNickname);

    // 检查 context (异步操作后需要)
    if (!context.mounted) return;

    final String? newNickname = await showDialog<String>(
      context: context,
      builder: (BuildContext contextDialog) { // 使用不同的 context 名字避免混淆
        return AlertDialog(
          title: Text(l10n.settingsNicknameTitle),
          content: TextField(
            controller: nicknameController,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.settingsNicknameSubtitle),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancelButton),
              onPressed: () => Navigator.of(contextDialog).pop(), // 使用 dialog 的 context
            ),
            TextButton(
              child: Text(l10n.saveButton), // 使用新 key
              onPressed: () {
                Navigator.of(contextDialog).pop(nicknameController.text.trim()); // 使用 dialog 的 context
              },
            ),
          ],
        );
      },
    );

    // 对话框关闭后处理结果
    if (newNickname != null && newNickname != _currentNickname) {
      await prefs.setString('userNickname', newNickname);
      if (mounted) { // 再次检查 context
         setState(() {
            _currentNickname = newNickname; // 更新状态变量
         });
      }
    }
    // 释放控制器
     nicknameController.dispose();
  }
  // --- 方法添加结束 ---
  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context); // 获取 l10n 用于显示选项
    // 使用 MyApp.of(context) 查找 _MyAppState
    final myAppState = MyApp.of(context);

    // 安全检查，确保找到了 _MyAppState
    if (myAppState == null) {
       debugPrint("错误：无法从 SettingsScreen 访问 _MyAppState");
       // 可以显示一个错误提示给用户
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(l10n.cannotChangeLanguageError))
       );
       return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(l10n.settingsLanguageTitle), // 对话框标题
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                myAppState.changeLocale(const Locale('en')); // 调用 _MyAppState 的方法
                Navigator.pop(context); // 关闭对话框
              },
              child: const Text('English'), // 选项1: 英文
            ),
            SimpleDialogOption(
              onPressed: () {
                myAppState.changeLocale(const Locale('zh')); // 调用 _MyAppState 的方法
                Navigator.pop(context); // 关闭对话框
              },
              child: const Text('中文'), // 选项2: 中文
            ),
            // 你可以根据需要添加更多语言选项...
            // 例如:
            // SimpleDialogOption(
            //   onPressed: () {
            //     myAppState.changeLocale(const Locale('es')); // 西班牙语
            //     Navigator.pop(context);
            //   },
            //   child: const Text('Español'),
            // ),
          ],
        );
      },
    );
  }

  // 显示特殊纪念日显示范围选择器
  Future<void> _showSpecialDaysRangePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // 创建一个临时变量，用于存储用户选择的值
    int tempRange = _specialDaysRange;

    // 显示对话框
    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.specialDaysRangeTitle ?? '特殊纪念日显示范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.specialDaysRangeDescription ?? '选择提前多少天显示特殊纪念日：'),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempRange.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: tempRange.toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempRange = value.round();
                      });
                    },
                  ),
                  Center(
                    child: Text(
                      '${tempRange.toString()} ${l10n.daysText ?? '天'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(tempRange),
                  child: Text(l10n.applyButton),
                ),
              ],
            );
          },
        );
      },
    );

    // 如果用户选择了新的值，保存并更新状态
    if (result != null && result != _specialDaysRange) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('specialDaysRange', result);

      if (mounted) {
        setState(() {
          _specialDaysRange = result;
        });

        // 通知主页面更新特殊纪念日显示范围
        final myAppState = MyApp.of(context);
        if (myAppState != null) {
          myAppState.updateSpecialDaysRange(result);
        }
      }
    }
  }
}