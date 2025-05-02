import 'package:flutter/material.dart';
import 'package:jinlin_app/tools/holiday_data_import_runner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HolidayDataImportApp());
}

class HolidayDataImportApp extends StatelessWidget {
  const HolidayDataImportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '节日数据导入工具',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HolidayDataImportRunner(),
    );
  }
}
