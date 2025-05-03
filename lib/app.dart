import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jinlin_app/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/models/language/language.dart';
import 'package:jinlin_app/providers/locale_provider.dart';
import 'package:jinlin_app/providers/theme_provider.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/theme/app_theme.dart';
import 'package:jinlin_app/utils/app_lifecycle_observer.dart';

/// 应用程序主类
class JinlinApp extends StatefulWidget {
  const JinlinApp({super.key});

  @override
  State<JinlinApp> createState() => _JinlinAppState();
}

class _JinlinAppState extends State<JinlinApp> {
  final LoggingService _logger = LoggingService();
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _logger.info('应用启动');

    // 初始化生命周期观察者
    _lifecycleObserver = AppLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _logger.info('应用关闭');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'CetaMind Reminder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.values[themeProvider.themeMode.index],
      locale: localeProvider.locale,
      supportedLocales: Language.supportedLanguages.map((lang) => lang.toLocale()).toList(),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
      navigatorKey: AppRouter.navigatorKey,
      navigatorObservers: [
        RouteObserver<PageRoute>(),
      ],
      builder: (context, child) {
        // 确保文本缩放不会超出合理范围
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
