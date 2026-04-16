# API Reference - 목차

> 화면(Screen)·위젯(Widget) 문서는 제외. 서비스·모델·API·알림 등 핵심 계층만 정리
>
> 주제별 가이드(아키텍처, 데이터 모델, 테스트, 보안 등)는 [`guides/`](./guides/), 기능별 상세는 [`features/`](./features/) 참조

## 앱 진입점
- [main](main.md) — 앱 초기화, MainScreen, 전역 상태

## API 계층 (lib/api/)
- [meal_data_api](api/meal_data_api.md) — NEIS 급식 API, 월간 프리페치, 24h/5min 캐시
- [notice_data_api](api/notice_data_api.md) — NEIS 학사일정 API, 예정 이벤트, 12h 캐시
- [timetable_data_api](api/timetable_data_api.md) — NEIS 시간표 API, 과목 조합, 12h 캐시

## 데이터 계층 (lib/data/)
- [auth_service](data/auth_service.md) — 소셜 로그인 4종, 프로필 CRUD, 5분 캐시
- [auth_repository](data/auth_repository.md) — AuthRepository 인터페이스, GetIt DI
- [grade_manager](data/grade_manager.md) — 성적 CRUD, 목표 관리, 등급 변환
- [grade_repository](data/grade_repository.md) — GradeRepository 인터페이스, GetIt DI
- [dday_manager](data/dday_manager.md) — D-day CRUD, Firestore 동기화
- [local_database](data/local_database.md) — SQLite 일정 DB, Firestore 동기화
- [subject_data_manager](data/subject_data_manager.md) — 선택과목 로드/저장
- [search_tokens](data/search_tokens.md) — 한국어 2-gram 토큰화
- [search_history_service](data/search_history_service.md) — 검색 기록 (최대 10개)
- [secure_storage_service](data/secure_storage_service.md) — 암호화 저장소 래퍼
- [analytics_service](data/analytics_service.md) — Firebase Analytics 이벤트 래퍼
- [setting_data](data/setting_data.md) — SharedPreferences 설정 싱글톤
- [service_locator](data/service_locator.md) — GetIt DI 설정
- [meal](data/meal.md) — Meal 데이터 모델 (freezed)
- [schedule_data](data/schedule_data.md) — Schedule 데이터 모델
- [subject](data/subject.md) — Subject 데이터 모델 (freezed)
- [device](data/device.md) — 디바이스 크기 계산 유틸리티
- [api_strings](data/api_strings.md) — API 센티널 문자열 상수 (데이터 유무 판별용)
- [board_categories](data/board_categories.md) — 게시판 카테고리 ��수 + l10n/색상/FCM 토픽 헬퍼
- [post_repository](data/post_repository.md) — 게시판 Firestore CRUD 싱글턴

## 알림 (lib/notification/)
- [fcm_service](notification/fcm_service.md) — FCM 푸시 알림, 토픽, 딥링크
- [daily_meal_notification](notification/daily_meal_notification.md) — 로컬 급식 알림 스케줄링
- [popup_notice](notification/popup_notice.md) — 인앱 팝업 공지
- [update_checker](notification/update_checker.md) — 앱 버전 체크

## 상태 관리 (lib/providers/)
- [providers](providers/providers.md) — Riverpod Notifier/AsyncNotifier 전체

## 스타일 (lib/styles/)
- [app_colors](styles/app_colors.md) — 테마 컬러 + AnimatedAppColors
- [dark_app_colors](styles/dark_app_colors.md) — 다크 테마 색상 구현체
- [light_app_colors](styles/light_app_colors.md) — 라이트 테마 색상 구현체

## 네트워크 (lib/network/)
- [network_status](network/network_status.md) — 네트워크 연결 상태 스트림
- [offline_queue_manager](network/offline_queue_manager.md) — 오프라인 쓰기 큐 (sqflite)
