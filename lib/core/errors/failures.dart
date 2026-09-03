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

class AccountUnauthorizedException implements Exception {
  final String email;
  final String uid;
  final String message;
  const AccountUnauthorizedException({
    required this.email,
    required this.uid,
    this.message = 'Account is pending approval by the administrator.',
  });

  @override
  String toString() => message;
}

class AccountDisabledException implements Exception {
  final String email;
  final String uid;
  final String message;
  const AccountDisabledException({
    required this.email,
    required this.uid,
    this.message = 'Account has been deactivated by the administrator.',
  });

  @override
  String toString() => message;
}
