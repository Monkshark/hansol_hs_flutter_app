import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/exceptions.dart';

void main() {
  group('AppException', () {
    test('message 저장', () {
      const e = AppException('테스트 에러');
      expect(e.message, '테스트 에러');
      expect(e.cause, isNull);
    });

    test('cause 저장', () {
      final cause = Exception('원인');
      final e = AppException('에러', cause);
      expect(e.cause, cause);
    });

    test('toString', () {
      const e = AppException('메시지');
      expect(e.toString(), 'AppException: 메시지');
    });

    test('Exception 인터페이스 구현', () {
      const e = AppException('test');
      expect(e, isA<Exception>());
    });
  });

  group('NetworkException', () {
    test('message 저장', () {
      const e = NetworkException('연결 실패');
      expect(e.message, '연결 실패');
    });

    test('AppException 상속', () {
      const e = NetworkException('test');
      expect(e, isA<AppException>());
      expect(e, isA<Exception>());
    });

    test('toString', () {
      const e = NetworkException('타임아웃');
      expect(e.toString(), 'NetworkException: 타임아웃');
    });

    test('cause 전달', () {
      final cause = Exception('socket');
      const e = NetworkException('실패', null);
      expect(e.cause, isNull);
      final e2 = NetworkException('실패', cause);
      expect(e2.cause, cause);
    });
  });

  group('ApiException', () {
    test('message 저장', () {
      const e = ApiException('파싱 에러');
      expect(e.message, '파싱 에러');
    });

    test('AppException 상속', () {
      const e = ApiException('test');
      expect(e, isA<AppException>());
    });

    test('toString', () {
      const e = ApiException('API 오류');
      expect(e.toString(), 'ApiException: API 오류');
    });
  });

  group('AuthException', () {
    test('message 저장', () {
      const e = AuthException('인증 실패');
      expect(e.message, '인증 실패');
    });

    test('AppException 상속', () {
      const e = AuthException('test');
      expect(e, isA<AppException>());
    });

    test('toString', () {
      const e = AuthException('토큰 만료');
      expect(e.toString(), 'AuthException: 토큰 만료');
    });
  });

  group('예외 타입 구분', () {
    test('isA 매처로 구분 가능', () {
      const Object network = NetworkException('net');
      const Object api = ApiException('api');
      const Object auth = AuthException('auth');
      const Object app = AppException('app');

      expect(network, isA<NetworkException>());
      expect(network, isA<AppException>());
      expect(network, isNot(isA<ApiException>()));

      expect(api, isA<ApiException>());
      expect(api, isA<AppException>());
      expect(api, isNot(isA<AuthException>()));

      expect(auth, isA<AuthException>());
      expect(auth, isA<AppException>());
      expect(auth, isNot(isA<NetworkException>()));

      expect(app, isA<AppException>());
      expect(app, isNot(isA<NetworkException>()));
    });

    test('catch 블록에서 타입별 처리', () {
      String handle(Object e) {
        if (e is NetworkException) return 'network';
        if (e is ApiException) return 'api';
        if (e is AuthException) return 'auth';
        if (e is AppException) return 'app';
        return 'unknown';
      }

      expect(handle(const NetworkException('n')), 'network');
      expect(handle(const ApiException('a')), 'api');
      expect(handle(const AuthException('u')), 'auth');
      expect(handle(const AppException('g')), 'app');
      expect(handle(Exception('x')), 'unknown');
    });
  });

  group('const 생성자', () {
    test('const 인스턴스 동일성', () {
      const a = NetworkException('같은 메시지');
      const b = NetworkException('같은 메시지');
      expect(identical(a, b), isTrue);
    });

    test('다른 메시지는 다른 인스턴스', () {
      const a = NetworkException('메시지1');
      const b = NetworkException('메시지2');
      expect(identical(a, b), isFalse);
    });
  });
}
