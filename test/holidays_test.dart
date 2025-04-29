import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/data/holidays_cn.dart';
import 'package:jinlin_app/data/holidays_intl.dart' as intl_holidays;
import 'package:jinlin_app/special_date.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 创建一个测试用的 Widget，用于提供 BuildContext
class TestApp extends StatelessWidget {
  final Locale locale;
  final Widget child;

  const TestApp({
    Key? key,
    required this.locale,
    required this.child,
  }) : super(key: key);

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

  const TestWidget({Key? key, required this.onBuild}) : super(key: key);

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
      final holidays = getHolidaysForRegion(testContext!, 'CN');
      
      // 验证节日列表不为空
      expect(holidays, isNotEmpty);
      
      // 验证包含春节
      final springFestival = holidays.firstWhere(
        (h) => h.id == 'CN_SpringFestival',
        orElse: () => SpecialDate(
          id: 'not_found',
          name: 'Not Found',
          type: SpecialDateType.other,
          regions: [],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '',
        ),
      );
      
      expect(springFestival.id, 'CN_SpringFestival');
      expect(springFestival.name, '春节');
      expect(springFestival.calculationType, DateCalculationType.fixedLunar);
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
      final holidays = intl_holidays.getHolidaysForRegion(testContext!, 'INTL');
      
      // 验证节日列表不为空
      expect(holidays, isNotEmpty);
      
      // 验证包含圣诞节
      final christmas = holidays.firstWhere(
        (h) => h.id == 'WEST_Christmas',
        orElse: () => SpecialDate(
          id: 'not_found',
          name: 'Not Found',
          type: SpecialDateType.other,
          regions: [],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '',
        ),
      );
      
      expect(christmas.id, 'WEST_Christmas');
      expect(christmas.name, 'Christmas');
      expect(christmas.calculationType, DateCalculationType.fixedGregorian);
      expect(christmas.calculationRule, '12-25');
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
      final holidays = getHolidaysForRegion(testContext!, 'CN');
      
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
      final holidays = intl_holidays.getHolidaysForRegion(testContext!, 'INTL');
      
      // 验证不包含春节
      final springFestival = holidays.where((h) => h.id == 'CN_SpringFestival').toList();
      expect(springFestival, isEmpty);
    });
  });
}
