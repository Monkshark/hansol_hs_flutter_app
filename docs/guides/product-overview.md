# 제품 개요

> English: [product-overview_en.md](./product-overview_en.md)

## 한 줄 소개

**세종시 한솔고등학교 학생·교사·졸업생·학부모를 위한 통합 학교 플랫폼.** Flutter 기반 모바일 앱 + Next.js 관리자 대시보드로 구성되며, NEIS 공공데이터 API 연동, Firebase 실시간 데이터베이스, 역할 기반 권한 시스템, 푸시 알림, 1:1 채팅 등 실서비스 수준의 기능을 구현했다.

## 왜 만들었는가

학교 공지, 급식, 시간표, 학사일정은 각기 다른 웹사이트/알림 채널에 흩어져 있다. 이 앱은 그것을 **하나의 사용자 맥락 안에서** 조회하고, 학생 커뮤니티(게시판/채팅) 기능까지 포함해 학내 소통을 통합한다.

또한 **성적 관리**는 철저히 로컬에만 저장해 학생 프라이버시를 보호하면서, 추이 그래프와 목표 등급 관리를 제공한다.

## 대상 사용자

| 사용자 | 제공 가치 |
|---|---|
| **재학생** | 급식/시간표/학사일정/게시판/채팅/성적/개인일정/홈 위젯 |
| **교사** | 교사 전용 시간표, 공지 작성, 승인/모더레이션 |
| **졸업생** | 로그인 + 커뮤니티 접근 (성적/시간표 제한) |
| **학부모** | 학사일정 / 공지 / 긴급 팝업 구독 |
| **관리자 (moderator/auditor/manager/admin)** | Flutter Admin 화면 + Next.js Admin Web (4단계 권한 분리) |

## 핵심 가치

- **하나의 앱에서 학교 생활 전반** — 급식, 시간표, 일정, 커뮤니티, 성적
- **학생 프라이버시 우선** — 성적은 로컬 전용, OAuth 전용 인증
- **실시간성** — Firestore onSnapshot + FCM 푸시
- **오프라인 친화** — 급식/시간표 캐시, 오프라인 배너, sqflite 개인 일정
- **저비용 운영** — 1,000명 기준 $0~3/월 (무료 한도 내)

## 범위 경계 (명시적으로 하지 않는 것)

- **성적은 서버 저장/백업 없음** — 기기 변경 시 이관 안 됨 (의도)
- **교무 시스템 연동 없음** — NEIS 공공 API만 사용
- **웹 버전 없음** — 관리자 대시보드만 웹. 일반 사용자는 앱 전용
- **결제/유료 기능 없음**

## 규모 지표

| 항목 | 수치 |
|---|---|
| 총 코드 라인 | 약 43,000 (Dart 36,031 + TS/TSX + Java/XML + Swift + JS) |
| 소스 파일 | 139 (Flutter) + 30 (Admin Web TS/TSX) + Android/iOS 위젯 |
| Cloud Functions | 24개 |
| OAuth 로그인 | 4종 (Google / Apple / Kakao / GitHub) |
| 푸시 알림 | FCM 4종 (`account` / `comment` / `new_post` / `chat`) + 로컬 3종 (조식/중식/석식) |
| 권한 모델 | 4단계 (`moderator` / `auditor` / `manager` / `admin`) + Firebase Auth custom claims |
| PIPA 컴플라이언스 | `appeals` (90일 TTL) / `data_requests` (30일 TTL) / `community_rules` |
| 테스트 | 563 Flutter + 85 Rules = 648개 |

## 기술 스택 요약

| 분류 | 기술 |
|---|---|
| Mobile | Flutter (Dart) — Android / iOS |
| State | Riverpod 2.5 |
| DI | GetIt + Abstract Repository |
| Admin Web | Next.js 14 + TypeScript + Tailwind |
| Backend | Firebase (Auth / Firestore / Storage / FCM / Crashlytics) |
| Server | Cloud Functions (Node.js) |
| External | NEIS 공공데이터 API |

상세는 [architecture-overview.md](./architecture-overview.md).

## 주요 플로우 요약

1. **OAuth 로그인 → 신분 선택 → 관리자 승인 → 홈 진입** ([account-and-access.md](./account-and-access.md))
2. **홈에서 급식/시간표/일정 조회** ([public-features.md](../features/public-features.md))
3. **게시판/채팅으로 소통** ([community-features.md](../features/community-features.md))
4. **성적/개인일정은 로컬 관리** ([personal-features.md](../features/personal-features.md))
5. **관리자는 Admin Web에서 사용자/콘텐츠 관리** ([admin-features.md](../features/admin-features.md))

## 관련 문서
- [아키텍처 개요](./architecture-overview.md)
- [아키텍처 의사결정 일지](./architecture-decisions.md)
- [기여 가이드](../CONTRIBUTING.md)
- [배포 가이드](../DEPLOY.md)
- [엔드유저 가이드](../USER_GUIDE.md)
