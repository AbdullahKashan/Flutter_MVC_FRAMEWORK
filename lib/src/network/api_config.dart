import 'interceptor.dart';

/// Global configuration options for the [ApiClient].
class ApiConfig {
  /// The base URL for all relative network endpoints (e.g. 'https://api.example.com/v1').
  final String baseUrl;

  /// Default headers to attach to every outgoing request.
  final Map<String, String> defaultHeaders;

  /// Default timeout duration for network requests.
  final Duration timeout;

  /// Whether to automatically log network traffic using [LoggingInterceptor].
  final bool loggingEnabled;

  /// Interceptors applied to requests and responses.
  final List<Interceptor> interceptors;

  const ApiConfig({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.timeout = const Duration(seconds: 30),
    this.loggingEnabled = false,
    this.interceptors = const [],
  });

  /// Creates a copy of this [ApiConfig] with optional modified parameters.
  ApiConfig copyWith({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    bool? loggingEnabled,
    List<Interceptor>? interceptors,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      timeout: timeout ?? this.timeout,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      interceptors: interceptors ?? this.interceptors,
    );
  }
}
