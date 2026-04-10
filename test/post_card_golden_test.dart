import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/board_screen.dart';

/// 플랫폼 간 폰트 렌더링 차이(Windows ↔ Linux)를 흡수하기 위한 tolerance comparator.
/// goldens는 Windows 로컬에서 생성되었고 CI는 Ubuntu라 anti-aliasing/font hinting
/// 차이로 0.3% 정도의 픽셀 diff가 발생함. 실제 시각 차이는 사람 눈에 안 보임.
class _ToleranceFileComparator extends LocalFileComparator {
  _ToleranceFileComparator(super.testFile, {this.tolerance = 0.01});
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= tolerance) {
      debugPrint(
        'Golden ${golden.path}: diff ${(result.diffPercent * 100).toStringAsFixed(2)}% '
        '≤ tolerance ${(tolerance * 100).toStringAsFixed(0)}% → 통과',
      );
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

/// PostCard golden 테스트
///
/// Phase 3에서 추가된 게시판 카드 UI(썸네일, +N badge, likeCount,
/// 익명 매니저뷰 등)가 의도한 모양으로 렌더링되는지 PNG 스냅샷으로 검증.
///
/// 최초 실행: `flutter test --update-goldens test/post_card_golden_test.dart`
/// 이후 실행: `flutter test test/post_card_golden_test.dart`
void main() {
  late FakeFirebaseFirestore fake;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // cached_network_image가 사용하는 path_provider mock
    // (테스트 환경에 디렉토리가 없어서 호출 시 MissingPluginException 발생함)
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '.');

    // 플랫폼 폰트 렌더링 차이 흡수 (Windows로 생성된 goldens를 Linux CI에서 비교)
    final prev = goldenFileComparator;
    if (prev is LocalFileComparator) {
      goldenFileComparator =
          _ToleranceFileComparator(Uri.parse('${prev.basedir}test.dart'));
    }
  });

  setUp(() async {
    fake = FakeFirebaseFirestore();
    AuthService.setCachedProfileForTest(null);
  });

  tearDown(() {
    AuthService.setCachedProfileForTest(null);
  });

  /// fake Firestore에 post 1개 넣고 QueryDocumentSnapshot으로 꺼내옴.
  /// (PostCard 생성자가 QueryDocumentSnapshot을 요구하기 때문)
  Future<QueryDocumentSnapshot<Map<String, dynamic>>> seedPost(
      Map<String, dynamic> data) async {
    await fake.collection('posts').doc('p1').set(data);
    final snap = await fake.collection('posts').get();
    return snap.docs.first;
  }

  Future<void> pumpCard(
    WidgetTester tester,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Center(
            child: SizedBox(
              width: 380,
              child: PostCard(doc: doc, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    // 이미지 로드/Shimmer를 기다리지 않고 즉시 frame만 그림 (network image는 어차피 fail)
    await tester.pump();
  }

  testWidgets('기본 카드 (좋아요/이미지 없음)', (tester) async {
    final doc = await seedPost({
      'title': '시험 범위 공지',
      'content': '수학 1~3단원, 영어 Lesson 1~4',
      'category': '정보공유',
      'authorName': '10105 이서준',
      'isAnonymous': false,
      'commentCount': 3,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 10, 0)),
      'likeCount': 0,
      'dislikeCount': 0,
      'imageUrls': <String>[],
    });

    await pumpCard(tester, doc);
    await expectLater(
      find.byType(PostCard),
      matchesGoldenFile('goldens/post_card_basic.png'),
    );
  });

  testWidgets('좋아요/싫어요 카운터 노출', (tester) async {
    final doc = await seedPost({
      'title': '체육대회 종목 투표',
      'content': '축구/피구/농구 중 골라주세요',
      'category': '학생회',
      'authorName': '20101 관리자',
      'isAnonymous': false,
      'commentCount': 12,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 2, 14, 30)),
      'likeCount': 53,
      'dislikeCount': 4,
      'imageUrls': <String>[],
    });

    await pumpCard(tester, doc);
    await expectLater(
      find.byType(PostCard),
      matchesGoldenFile('goldens/post_card_with_likes.png'),
    );
  });

  testWidgets('공지(pinned) 카드', (tester) async {
    final doc = await seedPost({
      'title': '동아리 축제 일정 안내',
      'content': '5월 16~17일 체육관 + 운동장',
      'category': '동아리',
      'authorName': '20302 김매니저',
      'isAnonymous': false,
      'commentCount': 8,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 3, 9, 0)),
      'likeCount': 89,
      'dislikeCount': 0,
      'imageUrls': <String>[],
      'isPinned': true,
    });

    await pumpCard(tester, doc);
    await expectLater(
      find.byType(PostCard),
      matchesGoldenFile('goldens/post_card_pinned.png'),
    );
  });

  testWidgets('이미지 4장 → 썸네일 + +3 badge', (tester) async {
    final doc = await seedPost({
      'title': '코딩 동아리 신규 부원 모집',
      'content': '매주 수요일 방과후, 1~2학년 대상',
      'category': '동아리',
      'authorName': '10210 정하늘',
      'isAnonymous': false,
      'commentCount': 5,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 4, 16, 20)),
      'likeCount': 38,
      'dislikeCount': 0,
      'imageUrls': const [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
        'https://example.com/c.jpg',
        'https://example.com/d.jpg',
      ],
    });

    await pumpCard(tester, doc);
    await expectLater(
      find.byType(PostCard),
      matchesGoldenFile('goldens/post_card_thumbnail_badge.png'),
    );
  });

  testWidgets('익명 글 + 매니저 view → 실명 노출', (tester) async {
    AuthService.setCachedProfileForTest(UserProfile(
      uid: 'manager_uid',
      name: '김매니저',
      studentId: '20302',
      grade: 2,
      classNum: 3,
      email: 'manager@test.com',
      approved: true,
      role: 'manager',
    ));

    final doc = await seedPost({
      'title': '급식 메뉴 건의',
      'content': '떡볶이 더 자주 나오게 해주세요',
      'category': '학생회',
      'authorName': '익명',
      'authorRealName': '20412 한소희',
      'isAnonymous': true,
      'commentCount': 7,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 5, 12, 10)),
      'likeCount': 93,
      'dislikeCount': 5,
      'imageUrls': <String>[],
    });

    await pumpCard(tester, doc);
    await expectLater(
      find.byType(PostCard),
      matchesGoldenFile('goldens/post_card_anonymous_manager_view.png'),
    );
  });
}
