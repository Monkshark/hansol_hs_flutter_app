import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/providers/theme_provider.dart';

/// 앱 부트 통합 테스트
///
/// 실제 main.dart는 Firebase 초기화에 의존하므로,
/// 여기서는 ThemeProvider 기반 MaterialApp을 부팅하여
/// Riverpod + 테마 토글 플로우만 검증합니다.
///
/// 실행: `flutter test integration_test/app_boot_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'themeModeIndex': 0});
    await SettingData().init();
  });

  group('App boot smoke test', () {
    testWidgets('boots with light theme and toggles to dark', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _BootHarness()),
      );
      await tester.pumpAndSettle();

      // 부팅 시 라이트 (또는 시스템) 모드 확인
      expect(find.text('Boot OK'), findsOneWidget);
      expect(find.byIcon(Icons.brightness_5), findsOneWidget);

      // 다크 모드로 토글
      await tester.tap(find.byKey(const Key('toggle-theme')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.brightness_4), findsOneWidget);
    });
  });
}

class _BootHarness extends ConsumerWidget {
  const _BootHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return MaterialApp(
      themeMode: mode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Boot OK'),
              Icon(mode == ThemeMode.dark
                  ? Icons.brightness_4
                  : Icons.brightness_5),
              ElevatedButton(
                key: const Key('toggle-theme'),
                onPressed: () => ref.read(themeProvider.notifier).setMode(1),
                child: const Text('Toggle dark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
