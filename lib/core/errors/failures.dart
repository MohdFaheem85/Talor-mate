abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred. Please try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Keeping data offline.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
