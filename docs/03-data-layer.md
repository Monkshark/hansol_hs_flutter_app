# 데이터 레이어 상세 가이드

`lib/data/` 디렉토리는 앱의 비즈니스 로직과 데이터 접근을 담당한다

> 각 클래스의 함수별 상세 설명은 [API Reference](api/README.md)�� 참조한다

---

## 데이터 모델 요약

| 모델 | 파일 | 패턴 | 저장소 | 레퍼런스 |
|------|------|------|--------|----------|
| [UserProfile](data/auth_service.md) | `auth_service.dart` | 수동 toMap/fromMap | Firestore `users/{uid}` |
| [Meal](data/meal.md) | `meal.dart` | freezed + json_serializable | SharedPreferences 캐시 |
| [Subject](data/subject.md) | `subject.dart` | freezed + 커스텀 == | SharedPreferences + Firestore |
| [Schedule](data/schedule_data.md) | `schedule_data.dart` | 수동 toMap/fromMap | SQLite + Firestore 동기화 |
| [Exam / SubjectScore](data/grade_manager.md) | `grade_manager.dart` | 수동 toJson/fromJson | SecureStorage (암호화) |
| [DDay](data/dday_manager.md) | `dday_manager.dart` | 수동 toJson/fromJson | SecureStorage + Firestore 동기화 |

---

## 서비스 클래스 요약

| 서비스 | 역할 | 저장 방식 | 레퍼런스 |
|--------|------|-----------|----------|
| [AuthService](data/auth_service.md) | 소셜 로그인 4종, 프로필 CRUD, 5분 캐시 | Firestore |
| [GradeManager](data/grade_manager.md) | 성적 CRUD, 목표 관리, 등급 변환 | SecureStorage (로컬 전용) |
| [DDayManager](data/dday_manager.md) | D-day CRUD, 핀 D-day 조회 | SecureStorage + Firestore |
| [LocalDataBase](data/local_database.md) | 개인 일정 CRUD (SQLite) | SQLite + Firestore |
| [SubjectDataManager](data/subject_data_manager.md) | 학년별 선택과목 로드/저장 | SharedPreferences + Firestore |
| [SearchTokens](data/search_tokens.md) | 한국�� 2-gram 토큰화 | — (순수 유틸) |
| [SearchHistoryService](data/search_history_service.md) | 검색 기록 (최대 10개, FIFO) | SharedPreferences |
| [AnalyticsService](data/analytics_service.md) | Firebase Analytics 이벤트 래퍼 | — |
| [SecureStorageService](data/secure_storage_service.md) | 암호화 저장소 래퍼 | Android Keystore / iOS Keychain |
| [SettingData](data/setting_data.md) | 사용자 설정 싱글톤 | SharedPreferences |

---

## 레포지토리 패턴

정적 메서드 → 인스턴스 인터페이스 래핑으로 테스트에서 mock 주입을 가능하게 한다

| Repository | 위임 대상 | 레퍼런스 |
|------------|-----------|----------|
| [AuthRepository](data/auth_repository.md) | [`AuthService`](data/auth_service.md) 정적 메서드 |
| [GradeRepository](data/grade_repository.md) | [`GradeManager`](data/grade_manager.md) 정적 메서드 |

**현재 상태**: GetIt + Riverpod 병행. 신규 코드는 Repository를, 기존 호출처는 정적 메서드를 사용 (점진적 마이그레이션)

---

## 서비스 로케이터

[ServiceLocator](data/service_locator.md) — GetIt 컨테이너에 Repository와 서비스를 등록한다

```dart
// 사용 예시
final auth = GetIt.I<AuthRepository>();
final grade = GetIt.I<GradeRepository>();
final db = GetIt.I<LocalDataBase>();
```

---

## 저장소 전략 요약

```
┌─────────────────────┐
│   SecureStorage      │ ← 성적, 목표, D-day (개인정보)
│   (암호화)           │
├─────────────────────┤
│   SharedPreferences  │ ← 설정, 캐시, 검색기록 (비민감)
│   (평문)             │
├─────────────────────┤
│   SQLite (sqflite)   │ ← 개인 일정 (CRUD 빈번)
├─────────────────────┤
│   Firestore          │ ← 프로필, 게시글, 채팅 (서버)
│                      │   + D-day/일정/과목 동기화
└─────────────────────┘
```

---

## 기타 유틸리티

| 유틸 | 역할 | 레퍼런스 |
|------|------|----------|
| [Device](data/device.md) | 화면 크기 계산, 태블릿 감지 |
| [NetworkStatus](network/network_status.md) | WiFi/모바일 연결 상태 확인 |
