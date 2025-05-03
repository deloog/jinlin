import 'package:flutter/material.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/screens/home/home_screen.dart';
import 'package:jinlin_app/screens/settings/settings_screen.dart';
import 'package:jinlin_app/screens/holiday_detail/holiday_detail_screen.dart';
import 'package:jinlin_app/screens/reminder/reminder_detail_screen.dart';
import 'package:jinlin_app/screens/about/about_screen.dart';
import 'package:jinlin_app/screens/debug/debug_screen.dart';
import 'package:jinlin_app/screens/auth/login_screen.dart';
import 'package:jinlin_app/screens/auth/register_screen.dart';
import 'package:jinlin_app/screens/auth/forgot_password_screen.dart';
import 'package:jinlin_app/screens/profile/profile_screen.dart';
import 'package:jinlin_app/screens/settings/language_screen.dart';
import 'package:jinlin_app/screens/settings/notification_screen.dart';
import 'package:jinlin_app/screens/settings/sync_settings_screen.dart';
import 'package:jinlin_app/screens/settings/theme_screen.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 应用路由管理器
class AppRouter {
  static final LoggingService _logger = LoggingService();

  // 路由名称常量
  static const String home = '/';
  static const String settings = '/settings';
  static const String holidayDetail = '/holiday-detail';
  static const String reminderDetail = '/reminder-detail';
  static const String about = '/about';
  static const String debug = '/debug';

  // 认证相关路由
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String changeEmail = '/change-email';

  // 设置相关路由
  static const String language = '/language';
  static const String theme = '/theme';
  static const String notification = '/notification';
  static const String syncSettings = '/sync-settings';

  /// 路由生成器
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    _logger.debug('导航到: ${routeSettings.name}');

    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const HomeScreen(),
        );

      case AppRouter.settings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SettingsScreen(),
        );

      case holidayDetail:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final holiday = args?['holiday'] as Holiday?;
        final occurrenceDate = args?['occurrenceDate'] as DateTime?;

        if (holiday == null) {
          _logger.error('导航到节日详情页失败: 缺少节日参数');
          return _errorRoute('缺少必要参数');
        }

        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => HolidayDetailScreen(
            holiday: holiday,
            occurrenceDate: occurrenceDate,
          ),
        );

      case reminderDetail:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final reminder = args?['reminder'] as Reminder?;
        final isEditing = args?['isEditing'] as bool? ?? false;

        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ReminderDetailScreen(
            reminder: reminder,
            isEditing: isEditing,
          ),
        );

      case about:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const AboutScreen(),
        );

      case debug:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const DebugScreen(),
        );

      case login:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const RegisterScreen(),
        );

      case forgotPassword:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case profile:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ProfileScreen(),
        );

      case changePassword:
        // TODO: 实现修改密码屏幕
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('修改密码')),
            body: const Center(child: Text('修改密码屏幕尚未实现')),
          ),
        );

      case changeEmail:
        // TODO: 实现修改电子邮件屏幕
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('修改电子邮件')),
            body: const Center(child: Text('修改电子邮件屏幕尚未实现')),
          ),
        );

      case language:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LanguageScreen(),
        );

      case theme:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ThemeScreen(),
        );

      case notification:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const NotificationScreen(),
        );

      case syncSettings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SyncSettingsScreen(),
        );

      default:
        _logger.warning('未知路由: ${routeSettings.name}');
        return _errorRoute('页面不存在');
    }
  }

  /// 创建错误路由
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('错误'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => navigatorKey.currentState?.pushReplacementNamed(home),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 全局导航器键
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 导航到首页
  static void navigateToHome([BuildContext? context, bool clearStack = false]) {
    if (context != null) {
      if (clearStack) {
        Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
      } else {
        Navigator.of(context).pushNamed(home);
      }
    } else {
      if (clearStack) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(home, (route) => false);
      } else {
        navigatorKey.currentState?.pushNamed(home);
      }
    }
  }

  /// 导航到设置页
  static void navigateToSettings([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(AppRouter.settings);
    } else {
      navigatorKey.currentState?.pushNamed(AppRouter.settings);
    }
  }

  /// 导航到节日详情页
  static void navigateToHolidayDetail(Holiday holiday, {DateTime? occurrenceDate, BuildContext? context}) {
    final args = {
      'holiday': holiday,
      'occurrenceDate': occurrenceDate,
    };

    if (context != null) {
      Navigator.of(context).pushNamed(holidayDetail, arguments: args);
    } else {
      navigatorKey.currentState?.pushNamed(holidayDetail, arguments: args);
    }
  }

  /// 导航到提醒详情页
  static void navigateToReminderDetail({Reminder? reminder, bool isEditing = false, BuildContext? context}) {
    final args = {
      'reminder': reminder,
      'isEditing': isEditing,
    };

    if (context != null) {
      Navigator.of(context).pushNamed(reminderDetail, arguments: args);
    } else {
      navigatorKey.currentState?.pushNamed(reminderDetail, arguments: args);
    }
  }

  /// 导航到关于页
  static void navigateToAbout([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(about);
    } else {
      navigatorKey.currentState?.pushNamed(about);
    }
  }

  /// 导航到调试页
  static void navigateToDebug([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(debug);
    } else {
      navigatorKey.currentState?.pushNamed(debug);
    }
  }

  /// 导航到登录页
  static void navigateToLogin([BuildContext? context, bool clearStack = false]) {
    if (context != null) {
      if (clearStack) {
        Navigator.of(context).pushNamedAndRemoveUntil(login, (route) => false);
      } else {
        Navigator.of(context).pushNamed(login);
      }
    } else {
      if (clearStack) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(login, (route) => false);
      } else {
        navigatorKey.currentState?.pushNamed(login);
      }
    }
  }

  /// 导航到注册页
  static void navigateToRegister([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(register);
    } else {
      navigatorKey.currentState?.pushNamed(register);
    }
  }

  /// 导航到忘记密码页
  static void navigateToForgotPassword([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(forgotPassword);
    } else {
      navigatorKey.currentState?.pushNamed(forgotPassword);
    }
  }

  /// 导航到个人资料页
  static void navigateToProfile([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(profile);
    } else {
      navigatorKey.currentState?.pushNamed(profile);
    }
  }

  /// 导航到修改密码页
  static void navigateToChangePassword([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(changePassword);
    } else {
      navigatorKey.currentState?.pushNamed(changePassword);
    }
  }

  /// 导航到修改电子邮件页
  static void navigateToChangeEmail([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(changeEmail);
    } else {
      navigatorKey.currentState?.pushNamed(changeEmail);
    }
  }

  /// 导航到语言设置页
  static void navigateToLanguage([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(language);
    } else {
      navigatorKey.currentState?.pushNamed(language);
    }
  }

  /// 导航到主题设置页
  static void navigateToTheme([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(theme);
    } else {
      navigatorKey.currentState?.pushNamed(theme);
    }
  }

  /// 导航到通知设置页
  static void navigateToNotification([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(notification);
    } else {
      navigatorKey.currentState?.pushNamed(notification);
    }
  }

  /// 导航到同步设置页
  static void navigateToSyncSettings([BuildContext? context]) {
    if (context != null) {
      Navigator.of(context).pushNamed(syncSettings);
    } else {
      navigatorKey.currentState?.pushNamed(syncSettings);
    }
  }
}
