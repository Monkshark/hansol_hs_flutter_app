# SubjectDataManager

> 한국어: [subject_data_manager.md](./subject_data_manager.md)

> `lib/data/subject_data_manager.dart` — Loads/saves elective subjects, syncs with Firestore

All methods are `static`. Manages per-grade elective subjects across both SharedPreferences (local) and Firestore (cloud).

---

## `loadSelectedSubjects`

```dart
static Future<List<Subject>> loadSelectedSubjects(int grade)
```

**Description**: Loads the list of elective subjects for a given grade.

1. Check local data from SharedPreferences:
   ```dart
   final jsonString = prefs.getString('$_selectedSubjectsKeyPrefix$grade');
   // keys: 'selected_subjects_grade_1', 'selected_subjects_grade_2', ...
   ```

2. If no local data and the user is signed in, restore from Firestore:
   ```dart
   if (localSubjects.isEmpty && AuthService.isLoggedIn) {
     final doc = await FirebaseFirestore.instance
         .collection('users').doc(uid)
         .collection('subjects').doc('grade_$grade')
         .get();
   }
   ```

3. Data restored from Firestore is also written locally:
   ```dart
   await _saveLocal(prefs, grade, localSubjects);
   ```

---

## `saveSelectedSubjects`

```dart
static Future<void> saveSelectedSubjects(int grade, List<Subject> selectedSubjects)
```

**Description**: Saves the selected subjects to both local storage and Firestore.

1. Immediately save to local SharedPreferences:
   ```dart
   await _saveLocal(prefs, grade, selectedSubjects);
   ```

2. If signed in, also sync to Firestore:
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

Internal helper. JSON-encodes the [Subject](subject.md) list and writes it to SharedPreferences.
