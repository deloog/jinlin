import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/services/database_manager_unified.dart';
import 'package:jinlin_app/admin/admin_dashboard.dart';

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
    return Provider<DatabaseManagerUnified>(
      create: (_) => DatabaseManagerUnified(),
      dispose: (_, db) => db.close(),
      child: MaterialApp(
        title: '鲸灵提醒管理后台',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const AdminDashboard(),
      ),
    );
  }
}
