sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}
