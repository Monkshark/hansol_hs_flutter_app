# 공개 기능 (급식 / 시간표 / 일정 / 위젯 / 공지)

> English: [public-features_en.md](./public-features_en.md)

로그인 여부와 크게 무관하게 모든 사용자가 접하는 핵심 정보 기능들을 다룹니다. 로그인이 필요한 항목이 섞여 있어도, 학교의 공개 정보 성격이 강한 기능을 이 문서에 묶었습니다.

## 급식 조회

- **NEIS API** 기반 조식/중식/석식 메뉴 실시간 조회
- **월간 프리페치** 캐시 (24시간 / 빈 결과 5분), Completer 패턴으로 동시 요청 방지 ([기술과제 #2](../guides/technical-challenges.md#2-급식-api-동시-요청-경합-race-condition))
- 급식 카드 탭 → 이미지 공유, **영양 성분** (탄수화물/단백질/지방 등) + 알레르기 유발 식품 표시
- 급식 알림에 메뉴 미리보기 포함 (로컬 알림 — 조식/중식/석식 개별 시간)

**관련 파일**: `lib/screens/main/meal_screen.dart`, `lib/api/meal_data_api.dart`, `test/meal_api_test.dart`, `test/meal_test.dart`

### 캐시 전략

| 상황 | TTL |
|---|---|
| 정상 응답 | 24시간 |
| 빈 응답(주말/방학) | 5분 (과도한 재요청 방지) |
| 오류 | 즉시 만료, 다음 접근 시 재시도 |

## 시간표

- **1학년**: 반별 자동 조회 / **2-3학년**: 선택과목 기반 맞춤 시간표
- **교사 전용 시간표**: 학년 탭(1/2/3학년) → 과목 스와이프 → 중복 반 선택
- **충돌 자동 감지** + 해결 팝업, 과목별 컬러 커스터마이징 (원형 피커) ([기술과제 #4](../guides/technical-challenges.md#4-선택과목-시간표-충돌-slot-conflict))
- **현재 교시** 실시간 표시 (1분 갱신, 프로그레스 바), 오늘 요일 하이라이트
- 선택과목 저장 확인 + 미저장 뒤로가기 경고
- 새 학기(3월) 시간표 + 선택과목 자동 리셋

**관련 파일**: `lib/screens/sub/timetable_view_screen.dart`, `lib/screens/sub/timetable_select_screen.dart`, `lib/screens/sub/teacher_timetable_select_screen.dart`, `test/timetable_api_test.dart`

## 학사일정 & 개인일정

- **커스텀 월간 캘린더** (스와이프 월 이동, 유동적 주 수, 한국어)
- **연속 학사일정 바** (끊김 없이 이어지는 컬러 바 + 일정명 표시)
- **개인일정** 하루/연속, **6색 + 원형 컬러피커** (밝기 조절)
- **NEIS 학사일정** 자동 표시, 개인일정 색상 점
- **D-day** 관리 + 홈 화면 핀 고정

**저장소**: 개인 일정은 `sqflite`(로컬). 학사일정은 NEIS API 캐시.

**관련 파일**: `lib/screens/main/home_screen.dart` (캘린더 위젯), `lib/screens/sub/dday_screen.dart`, `test/schedule_data_test.dart`, `test/dday_manager_test.dart`

## 홈 화면 위젯 (Android)

- **급식 위젯 (4×2)**: 오늘의 조식/중식/석식
- **시간표 위젯 (3×2)**: 오늘의 시간표, 현재 교시 강조
- **급식+시간표 통합 위젯 (5×2)**: 급식과 시간표를 한 화면에
- 시스템 다크/라이트 모드 자동 대응
- **자정 자동 갱신** (AlarmManager + Dart 백그라운드 콜백)
- 앱 실행 시 자동 갱신, **Firestore 읽기 0** (캐시 데이터 활용)

**관련 파일**: `android/app/src/main/java/.../widget/`, `lib/` 의 `home_widget` 브릿지 — 자세한 네이티브 동기화는 [기술과제 #참고](../guides/technical-challenges.md) 참조.

## 홈 화면 위젯 (iOS)

- **급식 위젯 (Medium)**: 오늘의 조식/중식/석식
- **시간표 위젯 (Medium)**: 오늘의 시간표, 현재 교시 강조
- **급식+시간표 통합 위젯 (Large)**: 급식과 시간표를 한 화면에
- **SwiftUI + WidgetKit** 네이티브 구현
- App Groups를 통한 Flutter ↔ 위젯 데이터 공유
- 시스템 다크/라이트 모드 자동 대응
- 1시간 주기 Timeline 갱신

**관련 파일**: `ios/Widget*/`, App Groups 설정은 [DEPLOY.md](../../DEPLOY.md) 참조.

## 긴급 팝업 공지

- 앱 실행 시 **모달 팝업**으로 중요 공지 표시
- **3종 타입**: 긴급(빨강), 공지(파랑), 이벤트(초록)
- **시작/종료일** 설정 → 기간 외 자동 비활성화
- **"오늘 안 보기"** 지원 (관리자 설정으로 비활성화 가능)
- 앱 Admin 화면 + Admin Web에서 작성/관리

**저장 위치**: `app_config/announcement` (Firestore). 자세한 관리는 [admin-features.md](./admin-features.md).

## 앱 업데이트 & 오프라인

- **업데이트 체커**: Firestore `app_config/version`에서 최신/최소 버전 비교
  - **필수 업데이트**: 닫기 불가 다이얼로그 + 스토어 이동
  - **선택 업데이트**: "나중에" 버튼 포함 안내 다이얼로그
  - 버전 비교 로직 (`major.minor.patch`)
- **오프라인 배너**: 네트워크 끊기면 상단에 빨간 "오프라인 상태입니다" 표시, 재연결 시 자동 소멸
- **오프라인 캐시**: 급식/시간표는 로컬 캐시로 오프라인에서도 조회 가능

**관련 파일**: `lib/main.dart` (초기화 체크), `lib/data/setting_data.dart`, 연결성은 `connectivity_plus` 패키지.

## 공지 목록

- **학교 공지** 섹션 (`lib/screens/main/notice_screen.dart`)
- 관리자가 작성하는 공식 공지 (게시판과 분리)
- 첨부 파일 / 중요 표시 지원

## 관련 문서
- [엔드유저 가이드](../../USER_GUIDE.md) — 실제 사용 방법
- [커뮤니티 기능](./community-features.md) — 게시판/채팅 등 로그인 필요 기능
- [개인 기능](./personal-features.md) — 성적/개인일정 등 개인화 기능
- [데이터 모델](../guides/data-model.md) — `app_config`, `users` 스키마
