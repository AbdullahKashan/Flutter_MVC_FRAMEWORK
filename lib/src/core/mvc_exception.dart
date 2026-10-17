/// Base exception for all errors originated within the flutter_mvc framework.
class MVCException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Optional underlying cause or error object.
  final dynamic cause;

  /// Optional stack trace captured when the exception occurred.
  final StackTrace? stackTrace;

  const MVCException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    if (cause != null) {
      return 'MVCException: $message (Caused by: $cause)';
    }
    return 'MVCException: $message';
  }
}

/// Thrown when an expected service or dependency is missing from the service locator.
class DependencyNotFoundException extends MVCException {
  const DependencyNotFoundException(Type type)
      : super('No instance registered for type $type in ServiceLocator.');
}

/// Thrown when an invalid state transition or operation is attempted in a controller.
class ControllerStateException extends MVCException {
  const ControllerStateException(super.message, {super.cause, super.stackTrace});
}
