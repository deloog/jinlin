import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:jinlin_app/app.dart';
import 'package:jinlin_app/firebase_options.dart';
import 'package:jinlin_app/providers/app_settings_provider.dart';
import 'package:jinlin_app/providers/auth_provider.dart';
import 'package:jinlin_app/providers/locale_provider.dart';
import 'package:jinlin_app/providers/notification_provider.dart';
import 'package:jinlin_app/providers/theme_provider.dart';
import 'package:jinlin_app/services/auth/auth_service.dart';
import 'package:jinlin_app/services/auth/third_party_auth_service.dart';
import 'package:jinlin_app/services/notification/notification_service.dart';
import 'package:jinlin_app/services/api/api_client.dart';
import 'package:jinlin_app/services/cache/cache_manager.dart';
import 'package:jinlin_app/services/database/database_service.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 应用程序入口点
void main() async {
  // 捕获全局错误
  runZonedGuarded(() async {
    // 确保Flutter绑定初始化
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // 加载环境变量
      await dotenv.load(fileName: '.env');

      // 初始化Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 设置应用方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 初始化日期格式
      await initializeDateFormatting('zh_CN', null);

      // 初始化服务
      final authService = AuthService();
      await authService.initialize();

      final thirdPartyAuthService = ThirdPartyAuthService();
      await thirdPartyAuthService.initialize();

      final notificationService = NotificationService();
      await notificationService.initialize();

      // 初始化日志服务
      final loggingService = LoggingService();

      // 初始化数据库服务
      final databaseService = DatabaseService();
      try {
        await databaseService.initialize();
        loggingService.info('数据库服务初始化成功');
      } catch (e, stack) {
        loggingService.error('数据库服务初始化失败', e, stack);
      }

      // 初始化API客户端
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:3002',
        client: http.Client(),
        cacheManager: CacheManager(),
      );

      // 初始化事件总线
      final eventBus = EventBus();

      // 初始化存储库
      final holidayRepository = HolidayRepository(
        apiClient: apiClient,
        databaseService: databaseService,
        eventBus: eventBus,
      );

      final reminderRepository = ReminderRepository(
        apiClient: apiClient,
        databaseService: databaseService,
      );

      // 初始化提供者
      final appSettingsProvider = AppSettingsProvider();
      await appSettingsProvider.initialize();

      final themeProvider = ThemeProvider();
      // 加载主题设置

      final localeProvider = LocaleProvider();
      // 加载语言设置

      final authProvider = AuthProvider(authService: authService);

      final notificationProvider = NotificationProvider(
        notificationService: notificationService,
      );

      // 运行应用
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettingsProvider),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: localeProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: notificationProvider),
            Provider<LoggingService>.value(value: loggingService),
            Provider<HolidayRepository>.value(value: holidayRepository),
            Provider<ReminderRepository>.value(value: reminderRepository),
          ],
          child: const JinlinApp(),
        ),
      );

    } catch (e, stack) {
      debugPrint('应用启动失败: $e');
      debugPrint('堆栈: $stack');

      // 显示错误界面
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '应用启动失败',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '错误: $e',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 重新启动应用
                      main();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    // 处理未捕获的异常
    debugPrint('未捕获的异常: $error');
    debugPrint('堆栈: $stack');
  });
}
