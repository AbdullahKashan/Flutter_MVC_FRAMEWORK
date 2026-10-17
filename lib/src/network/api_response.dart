import 'package:flutter/foundation.dart';

/// Represents a standardized HTTP response returned by [ApiClient].
@immutable
class ApiResponse<T> {
  /// The HTTP status code of the response.
  final int statusCode;

  /// The parsed or mapped response body of type [T].
  final T data;

  /// The response headers as key-value pairs.
  final Map<String, String> headers;

  /// The raw unparsed response body string.
  final String rawBody;

  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
    required this.rawBody,
  });

  /// Whether the HTTP status code is in the 2xx range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether the HTTP status code is in the 3xx range.
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Whether the HTTP status code is in the 4xx range.
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether the HTTP status code is in the 5xx range.
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Creates a copy of this response with updated values.
  ApiResponse<R> copyWith<R>({
    int? statusCode,
    R? data,
    Map<String, String>? headers,
    String? rawBody,
  }) {
    return ApiResponse<R>(
      statusCode: statusCode ?? this.statusCode,
      data: data ?? (this.data as R),
      headers: headers ?? this.headers,
      rawBody: rawBody ?? this.rawBody,
    );
  }

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, data: $data, isSuccess: $isSuccess)';
}
