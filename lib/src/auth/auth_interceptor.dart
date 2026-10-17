import 'dart:async';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/interceptor.dart';
import 'auth_manager.dart';

/// Interceptor that handles injection of Bearer authorization headers
/// and automatic token refreshing upon receiving 401 Unauthorized responses.
class AuthInterceptor extends Interceptor {
  final AuthManager authManager;
  final ApiClient Function() getClient;

  AuthInterceptor({
    required this.authManager,
    required this.getClient,
  });

  @override
  FutureOr<RequestOptions> onRequest(RequestOptions options) async {
    if (!options.requiresAuth) {
      return options;
    }

    final token = await authManager.tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final updatedHeaders = Map<String, String>.from(options.headers);
      updatedHeaders['Authorization'] = 'Bearer $token';
      return options.copyWith(headers: updatedHeaders);
    }

    return options;
  }

  @override
  FutureOr<dynamic> onError(ApiException error) async {
    // Only attempt refresh on 401 Unauthorized
    if (error.statusCode != 401) {
      return null;
    }

    final client = getClient();
    final newTokens = await authManager.refreshToken(client);

    if (newTokens != null) {
      // Token was refreshed successfully.
      // Callers can catch and retry, or the client handles retry.
      return null;
    }

    return null;
  }
}
