import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/providers/theme_provider.dart';
import 'package:hansol_high_school/providers/settings_provider.dart';

/// 하단 네비게이션 + 페이지 전환 통합 테스트
///
/// Firebase 의존 없이 네비게이션 바 동작만 검증합니다.
/// 실행: `flutter test integration_test/navigation_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'themeModeIndex': 0});
    await SettingData().init();
  });

  group('Bottom navigation', () {
    testWidgets('swipe between pages updates selected index', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _NavHarness()),
      );
      await tester.pumpAndSettle();

      // 초기: 가운데 (홈) 선택
      expect(find.text('Page 1'), findsOneWidget);

      // 왼쪽으로 스와이프 → 오른쪽 페이지
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 500);
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      // 오른쪽으로 두 번 스와이프 → 왼쪽 페이지
      await tester.fling(find.byType(PageView), const Offset(300, 0), 500);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(300, 0), 500);
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('tapping nav destination switches page', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _NavHarness()),
      );
      await tester.pumpAndSettle();

      // 세 번째 탭 클릭
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      // 첫 번째 탭 클릭
      await tester.tap(find.byIcon(Icons.restaurant_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);
    });
  });

  group('Locale toggle', () {
    testWidgets('switches between ko and en', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _LocaleHarness()),
      );
      await tester.pumpAndSettle();

      // 기본: 한국어
      expect(find.text('ko'), findsOneWidget);

      // 영어로 전환
      await tester.tap(find.byKey(const Key('toggle-locale')));
      await tester.pumpAndSettle();
      expect(find.text('en'), findsOneWidget);
    });
  });
}

class _NavHarness extends StatefulWidget {
  const _NavHarness();

  @override
  State<_NavHarness> createState() => _NavHarnessState();
}

class _NavHarnessState extends State<_NavHarness> {
  int _index = 1;
  final _controller = PageController(initialPage: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          children: List.generate(3, (i) => Center(child: Text('Page $i'))),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            _controller.animateToPage(i,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), label: ''),
            NavigationDestination(icon: Icon(Icons.home_outlined), label: ''),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: ''),
          ],
        ),
      ),
    );
  }
}

class _LocaleHarness extends ConsumerWidget {
  const _LocaleHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(locale.languageCode),
              ElevatedButton(
                key: const Key('toggle-locale'),
                onPressed: () {
                  final next = locale.languageCode == 'ko'
                      ? const Locale('en')
                      : const Locale('ko');
                  ref.read(localeProvider.notifier).setLocale(next);
                },
                child: const Text('Toggle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
