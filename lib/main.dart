// 文件： jinlin_app/lib/main.dart
import 'reminder_detail_screen.dart';
import 'settings_screen.dart';
import 'holiday_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:io'; // 导入IO包，用于文件操作
import 'reminder.dart';
import 'add_reminder_screen.dart'; // 确保导入了 AddReminderScreen
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/date_formatter.dart';

import 'package:jinlin_app/holiday_filter_dialog.dart'; // 节日筛选对话框
import 'package:jinlin_app/special_date.dart' as special_date; // 特殊日期数据模型
import 'timeline_item.dart';
import 'package:jinlin_app/services/database_manager_enhanced.dart';
import 'package:jinlin_app/services/theme_service.dart'; // 主题服务
import 'package:jinlin_app/services/auto_sync_service.dart'; // 自动同步服务
import 'package:jinlin_app/utils/event_bus.dart'; // 事件总线
import 'dart:async'; // StreamSubscription
import 'package:jinlin_app/services/localization_service.dart' as localization; // 本地化服务
import 'package:jinlin_app/providers/app_settings_provider.dart'; // 应用设置提供者
import 'package:jinlin_app/services/database_manager_unified.dart'; // 统一数据库管理服务
import 'package:jinlin_app/models/unified/holiday.dart' as models; // 统一的节日模型
import 'package:jinlin_app/services/error_handling_service.dart'; // 错误处理服务

import 'widgets/page_transitions.dart';
import 'widgets/card_icon.dart';

// 创建一个全局的 NavigatorKey，用于在没有 context 的情况下访问 Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 全局错误日志文件
File? _errorLogFile;

// 初始化错误日志文件
void _initErrorLogFile() {
  try {
    // 检查是否在Web平台上运行
    if (kIsWeb) {
      debugPrint('在Web平台上运行，跳过文件日志初始化');
      return;
    }

    final appDir = Directory.current;
    _errorLogFile = File('${appDir.path}/jinlin_app_error_log.txt');
    _logErrorToFile('=== 错误日志初始化 ${DateTime.now()} ===');
  } catch (e) {
    debugPrint('错误日志初始化失败: $e');
  }
}

// 记录错误到文件
void _logErrorToFile(String message) {
  try {
    // 检查是否在Web平台上运行
    if (kIsWeb) {
      // 在Web平台上，只使用控制台输出
      debugPrint('[ERROR] $message');
      return;
    }

    _errorLogFile?.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
  } catch (e) {
    // 忽略日志写入错误
    debugPrint('写入错误日志失败: $e');
  }
}

// 全局错误处理函数
void _handleError(Object error, StackTrace stack) {
  debugPrint('=== 捕获到全局错误 ===');
  debugPrint('错误: $error');
  debugPrint('堆栈: $stack');

  // 确保错误日志文件已初始化
  if (_errorLogFile == null) {
    _initErrorLogFile();
  }

  // 记录错误到文件
  _logErrorToFile('=== 捕获到全局错误 ===');
  _logErrorToFile('错误: $error');
  _logErrorToFile('堆栈: $stack');

  // 这里可以添加错误上报逻辑
}

Future<void> main() async {
  // 初始化错误日志文件
  _initErrorLogFile();

  // 初始化错误处理服务
  errorHandlingService.initialize();

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
        final logFile = File('${appDir.path}/jinlin_app_log.txt');

        // 写入启动日志
        logFile.writeAsStringSync(
          '=== 应用启动 ${DateTime.now()} ===\n平台: ${defaultTargetPlatform.name}\n',
          mode: FileMode.append,
        );

        // 创建自定义日志函数
        void logToFile(String message) {
          try {
            logFile.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
          } catch (e) {
            // 忽略日志写入错误
          }
        }

        // 记录一些基本信息
        logToFile('日志系统初始化成功');
        logToFile('应用版本: 1.0.0');
        logToFile('设备信息: ${defaultTargetPlatform.name}');
      }
    } catch (e, stack) {
      debugPrint('日志系统初始化失败: $e');
      debugPrint('堆栈: $stack');
    }

    // 初始化Firebase
    try {
      // 检查当前平台是否支持Firebase
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        debugPrint('正在初始化Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint("Firebase初始化成功");
      } else {
        debugPrint("当前平台 (${defaultTargetPlatform.name}) 不支持Firebase，跳过初始化");
      }
    } catch (e, stack) {
      debugPrint("Firebase初始化失败: $e");
      debugPrint("堆栈: $stack");
    }
  } catch (e, stack) {
    _handleError(e, stack);
  }

  // 初始化中文 locale，必须在 runApp 前
  await initializeDateFormatting('zh_CN', null);
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("无法加载 .env 文件: $e");
  }

  // 创建一个临时的应用用于数据迁移
  final app = MaterialApp(
    navigatorKey: navigatorKey, // 使用全局定义的 navigatorKey
    home: const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
  );

  // 运行临时应用
  runApp(app);

  // 等待框架渲染第一帧
  await Future.delayed(const Duration(milliseconds: 100));

  try {
    debugPrint("开始初始化数据库和服务...");

    // 初始化AppSettingsProvider
    final appSettingsProvider = AppSettingsProvider();
    await appSettingsProvider.initialize();
    debugPrint("AppSettingsProvider初始化成功");

    // 初始化DatabaseManagerUnified
    final dbManager = DatabaseManagerUnified();
    try {
      await dbManager.initialize(null);
      debugPrint("DatabaseManagerUnified初始化成功");
    } catch (e) {
      debugPrint("DatabaseManagerUnified初始化失败: $e");
      // 继续执行，不要因为数据库初始化失败而中断整个流程
    }

    // 运行实际应用，使用Provider包装
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => appSettingsProvider),
          Provider<DatabaseManagerUnified>(
            create: (_) => DatabaseManagerUnified(),
            dispose: (_, db) => db.close(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    debugPrint("应用程序启动成功");
  } catch (e, stack) {
    debugPrint("初始化过程中出错: $e");
    debugPrint("堆栈: $stack");
    _logErrorToFile("初始化过程中出错: $e");
    _logErrorToFile("堆栈: $stack");

    // 如果初始化失败，运行一个简单的应用程序
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('应用程序初始化失败'),
              Text('错误: $e'),
              ElevatedButton(
                onPressed: () {
                  // 重新启动应用程序
                  main();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  // 使用私有方法代替公共API中的私有类型
  static _MyAppState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  // 提供公共方法来访问需要的功能
  static void updateLocale(BuildContext context, Locale locale) {
    final state = _of(context);
    if (state != null && state.mounted) {
      state._updateLocale(locale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  int _specialDaysRange = 10; // 默认显示10天内的特殊纪念日
  final ThemeService _themeService = ThemeService();

  // 日志文件
  File? _logFile;

  // 记录日志到文件
  void _logToFile(String message) {
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        // 在Web平台上，只使用控制台输出
        debugPrint('[UI] $message');
        return;
      }

      _logFile?.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
    } catch (e) {
      // 忽略日志写入错误
    }
  }

  @override
  void initState() {
    super.initState();

    // 添加观察者以监听应用生命周期变化
    WidgetsBinding.instance.addObserver(this);

    // 初始化日志文件
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        debugPrint('=== UI初始化 ${DateTime.now()} ===');
        debugPrint('在Web平台上运行，跳过UI日志文件初始化');
      } else {
        final appDir = Directory.current;
        _logFile = File('${appDir.path}/jinlin_app_ui_log.txt');
        _logToFile('=== UI初始化 ${DateTime.now()} ===');
      }
    } catch (e) {
      debugPrint('UI日志初始化失败: $e');
    }

    _loadSpecialDaysRange(); // 加载特殊纪念日显示范围
    _initThemeService(); // 初始化主题服务

    // 设置错误处理
    FlutterError.onError = (FlutterErrorDetails details) {
      _logToFile('UI错误: ${details.exception}');
      _logToFile('堆栈: ${details.stack}');
      FlutterError.presentError(details); // 仍然显示错误
    };
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    _logToFile('=== UI销毁 ${DateTime.now()} ===');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 记录应用生命周期变化
    _logToFile('应用生命周期状态变化: $state');

    // 如果应用进入后台，确保日志写入
    if (state == AppLifecycleState.paused) {
      _logToFile('应用进入后台');
    } else if (state == AppLifecycleState.resumed) {
      _logToFile('应用回到前台');
    }
  }

  // 更新应用程序语言
  void _updateLocale(Locale locale) {
    if (mounted) {
      final appSettings = Provider.of<AppSettingsProvider>(context, listen: false);
      appSettings.updateLocale(locale);

      // 通知所有需要刷新的页面
      EventBus.instance.fire(RefreshTimelineEvent());
      debugPrint('语言已更改为 ${locale.languageCode}，已发送刷新事件');
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

  // 加载特殊纪念日显示范围
  Future<void> _loadSpecialDaysRange() async {
    final prefs = await SharedPreferences.getInstance();
    final int range = prefs.getInt('specialDaysRange') ?? 10; // 默认为10天

    if (mounted) {
      setState(() {
        _specialDaysRange = range;
      });
    }
  }

  // 更新特殊纪念日显示范围
  Future<void> updateSpecialDaysRange(int range) async {
    if (_specialDaysRange == range) return; // 范围没变，不用操作

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('specialDaysRange', range); // 保存新范围

    if (mounted) {
      setState(() {
        _specialDaysRange = range; // 更新状态
      });

      // 通知所有需要刷新的页面
      if (mounted) {
        // 找到 MyHomePage 的状态并刷新
        final homeState = context.findAncestorStateOfType<_MyHomePageState>();
        if (homeState != null && homeState.mounted) {
          homeState._prepareTimelineItems();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 从Provider获取AppSettingsProvider
    final appSettings = Provider.of<AppSettingsProvider>(context);

    return MaterialApp(
      locale: appSettings.locale,
      navigatorKey: errorHandlingService.navigatorKey, // 使用错误处理服务的 navigatorKey
      title: 'CetaMind Reminder',
      theme: _themeService.lightTheme,
      darkTheme: _themeService.darkTheme,
      themeMode: appSettings.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: localization.LocalizationService.supportedLocales,
      home: const MyHomePage(title: 'CetaMind Reminder'),
      debugShowCheckedModeBanner: false,
      // 添加错误构建器，用于处理路由错误
      builder: (context, child) {
        // 添加错误边界
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('应用程序遇到了问题', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// _MyHomePageState 类开始
class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  List<TimelineItem> _sortedTimelineItems = [];

  // 事件订阅
  late StreamSubscription _eventSubscription;

  // 日志文件
  File? _logFile;

  // 记录日志到文件
  void _logToFile(String message) {
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        // 在Web平台上，只使用控制台输出
        debugPrint('[首页] $message');
        return;
      }

      _logFile?.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
    } catch (e) {
      // 忽略日志写入错误
    }
  }

  // 记录错误到全局错误日志文件
  void _logErrorToFile(String message) {
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        // 在Web平台上，只使用控制台输出
        debugPrint('[ERROR][首页] $message');
        return;
      }

      if (_errorLogFile == null) {
        _initErrorLogFile();
      }
      _errorLogFile?.writeAsStringSync('${DateTime.now()}: [首页] $message\n', mode: FileMode.append);
    } catch (e) {
      // 忽略日志写入错误
      debugPrint('写入错误日志失败: $e');
    }
  }

  // 节日筛选状态
  Set<special_date.SpecialDateType> _selectedHolidayTypes = {
    special_date.SpecialDateType.statutory,
    special_date.SpecialDateType.traditional,
    special_date.SpecialDateType.memorial,
    special_date.SpecialDateType.solarTerm,
  };

  @override
  void initState() {
    super.initState();

    // 添加观察者以监听应用生命周期变化
    WidgetsBinding.instance.addObserver(this);

    // 初始化日志文件
    try {
      // 检查是否在Web平台上运行
      if (kIsWeb) {
        debugPrint('=== 首页初始化 ${DateTime.now()} ===');
        debugPrint('在Web平台上运行，跳过首页日志文件初始化');
      } else {
        final appDir = Directory.current;
        _logFile = File('${appDir.path}/jinlin_app_home_log.txt');
        _logToFile('=== 首页初始化 ${DateTime.now()} ===');
      }
    } catch (e) {
      debugPrint('首页日志初始化失败: $e');
    }

    // 监听刷新时间线事件
    _eventSubscription = EventBus.instance.on.listen((event) {
      if (event is RefreshTimelineEvent) {
        // 收到刷新事件，重新加载时间线
        _logToFile('收到刷新时间线事件');
        _prepareTimelineItems();
      }
    });

    // 加载提醒列表
    _loadReminders();
  }

  @override
  void dispose() {
    // 取消事件订阅
    _eventSubscription.cancel();

    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    _logToFile('=== 首页销毁 ${DateTime.now()} ===');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 记录应用生命周期变化
    _logToFile('首页生命周期状态变化: $state');
  }

  // 标记是否已经加载过数据
  bool _hasLoadedData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里调用依赖于 context 的方法，但只在第一次调用时加载数据
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _prepareTimelineItems();
    }
  }

  // 从 SharedPreferences 加载提醒列表
  Future<void> _loadReminders() async {
    if (!mounted) return;
    _logToFile('开始加载提醒列表');
    setState(() { _isLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? remindersString = prefs.getString('reminders');
      if (remindersString != null) {
        _logToFile('从SharedPreferences加载到提醒数据，长度: ${remindersString.length}');
        final List<dynamic> reminderJson = jsonDecode(remindersString);
        _logToFile('JSON解码成功，项目数量: ${reminderJson.length}');

        final loadedReminders = reminderJson
            .map((json) => Reminder.fromJson(json))
            .whereType<Reminder>() // 确保转换成功
            .toList();
        _logToFile('成功转换为Reminder对象，数量: ${loadedReminders.length}');

        if (mounted) {
          setState(() { _reminders = loadedReminders; });
          _logToFile('已更新状态，设置_reminders');
        }
      } else {
        _logToFile('SharedPreferences中没有找到提醒数据');
      }
    } catch (e, stack) {
      debugPrint("加载提醒事项失败: $e");
      _logToFile("加载提醒事项失败: $e");
      _logToFile("堆栈: $stack");
      _logErrorToFile("加载提醒事项失败: $e");
      _logErrorToFile("堆栈: $stack");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载提醒事项失败')),
        );
      }
    } finally {
      if (mounted) {
          setState(() { _isLoading = false; });
          _logToFile('加载完成，设置_isLoading = false');
      }
    }
  } // _loadReminders 结束

  // 保存提醒列表到 SharedPreferences
  Future<void> _saveReminders() async {
    _logToFile('开始保存提醒列表，数量: ${_reminders.length}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final String remindersString = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      _logToFile('JSON编码成功，数据长度: ${remindersString.length}');
      await prefs.setString('reminders', remindersString);
      _logToFile('提醒列表保存成功');
    } catch (e, stack) {
      debugPrint("保存提醒事项失败: $e");
      _logToFile("保存提醒事项失败: $e");
      _logToFile("堆栈: $stack");
      _logErrorToFile("保存提醒事项失败: $e");
      _logErrorToFile("堆栈: $stack");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存提醒事项失败')),
        );
      }
    }
  } // _saveReminders 结束

  // 添加一个新提醒
  void _addReminder(Reminder reminder) { // [cite: 31]
  if (!mounted) return;
  // 直接修改 _reminders 可能与 _prepareTimelineItems 冲突
  // 为了保证数据一致性，更好的做法是先保存，再重新准备
  final updatedReminders = List<Reminder>.from(_reminders)..add(reminder);
  _saveRemindersDirectly(updatedReminders).then((_) { // 假设有一个直接保存列表的方法
     if (mounted) {
       _prepareTimelineItems(); // 重新准备时间线以包含新提醒
     }
  });

  // 或者，如果必须先 setState:
  // setState(() { _reminders.add(reminder); });
  // _saveReminders();
  // _prepareTimelineItems(); // 在 save 之后调用
}

// 您可能需要一个像这样的辅助方法来直接保存列表
Future<void> _saveRemindersDirectly(List<Reminder> remindersToSave) async {
   _logToFile('开始直接保存提醒列表，数量: ${remindersToSave.length}');
   try {
     final prefs = await SharedPreferences.getInstance();
     final String remindersString = jsonEncode(remindersToSave.map((r) => r.toJson()).toList());
     _logToFile('JSON编码成功，数据长度: ${remindersString.length}');
     await prefs.setString('reminders', remindersString);
     _logToFile('提醒列表直接保存成功');
   } catch (e, stack) {
     debugPrint("直接保存提醒事项失败: $e");
     _logToFile("直接保存提醒事项失败: $e");
     _logToFile("堆栈: $stack");
     _logErrorToFile("直接保存提醒事项失败: $e");
     _logErrorToFile("堆栈: $stack");

     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存提醒事项失败')),
        );
     }
   }
}// _addReminder 结束

  // 删除一个提醒
 void _deleteReminder(String id) { // <--- 参数改为 String id
  if (!mounted) return;
  // 构建删除了指定 id 提醒的新列表
  final updatedReminders = List<Reminder>.from(_reminders);
  final initialLength = updatedReminders.length;
  updatedReminders.removeWhere((reminder) => reminder.id == id); // <--- 使用 removeWhere 和 id

  // 检查是否真的有元素被移除，避免不必要的保存和刷新
  if (updatedReminders.length < initialLength) {
     _saveRemindersDirectly(updatedReminders).then((_) { // 保存新列表
        if (mounted) {
          _prepareTimelineItems(); // 重新准备时间线
        }
     });
  } else {
     debugPrint("错误：尝试删除 ID 为 $id 的提醒，但在列表中未找到。");
  }
}

  // 切换提醒的完成状态
  void _toggleCompleteStatus(Reminder reminder) { // [cite: 34]
  if (!mounted) return;
  final index = _reminders.indexWhere((r) => r.id == reminder.id); // 最好用唯一 ID 查找
  if (index != -1) {
     final updatedReminders = List<Reminder>.from(_reminders);
     // 创建新的 Reminder 对象来更新状态 (如果 Reminder 是不可变的)
     // 或者直接修改状态 (如果 isCompleted 不是 final)
     updatedReminders[index].isCompleted = !updatedReminders[index].isCompleted;
     // 可能还需要更新完成时间等...
     updatedReminders[index].completedDate = updatedReminders[index].isCompleted ? DateTime.now() : null;

     _saveRemindersDirectly(updatedReminders).then((_) { // 保存更新后的列表
       if (mounted) {
         _prepareTimelineItems(); // 重新准备时间线
       }
     });
     // 或者，如果必须先 setState:
     // setState(() {
     //    _reminders[index].isCompleted = !_reminders[index].isCompleted;
     //    _reminders[index].completedDate = _reminders[index].isCompleted ? DateTime.now() : null;
     // });
     // _saveReminders();
     // _prepareTimelineItems();
  }
} // _toggleCompleteStatus 结束

  // 导航到添加或编辑页面
  Future<void> _navigateToAddEditScreen({Reminder? reminder, int? index}) async {
     final List<Reminder> currentReminders = List.from(_reminders); // 创建一个副本传递
    final result = await Navigator.push(
      context,
      SlidePageRoute(
        page: AddReminderScreen(
          initialReminder: reminder,
          reminderIndex: index,
          existingReminders: currentReminders,
        ),
        direction: SlideDirection.up,
      ),
    );

    // 处理返回结果
    if (result == null || !mounted) return;

if (result is Reminder) { // --- 处理单个添加/编辑的情况 ---
  // 这个分支处理的是手动添加单个提醒，或者编辑后返回单个提醒的情况
  // （注意：编辑返回的是 Map，下面那个 else if 会处理）
  _addReminder(result); // 调用原来的单个添加逻辑
} else if (result is Map && result.containsKey('index') && result.containsKey('reminder')) { // --- 处理编辑返回的情况 ---
  // 编辑提醒的返回逻辑保持不变
  final int returnedIndex = result['index'];
  final Reminder updatedReminder = result['reminder'];
  if (returnedIndex >= 0 && returnedIndex < _reminders.length) {
     // ... (原来的编辑更新逻辑) ...
     setState(() {
       _reminders[returnedIndex] = updatedReminder;
     });
     _saveReminders(); // 保存整个列表
     _prepareTimelineItems(); // 刷新首页
  } else {
     debugPrint("错误：编辑返回的索引无效 ($returnedIndex)");
     final l10n = AppLocalizations.of(context);
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
  }
} else if (result is List<Reminder>) { // --- 新增：处理批量添加返回的情况 ---
  // 如果返回的是一个 Reminder 列表 (来自批量保存)
  debugPrint(">>> MainScreen - Received a list of ${result.length} new reminders.");

  // 创建一个新的列表，包含旧的和所有新添加的
  final updatedReminders = List<Reminder>.from(_reminders)..addAll(result);

  // 一次性保存包含所有新提醒的完整列表
  _saveRemindersDirectly(updatedReminders).then((_) {
     if (mounted) {
       _prepareTimelineItems(); // 刷新首页以显示所有新提醒
     }
  });
} else {
   // 可以处理其他未知的返回类型，或者忽略
   debugPrint("从 AddReminderScreen 返回了未知类型的结果: $result");
}
  } // _navigateToAddEditScreen 结束

  // 注意：此方法已被_prepareTimelineItems替代并移除
  // 如果需要过滤和排序提醒列表的功能，请参考_prepareTimelineItems方法

  // 构建主界面 UI
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day); // 今天日期，忽略时间

    // 使用 collection 包的 groupBy 进行分组
    final groupedReminders = groupBy<Reminder, DateTime?>(
      _reminders, // 使用原始列表
      (reminder) {
        if (reminder.dueDate == null) return null; // 无日期
        return DateTime(reminder.dueDate!.year, reminder.dueDate!.month, reminder.dueDate!.day); // 按年月日分组
      },
    );

    // --- 2. 准备用于 ListView 的数据 ---
    final List<DateTime?> sortedDates = groupedReminders.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1; // null (无日期) 排最后
        if (b == null) return -1;
        return a.compareTo(b); // 按日期升序
      });

    // 将今天的日期移到最前面
    if (groupedReminders.containsKey(todayDate)) {
       sortedDates.remove(todayDate);
       sortedDates.insert(0, todayDate);
    }

    return Scaffold(
      appBar: AppBar(
         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
         title: Text(l10n.appTitle),
         actions: [
            // 节日筛选按钮
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: l10n.filterHolidays,
              onPressed: () {
                _showHolidayFilterDialog();
              },
            ),

            // 设置按钮
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: l10n.settingsTooltip,
              onPressed: () {
                 Navigator.push(
                   context,
                   SlidePageRoute(
                     page: const SettingsScreen(),
                     direction: SlideDirection.left,
                   ),
                 );
              },
            ),
         ],
          bottom: PreferredSize( // 使用 PreferredSize 指定 AppBar 底部区域的高度
              preferredSize: const Size.fromHeight(30.0), // 调整合适的高度
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: _buildCurrentDateDisplay(context), // 调用新方法构建日期显示
              ),
           ),
      ),
      body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _sortedTimelineItems.isEmpty // <--- 改为检查新的列表是否为空
        ? _buildEmptyStateWidget() // <--- 调用新的空状态 Widget
        : _buildCombinedList(), // <--- 调用重命名/修改后的方法
// --- 修改结束 ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(), // 导航到添加/编辑页的调用不变
        tooltip: l10n.addReminderTooltip,
        child: const Icon(Icons.add),
      ),
    );
  } // build 结束
  // --- 在 _MyHomePageState 类内部，添加这个新方法 ---
Widget _buildCombinedList() {
  // 使用 collection 包的 groupBy 功能，对合并排序后的列表按日期分组
  // 注意：我们现在处理的是 _sortedTimelineItems 状态变量
  final groupedItems = groupBy<TimelineItem, String?>(
    _sortedTimelineItems,
    (item) {
      // --- 修改这里 ---
    // 如果 displayDate 为 null，返回 null 作为 key；否则，返回日期字符串
      return item.displayDate?.toIso8601String().substring(0, 10); // 使用 ?. 安全访问
    },
  );

  // 准备日期键并排序，“今天”优先，null (无日期) 最后
  final now = DateTime.now();
  final todayKey = now.toIso8601String().substring(0, 10); // 今天日期的键
  final List<String?> sortedDateKeys = groupedItems.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1; // null 排最后
      if (b == null) return -1;
      if (a == todayKey) return -1; // 今天排最前 (除了 null)
      if (b == todayKey) return 1;
      return a.compareTo(b); // 其他按日期升序
    });

  // 如果今天不在 keys 里，但列表不为空，则手动将今天加到最前面
  // （这处理了即使今天没事件，排序时也考虑“今天”的情况）
  if (!groupedItems.containsKey(todayKey) && _sortedTimelineItems.isNotEmpty) {
     // 如果需要，可以在这里插入一个空的 "今天" 占位符或其他逻辑
     // 但更简单的做法是，如果今天没有事件，分组里就不会有 todayKey，
     // 排序后它自然不会出现在前面。
     // 我们需要确保排序逻辑将 todayKey（如果存在）置顶。
     // 上面的排序已经处理了这一点。
  }


  // 构建 ListView
  return ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
    itemCount: sortedDateKeys.length, // 列表项数量是日期的组数
    itemBuilder: (context, index) {
      final dateKey = sortedDateKeys[index]; // 当前日期组的键 (YYYY-MM-DD 或 null)
      final itemsForDate = groupedItems[dateKey] ?? []; // 获取该日期的所有 TimelineItem

      // --- 根据日期键构建不同的 UI ---

      // 1. 处理“今天”的逻辑
      if (dateKey == todayKey) {
        // 将今天的项目分为提醒和节日
        final todayReminders = itemsForDate
            .where((item) => item.itemType == TimelineItemType.reminder)
            .map((item) => item.originalObject as Reminder)
            .toList();
        // 获取今天的节日（暂未使用，但保留以备将来使用）
        // final todayHolidays = itemsForDate
        //     .where((item) => item.itemType == TimelineItemType.holiday)
        //     .map((item) => item.originalObject as special_date.SpecialDate)
        //     .toList();

        // 按提醒、节日顺序显示在一个 Column 里
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示今天的节日 (如果有)
            ...itemsForDate // 遍历今天的 TimelineItem
    .where((item) => item.itemType == TimelineItemType.holiday) // 筛选出节日
    .map((item) {
      final holiday = item.originalObject as special_date.SpecialDate;
      final occurrenceDate = item.displayDate; // 先不强制解包
if (occurrenceDate != null) { // 添加检查
  return _buildHolidayCard(context, holiday, occurrenceDate);
} else {
  return const SizedBox.shrink(); // 日期为空则不显示（理论上不应发生）
}
    }),

            // 显示今天的提醒
            if (todayReminders.isNotEmpty)
              (todayReminders.length > 1)
                  ? _buildConsolidatedTodayCard(context, todayReminders, DateTime.now()) // 多个提醒用合并卡
                  : _buildSingleReminderCard(context, todayReminders.first, _reminders.indexOf(todayReminders.first), isToday: true), // 单个提醒用单卡
          ],
        );
      }
      // 2. 处理未来日期或无日期 (非今天)
      else {
         // （可选）可以为每个非今天的日期组添加一个日期标题
         // Widget dateHeader = dateKey != null
         //    ? Padding(padding: const EdgeInsets.all(8.0), child: Text(dateKey)) // 显示 YYYY-MM-DD
         //    : Padding(padding: const EdgeInsets.all(8.0), child: Text(l10n.noDate)); // 使用本地化字符串

         return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // if (dateHeader != null) dateHeader, // 如果需要日期标题，取消注释
               // 遍历该日期的所有项目，生成对应的卡片
               ...itemsForDate.map((item) {
                  if (item.itemType == TimelineItemType.reminder) {
                     final reminder = item.originalObject as Reminder;
                     final originalIndex = _reminders.indexOf(reminder); // 找到原始索引
                     return _buildSingleReminderCard(context, reminder, originalIndex);
                  } else { // itemType is holiday
                     final holiday = item.originalObject as special_date.SpecialDate;
                     // 注意： item.displayDate 是节日发生的日期
                     final holidayDate = item.displayDate; // 先不强制解包
if (holidayDate != null) { // 添加检查
   return _buildHolidayCard(context, holiday, holidayDate);
} else {
   return const SizedBox.shrink(); // 日期为空则不显示（理论上不应发生）
}
                  }
               }),
            ],
         );
      }
    },
  );
}
// --- 在 _MyHomePageState 类内部，添加这个新方法 ---
Widget _buildEmptyStateWidget() {
  final l10n = AppLocalizations.of(context); // 获取本地化实例
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.emptyStateMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 重新加载数据
              _prepareTimelineItems();
            },
            child: const Text("刷新"),
          ),
        ],
      ),
    ),
  );
}
// --- 新方法添加结束 ---



// 方法3：构建单个节日卡片的 Widget
Widget _buildHolidayCard(BuildContext context, special_date.SpecialDate holiday, DateTime upcomingDate) {
  // 获取本地化实例
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  DateTime now = DateTime.now();
  // 传递语言环境参数
  String formattedGregorianDate = holiday.formatUpcomingDate(upcomingDate, now, locale: locale);

  // --- 新增：计算农历日期 (仅当节日类型是农历且是中文环境时) ---
  String? lunarDateString;
  if (holiday.calculationType == special_date.DateCalculationType.fixedLunar &&
      Localizations.localeOf(context).languageCode == 'zh') {
    try {
      // 对于农历节日，直接从 calculationRule 中获取农历月日
      final parts = holiday.calculationRule.replaceFirst('L', '').split('-');
      if (parts.length == 2) {
        final lMonth = int.parse(parts[0]);
        final lDay = int.parse(parts[1]);

        // 使用农历月日构建农历字符串
        String monthInChinese;
        switch (lMonth) {
          case 1: monthInChinese = '正'; break;
          case 2: monthInChinese = '二'; break;
          case 3: monthInChinese = '三'; break;
          case 4: monthInChinese = '四'; break;
          case 5: monthInChinese = '五'; break;
          case 6: monthInChinese = '六'; break;
          case 7: monthInChinese = '七'; break;
          case 8: monthInChinese = '八'; break;
          case 9: monthInChinese = '九'; break;
          case 10: monthInChinese = '十'; break;
          case 11: monthInChinese = '冬'; break;
          case 12: monthInChinese = '腊'; break;
          default: monthInChinese = lMonth.toString();
        }

        String dayInChinese;
        if (lDay <= 10) {
          dayInChinese = '初${_convertToChinese(lDay)}';
        } else if (lDay < 20) {
          dayInChinese = '十${_convertToChinese(lDay - 10)}';
        } else if (lDay == 20) {
          dayInChinese = '二十';
        } else if (lDay < 30) {
          dayInChinese = '廿${_convertToChinese(lDay - 20)}';
        } else if (lDay == 30) {
          dayInChinese = '三十';
        } else {
          dayInChinese = lDay.toString();
        }

        lunarDateString = '${l10n.lunar} $monthInChinese月$dayInChinese';
      } else {
        // 如果解析失败，回退到从公历转换
        final solar = Solar.fromDate(upcomingDate);
        final lunar = solar.getLunar();
        lunarDateString = '${l10n.lunar} ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
      }
    } catch (e) {
      // 如果出错，就不显示农历
      debugPrint("Error formatting lunar date for ${holiday.name}: $e");
    }
  }
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
    shape: RoundedRectangleBorder( // 添加圆角
      borderRadius: BorderRadius.circular(12.0),
    ),
    elevation: 3.0,
    child: ListTile(
       contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      leading: CardIcon(
        icon: holiday.typeIcon,
        color: holiday.getHolidayColor(),
      ),
      title: Text(
        holiday.name, // 假设 name 已经是目标语言，或者需要本地化
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column( // 改用 Column 垂直排列日期信息
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4.0), // 加一点间距
          Text(
            formattedGregorianDate, // 显示公历日期和剩余天数
            // --- UI 调整：调整字体大小和颜色 ---
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            // --- UI 调整结束 ---
          ),
          // 如果是农历节日，额外显示农历日期
          if (lunarDateString != null)
            Padding( // 给农历日期加点上边距
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                lunarDateString,
                // --- UI 调整：农历日期用不同样式 ---
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                // --- UI 调整结束 ---
              ),
            ),
        ],
      ), // 使用 special_date.dart 中的格式化方法
      // 未来可能添加分享按钮
      // trailing: IconButton(
      //   icon: Icon(Icons.share),
      //   onPressed: () {
      //     // 分享功能
      //   },
      // ),
      onTap: () {
        // 导航到节日详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HolidayDetailScreen(
              holiday: holiday,
              occurrenceDate: upcomingDate,
            ),
          ),
        );
      },
    ),
  );
}
// --- 新方法添加结束 ---
  // --- 新增方法：构建单个提醒卡片 ---
  Widget _buildSingleReminderCard(BuildContext context, Reminder reminder, int originalIndex, {bool isToday = false}) {
    final l10n = AppLocalizations.of(context);
     final textStyleCompleted = TextStyle( decoration: TextDecoration.lineThrough, color: Colors.grey[500],);
     final textStyleNormal = TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color);
     final dateTextStyle = TextStyle( fontSize: 12, color: reminder.isCompleted ? Colors.grey[500] : Colors.grey[600], decoration: reminder.isCompleted ? TextDecoration.lineThrough : TextDecoration.none, );

     // 简单的安全检查，防止索引越界 (虽然理论上不应该发生)
     if (originalIndex < 0 || originalIndex >= _reminders.length) {
         debugPrint("警告: _buildSingleReminderCard 收到无效索引 $originalIndex");
         // 可以返回一个空的 SizedBox 或者一个错误提示 Widget
         // return const SizedBox.shrink();
         // 或者尝试重新查找，但这可能效率低
         originalIndex = _reminders.indexOf(reminder);
         if (originalIndex == -1) return const SizedBox.shrink(); // 找不到就放弃渲染
     }


     return Card(
       key: ValueKey(reminder.hashCode),
       margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
       color: isToday ? Colors.lightBlue[50] : null,
       child: ListTile(
         leading: Checkbox(
           value: reminder.isCompleted,
           onChanged: (bool? newValue) {
             if (newValue != null) { _toggleCompleteStatus(reminder); }
           },
         ),
         title: Text( reminder.title, style: reminder.isCompleted ? textStyleCompleted : textStyleNormal, ),
         subtitle: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             if (reminder.description.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(bottom: 4.0),
                 child: Text( reminder.description, style: reminder.isCompleted ? textStyleCompleted : textStyleNormal, maxLines: 2, overflow: TextOverflow.ellipsis,),
               ),
             if (reminder.dueDate != null)
               Text(
                 formatReminderDate(context, reminder.dueDate,reminder.type),
                 style: dateTextStyle,
               ),
           ],
         ),
         trailing: IconButton(
           icon: const Icon(Icons.delete, color: Colors.red),
           tooltip: l10n.deleteTooltip,
           onPressed: () {
            // 确保 originalIndex 有效才执行删除
            if (originalIndex != -1) {
               _deleteReminder(reminder.id);
            } else {
               debugPrint("错误: 在卡片上删除时索引无效");
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
            }
        },
         ),
         isThreeLine: reminder.description.isNotEmpty && reminder.dueDate != null,
         onTap: () {
          if (originalIndex == -1) { // 检查传入的参数 originalIndex
     debugPrint("错误: _buildSingleReminderCard 收到的 originalIndex 无效 (-1)。");
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotOpenReminderDetails)),
        );
     }
     return; // 索引无效，直接返回，不执行导航
   }
           // 导航到详情页
           Navigator.push( context, MaterialPageRoute( builder: (context) => ReminderDetailScreen(reminder: reminder,originalIndex: originalIndex,existingReminders: _reminders,),),
          ).then((result) {
          // --- 替换 .then 内部逻辑 ---
          if (result != null && result is Map) {
            final action = result['action'];
            final index = result['index']; // 获取返回的索引

            if (index != null && index >= 0 && index < _reminders.length) {
               if (action == 'deleted') {
  // 如果是从详情页返回删除，主页需要处理删除
  _deleteReminder(reminder.id); // <--- 修改为传递 reminder.id
} else if (action == 'edited') {
  final updatedReminder = result['reminder'];
  if (updatedReminder != null && updatedReminder is Reminder && index != null && index >= 0 && index < _reminders.length) {
     final updatedReminders = List<Reminder>.from(_reminders);
     updatedReminders[index] = updatedReminder; // 更新列表副本
     _saveRemindersDirectly(updatedReminders).then((_) { // 保存更新后的列表
        if (mounted) {
         _prepareTimelineItems();
        }
     });

     // 或者，如果必须先 setState:
     // setState(() { _reminders[index] = updatedReminder; });
     // _saveReminders();
     // _prepareTimelineItems(); // 在 save 之后调用
  }
}
            } else if (action == 'deleted' && index == null) {
               // 如果索引无效但标记为删除，可能需要重新加载或提示错误
               debugPrint("从详情页返回删除，但索引无效");
               _loadReminders();
               _prepareTimelineItems();// 尝试重新加载以同步状态
            }
          } else if (result == 'deleted') { // 兼容旧的返回方式 (以防万一)
             debugPrint("从详情页返回 'deleted' 字符串，可能需要刷新");
             _loadReminders();
             _prepareTimelineItems();// 尝试重新加载
          }
          // --- 替换结束 ---
       });
         },
       ),
     );
  }

  // --- 添加新方法：构建顶部日期显示 ---
  Widget _buildCurrentDateDisplay(BuildContext context) {
    final l10n = AppLocalizations.of(context); // 获取本地化实例
    final locale = Localizations.localeOf(context); // 获取当前 Locale
    final now = DateTime.now(); // 获取当前时间

    // 使用 intl 格式化公历日期，根据语言环境选择不同的格式
    String gregorianDateString;
    if (locale.languageCode == 'zh') {
      // 中文环境使用中文格式
      gregorianDateString = DateFormat('yyyy年M月d日', locale.toString()).format(now);
    } else {
      // 其他语言环境使用通用格式
      gregorianDateString = DateFormat.yMMMMd(locale.toString()).format(now);
    }

    String fullDateString = gregorianDateString; // 默认只显示公历

    // 只在中文环境显示农历信息
    if (locale.languageCode == 'zh') {
      final solar = Solar.fromDate(now); // 使用 lunar 包从公历日期创建 Solar 对象
      final lunar = solar.getLunar(); // 获取对应的 Lunar 对象

      // 格式化农历字符串 (可以自定义)
      // lunar.getMonthInChinese() 获取中文月份 (如 正月, 二月)
      // lunar.getDayInChinese() 获取中文日期 (如 初一, 十五, 廿二)
      final lunarDateString = '${l10n.lunar} ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}'; // 基础格式

      fullDateString += ' $lunarDateString'; // 拼接公历和农历

      // 检查是否有节气
      final jieQi = lunar.getJieQi();
      if (jieQi.isNotEmpty) {
         fullDateString += ' $jieQi'; // 如果有节气，也加上
      }
    }

    return SizedBox(
      width: double.infinity, // 使用全宽
      child: Text(
        fullDateString,
        textAlign: TextAlign.center, // 居中显示
        overflow: TextOverflow.ellipsis, // 文本溢出时显示省略号
        maxLines: 1, // 限制为单行
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white, // 尝试匹配 AppBar 标题颜色
        ),
      ),
    );
  }
  // --- 方法添加结束 ---
  // --- 新增方法：构建今日合并卡片 ---
  Widget _buildConsolidatedTodayCard(BuildContext context, List<Reminder> reminders, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    // 合并卡片内也需要过滤过期的已完成提醒
    final nowMinute = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute);
    final relevantRemindersInCard = reminders.where((r) {
        if (r.isCompleted && r.dueDate != null) {
           final reminderDueMinute = DateTime(r.dueDate!.year, r.dueDate!.month, r.dueDate!.day, r.dueDate!.hour, r.dueDate!.minute);
           return !reminderDueMinute.isBefore(nowMinute);
        }
        return true;
    }).toList();

    // 如果过滤后合并卡内也没内容了，则不显示
    if (relevantRemindersInCard.isEmpty) return const SizedBox.shrink();

    // 对合并卡内的内容按时间排序
    relevantRemindersInCard.sort((a, b) {
       if (a.dueDate == null) return 1;
       if (b.dueDate == null) return -1;
       return a.dueDate!.compareTo(b.dueDate!);
    });

    return Card(
       margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
       color: Colors.amber[50],
       child: Padding(
         padding: const EdgeInsets.all(12.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text(
                   l10n.today,
                   style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8.0),
              const Divider(),
              // 遍历今天的提醒
              ...relevantRemindersInCard.map((reminder) {

                  final textStyleCompleted = TextStyle( decoration: TextDecoration.lineThrough, color: Colors.grey[500],);
                  final textStyleNormal = TextStyle(color: Theme.of(context).textTheme.bodySmall?.color);
                   final timeStyle = TextStyle( fontSize: 12, color: reminder.isCompleted ? Colors.grey[500] : Colors.blueGrey[700], decoration: reminder.isCompleted ? TextDecoration.lineThrough : TextDecoration.none, fontWeight: FontWeight.bold );

                  return ListTile(
                     key: ValueKey(reminder.hashCode),
                     dense: true,
                     visualDensity: VisualDensity.compact,
                     leading: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: reminder.isCompleted,
                        onChanged: (bool? newValue) {
                          if (newValue != null) { _toggleCompleteStatus(reminder); }
                        },
                      ),
                     title: Text(reminder.title, style: reminder.isCompleted ? textStyleCompleted : textStyleNormal),
                     subtitle: reminder.description.isNotEmpty ? Text(reminder.description, style: reminder.isCompleted ? textStyleCompleted.copyWith(fontSize: 11) : textStyleNormal.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                     trailing: Text(
                       reminder.dueDate != null ? DateFormat.Hm(locale).format(reminder.dueDate!) : '',
                       style: timeStyle,
                     ),
                     onTap: () {
                      final originalIndex = _reminders.indexOf(reminder); // 查找原始索引
                  if (originalIndex == -1) {
  debugPrint("错误: 跳转详情页前无法在列表中找到提醒对象 (合并卡片)。");
  if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(l10n.cannotOpenReminderDetails)),
     );
  }
  return; // 索引无效，不导航
}
// 只有 originalIndex 有效才继续执行下面的 Navigator.push(...).then(...)
                        // 跳转到详情页
                        Navigator.push( context, MaterialPageRoute( builder: (context) => ReminderDetailScreen(reminder: reminder,originalIndex: originalIndex,existingReminders: _reminders, ),),
                        ).then((result) {
          // --- 替换 .then 内部逻辑 ---
          if (result != null && result is Map) {
            final action = result['action'];
            final index = result['index']; // 获取返回的索引

            if (index != null && index >= 0 && index < _reminders.length) {
                  if (action == 'deleted') {
                   // 如果是从详情页返回删除，主页需要处理删除
                   _deleteReminder(reminder.id); // <--- 修改为传递 reminder.id
                   }else if (action == 'edited') {
                  // 如果是从编辑页经过详情页返回，主页需要处理更新
                  final updatedReminder = result['reminder'];
                  if (updatedReminder != null && updatedReminder is Reminder) {
                     setState(() {
                       _reminders[index] = updatedReminder;
                     });
                     _saveReminders();
                     _prepareTimelineItems();
                  }
               }
            } else if (action == 'deleted' && index == null) {
               // 如果索引无效但标记为删除，可能需要重新加载或提示错误
               debugPrint("从详情页返回删除，但索引无效");
               _loadReminders();
               _prepareTimelineItems();// 尝试重新加载以同步状态
            }
          } else if (result == 'deleted') { // 兼容旧的返回方式 (以防万一)
             debugPrint("从详情页返回 'deleted' 字符串，可能需要刷新");
             _loadReminders(); // 尝试重新加载
             _prepareTimelineItems();
          }
          // --- 替换结束 ---
       });
                     },
                  );
              }),
           ],
         ),
       ),
    );
  }
  // --- 在 _MyHomePageState 类内部，添加这个新方法 ---
// --- 粘贴开始：用这段完整代码替换你原来的 _prepareTimelineItems 方法 ---
Future<void> _prepareTimelineItems() async {
  debugPrint('=== 开始准备时间线项目 ===');
  _logToFile('=== 开始准备时间线项目 ===');

  try {
    // 如果 widget 不再显示，则不执行后续操作
    if (!mounted) {
      debugPrint('组件已卸载，取消准备时间线');
      _logToFile('组件已卸载，取消准备时间线');
      return;
    }

    // 记录当前状态
    _logToFile('当前提醒数量: ${_reminders.length}');
    _logToFile('当前时间线项目数量: ${_sortedTimelineItems.length}');
    _logToFile('当前加载状态: $_isLoading');
    _logToFile('当前选中的节日类型: ${_selectedHolidayTypes.map((t) => t.toString()).join(', ')}');
  } catch (e, stack) {
    _logToFile('准备时间线初始检查出错: $e');
    _logToFile('堆栈: $stack');
    _logErrorToFile('准备时间线初始检查出错: $e');
    _logErrorToFile('堆栈: $stack');
  }

  // 准备一个临时的列表来存放最终结果
  List<TimelineItem> combinedItems = [];
  // 同时准备一个临时的列表来存放当前加载的提醒，用于更新 _reminders
  List<Reminder> currentReminders = [];

  try {
    // 开始处理数据，设置加载状态为 true
    setState(() {
      _isLoading = true;
      // 清空旧的时间线数据，避免重复添加
      _sortedTimelineItems = [];
    });
    debugPrint('已设置加载状态，清空旧数据');
    _logToFile('已设置加载状态，清空旧数据');
    debugPrint('已初始化临时列表');
    _logToFile('已初始化临时列表');
  } catch (e, stack) {
    debugPrint('=== 准备时间线初始化阶段出错 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');
    _logToFile('=== 准备时间线初始化阶段出错 ===');
    _logToFile('错误: $e');
    _logToFile('堆栈: $stack');
    _logErrorToFile('=== 准备时间线初始化阶段出错 ===');
    _logErrorToFile('错误: $e');
    _logErrorToFile('堆栈: $stack');

    // 确保不会因为初始化错误而阻止后续操作
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _logToFile('由于初始化错误，已设置加载状态为false');
    }
    return;
  }

  // 1. 加载提醒事项
  try {
    debugPrint('开始加载提醒事项...');
    _logToFile('开始加载提醒事项...');
    final prefs = await SharedPreferences.getInstance();
    final String? remindersString = prefs.getString('reminders');

    if (remindersString != null) {
      debugPrint('找到提醒事项数据，长度: ${remindersString.length}字节');

      try {
        final List<dynamic> reminderJson = jsonDecode(remindersString);
        debugPrint('成功解析JSON，找到${reminderJson.length}个提醒事项');

        // 先将 JSON 转换为 Reminder 对象
        currentReminders = reminderJson
            .map((json) {
              try {
                return Reminder.fromJson(json);
              } catch (e, stack) {
                debugPrint('解析单个提醒事项失败: $e');
                debugPrint('堆栈: $stack');
                return null;
              }
            })
            .whereType<Reminder>() // 过滤掉转换失败的
            .toList();

        debugPrint('成功转换${currentReminders.length}个提醒事项对象');

        // 再将加载的 Reminder 转换为 TimelineItem
        final reminderTimelineItems = currentReminders.map((reminder) {
          return TimelineItem(
            displayDate: reminder.dueDate,
            itemType: TimelineItemType.reminder,
            originalObject: reminder,
          );
        }).toList();

        debugPrint('成功创建${reminderTimelineItems.length}个时间线项目');
        combinedItems.addAll(reminderTimelineItems);
      } catch (e, stack) {
        debugPrint('=== JSON解析或对象转换失败 ===');
        debugPrint('错误: $e');
        debugPrint('堆栈: $stack');

        // 尝试恢复：使用空列表继续
        currentReminders = [];
      }
    } else {
      debugPrint('未找到提醒事项数据，使用空列表');
    }
  } catch (e, stack) {
    debugPrint('=== 加载提醒事项失败 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loadingRemindersError)),
      );
    }
  }

  // 2. 从数据库加载特殊纪念日
  try {
    debugPrint('开始加载特殊纪念日...');

    // 获取当前日期
    DateTime now = DateTime.now();
    debugPrint('当前日期: ${now.toIso8601String()}');

    // 获取 MyApp 的状态以访问特殊纪念日显示范围
    int specialDaysRange = 10; // 默认为10天
    if (mounted) {
      try {
        final myAppState = context.findAncestorStateOfType<_MyAppState>();
        specialDaysRange = myAppState?._specialDaysRange ?? 10;
        debugPrint('特殊纪念日显示范围: $specialDaysRange天');
      } catch (e, stack) {
        debugPrint('获取特殊纪念日显示范围失败: $e');
        debugPrint('堆栈: $stack');
        // 使用默认值继续
      }
    }

    // 使用统一的数据库管理服务
    if (mounted) {
      try {
        debugPrint('开始从数据库获取节日数据...');
        final dbManager = Provider.of<DatabaseManagerUnified>(context, listen: false);
        final currentLanguageCode = Localizations.localeOf(context).languageCode;
        final userRegion = localization.LocalizationService.getUserRegion(context);
        debugPrint('当前语言: $currentLanguageCode, 用户地区: $userRegion');

        // 获取用户所在地区的节日
        List<models.Holiday> holidays = [];

        // 根据当前语言获取对应地区的节日
        if (currentLanguageCode == 'ja') {
          // 日语 - 获取日本节日
          holidays = await dbManager.getHolidaysByRegion('JP', languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个日本节日');
        } else if (currentLanguageCode == 'ko') {
          // 韩语 - 获取韩国节日
          holidays = await dbManager.getHolidaysByRegion('KR', languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个韩国节日');
        } else if (currentLanguageCode == 'fr') {
          // 法语 - 获取法国节日
          holidays = await dbManager.getHolidaysByRegion('FR', languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个法国节日');
        } else if (currentLanguageCode == 'de') {
          // 德语 - 获取德国节日
          holidays = await dbManager.getHolidaysByRegion('DE', languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个德国节日');
        } else {
          // 其他语言 - 获取用户所在地区的节日
          holidays = await dbManager.getHolidaysByRegion(userRegion, languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个${userRegion}地区节日');
        }

        // 如果没有获取到节日数据，尝试获取国际节日
        if (holidays.isEmpty) {
          holidays = await dbManager.getHolidaysByRegion('INTL', languageCode: currentLanguageCode);
          debugPrint('从数据库获取到${holidays.length}个国际节日');
        }

        // 将Holiday转换为SpecialDate
        final specialDays = holidays.map((holiday) {
          try {
            return special_date.SpecialDate(
              id: holiday.id,
              name: holiday.getLocalizedName(currentLanguageCode),
              description: holiday.getLocalizedDescription(currentLanguageCode) ?? '',
              type: _convertHolidayTypeToSpecialDateType(holiday.type),
              regions: holiday.regions,
              calculationType: _convertCalculationTypeToSpecialDateCalculationType(holiday.calculationType),
              calculationRule: holiday.calculationRule,
              importanceLevel: _convertImportanceLevelToImportanceLevel(holiday.importanceLevel),
            );
          } catch (e, stack) {
            debugPrint('转换节日数据出错 (ID: ${holiday.id}): $e');
            debugPrint('堆栈: $stack');
            return null;
          }
        }).whereType<special_date.SpecialDate>().toList();

        debugPrint('成功转换${specialDays.length}个特殊日期对象');

        // 智能显示策略：根据重要性和时间范围显示节日
        debugPrint('开始处理节日显示策略...');
        int processedCount = 0;
        int addedCount = 0;

        for (var specialDay in specialDays) {
          try {
            processedCount++;
            if (_selectedHolidayTypes.contains(specialDay.type)) {
              DateTime? occurrence = specialDay.getUpcomingOccurrence(now);
              if (occurrence != null) {
                // 计算与当前日期的天数差
                int daysDifference = occurrence.difference(now).inDays;

                // 获取当前节日的重要性
                int importance = 0;

                // 根据importanceLevel设置importance
                switch (specialDay.importanceLevel) {
                  case special_date.ImportanceLevel.high:
                    importance = 2; // 非常重要
                    break;
                  case special_date.ImportanceLevel.medium:
                    importance = 1; // 重要
                    break;
                  default:
                    importance = 0; // 普通
                    break;
                }

                // 根据重要性和时间范围决定是否显示
                bool shouldShow = false;

                // 非常重要的节日始终显示
                if (importance == 2) {
                  shouldShow = true;
                }
                // 重要的节日在较长时间范围内显示（2倍范围）
                else if (importance == 1) {
                  shouldShow = daysDifference >= 0 && daysDifference <= specialDaysRange * 2;
                }
                // 普通重要性的节日只在指定范围内显示
                else {
                  shouldShow = daysDifference >= 0 && daysDifference <= specialDaysRange;
                }

                // 如果应该显示，则添加到列表中
                if (shouldShow) {
                  combinedItems.add(TimelineItem(
                    displayDate: occurrence,
                    itemType: TimelineItemType.holiday,
                    originalObject: specialDay,
                  ));
                  addedCount++;
                }
              } else {
                debugPrint('节日 "${specialDay.name}" 无法计算下一个发生日期');
              }
            }
          } catch (e, stack) {
            debugPrint('处理节日 "${specialDay.name}" 时出错: $e');
            debugPrint('堆栈: $stack');
            // 继续处理下一个节日
          }
        }

        debugPrint('节日处理完成: 处理了$processedCount个节日，添加了$addedCount个到时间线');
      } catch (e, stack) {
        debugPrint('=== 获取节日数据出错 ===');
        debugPrint('错误: $e');
        debugPrint('堆栈: $stack');
      }
    }
  } catch (e, stack) {
    debugPrint('=== 加载特殊纪念日失败 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');
  }

  // 3. 排序合并后的列表
  try {
    debugPrint('开始排序合并后的列表，共${combinedItems.length}个项目...');
    combinedItems.sort();
    debugPrint('排序完成');
  } catch (e, stack) {
    debugPrint('=== 排序时间线项目失败 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');
    // 尝试恢复：不排序继续
  }

  // 4. 更新状态
  try {
    if (mounted) {
      debugPrint('更新UI状态...');
      setState(() {
        _reminders = currentReminders;
        _sortedTimelineItems = combinedItems;
        _isLoading = false;
      });
      debugPrint('=== 时间线准备完成 ===');
      debugPrint('提醒事项: ${currentReminders.length}个');
      debugPrint('时间线项目: ${combinedItems.length}个');
    } else {
      debugPrint('组件已卸载，取消更新状态');
    }
  } catch (e, stack) {
    debugPrint('=== 更新UI状态失败 ===');
    debugPrint('错误: $e');
    debugPrint('堆栈: $stack');

    // 尝试最后的恢复：至少关闭加载状态
    if (mounted) {
      try {
        setState(() {
          _isLoading = false;
        });
      } catch (finalError) {
        debugPrint('最终恢复尝试也失败: $finalError');
      }
    }
  }
}
// --- 粘贴结束：确认这是 _prepareTimelineItems 方法的结尾 ---

  // 辅助方法：将数字转换为中文数字
  String _convertToChinese(int num) {
    switch (num) {
      case 0: return '〇';
      case 1: return '一';
      case 2: return '二';
      case 3: return '三';
      case 4: return '四';
      case 5: return '五';
      case 6: return '六';
      case 7: return '七';
      case 8: return '八';
      case 9: return '九';
      default: return num.toString();
    }
  }

  // 将HolidayType转换为SpecialDateType
  special_date.SpecialDateType _convertHolidayTypeToSpecialDateType(models.HolidayType type) {
    switch (type) {
      case models.HolidayType.statutory:
        return special_date.SpecialDateType.statutory;
      case models.HolidayType.traditional:
        return special_date.SpecialDateType.traditional;
      case models.HolidayType.solarTerm:
        return special_date.SpecialDateType.solarTerm;
      case models.HolidayType.memorial:
        return special_date.SpecialDateType.memorial;
      case models.HolidayType.custom:
        return special_date.SpecialDateType.custom;
      default:
        return special_date.SpecialDateType.other;
    }
  }

  // 将统一模型的DateCalculationType转换为特殊日期的DateCalculationType
  dynamic _convertCalculationTypeToSpecialDateCalculationType(models.DateCalculationType type) {
    if (type == models.DateCalculationType.fixedGregorian) {
      return special_date.DateCalculationType.fixedGregorian;
    } else if (type == models.DateCalculationType.fixedLunar) {
      return special_date.DateCalculationType.fixedLunar;
    } else if (type == models.DateCalculationType.variableRule) {
      return special_date.DateCalculationType.nthWeekdayOfMonth;
    } else {
      return special_date.DateCalculationType.fixedGregorian;
    }
  }

  // 将统一模型的ImportanceLevel转换为特殊日期的ImportanceLevel
  dynamic _convertImportanceLevelToImportanceLevel(models.ImportanceLevel level) {
    if (level == models.ImportanceLevel.low) {
      return special_date.ImportanceLevel.low;
    } else if (level == models.ImportanceLevel.medium) {
      return special_date.ImportanceLevel.medium;
    } else if (level == models.ImportanceLevel.high) {
      return special_date.ImportanceLevel.high;
    } else {
      return special_date.ImportanceLevel.low;
    }
  }

  // 显示节日筛选对话框
  void _showHolidayFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => HolidayFilterDialog(
        selectedTypes: _selectedHolidayTypes,
        onApply: (selectedTypes) {
          setState(() {
            _selectedHolidayTypes = selectedTypes;
          });
          // 重新加载节日列表
          _prepareTimelineItems();
        },
      ),
    );
  }


} // _MyHomePageState 类结束