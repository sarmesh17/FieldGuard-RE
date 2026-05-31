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

/// A 409 from the API — the request clashed with existing state. The only
/// source today is the globally-unique phone constraint (a phone already
/// registered to another user/company/shop). The backend's [message] is
/// already user-actionable, so it's shown verbatim.
class ConflictException extends AppException {
  const ConflictException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}
