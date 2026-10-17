import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'http_method.dart';

/// Request configuration passed through interceptors before execution.
class RequestOptions {
  /// The target URI for the request.
  final Uri uri;

  /// The HTTP method for the request.
  final HttpMethod method;

  /// HTTP headers to be sent with the request.
  final Map<String, String> headers;

  /// Query parameters attached to the request URL.
  final Map<String, dynamic>? queryParameters;

  /// The request payload (String, Map, List, or null).
  final dynamic body;

  /// Timeout duration for this specific request.
  final Duration? timeout;

  /// Whether this request should include authentication headers.
  final bool requiresAuth;

  /// Extra custom metadata or tags associated with this request.
  final Map<String, dynamic> extra;

  const RequestOptions({
    required this.uri,
    required this.method,
    required this.headers,
    this.queryParameters,
    this.body,
    this.timeout,
    this.requiresAuth = true,
    this.extra = const {},
  });

  /// Creates a copy of [RequestOptions] with updated properties.
  RequestOptions copyWith({
    Uri? uri,
    HttpMethod? method,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Duration? timeout,
    bool? requiresAuth,
    Map<String, dynamic>? extra,
  }) {
    return RequestOptions(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? Map<String, String>.from(this.headers),
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      extra: extra ?? Map<String, dynamic>.from(this.extra),
    );
  }
}

/// Abstract interceptor to hook into request, response, and error lifecycles.
abstract class Interceptor {
  const Interceptor();

  /// Called before the request is dispatched to the network.
  /// Return the modified (or original) [options].
  FutureOr<RequestOptions> onRequest(RequestOptions options) => options;

  /// Called after a response is received from the server.
  /// Return the modified (or original) [response].
  FutureOr<ApiResponse> onResponse(ApiResponse response) => response;

  /// Called when an error occurs during request execution.
  /// You can rethrow, return a fallback [ApiResponse], or return null to proceed.
  FutureOr<dynamic> onError(ApiException error) => null;
}

/// An interceptor that logs detailed HTTP request and response information.
class LoggingInterceptor extends Interceptor {
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final void Function(String message) logPrint;

  const LoggingInterceptor({
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponseHeaders = false,
    this.logResponseBody = true,
    this.logPrint = _defaultLogger,
  });

  static void _defaultLogger(String msg) {
    debugPrint(msg);
  }

  @override
  FutureOr<RequestOptions> onRequest(RequestOptions options) {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();
    buffer.writeln('-------------------- [HTTP REQUEST] --------------------');
    buffer.writeln('Time:    $timestamp');
    buffer.writeln('Method:  ${options.method.value}');
    buffer.writeln('URL:     ${options.uri}');

    if (logRequestHeaders && options.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      options.headers.forEach((k, v) {
        // Redact Authorization tokens in logs for security
        final displayVal = (k.toLowerCase() == 'authorization')
            ? (v.length > 15 ? '${v.substring(0, 10)}... (redacted)' : '***')
            : v;
        buffer.writeln('  $k: $displayVal');
      });
    }

    if (logRequestBody && options.body != null) {
      buffer.writeln('Body:    ${options.body}');
    }
    buffer.writeln('--------------------------------------------------------');
    logPrint(buffer.toString());
    return options;
  }

  @override
  FutureOr<ApiResponse> onResponse(ApiResponse response) {
    final buffer = StringBuffer();
    final indicator = response.isSuccess ? '✅ [HTTP SUCCESS]' : '⚠️ [HTTP RESPONSE]';
    buffer.writeln('-------------------- $indicator --------------------');
    buffer.writeln('Status:  ${response.statusCode}');

    if (logResponseHeaders && response.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      response.headers.forEach((k, v) => buffer.writeln('  $k: $v'));
    }

    if (logResponseBody) {
      buffer.writeln('Body:    ${response.rawBody}');
    }
    buffer.writeln('--------------------------------------------------------');
    logPrint(buffer.toString());
    return response;
  }

  @override
  FutureOr<dynamic> onError(ApiException error) {
    final buffer = StringBuffer();
    buffer.writeln('-------------------- ❌ [HTTP ERROR] --------------------');
    buffer.writeln('Message:    ${error.message}');
    if (error.statusCode != null) {
      buffer.writeln('Status:     ${error.statusCode}');
    }
    if (error.errorData != null) {
      buffer.writeln('Error Data: ${error.errorData}');
    }
    if (error.cause != null) {
      buffer.writeln('Cause:      ${error.cause}');
    }
    buffer.writeln('--------------------------------------------------------');
    logPrint(buffer.toString());
    return null;
  }
}
