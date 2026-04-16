import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/network/network_status.dart';

void main() {
  setUp(() {
    NetworkStatus.testOverride = null;
    NetworkStatus.resetStream();
  });

  group('isUnconnected()', () {
    test('testOverride로 오프라인 시뮬레이션', () async {
      NetworkStatus.testOverride = () async => true;
      expect(await NetworkStatus.isUnconnected(), isTrue);
    });

    test('testOverride로 온라인 시뮬레이션', () async {
      NetworkStatus.testOverride = () async => false;
      expect(await NetworkStatus.isUnconnected(), isFalse);
    });

    test('testOverride 재설정 가능', () async {
      NetworkStatus.testOverride = () async => true;
      expect(await NetworkStatus.isUnconnected(), isTrue);
      NetworkStatus.testOverride = () async => false;
      expect(await NetworkStatus.isUnconnected(), isFalse);
    });
  });

  group('isOffline', () {
    test('초기값 false', () {
      expect(NetworkStatus.isOffline, isFalse);
    });
  });

  group('resetStream()', () {
    test('리셋 후 isOffline false', () {
      NetworkStatus.resetStream();
      expect(NetworkStatus.isOffline, isFalse);
    });
  });
}
