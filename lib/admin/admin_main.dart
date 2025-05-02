import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/admin/screens/login_screen.dart';
import 'package:jinlin_app/admin/screens/holiday_list_screen.dart';
import 'package:jinlin_app/admin/providers/admin_auth_provider.dart';

/// 管理后台入口
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

/// 管理后台应用
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        Provider<DatabaseManagerUnified>(
          create: (_) => DatabaseManagerUnified(),
          dispose: (_, db) => db.close(),
        ),
      ],
      child: MaterialApp(
        title: '鲸灵提醒管理后台',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const AdminHomePage(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/holidays': (context) => const HolidayListScreen(),
        },
      ),
    );
  }
}

/// 管理后台首页
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);

    // 检查是否已登录
    if (!authProvider.isLoggedIn) {
      // 未登录，跳转到登录页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 已登录，显示管理后台首页
    return Scaffold(
      appBar: AppBar(
        title: const Text('鲸灵提醒管理后台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '欢迎使用鲸灵提醒管理后台',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('节日管理'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/holidays');
              },
            ),
          ],
        ),
      ),
    );
  }
}
