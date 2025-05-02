// 文件： lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// import 'main.dart'; // 不再需要
import 'holiday_management_screen.dart';
import 'holiday_sync_screen.dart';
import 'cloud_sync_screen.dart';
import 'package:jinlin_app/services/localization_service.dart';
import 'package:jinlin_app/services/theme_service.dart';
import 'package:jinlin_app/services/holiday_init_service.dart';
import 'package:jinlin_app/services/layout_service.dart';
import 'package:jinlin_app/providers/app_settings_provider.dart';
import 'package:jinlin_app/screens/settings/language_settings_screen.dart';
import 'package:jinlin_app/admin/admin_dashboard.dart'; // 管理后台仪表盘
import 'package:jinlin_app/services/database_manager_unified.dart'; // 统一数据库管理服务
import 'package:jinlin_app/pages/settings/database_performance_page.dart'; // 数据库性能测试页面


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();



}
@override
class _SettingsScreenState extends State<SettingsScreen> {
  String _currentNickname = '';
  int _specialDaysRange = 10; // 默认显示10天内的特殊纪念日
  final ThemeService _themeService = ThemeService();
  final LayoutService _layoutService = LayoutService();

  @override
  void initState() {
    super.initState();
    _loadNickname(); // 加载已保存的昵称
    _loadSpecialDaysRange(); // 加载特殊纪念日显示范围
    _initThemeService(); // 初始化主题服务
    _initLayoutService(); // 初始化布局服务
  }

  // 初始化布局服务
  Future<void> _initLayoutService() async {
    await _layoutService.initialize();
    // 强制刷新UI以显示正确的布局设置
    if (mounted) {
      setState(() {});
    }
  }

  // 初始化主题服务
  Future<void> _initThemeService() async {
    await _themeService.initialize();
    // 强制刷新UI以显示正确的主题模式
    if (mounted) {
      setState(() {});
    }
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isChinese = LocalizationService.isChineseLocale(context);
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),
          // 主题切换选项
          ListTile(
            leading: Icon(_themeService.getThemeModeIcon()),
            title: Text(l10n.themeSettings),
            subtitle: Text(_themeService.getThemeModeName(context, isChinese)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemePicker(context);
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

          // 首页布局设置
          ListTile(
            leading: Icon(_layoutService.getHomeLayoutTypeIcon()),
            title: Text(l10n.homeLayout),
            subtitle: Text(_layoutService.getHomeLayoutTypeName(context, isChinese)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHomeLayoutPicker(context);
            },
          ),

          // 卡片样式设置
          ListTile(
            leading: Icon(_layoutService.getCardStyleTypeIcon()),
            title: Text(l10n.cardStyle),
            subtitle: Text(_layoutService.getCardStyleTypeName(context, isChinese)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCardStylePicker(context);
            },
          ),

          // 卡片图标形状设置
          ListTile(
            leading: Icon(_layoutService.getIconShapeTypeIcon()),
            title: Text(isChinese ? '图标形状' : 'Icon Shape'),
            subtitle: Text(_layoutService.getIconShapeTypeName(context, isChinese)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showIconShapePicker(context);
            },
          ),

          // 卡片图标大小设置
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(isChinese ? '图标大小' : 'Icon Size'),
            subtitle: Text(_layoutService.getIconSizeName(context, isChinese, _layoutService.iconSize)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showIconSizePicker(context);
            },
          ),

          // 卡片颜色饱和度设置
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(isChinese ? '颜色饱和度' : 'Color Saturation'),
            subtitle: Text(_layoutService.getColorSaturationName(context, isChinese, _layoutService.colorSaturation)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showColorSaturationPicker(context);
            },
          ),

          // 提醒优先级设置
          ListTile(
            leading: Icon(_layoutService.getReminderPriorityIcon()),
            title: Text(l10n.reminderPriority),
            subtitle: Text(_layoutService.getReminderPriorityName(context, isChinese)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReminderPriorityPicker(context);
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
           // 管理后台入口
           ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(isChinese ? '节日数据管理后台' : 'Holiday Data Admin'),
            subtitle: Text(isChinese ? '添加、编辑和删除节日数据（管理员功能）' : 'Add, edit and delete holiday data (admin function)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Provider<DatabaseManagerUnified>(
                    create: (_) => DatabaseManagerUnified(),
                    dispose: (_, db) => db.close(),
                    child: const AdminDashboard(),
                  ),
                ),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.festival_outlined),
            title: Text(isChinese ? '个人节日设置' : 'Holiday Management'),
            subtitle: Text(isChinese ? '设置节日显示和个人重要性' : 'Set holiday display and personal importance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Provider<DatabaseManagerUnified>(
                    create: (_) => DatabaseManagerUnified(),
                    child: const HolidayManagementScreen(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(l10n.localDataSync),
            subtitle: Text(l10n.importExportHolidayData),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HolidaySyncScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: Text(isChinese ? '云同步' : 'Cloud Sync'),
            subtitle: Text(isChinese ? '在不同设备间同步数据' : 'Sync data between devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudSyncScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(isChinese ? '数据库性能测试' : 'Database Performance Test'),
            subtitle: Text(isChinese ? '测试和监控数据库性能' : 'Test and monitor database performance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabasePerformancePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.resetGlobalHolidays),
            subtitle: Text(l10n.resetGlobalHolidaysConfirm),
            onTap: () {
              // 显示确认对话框
              _showResetConfirmationDialog();
            },
          ),

           // --- 关于 ---
           _buildSectionTitle(context, l10n.settingsSectionAbout),
           ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutAppTitle),
            onTap: () {
              // 显示关于信息对话框或页面 (待实现)
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.settingsFeatureNotImplemented(l10n.settingsAboutAppTitle))),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacyPolicyTitle),
            onTap: () {
              // 打开隐私政策链接 (待实现)
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
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n.specialDaysRangeTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.specialDaysRangeDescription),
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
                      '${tempRange.toString()} ${l10n.daysText}',
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
        if (context.mounted) {
          final appSettings = Provider.of<AppSettingsProvider>(context, listen: false);
          appSettings.updateSpecialDaysRange(result);
        }
      }
    }
  }

  // 显示主题选择器
  void _showThemePicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isChinese ? '主题设置' : 'Theme Settings'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                await _themeService.setThemeMode(ThemeMode.light);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: Text(isChinese ? '浅色模式' : 'Light Mode'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _themeService.setThemeMode(ThemeMode.dark);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.nightlight_round),
                title: Text(isChinese ? '深色模式' : 'Dark Mode'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _themeService.setThemeMode(ThemeMode.system);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.settings_brightness),
                title: Text(isChinese ? '跟随系统' : 'System Mode'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示首页布局选择器
  void _showHomeLayoutPicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isChinese ? '首页布局' : 'Home Layout'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setHomeLayoutType(HomeLayoutType.timeline);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(isChinese ? '时间线视图' : 'Timeline View'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setHomeLayoutType(HomeLayoutType.calendar);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(isChinese ? '日历视图' : 'Calendar View'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setHomeLayoutType(HomeLayoutType.list);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.list),
                title: Text(isChinese ? '列表视图' : 'List View'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示卡片样式选择器
  void _showCardStylePicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isChinese ? '卡片样式' : 'Card Style'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setCardStyleType(CardStyleType.standard);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.crop_square),
                title: Text(isChinese ? '标准样式' : 'Standard Style'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setCardStyleType(CardStyleType.compact);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.crop_7_5),
                title: Text(isChinese ? '紧凑样式' : 'Compact Style'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setCardStyleType(CardStyleType.expanded);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.crop_16_9),
                title: Text(isChinese ? '展开样式' : 'Expanded Style'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示提醒优先级选择器
  void _showReminderPriorityPicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isChinese ? '提醒优先级' : 'Reminder Priority'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setReminderPriority(ReminderPriority.dateOrder);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(isChinese ? '按日期排序' : 'Date Order'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setReminderPriority(ReminderPriority.importanceFirst);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.priority_high),
                title: Text(isChinese ? '重要性优先' : 'Importance First'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setReminderPriority(ReminderPriority.typeGrouped);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.category),
                title: Text(isChinese ? '按类型分组' : 'Type Grouped'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示卡片图标形状选择器
  void _showIconShapePicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isChinese ? '图标形状' : 'Icon Shape'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setIconShapeType(IconShapeType.square);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.crop_square),
                title: Text(isChinese ? '方形图标' : 'Square Icons'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                await _layoutService.setIconShapeType(IconShapeType.circle);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: ListTile(
                leading: const Icon(Icons.circle_outlined),
                title: Text(isChinese ? '圆形图标' : 'Circle Icons'),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示卡片图标大小选择器
  void _showIconSizePicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    // 创建一个临时变量，用于存储用户选择的值
    double tempSize = _layoutService.iconSize;

    // 显示对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isChinese ? '图标大小' : 'Icon Size'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isChinese ? '调整卡片图标大小' : 'Adjust card icon size'),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempSize,
                    min: 24.0,
                    max: 48.0,
                    divisions: 6,
                    label: tempSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),
                  Center(
                    child: Container(
                      width: tempSize,
                      height: tempSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          _layoutService.iconShapeType == IconShapeType.circle ? tempSize / 2 : 8.0,
                        ),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                        size: tempSize * 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _layoutService.getIconSizeName(context, isChinese, tempSize),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isChinese ? '取消' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _layoutService.setIconSize(tempSize);
                    if (mounted) {
                      setState(() {});
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isChinese ? '应用' : 'Apply'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 显示卡片颜色饱和度选择器
  void _showColorSaturationPicker(BuildContext context) {
    final isChinese = LocalizationService.isChineseLocale(context);

    // 创建一个临时变量，用于存储用户选择的值
    double tempSaturation = _layoutService.colorSaturation;

    // 显示对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isChinese ? '颜色饱和度' : 'Color Saturation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isChinese ? '调整卡片颜色饱和度' : 'Adjust card color saturation'),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempSaturation,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    label: '${(tempSaturation * 100).round()}%',
                    onChanged: (double value) {
                      setState(() {
                        tempSaturation = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorSample(context, Colors.red, tempSaturation),
                      _buildColorSample(context, Colors.green, tempSaturation),
                      _buildColorSample(context, Colors.blue, tempSaturation),
                      _buildColorSample(context, Colors.orange, tempSaturation),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _layoutService.getColorSaturationName(context, isChinese, tempSaturation),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isChinese ? '取消' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _layoutService.setColorSaturation(tempSaturation);
                    if (mounted) {
                      setState(() {});
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isChinese ? '应用' : 'Apply'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 构建颜色样本
  Widget _buildColorSample(BuildContext context, Color baseColor, double saturation) {
    // 调整颜色饱和度
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final Color adjustedColor = hslColor.withSaturation(saturation).toColor();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: adjustedColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  // 显示重置确认对话框
  Future<void> _showResetConfirmationDialog() async {
    final l10n = AppLocalizations.of(context);

    // 显示确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmReset),
        content: Text(l10n.resetGlobalHolidaysConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.resetGlobalHolidays),
          ),
        ],
      ),
    );

    // 如果用户确认，执行重置
    if (confirm == true) {
      // 在异步操作前捕获所需的本地化字符串
      final successMessage = l10n.globalHolidayDataReset;
      final failureMessagePrefix = l10n.resetFailed('');

      try {
        final holidayInitService = HolidayInitService();
        await holidayInitService.resetGlobalHolidays();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          // 移除前缀中的占位符，然后添加实际错误信息
          final errorMessage = failureMessagePrefix.replaceAll('', '') + e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    }
  }
}