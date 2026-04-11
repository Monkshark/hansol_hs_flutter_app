# SubjectDataManager

> `lib/data/subject_data_manager.dart` — 선택과목 로드/저장, Firestore 동기화

모든 메서드가 `static`. 학년별 선택과목을 SharedPreferences(로컬)와 Firestore(클라우드) 양쪽에 관리

---

## `loadSelectedSubjects`

```dart
static Future<List<Subject>> loadSelectedSubjects(int grade)
```

**설명**: 학년별 선택과목 목록을 로드함

1. SharedPreferences에서 로컬 데이터 확인:
   ```dart
   final jsonString = prefs.getString('$_selectedSubjectsKeyPrefix$grade');
   // 키: 'selected_subjects_grade_1', 'selected_subjects_grade_2', ...
   ```

2. 로컬 데이터가 없고 로그인 상태면 Firestore에서 복원:
   ```dart
   if (localSubjects.isEmpty && AuthService.isLoggedIn) {
     final doc = await FirebaseFirestore.instance
         .collection('users').doc(uid)
         .collection('subjects').doc('grade_$grade')
         .get();
   }
   ```

3. Firestore에서 복원한 데이터는 로컬에도 저장:
   ```dart
   await _saveLocal(prefs, grade, localSubjects);
   ```

---

## `saveSelectedSubjects`

```dart
static Future<void> saveSelectedSubjects(int grade, List<Subject> selectedSubjects)
```

**설명**: 선택과목을 로컬과 Firestore 양쪽에 저장함

1. 로컬 SharedPreferences에 즉시 저장:
   ```dart
   await _saveLocal(prefs, grade, selectedSubjects);
   ```

2. 로그인 상태면 Firestore에도 동기화:
   ```dart
   await FirebaseFirestore.instance
       .collection('users').doc(uid)
       .collection('subjects').doc('grade_$grade')
       .set({
     'subjects': selectedSubjects.map((s) => s.toJson()).toList(),
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

---

## `_saveLocal`

```dart
static Future<void> _saveLocal(SharedPreferences prefs, int grade, List<Subject> subjects)
```

내부 헬퍼. [Subject](subject.md) 리스트를 JSON 인코딩 후 SharedPreferences에 저장
