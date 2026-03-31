import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Google 로그인/로그아웃, Firestore 프로필 CRUD
///
/// - Google 로그인 및 Firebase 인증 처리
/// - Firestore 사용자 프로필 생성/조회/수정
/// - 승인 여부 및 매니저 권한 체크, 5분 캐시
class UserProfile {
  final String uid;
  final String name;
  final String studentId;
  final int grade;
  final int classNum;
  final String email;
  final bool approved;
  final String role;
  final String userType;
  final String lastProfileUpdate;
  final int? graduationYear;
  final String? teacherSubject;
  final DateTime? suspendedUntil;

  UserProfile({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.grade,
    required this.classNum,
    required this.email,
    this.approved = false,
    this.role = 'user',
    this.userType = 'student',
    this.lastProfileUpdate = '',
    this.graduationYear,
    this.teacherSubject,
    this.suspendedUntil,
  });

  bool get isManager => role == 'manager' || role == 'admin';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!);
  bool get isStudent => userType == 'student';
  bool get isGraduate => userType == 'graduate';
  bool get isTeacher => userType == 'teacher';
  bool get isParent => userType == 'parent';

  String get displayName {
    switch (userType) {
      case 'graduate':
        return '졸업(${graduationYear ?? ''}) $name';
      case 'teacher':
        return '교사 $name';
      case 'parent':
        return '학부모 $name';
      default:
        return studentId.isNotEmpty ? '$studentId $name' : name;
    }
  }

  bool get needsProfileUpdate {
    if (lastProfileUpdate.isEmpty) return true;
    final now = DateTime.now();
    final currentYear = now.year.toString();
    return lastProfileUpdate != currentYear && now.month >= 3;
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'studentId': studentId,
    'grade': grade,
    'classNum': classNum,
    'email': email,
    'approved': approved,
    'role': role,
    'userType': userType,
    'lastProfileUpdate': lastProfileUpdate,
    'graduationYear': graduationYear,
    'teacherSubject': teacherSubject,
    if (suspendedUntil != null) 'suspendedUntil': Timestamp.fromDate(suspendedUntil!),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    studentId: map['studentId'] ?? '',
    grade: map['grade'] ?? 0,
    classNum: map['classNum'] ?? 0,
    email: map['email'] ?? '',
    approved: map['approved'] ?? false,
    role: map['role'] ?? 'user',
    userType: map['userType'] ?? 'student',
    lastProfileUpdate: map['lastProfileUpdate'] ?? '',
    graduationYear: map['graduationYear'],
    teacherSubject: map['teacherSubject'],
    suspendedUntil: map['suspendedUntil'] != null ? (map['suspendedUntil'] as Timestamp).toDate() : null,
  );
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      log('AuthService: Google sign in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  static Future<bool> hasProfile() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists && doc.data()?['name'] != null;
  }

  static Future<bool> isApproved() async {
    final profile = await getUserProfile();
    if (profile == null) return false;
    if (profile.isSuspended) return false;
    return profile.approved || profile.isManager;
  }

  static Future<String?> getSuspendedMessage() async {
    final profile = await getCachedProfile();
    if (profile == null || !profile.isSuspended) return null;
    final diff = profile.suspendedUntil!.difference(DateTime.now());
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}일');
    if (hours > 0) parts.add('${hours}시간');
    if (minutes > 0) parts.add('${minutes}분');
    if (parts.isEmpty) parts.add('${seconds}초');
    return parts.join(' ');
  }

  static Future<bool> isManager() async {
    final profile = await getUserProfile();
    return profile?.isManager ?? false;
  }

  static UserProfile? get cachedProfile => _cachedProfile;
  static UserProfile? _cachedProfile;
  static DateTime? _cacheTime;

  static Future<UserProfile?> getCachedProfile() async {
    if (_cachedProfile != null && _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inMinutes < 5) {
      return _cachedProfile;
    }
    _cachedProfile = await getUserProfile();
    _cacheTime = DateTime.now();
    return _cachedProfile;
  }

  static void clearProfileCache() {
    _cachedProfile = null;
    _cacheTime = null;
  }
}
