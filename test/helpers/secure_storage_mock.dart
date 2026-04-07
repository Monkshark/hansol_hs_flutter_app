import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_secure_storage 메서드 채널 in-memory mock
///
/// 사용:
/// ```dart
/// void main() {
///   TestWidgetsFlutterBinding.ensureInitialized();
///   final secureStore = setupSecureStorageMock();
///   setUp(() => secureStore.clear());
///   ...
/// }
/// ```
Map<String, String> setupSecureStorageMock() {
  final Map<String, String> store = {};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return store[key];
      case 'write':
        store[key!] = args['value'] as String;
        return null;
      case 'delete':
        store.remove(key);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      case 'containsKey':
        return store.containsKey(key);
      default:
        return null;
    }
  });
  return store;
}
