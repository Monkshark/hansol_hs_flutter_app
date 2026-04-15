import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/auth_service.dart';

void main() {
  group('UserProfile', () {
    test('fromMap creates correct profile', () {
      final map = {
        'uid': 'test123',
        'name': '홍길동',
        'studentId': '20301',
        'grade': 2,
        'classNum': 3,
        'email': 'test@test.com',
        'approved': true,
        'role': 'manager',
        'userType': 'student',
        'lastProfileUpdate': '2026',
        'loginProvider': 'google',
        'blockedUsers': ['blocked1', 'blocked2'],
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.uid, 'test123');
      expect(profile.name, '홍길동');
      expect(profile.studentId, '20301');
      expect(profile.grade, 2);
      expect(profile.classNum, 3);
      expect(profile.approved, true);
      expect(profile.role, 'manager');
      expect(profile.isManager, true);
      expect(profile.isAdmin, false);
      expect(profile.isStudent, true);
      expect(profile.loginProvider, 'google');
      expect(profile.blockedUsers.length, 2);
    });

    test('fromMap handles missing fields', () {
      final profile = UserProfile.fromMap({});

      expect(profile.uid, '');
      expect(profile.name, '');
      expect(profile.approved, false);
      expect(profile.role, 'user');
      expect(profile.isManager, false);
      expect(profile.userType, 'student');
      expect(profile.blockedUsers, isEmpty);
      expect(profile.loginProvider, 'google');
    });

    test('toMap includes all fields', () {
      final profile = UserProfile(
        uid: 'u1',
        name: '김철수',
        studentId: '10101',
        grade: 1,
        classNum: 1,
        email: 'a@b.com',
        approved: true,
        role: 'admin',
        userType: 'student',
        lastProfileUpdate: '2026',
        loginProvider: 'kakao',
      );

      final map = profile.toMap();

      expect(map['uid'], 'u1');
      expect(map['name'], '김철수');
      expect(map['role'], 'admin');
      expect(map['loginProvider'], 'kakao');
      expect(map['approved'], true);
    });

    test('displayName returns correct format', () {
      expect(
        UserProfile(uid: '', name: '홍길동', studentId: '20301', grade: 2, classNum: 3, email: '').displayName,
        '20301 홍길동',
      );

      expect(
        UserProfile(uid: '', name: '홍길동', studentId: '', grade: 0, classNum: 0, email: '', userType: 'graduate', graduationYear: 2025).displayName,
        '졸업생 홍길동',
      );

      expect(
        UserProfile(uid: '', name: '홍길동', studentId: '', grade: 0, classNum: 0, email: '', userType: 'teacher').displayName,
        '교사 홍길동',
      );

      expect(
        UserProfile(uid: '', name: '홍길동', studentId: '', grade: 0, classNum: 0, email: '', userType: 'parent').displayName,
        '학부모 홍길동',
      );
    });

    test('isManager and isAdmin work correctly', () {
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', role: 'user').isManager, false);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', role: 'manager').isManager, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', role: 'admin').isManager, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', role: 'admin').isAdmin, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', role: 'manager').isAdmin, false);
    });

    test('isSuspended checks correctly', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      final past = DateTime.now().subtract(const Duration(hours: 1));

      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', suspendedUntil: future).isSuspended, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', suspendedUntil: past).isSuspended, false);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '').isSuspended, false);
    });

    test('needsProfileUpdate works correctly', () {
      final currentYear = DateTime.now().year.toString();
      final lastYear = (DateTime.now().year - 1).toString();

      final upToDate = UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', lastProfileUpdate: currentYear);
      expect(upToDate.needsProfileUpdate, false);

      final outdated = UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', lastProfileUpdate: lastYear);
      expect(outdated.needsProfileUpdate, DateTime.now().month >= 3);

      final empty = UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '');
      expect(empty.needsProfileUpdate, true);
    });

    test('needsProfileUpdate returns false for graduate', () {
      final graduate = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'graduate', lastProfileUpdate: '',
      );
      expect(graduate.needsProfileUpdate, false);
    });

    test('needsProfileUpdate returns false for parent', () {
      final parent = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'parent', lastProfileUpdate: '',
      );
      expect(parent.needsProfileUpdate, false);
    });

    test('needsProfileUpdate returns true for teacher with empty lastProfileUpdate', () {
      final teacher = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'teacher', lastProfileUpdate: '',
      );
      expect(teacher.needsProfileUpdate, true);
    });

    test('needsProfileUpdate returns false for student with current year', () {
      final currentYear = DateTime.now().year.toString();
      final student = UserProfile(
        uid: '', name: '', studentId: '10101', grade: 1, classNum: 1, email: '',
        userType: 'student', lastProfileUpdate: currentYear,
      );
      expect(student.needsProfileUpdate, false);
    });

    test('isSuspended returns false when suspendedUntil is null', () {
      final profile = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
      );
      expect(profile.isSuspended, false);
    });

    test('isSuspended returns true when suspendedUntil is in the future', () {
      final profile = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
        suspendedUntil: DateTime.now().add(const Duration(days: 7)),
      );
      expect(profile.isSuspended, true);
    });

    test('isSuspended returns false when suspendedUntil is in the past', () {
      final profile = UserProfile(
        uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '',
        suspendedUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(profile.isSuspended, false);
    });

    test('displayName for student with studentId', () {
      final profile = UserProfile(
        uid: '', name: '김철수', studentId: '10305', grade: 1, classNum: 3, email: '',
        userType: 'student',
      );
      expect(profile.displayName, '10305 김철수');
    });

    test('displayName for student without studentId', () {
      final profile = UserProfile(
        uid: '', name: '김철수', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'student',
      );
      expect(profile.displayName, '김철수');
    });

    test('displayName for graduate', () {
      final profile = UserProfile(
        uid: '', name: '이영희', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'graduate', graduationYear: 2025,
      );
      expect(profile.displayName, '졸업생 이영희');
    });

    test('displayName for teacher', () {
      final profile = UserProfile(
        uid: '', name: '박선생', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'teacher',
      );
      expect(profile.displayName, '교사 박선생');
    });

    test('displayName for parent', () {
      final profile = UserProfile(
        uid: '', name: '최학부모', studentId: '', grade: 0, classNum: 0, email: '',
        userType: 'parent',
      );
      expect(profile.displayName, '학부모 최학부모');
    });

    test('isStudent/isGraduate/isTeacher/isParent flags', () {
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', userType: 'student').isStudent, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', userType: 'student').isGraduate, false);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', userType: 'graduate').isGraduate, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', userType: 'teacher').isTeacher, true);
      expect(UserProfile(uid: '', name: '', studentId: '', grade: 0, classNum: 0, email: '', userType: 'parent').isParent, true);
    });

    test('profilePhotoUrl is preserved through fromMap', () {
      final map = {
        'uid': 'u1',
        'name': 'test',
        'profilePhotoUrl': 'https://example.com/photo.jpg',
      };
      final profile = UserProfile.fromMap(map);
      expect(profile.profilePhotoUrl, 'https://example.com/photo.jpg');
    });

    test('profilePhotoUrl defaults to null', () {
      final profile = UserProfile.fromMap({});
      expect(profile.profilePhotoUrl, isNull);
    });
  });
}
