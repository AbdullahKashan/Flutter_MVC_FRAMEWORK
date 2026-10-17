import '../core/mvc_exception.dart';

/// Base exception for all network and REST API related errors.
class ApiException extends MVCException {
  /// The HTTP status code associated with this error, if any.
  final int? statusCode;

  /// Parsed error payload returned by the server (e.g. JSON map or string).
  final dynamic errorData;

  const ApiException(
    super.message, {
    this.statusCode,
    this.errorData,
    super.cause,
    super.stackTrace,
  });

  /// Factory to instantiate the appropriate [ApiException] subclass based on status code.
  factory ApiException.fromResponse(
    int statusCode,
    dynamic responseBody, {
    dynamic cause,
    StackTrace? stackTrace,
  }) {
    String message = 'API request failed with status code $statusCode.';
    if (responseBody is Map) {
      if (responseBody.containsKey('message') &&
          responseBody['message'] is String) {
        message = responseBody['message'];
      } else if (responseBody.containsKey('error') &&
          responseBody['error'] is String) {
        message = responseBody['error'];
      }
    } else if (responseBody is String && responseBody.trim().isNotEmpty) {
      message = responseBody;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      case 401:
        return UnauthorizedException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      case 403:
        return ForbiddenException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      case 404:
        return NotFoundException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      case 409:
        return ConflictException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      case 422:
        return ValidationException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
      default:
        if (statusCode >= 500 && statusCode < 600) {
          return ServerException(message,
              statusCode: statusCode,
              errorData: responseBody,
              cause: cause,
              stackTrace: stackTrace);
        }
        return ApiException(message,
            statusCode: statusCode,
            errorData: responseBody,
            cause: cause,
            stackTrace: stackTrace);
    }
  }

  @override
  String toString() {
    final status = statusCode != null ? ' (Status: $statusCode)' : '';
    return 'ApiException$status: $message';
  }
}

/// Thrown when no internet connection is available or socket lookup fails.
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a request times out waiting for connection or response.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException(super.message, {super.cause, super.stackTrace});
}

/// Thrown on HTTP 400 Bad Request.
class BadRequestException extends ApiException {
  const BadRequestException(super.message,
      {super.statusCode = 400, super.errorData, super.cause, super.stackTrace});
}

/// Thrown on HTTP 401 Unauthorized.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message,
      {super.statusCode = 401, super.errorData, super.cause, super.stackTrace});
}

/// Thrown on HTTP 403 Forbidden.
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message,
      {super.statusCode = 403, super.errorData, super.cause, super.stackTrace});
}

/// Thrown on HTTP 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException(super.message,
      {super.statusCode = 404, super.errorData, super.cause, super.stackTrace});
}

/// Thrown on HTTP 409 Conflict.
class ConflictException extends ApiException {
  const ConflictException(super.message,
      {super.statusCode = 409, super.errorData, super.cause, super.stackTrace});
}

/// Thrown on HTTP 422 Unprocessable Entity (e.g. form validation errors).
class ValidationException extends ApiException {
  const ValidationException(super.message,
      {super.statusCode = 422, super.errorData, super.cause, super.stackTrace});

  /// Map of field errors if provided in the response body.
  Map<String, dynamic> get validationErrors {
    if (errorData is Map<String, dynamic>) {
      final errors = (errorData as Map<String, dynamic>)['errors'];
      if (errors is Map<String, dynamic>) return errors;
    }
    return const {};
  }
}

/// Thrown on HTTP 5xx Server Errors.
class ServerException extends ApiException {
  const ServerException(super.message,
      {super.statusCode = 500, super.errorData, super.cause, super.stackTrace});
}

/// Thrown when parsing the response JSON fails.
class ParseException extends ApiException {
  const ParseException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a request was explicitly cancelled.
class CancelledException extends ApiException {
  const CancelledException([super.message = 'Request was cancelled.']);
}
