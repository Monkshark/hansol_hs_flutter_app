class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, [this.cause]);
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
  @override
  String toString() => 'NetworkException: $message';
}

class ApiException extends AppException {
  const ApiException(super.message, [super.cause]);
  @override
  String toString() => 'ApiException: $message';
}

class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
  @override
  String toString() => 'AuthException: $message';
}
