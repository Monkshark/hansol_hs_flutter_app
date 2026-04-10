# Subject

> `lib/data/subject.dart` — 과목 데이터 모델 (freezed)

`@freezed` 기반이지만 커스텀 `==`/`hashCode`를 오버라이드. JSON 직렬화는 코드 생성(`subject.g.dart`).

---

## 필드

```dart
@freezed
class Subject with _$Subject {
  const factory Subject({
    required String subjectName,   // 과목명 (예: '국어', '수학')
    required int subjectClass,     // 반 번호. -1이면 특별실 과목
    String? category,              // 과목 카테고리 (관리자 Firestore에서 설정)
    @Default(false) bool isOriginal, // 관리자가 등록한 원본 과목 여부
  }) = _Subject;
}
```

- `subjectClass`: NEIS 시간표에서 `CLASS_NM` 값. 특별실(반 번호 없음)이면 `-1`
- `category`: `TimetableDataApi.getSubjectsFromAdminFirestore`에서 가져오는 분류
- `isOriginal`: 관리자 등록 과목이면 true, NEIS 자동 추출이면 false

---

## 동등성 비교 (커스텀)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is Subject &&
        runtimeType == other.runtimeType &&
        subjectName == other.subjectName &&
        subjectClass == other.subjectClass;

@override
int get hashCode => subjectName.hashCode ^ subjectClass.hashCode;
```

`subjectName` + `subjectClass` 조합으로 동등성 판단. `category`와 `isOriginal`은 비교에서 제외.

**이유**: `TimetableDataApi.getAllSubjectCombinations`에서 Set에 Subject를 넣어 중복 제거 시, 같은 과목+반 조합이면 같은 과목으로 취급해야 하므로.

---

## JSON 직렬화

```dart
factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
```

[`SubjectDataManager`](subject_data_manager.md)에서 SharedPreferences/Firestore에 저장/복원할 때 사용.

---

## 사용처

| 위치 | 용도 |
|------|------|
| `TimetableDataApi.getAllSubjectCombinations` | NEIS 시간표에서 과목+반 조합 추출, Set으로 중복 제거 |
| `TimetableDataApi.getCustomTimeTable` | 사용자 선택 Subject 리스트로 커스텀 시간표 생성 |
| `TimetableDataApi.getSubjectsFromAdminFirestore` | Firestore에서 관리자 등록 과목 조회 |
| `SubjectDataManager` | 선택과목 로컬/Firestore 저장 |
| `TimetableSelectScreen` | 과목 선택 UI에서 Subject 리스트 표시 |
