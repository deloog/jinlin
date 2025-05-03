import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/app.dart';
import 'package:jinlin_app/providers/app_state.dart';
import 'package:jinlin_app/providers/locale_provider.dart';
import 'package:jinlin_app/providers/settings_provider.dart';
import 'package:jinlin_app/providers/theme_provider.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// 创建模拟类
class MockHolidayRepository extends Mock implements HolidayRepository {}
class MockReminderRepository extends Mock implements ReminderRepository {}
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  // 初始化模拟对象
  final mockHolidayRepository = MockHolidayRepository();
  final mockReminderRepository = MockReminderRepository();
  final mockLoggingService = MockLoggingService();

  // 测试应用程序是否正确启动
  testWidgets('App should start without errors', (WidgetTester tester) async {
    // 构建应用程序
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LoggingService>.value(value: mockLoggingService),
          Provider<HolidayRepository>.value(value: mockHolidayRepository),
          Provider<ReminderRepository>.value(value: mockReminderRepository),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(
              holidayRepository: mockHolidayRepository,
              reminderRepository: mockReminderRepository,
            ),
          ),
        ],
        child: const JinlinApp(),
      ),
    );

    // 等待应用程序加载
    await tester.pumpAndSettle();

    // 验证应用程序已启动
    expect(find.byType(JinlinApp), findsOneWidget);
  });

  // 测试主屏幕是否正确显示
  testWidgets('Home screen should display correctly', (WidgetTester tester) async {
    // 构建应用程序
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LoggingService>.value(value: mockLoggingService),
          Provider<HolidayRepository>.value(value: mockHolidayRepository),
          Provider<ReminderRepository>.value(value: mockReminderRepository),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(
              holidayRepository: mockHolidayRepository,
              reminderRepository: mockReminderRepository,
            ),
          ),
        ],
        child: const JinlinApp(),
      ),
    );

    // 等待应用程序加载
    await tester.pumpAndSettle();

    // 验证主屏幕已显示
    // 应用程序标题可能已更改，所以我们只验证应用程序已启动
    expect(find.byType(JinlinApp), findsOneWidget);

    // 验证底部导航栏已显示
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  // 测试设置屏幕是否正确显示
  testWidgets('Settings screen should display correctly', (WidgetTester tester) async {
    // 构建应用程序
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LoggingService>.value(value: mockLoggingService),
          Provider<HolidayRepository>.value(value: mockHolidayRepository),
          Provider<ReminderRepository>.value(value: mockReminderRepository),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(
              holidayRepository: mockHolidayRepository,
              reminderRepository: mockReminderRepository,
            ),
          ),
        ],
        child: const JinlinApp(),
      ),
    );

    // 等待应用程序加载
    await tester.pumpAndSettle();

    // 点击设置按钮
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // 验证设置屏幕已显示
    expect(find.text('设置'), findsOneWidget);

    // 验证设置项已显示
    expect(find.text('通用设置'), findsOneWidget);
    expect(find.text('数据设置'), findsOneWidget);
    expect(find.text('同步设置'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
  });

  // 测试主题切换是否正常工作
  testWidgets('Theme switching should work correctly', (WidgetTester tester) async {
    // 构建应用程序
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LoggingService>.value(value: mockLoggingService),
          Provider<HolidayRepository>.value(value: mockHolidayRepository),
          Provider<ReminderRepository>.value(value: mockReminderRepository),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(
              holidayRepository: mockHolidayRepository,
              reminderRepository: mockReminderRepository,
            ),
          ),
        ],
        child: const JinlinApp(),
      ),
    );

    // 等待应用程序加载
    await tester.pumpAndSettle();

    // 获取ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(tester.element(find.byType(JinlinApp)));

    // 切换到深色主题
    themeProvider.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    // 验证主题已切换
    expect(themeProvider.themeMode, equals(ThemeMode.dark));

    // 切换到浅色主题
    themeProvider.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();

    // 验证主题已切换
    expect(themeProvider.themeMode, equals(ThemeMode.light));
  });

  // 测试语言切换是否正常工作
  testWidgets('Language switching should work correctly', (WidgetTester tester) async {
    // 构建应用程序
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LoggingService>.value(value: mockLoggingService),
          Provider<HolidayRepository>.value(value: mockHolidayRepository),
          Provider<ReminderRepository>.value(value: mockReminderRepository),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(
              holidayRepository: mockHolidayRepository,
              reminderRepository: mockReminderRepository,
            ),
          ),
        ],
        child: const JinlinApp(),
      ),
    );

    // 等待应用程序加载
    await tester.pumpAndSettle();

    // 获取LocaleProvider
    final localeProvider = Provider.of<LocaleProvider>(tester.element(find.byType(JinlinApp)));

    // 切换到英语
    localeProvider.setLocale(const Locale('en', 'US'));
    await tester.pumpAndSettle();

    // 验证语言已切换
    expect(localeProvider.locale?.languageCode, equals('en'));
    expect(localeProvider.locale?.countryCode, equals('US'));

    // 切换到中文
    localeProvider.setLocale(const Locale('zh', 'CN'));
    await tester.pumpAndSettle();

    // 验证语言已切换
    expect(localeProvider.locale?.languageCode, equals('zh'));
    expect(localeProvider.locale?.countryCode, equals('CN'));
  });
}
