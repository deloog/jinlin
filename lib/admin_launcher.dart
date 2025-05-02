import 'package:flutter/material.dart';
import 'package:jinlin_app/admin/admin_main.dart';

/// 管理后台启动器
///
/// 用于从主应用中启动管理后台
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}
