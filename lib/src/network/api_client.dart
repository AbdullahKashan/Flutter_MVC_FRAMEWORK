import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'http_method.dart';
import 'interceptor.dart';
import 'multipart_request.dart';

/// Core HTTP client for executing REST requests within the flutter_mvc framework.
class ApiClient {
  /// Configuration options for the client.
  ApiConfig config;

  final http.Client _httpClient;
  final List<Interceptor> _interceptors = [];

  ApiClient({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _interceptors.addAll(config.interceptors);
    if (config.loggingEnabled) {
      _interceptors.add(const LoggingInterceptor());
    }
  }

  /// Adds an interceptor to the execution pipeline.
  void addInterceptor(Interceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Removes an interceptor from the execution pipeline.
  void removeInterceptor(Interceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Closes the underlying HTTP client.
  void close() {
    _httpClient.close();
  }

  /// Resolves the absolute URI from [endpoint] and query parameters.
  Uri resolveUri(String endpoint, [Map<String, dynamic>? query]) {
    final baseUri = Uri.parse(config.baseUrl);
    Uri endpointUri = Uri.parse(endpoint);

    Uri mergedUri;
    if (endpointUri.hasScheme) {
      mergedUri = endpointUri;
    } else {
      String basePath = baseUri.path;
      String endpointPath = endpointUri.path;

      if (!basePath.endsWith('/') && !endpointPath.startsWith('/')) {
        basePath = '$basePath/$endpointPath';
      } else if (basePath.endsWith('/') && endpointPath.startsWith('/')) {
        basePath = '$basePath${endpointPath.substring(1)}';
      } else {
        basePath = '$basePath$endpointPath';
      }

      mergedUri = baseUri.replace(
        path: basePath,
        queryParameters: endpointUri.hasQuery ? endpointUri.queryParameters : null,
      );
    }

    if (query != null && query.isNotEmpty) {
      final mergedParams = Map<String, dynamic>.from(mergedUri.queryParameters);
      query.forEach((key, value) {
        if (value != null) {
          mergedParams[key] = value.toString();
        }
      });
      mergedUri = mergedUri.replace(
        queryParameters: mergedParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }

    return mergedUri;
  }

  /// Executes an HTTP GET request.
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.get,
      endpoint: endpoint,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      requiresAuth: requiresAuth,
    );
  }

  /// Executes an HTTP POST request.
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: body,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      requiresAuth: requiresAuth,
    );
  }

  /// Executes an HTTP PUT request.
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: body,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      requiresAuth: requiresAuth,
    );
  }

  /// Executes an HTTP PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.patch,
      endpoint: endpoint,
      body: body,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      requiresAuth: requiresAuth,
    );
  }

  /// Executes an HTTP DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) {
    return _sendRequest<T>(
      method: HttpMethod.delete,
      endpoint: endpoint,
      body: body,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      requiresAuth: requiresAuth,
    );
  }

  /// Uploads files using multipart/form-data.
  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required MultipartPayload payload,
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = resolveUri(endpoint, query);
    final requestHeaders = Map<String, String>.from(config.defaultHeaders);
    // Remove JSON content-type header for multipart requests so boundary is set automatically
    requestHeaders.remove('Content-Type');
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var options = RequestOptions(
      uri: uri,
      method: method,
      headers: requestHeaders,
      queryParameters: query,
      body: payload,
      timeout: timeout ?? config.timeout,
      requiresAuth: requiresAuth,
    );

    // Apply onRequest interceptors
    for (final interceptor in _interceptors) {
      options = await interceptor.onRequest(options);
    }

    try {
      final multipartRequest = http.MultipartRequest(options.method.value, options.uri);
      multipartRequest.headers.addAll(options.headers);
      multipartRequest.fields.addAll(payload.fields);

      for (final file in payload.files) {
        multipartRequest.files.add(file.toHttpMultipartFile());
      }

      final streamedResponse = await _httpClient
          .send(multipartRequest)
          .timeout(options.timeout ?? config.timeout);

      final response = await http.Response.fromStream(streamedResponse);
      return await _processResponse<T>(response, options, parser);
    } catch (e, stackTrace) {
      return await _handleException<T>(e, stackTrace);
    }
  }

  /// Core helper to dispatch standard HTTP requests.
  Future<ApiResponse<T>> _sendRequest<T>({
    required HttpMethod method,
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(dynamic data)? parser,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    final uri = resolveUri(endpoint, query);
    final requestHeaders = Map<String, String>.from(config.defaultHeaders);
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    var options = RequestOptions(
      uri: uri,
      method: method,
      headers: requestHeaders,
      queryParameters: query,
      body: body,
      timeout: timeout ?? config.timeout,
      requiresAuth: requiresAuth,
    );

    // Apply onRequest interceptors
    for (final interceptor in _interceptors) {
      options = await interceptor.onRequest(options);
    }

    try {
      final dynamic serializedBody = _serializeBody(options.body, options.headers);
      final duration = options.timeout ?? config.timeout;

      final http.Response httpResponse;
      switch (options.method) {
        case HttpMethod.get:
          httpResponse = await _httpClient
              .get(options.uri, headers: options.headers)
              .timeout(duration);
          break;
        case HttpMethod.post:
          httpResponse = await _httpClient
              .post(options.uri, headers: options.headers, body: serializedBody)
              .timeout(duration);
          break;
        case HttpMethod.put:
          httpResponse = await _httpClient
              .put(options.uri, headers: options.headers, body: serializedBody)
              .timeout(duration);
          break;
        case HttpMethod.patch:
          httpResponse = await _httpClient
              .patch(options.uri, headers: options.headers, body: serializedBody)
              .timeout(duration);
          break;
        case HttpMethod.delete:
          httpResponse = await _httpClient
              .delete(options.uri, headers: options.headers, body: serializedBody)
              .timeout(duration);
          break;
        case HttpMethod.head:
          httpResponse = await _httpClient
              .head(options.uri, headers: options.headers)
              .timeout(duration);
          break;
      }

      return await _processResponse<T>(httpResponse, options, parser);
    } catch (e, stackTrace) {
      return await _handleException<T>(e, stackTrace);
    }
  }

  /// Serializes body if Content-Type is json and body is a Map or List.
  dynamic _serializeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    final contentType = headers['Content-Type'] ?? headers['content-type'] ?? '';
    if (contentType.contains('application/json') && (body is Map || body is List)) {
      return jsonEncode(body);
    }
    return body;
  }

  /// Decodes and maps the raw HTTP response.
  Future<ApiResponse<T>> _processResponse<T>(
    http.Response httpResponse,
    RequestOptions options,
    T Function(dynamic data)? parser,
  ) async {
    final rawBody = httpResponse.body;
    dynamic decodedData = rawBody;

    final contentType = httpResponse.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json') ||
        (rawBody.trim().startsWith('{') && rawBody.trim().endsWith('}')) ||
        (rawBody.trim().startsWith('[') && rawBody.trim().endsWith(']'));

    if (isJson && rawBody.isNotEmpty) {
      try {
        decodedData = jsonDecode(rawBody);
      } catch (_) {
        // Fallback to raw string if JSON parsing fails
      }
    }

    if (httpResponse.statusCode >= 400) {
      final apiException = ApiException.fromResponse(
        httpResponse.statusCode,
        decodedData,
      );

      // Trigger interceptor onError
      for (final interceptor in _interceptors) {
        final result = await interceptor.onError(apiException);
        if (result is ApiResponse<T>) {
          return result;
        }
      }

      throw apiException;
    }

    T parsedData;
    if (parser != null) {
      try {
        parsedData = parser(decodedData);
      } catch (e, st) {
        throw ParseException(
          'Failed to parse API response: $e',
          cause: e,
          stackTrace: st,
        );
      }
    } else {
      parsedData = decodedData as T;
    }

    var apiResponse = ApiResponse<T>(
      statusCode: httpResponse.statusCode,
      data: parsedData,
      headers: httpResponse.headers,
      rawBody: rawBody,
    );

    // Apply onResponse interceptors
    for (final interceptor in _interceptors) {
      apiResponse = (await interceptor.onResponse(apiResponse)) as ApiResponse<T>;
    }

    return apiResponse;
  }

  /// Handles internal connection / timeout errors and maps to [ApiException].
  Future<ApiResponse<T>> _handleException<T>(
    dynamic error,
    StackTrace stackTrace,
  ) async {
    if (error is ApiException) {
      throw error;
    }

    final ApiException mappedException;
    if (error is TimeoutException) {
      mappedException = RequestTimeoutException(
        'Request timed out. Please check your network connection.',
        cause: error,
        stackTrace: stackTrace,
      );
    } else if (error is SocketException) {
      mappedException = NetworkException(
        'Unable to reach server. Please check your internet connection.',
        cause: error,
        stackTrace: stackTrace,
      );
    } else {
      mappedException = ApiException(
        error.toString(),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    for (final interceptor in _interceptors) {
      final result = await interceptor.onError(mappedException);
      if (result is ApiResponse<T>) {
        return result;
      }
    }

    throw mappedException;
  }
}
