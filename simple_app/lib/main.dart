import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// 创建一个全局的 NavigatorKey，用于在没有 context 的情况下访问 Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 简化版的提醒类
class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  bool isCompleted;
  DateTime? completedDate;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
    );
  }
}

// 简化版的设置提供者
class AppSettingsProvider with ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');
  ThemeMode _themeMode = ThemeMode.system;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localeString = prefs.getString('locale');
    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      }
    }

    final String? themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      switch (themeModeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }
  }

  void updateLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    _saveLocale();
  }

  void updateThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
    _saveThemeMode();
  }

  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', '${_locale.languageCode}_${_locale.countryCode}');
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (_themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
        break;
    }
    await prefs.setString('themeMode', themeModeString);
  }
}

// 主函数
Future<void> main() async {
  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== 捕获到Flutter错误 ===');
    debugPrint('错误: ${details.exception}');
    debugPrint('堆栈: ${details.stack}');
  };

  try {
    debugPrint('=== 应用启动 ===');
    debugPrint('平台: ${defaultTargetPlatform.name}');

    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter绑定初始化完成');

    // 添加文件日志记录
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        debugPrint('=== 应用启动 ${DateTime.now()} ===');
        debugPrint('平台: ${defaultTargetPlatform.name}');
        debugPrint('在Web平台上运行，跳过文件日志初始化');
        debugPrint('应用版本: 1.0.0');
        debugPrint('设备信息: ${defaultTargetPlatform.name}');
      } else {
        // 获取应用文档目录
        final appDir = Directory.current;
        final logFile = File('${appDir.path}/simplified_app_log.txt');

        // 写入启动日志
        logFile.writeAsStringSync(
          '=== 应用启动 ${DateTime.now()} ===\n平台: ${defaultTargetPlatform.name}\n',
          mode: FileMode.append,
        );

        // 记录一些基本信息
        logFile.writeAsStringSync('日志系统初始化成功\n', mode: FileMode.append);
        logFile.writeAsStringSync('应用版本: 1.0.0\n', mode: FileMode.append);
        logFile.writeAsStringSync('设备信息: ${defaultTargetPlatform.name}\n', mode: FileMode.append);
      }
    } catch (e, stack) {
      debugPrint('日志系统初始化失败: $e');
      debugPrint('堆栈: $stack');
    }
  } catch (e, stack) {
    debugPrint('=== 捕获到全局错误 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');
  }

  // 初始化中文 locale，必须在 runApp 前
  await initializeDateFormatting('zh_CN', null);

  // 初始化AppSettingsProvider
  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.initialize();

  // 运行实际应用，使用Provider包装
  runApp(
    ChangeNotifierProvider(
      create: (_) => appSettingsProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 从Provider获取AppSettingsProvider
    final appSettings = Provider.of<AppSettingsProvider>(context);

    return MaterialApp(
      locale: appSettings.locale,
      navigatorKey: navigatorKey, // 使用全局定义的 navigatorKey
      title: 'CetaMind Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: appSettings.themeMode,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const MyHomePage(title: 'CetaMind Reminder'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // 从 SharedPreferences 加载提醒列表
  Future<void> _loadReminders() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? remindersString = prefs.getString('reminders');
      if (remindersString != null) {
        final List<dynamic> reminderJson = jsonDecode(remindersString);
        final loadedReminders = reminderJson
            .map((json) => Reminder.fromJson(json))
            .toList();
        if (mounted) {
          setState(() { _reminders = loadedReminders; });
        }
      }
    } catch (e) {
      debugPrint("加载提醒事项失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载提醒事项失败')),
        );
      }
    } finally {
      if (mounted) {
          setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 打开设置页面
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _reminders.isEmpty
          ? const Center(child: Text('没有提醒事项'))
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return ListTile(
                  title: Text(reminder.title),
                  subtitle: Text(reminder.description),
                  trailing: reminder.dueDate != null
                    ? Text(DateFormat('yyyy-MM-dd').format(reminder.dueDate!))
                    : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加新提醒
        },
        tooltip: '添加提醒',
        child: const Icon(Icons.add),
      ),
    );
  }
}
