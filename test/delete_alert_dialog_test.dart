import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/widgets/alert/delete_alert_dialog.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: child),
    );
  }

  Future<bool?> showDialogFor(WidgetTester tester, String title, String content) async {
    bool? result;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => DeleteAlertDialog(title: title, content: content),
          );
        },
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('title / content / 취소 / 삭제 버튼 렌더링', (tester) async {
    await showDialogFor(tester, '정말 삭제?', '되돌릴 수 없습니다');

    expect(find.text('정말 삭제?'), findsOneWidget);
    expect(find.text('되돌릴 수 없습니다'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });

  testWidgets('취소 버튼 → false로 pop', (tester) async {
    bool? result;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => const DeleteAlertDialog(title: 't', content: 'c'),
          );
        },
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('삭제 버튼 → true로 pop', (tester) async {
    bool? result;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => const DeleteAlertDialog(title: 't', content: 'c'),
          );
        },
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
