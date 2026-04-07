import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/providers/grade_provider.dart';
import 'package:hansol_high_school/screens/sub/grade_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/secure_storage_mock.dart';

/// GradeScreen 위젯 테스트
///
/// `ProviderScope.overrides`로 mock 데이터 주입.
/// `examsProvider`/`goalsProvider`를 override하여 비동기 의존성 제거.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStore = setupSecureStorageMock();

  setUpAll(() {
    AnimatedAppColors.instance.setDark(false, animate: false);
    AnimatedAppColors.instance.tick(0);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStore.clear();
  });

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('빈 상태에서 "시험을 추가하세요" 표시', (tester) async {
    await tester.pumpWidget(wrap(const GradeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('성적 관리'), findsOneWidget);
    expect(find.text('성적 점수는 서버에 저장되지 않습니다'), findsOneWidget);
    expect(find.text('시험을 추가하세요'), findsOneWidget);
    expect(find.text('수시'), findsOneWidget);
    expect(find.text('정시'), findsOneWidget);
  });

  testWidgets('탭 전환 시 인덱스 변경', (tester) async {
    await tester.pumpWidget(wrap(const GradeScreen()));
    await tester.pumpAndSettle();

    // 정시 탭 클릭
    await tester.tap(find.text('정시'));
    await tester.pumpAndSettle();

    // 빈 상태이므로 여전히 "시험을 추가하세요"가 보임
    expect(find.text('시험을 추가하세요'), findsWidgets);
  });

  testWidgets('FAB 표시 + 목표 설정 액션 버튼 표시', (tester) async {
    await tester.pumpWidget(wrap(const GradeScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('examsProvider override로 mock 데이터 주입 (수시)', (tester) async {
    await tester.pumpWidget(wrap(
      const GradeScreen(),
      overrides: [
        examsProvider.overrideWith(() => _MockExamsNotifier([
              Exam(
                id: 't1',
                type: 'midterm',
                year: 2026,
                semester: 1,
                grade: 2,
                scores: [
                  SubjectScore(subject: '국어', rawScore: 88, rank: 2, achievement: 'B'),
                  SubjectScore(subject: '수학', rawScore: 95, rank: 1, achievement: 'A'),
                ],
              ),
            ])),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('2026 1학기 중간고사'), findsOneWidget);
    expect(find.text('2과목'), findsOneWidget);
  });

  testWidgets('정시 탭에서 mock 데이터 표시', (tester) async {
    await tester.pumpWidget(wrap(
      const GradeScreen(),
      overrides: [
        examsProvider.overrideWith(() => _MockExamsNotifier([
              Exam(
                id: 'm1',
                type: 'mock',
                year: 2026,
                semester: 1,
                grade: 3,
                mockLabel: '6월',
                scores: [
                  SubjectScore(subject: '국어', percentile: 92, rank: 2),
                ],
              ),
            ])),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('정시'));
    await tester.pumpAndSettle();

    expect(find.text('2026 6월 모의고사'), findsOneWidget);
  });

  testWidgets('로딩 상태 → CircularProgressIndicator 표시', (tester) async {
    final loader = _LoadingExamsNotifier();
    await tester.pumpWidget(wrap(
      const GradeScreen(),
      overrides: [
        examsProvider.overrideWith(() => loader),
      ],
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 타이머 누수 방지: 테스트 종료 전 Completer 완료
    loader._completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('에러 상태 → 에러 메시지 표시', (tester) async {
    await tester.pumpWidget(wrap(
      const GradeScreen(),
      overrides: [
        examsProvider.overrideWith(() => _ErrorExamsNotifier()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('불러오기 실패'), findsOneWidget);
  });
}

class _MockExamsNotifier extends ExamsNotifier {
  _MockExamsNotifier(this._mockExams);
  final List<Exam> _mockExams;

  @override
  Future<List<Exam>> build() async => _mockExams;
}

class _LoadingExamsNotifier extends ExamsNotifier {
  final Completer<List<Exam>> _completer = Completer<List<Exam>>();

  @override
  Future<List<Exam>> build() => _completer.future;
}

class _ErrorExamsNotifier extends ExamsNotifier {
  @override
  Future<List<Exam>> build() async {
    throw Exception('테스트 에러');
  }
}
