import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/auth_service.dart';

void main() {
  group('UserProfile role checks', () {
    test('isManager true for manager role', () {
      final p = _profile(role: 'manager');
      expect(p.isManager, true);
      expect(p.isAdmin, false);
    });

    test('isManager true for admin role', () {
      final p = _profile(role: 'admin');
      expect(p.isManager, true);
      expect(p.isAdmin, true);
    });

    test('isManager false for user role', () {
      final p = _profile(role: 'user');
      expect(p.isManager, false);
      expect(p.isAdmin, false);
    });
  });

  group('UserProfile userType checks', () {
    test('isStudent true for student', () {
      expect(_profile(userType: 'student').isStudent, true);
      expect(_profile(userType: 'student').isTeacher, false);
    });

    test('isGraduate true for graduate', () {
      expect(_profile(userType: 'graduate').isGraduate, true);
      expect(_profile(userType: 'graduate').isStudent, false);
    });

    test('isTeacher true for teacher', () {
      expect(_profile(userType: 'teacher').isTeacher, true);
    });

    test('isParent true for parent', () {
      expect(_profile(userType: 'parent').isParent, true);
    });
  });

  group('UserProfile isSuspended', () {
    test('not suspended when null', () {
      expect(_profile().isSuspended, false);
    });

    test('suspended when future date', () {
      final p = _profile(suspendedUntil: DateTime.now().add(const Duration(hours: 1)));
      expect(p.isSuspended, true);
    });

    test('not suspended when past date', () {
      final p = _profile(suspendedUntil: DateTime.now().subtract(const Duration(hours: 1)));
      expect(p.isSuspended, false);
    });
  });

  group('UserProfile displayName', () {
    test('student with studentId shows id and name', () {
      final p = _profile(userType: 'student', studentId: '10301', name: '김민수');
      expect(p.displayName, '10301 김민수');
    });

    test('student without studentId shows name only', () {
      final p = _profile(userType: 'student', studentId: '', name: '김민수');
      expect(p.displayName, '김민수');
    });

    test('graduate shows 졸업생 prefix', () {
      final p = _profile(userType: 'graduate', name: '이영희');
      expect(p.displayName, '졸업생 이영희');
    });

    test('teacher shows 교사 prefix', () {
      final p = _profile(userType: 'teacher', name: '박선생');
      expect(p.displayName, '교사 박선생');
    });

    test('parent shows 학부모 prefix', () {
      final p = _profile(userType: 'parent', name: '최부모');
      expect(p.displayName, '학부모 최부모');
    });
  });

  group('UserProfile needsProfileUpdate', () {
    test('graduate does not need update', () {
      final p = _profile(userType: 'graduate', lastProfileUpdate: '');
      expect(p.needsProfileUpdate, false);
    });

    test('parent does not need update', () {
      final p = _profile(userType: 'parent', lastProfileUpdate: '');
      expect(p.needsProfileUpdate, false);
    });

    test('student with empty lastProfileUpdate needs update', () {
      final p = _profile(userType: 'student', lastProfileUpdate: '');
      expect(p.needsProfileUpdate, true);
    });

    test('student with current year does not need update', () {
      final year = DateTime.now().year.toString();
      final p = _profile(userType: 'student', lastProfileUpdate: year);
      expect(p.needsProfileUpdate, false);
    });

    test('student with old year needs update if March or later', () {
      final now = DateTime.now();
      final p = _profile(userType: 'student', lastProfileUpdate: '2025');
      if (now.month >= 3) {
        expect(p.needsProfileUpdate, true);
      } else {
        expect(p.needsProfileUpdate, false);
      }
    });

    test('teacher follows same rules as student', () {
      final p = _profile(userType: 'teacher', lastProfileUpdate: '');
      expect(p.needsProfileUpdate, true);
    });
  });

  group('UserProfile defaults', () {
    test('default values are correct', () {
      final p = UserProfile(uid: 'u1', name: 'test', studentId: '', grade: 0, classNum: 0, email: '');
      expect(p.approved, false);
      expect(p.role, 'user');
      expect(p.userType, 'student');
      expect(p.lastProfileUpdate, '');
      expect(p.graduationYear, null);
      expect(p.teacherSubject, null);
      expect(p.suspendedUntil, null);
      expect(p.blockedUsers, isEmpty);
      expect(p.loginProvider, 'google');
      expect(p.profilePhotoUrl, null);
    });
  });
}

UserProfile _profile({
  String name = 'test',
  String role = 'user',
  String userType = 'student',
  String studentId = '',
  String lastProfileUpdate = '',
  DateTime? suspendedUntil,
}) {
  return UserProfile(
    uid: 'uid1',
    name: name,
    studentId: studentId,
    grade: 1,
    classNum: 3,
    email: 'test@test.com',
    role: role,
    userType: userType,
    lastProfileUpdate: lastProfileUpdate,
    suspendedUntil: suspendedUntil,
  );
}
