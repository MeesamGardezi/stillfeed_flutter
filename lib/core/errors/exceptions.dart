class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message);
}

class AuthException extends AppException {
  AuthException([String message = 'Authentication failed'])
      : super(message, statusCode: 401);
}

class ValidationException extends AppException {
  ValidationException([String message = 'Validation failed'])
      : super(message, statusCode: 400);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}

class ServerException extends AppException {
  ServerException([String message = 'Server error occurred'])
      : super(message, statusCode: 500);
}