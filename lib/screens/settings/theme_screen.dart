import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jinlin_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// 主题选择屏幕
///
/// 用于选择应用程序的主题
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  // 当前选择的颜色
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedColor = themeProvider.primaryColor;
  }

  /// 显示颜色选择器对话框
  void _showColorPickerDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor ?? themeProvider.primaryColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsl,
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_selectedColor != null) {
                themeProvider.setPrimaryColor(_selectedColor!);
              }
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: ListView(
        children: [
          // 主题模式
          ListTile(
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
            leading: const Icon(Icons.brightness_6),
            onTap: () => _showThemeModeDialog(context, themeProvider),
          ),

          const Divider(),

          // 主题色
          ListTile(
            title: const Text('主题色'),
            subtitle: const Text('选择应用主题色'),
            leading: const Icon(Icons.color_lens),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: _showColorPickerDialog,
          ),

          const Divider(),

          // 使用Material 3
          SwitchListTile(
            title: const Text('使用Material 3'),
            subtitle: const Text('启用Material Design 3风格'),
            secondary: const Icon(Icons.style),
            value: themeProvider.useMaterial3,
            onChanged: (value) => themeProvider.setUseMaterial3(value),
          ),

          const Divider(),

          // 使用动态颜色
          SwitchListTile(
            title: const Text('使用动态颜色'),
            subtitle: const Text('根据系统主题自动调整颜色'),
            secondary: const Icon(Icons.auto_awesome),
            value: themeProvider.useDynamicColors,
            onChanged: (value) => themeProvider.setUseDynamicColors(value),
          ),

          const Divider(),

          // 重置主题设置
          ListTile(
            title: const Text('重置主题设置'),
            subtitle: const Text('恢复默认主题设置'),
            leading: const Icon(Icons.restore),
            onTap: () => _showResetThemeDialog(context, themeProvider),
          ),

          const Divider(),

          // 主题预览
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题预览',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // 按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('主按钮'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('次按钮'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('文本按钮'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '卡片标题',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '这是一个卡片示例，用于展示主题效果。',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 输入框
                const TextField(
                  decoration: InputDecoration(
                    labelText: '输入框',
                    hintText: '请输入内容',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),

                // 开关
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('开关'),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),

                // 复选框
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('复选框'),
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),

                // 单选按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('单选按钮'),
                    Radio<bool>(
                      value: true,
                      groupValue: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取主题模式文本
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  /// 显示主题模式对话框
  void _showThemeModeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示重置主题对话框
  void _showResetThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置主题设置'),
        content: const Text('确定要重置主题设置吗？这将恢复默认主题设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              themeProvider.resetThemeSettings();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
