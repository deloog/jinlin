import 'package:flutter/material.dart';
import 'package:jinlin_app/examples/api_usage_example.dart';

/// API测试应用
///
/// 用于测试API交互
void main() {
  runApp(const ApiTestApp());
}

class ApiTestApp extends StatelessWidget {
  const ApiTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API测试应用',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ApiUsageExample(),
    );
  }
}
