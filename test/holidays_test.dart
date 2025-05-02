import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:jinlin_app/services/holiday_storage_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 创建一个测试用的 Widget，用于提供 BuildContext
class TestApp extends StatelessWidget {
  final Locale locale;
  final Widget child;

  const TestApp({
    super.key,
    required this.locale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

// 测试用的 Widget，用于获取 BuildContext
class TestWidget extends StatelessWidget {
  final Function(BuildContext) onBuild;

  const TestWidget({super.key, required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const Placeholder();
  }
}

void main() {
  group('节日系统测试', () {
    testWidgets('中文环境下获取中国节日', (WidgetTester tester) async {
      BuildContext? testContext;

      await tester.pumpWidget(
        TestApp(
          locale: const Locale('zh'),
          child: TestWidget(
            onBuild: (context) {
              testContext = context;
            },
          ),
        ),
      );

      // 等待本地化加载完成
      await tester.pumpAndSettle();

      // 确保 testContext 不为 null
      expect(testContext, isNotNull);

      // 获取中国节日
      final holidays = HolidayStorageService.getHolidaysForRegion(testContext!, 'CN');

      // 验证节日列表不为空
      expect(holidays, isNotEmpty);

      // 验证包含春节
      final springFestival = holidays.where((h) => h.id == 'CN_SpringFestival').toList();
      expect(springFestival.isNotEmpty, true, reason: '应该包含春节');

      if (springFestival.isNotEmpty) {
        final holiday = springFestival.first;
        expect(holiday.id, 'CN_SpringFestival');
        expect(holiday.name, '春节');
        expect(holiday.calculationType, DateCalculationType.fixedLunar);
      }
    });

    testWidgets('英文环境下获取国际节日', (WidgetTester tester) async {
      BuildContext? testContext;

      await tester.pumpWidget(
        TestApp(
          locale: const Locale('en'),
          child: TestWidget(
            onBuild: (context) {
              testContext = context;
            },
          ),
        ),
      );

      // 等待本地化加载完成
      await tester.pumpAndSettle();

      // 确保 testContext 不为 null
      expect(testContext, isNotNull);

      // 获取国际节日
      final holidays = HolidayStorageService.getHolidaysForRegion(testContext!, 'INTL');

      // 验证节日列表不为空
      expect(holidays, isNotEmpty);

      // 验证包含圣诞节
      final christmas = holidays.where((h) => h.id == 'WEST_Christmas').toList();
      expect(christmas.isNotEmpty, true, reason: '应该包含圣诞节');

      if (christmas.isNotEmpty) {
        final holiday = christmas.first;
        expect(holiday.id, 'WEST_Christmas');
        expect(holiday.name, 'Christmas');
        expect(holiday.calculationType, DateCalculationType.fixedGregorian);
        expect(holiday.calculationRule, '12-25');
      }
    });

    testWidgets('中文环境下不应包含复活节', (WidgetTester tester) async {
      BuildContext? testContext;

      await tester.pumpWidget(
        TestApp(
          locale: const Locale('zh'),
          child: TestWidget(
            onBuild: (context) {
              testContext = context;
            },
          ),
        ),
      );

      // 等待本地化加载完成
      await tester.pumpAndSettle();

      // 确保 testContext 不为 null
      expect(testContext, isNotNull);

      // 获取中国节日
      final holidays = HolidayStorageService.getHolidaysForRegion(testContext!, 'CN');

      // 验证不包含复活节
      final easter = holidays.where((h) => h.id == 'WEST_Easter').toList();
      expect(easter, isEmpty);
    });

    testWidgets('英文环境下不应包含春节', (WidgetTester tester) async {
      BuildContext? testContext;

      await tester.pumpWidget(
        TestApp(
          locale: const Locale('en'),
          child: TestWidget(
            onBuild: (context) {
              testContext = context;
            },
          ),
        ),
      );

      // 等待本地化加载完成
      await tester.pumpAndSettle();

      // 确保 testContext 不为 null
      expect(testContext, isNotNull);

      // 获取国际节日
      final holidays = HolidayStorageService.getHolidaysForRegion(testContext!, 'INTL');

      // 验证不包含春节
      final springFestival = holidays.where((h) => h.id == 'CN_SpringFestival').toList();
      expect(springFestival, isEmpty);
    });
  });
}
