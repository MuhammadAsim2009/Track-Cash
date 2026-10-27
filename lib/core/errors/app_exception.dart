/// Typed domain exceptions for TrackCash matching docs/rules.md.
sealed class AppException implements Exception {
  const AppException(this.message, [this.details]);

  final String message;
  final Object? details;

  @override
  String toString() => details != null ? '$message ($details)' : message;
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.details]);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.details]);
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.details]);
}

class AuthException extends AppException {
  const AuthException(super.message, [super.details]);
}

class SyncException extends AppException {
  const SyncException(super.message, [super.details]);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.details]);
}
