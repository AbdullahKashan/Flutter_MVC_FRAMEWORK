import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth/auth_interceptor.dart';
import 'auth/auth_manager.dart';
import 'auth/token_manager.dart';
import 'dependency/service_locator.dart';
import 'network/api_client.dart';
import 'network/api_config.dart';
import 'network/interceptor.dart';
import 'storage/secure_storage.dart';
import 'storage/storage.dart';

/// Configuration options for automated authentication handling.
class AuthConfig {
  /// The relative or absolute endpoint for logging in.
  final String? loginEndpoint;

  /// The relative or absolute endpoint for refreshing expired tokens.
  final String? refreshEndpoint;

  /// The JSON key for the access token in authentication responses.
  final String tokenKey;

  /// The JSON key for the refresh token in authentication responses.
  final String refreshTokenKey;

  /// Header authorization prefix (defaults to 'Bearer').
  final String headerPrefix;

  const AuthConfig({
    this.loginEndpoint,
    this.refreshEndpoint,
    this.tokenKey = 'access_token',
    this.refreshTokenKey = 'refresh_token',
    this.headerPrefix = 'Bearer',
  });
}

/// Global framework orchestrator and entry point for flutter_mvc.
class MVC {
  MVC._();

  static bool _initialized = false;

  /// Whether [MVC.initialize] has been called.
  static bool get isInitialized => _initialized;

  /// Resolves the global [ApiClient] instance.
  static ApiClient get api => ServiceLocator().get<ApiClient>();

  /// Resolves the global [AuthManager] instance.
  static AuthManager get auth => ServiceLocator().get<AuthManager>();

  /// Resolves the active [TokenManager] instance.
  static TokenManager get tokens => ServiceLocator().get<TokenManager>();

  /// Resolves the active [Storage] instance.
  static Storage get storage => ServiceLocator().get<Storage>();

  /// Resolves the active [SecureStorage] instance.
  static SecureStorage get secureStorage => ServiceLocator().get<SecureStorage>();

  /// Accesses the underlying [ServiceLocator] singleton.
  static ServiceLocator get locator => ServiceLocator();

  /// Resolves a dependency of type [T] from the [ServiceLocator].
  static T locate<T>() => ServiceLocator().get<T>();

  /// Registers an instance into the [ServiceLocator].
  static void register<T>(T instance) => ServiceLocator().register<T>(instance);

  /// Registers a lazy singleton factory into the [ServiceLocator].
  static void registerLazySingleton<T>(T Function() factory) =>
      ServiceLocator().registerLazySingleton<T>(factory);

  /// Registers a factory into the [ServiceLocator].
  static void registerFactory<T>(T Function() factory) =>
      ServiceLocator().registerFactory<T>(factory);

  /// Initializes the flutter_mvc framework and its core subsystems.
  static Future<void> initialize({
    required String baseUrl,
    ApiConfig? config,
    AuthConfig? auth,
    TokenRefreshHandler? onRefreshToken,
    VoidCallback? onSessionExpired,
    Storage? storage,
    SecureStorage? secureStorage,
    List<Interceptor>? interceptors,
    bool logging = false,
    http.Client? httpClient,
  }) async {
    final effectiveStorage = storage ?? MemoryStorage();
    final effectiveSecureStorage = secureStorage ?? DefaultSecureStorage();

    final tokenManager = TokenManager(storage: effectiveSecureStorage);

    TokenRefreshHandler? refreshHandler = onRefreshToken;
    if (refreshHandler == null && auth?.refreshEndpoint != null) {
      refreshHandler = (refreshToken, client) async {
        try {
          final res = await client.post<dynamic>(
            auth!.refreshEndpoint!,
            body: {auth.refreshTokenKey: refreshToken},
            requiresAuth: false,
          );
          if (res.data is Map) {
            final map = Map<String, dynamic>.from(res.data as Map);
            final newAccessToken = (map[auth.tokenKey] ?? '').toString();
            final newRefreshToken = map[auth.refreshTokenKey]?.toString() ?? refreshToken;
            return TokenPair(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
              tokenType: auth.headerPrefix,
            );
          }
        } catch (_) {}
        return null;
      };
    }

    final authManager = AuthManager(
      tokenManager: tokenManager,
      onRefreshToken: refreshHandler,
      onSessionExpired: onSessionExpired,
    );
    await authManager.initialize();

    final authInterceptor = AuthInterceptor(
      authManager: authManager,
      getClient: () => api,
    );

    final mergedInterceptors = <Interceptor>[
      authInterceptor,
      ...?interceptors,
      ...?config?.interceptors,
    ];

    final apiConfig = (config ?? const ApiConfig(baseUrl: '')).copyWith(
      baseUrl: baseUrl,
      loggingEnabled: logging || (config?.loggingEnabled ?? false),
      interceptors: mergedInterceptors,
    );

    final apiClient = ApiClient(
      config: apiConfig,
      httpClient: httpClient,
    );

    final sl = ServiceLocator();
    sl.register<Storage>(effectiveStorage);
    sl.register<SecureStorage>(effectiveSecureStorage);
    sl.register<TokenManager>(tokenManager);
    sl.register<AuthManager>(authManager);
    sl.register<ApiClient>(apiClient);

    _initialized = true;
  }

  /// Resets the framework state, clears dependency registrations, and closes open clients.
  static void reset() {
    if (ServiceLocator().isRegistered<ApiClient>()) {
      try {
        ServiceLocator().get<ApiClient>().close();
      } catch (_) {}
    }
    ServiceLocator().reset();
    _initialized = false;
  }
}
