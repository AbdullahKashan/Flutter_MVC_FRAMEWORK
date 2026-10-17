import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import 'token_manager.dart';

/// Represents the current authentication state of the application.
enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
}

/// Callback signature for handling refresh-token requests.
typedef TokenRefreshHandler = Future<TokenPair?> Function(
  String refreshToken,
  ApiClient client,
);

/// Coordinates authentication state, token storage, and session lifecycles.
class AuthManager extends ChangeNotifier {
  final TokenManager tokenManager;
  final TokenRefreshHandler? onRefreshToken;
  final VoidCallback? onSessionExpired;

  AuthStatus _status = AuthStatus.unauthenticated;
  Completer<TokenPair?>? _refreshCompleter;

  AuthManager({
    TokenManager? tokenManager,
    this.onRefreshToken,
    this.onSessionExpired,
  }) : tokenManager = tokenManager ?? TokenManager();

  /// Current authentication status.
  AuthStatus get status => _status;

  /// Returns true if currently authenticated.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Returns true if currently in the process of authenticating.
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  /// Returns true if unauthenticated.
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  /// Initializes authentication state by inspecting existing tokens.
  Future<void> initialize() async {
    final hasToken = await tokenManager.hasValidToken();
    _status = hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Sets tokens and marks status as authenticated.
  Future<void> login(TokenPair tokens) async {
    await tokenManager.saveTokenPair(tokens);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Clears stored tokens and marks status as unauthenticated.
  Future<void> logout() async {
    await tokenManager.clearTokens();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refreshes the access token using the stored refresh token.
  /// If a refresh is already in progress, subsequent callers will await the same future.
  Future<TokenPair?> refreshToken(ApiClient client) async {
    // If a refresh operation is already in progress, join it
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<TokenPair?>();

    try {
      final currentRefreshToken = await tokenManager.getRefreshToken();
      if (currentRefreshToken == null || onRefreshToken == null) {
        await _handleSessionExpiry();
        _refreshCompleter!.complete(null);
        return null;
      }

      final newTokens = await onRefreshToken!(currentRefreshToken, client);
      if (newTokens != null) {
        await tokenManager.saveTokenPair(newTokens);
        _status = AuthStatus.authenticated;
        notifyListeners();
        _refreshCompleter!.complete(newTokens);
        return newTokens;
      } else {
        await _handleSessionExpiry();
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      await _handleSessionExpiry();
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // Clear completer reference once finished
      final c = _refreshCompleter;
      Timer.run(() {
        if (_refreshCompleter == c) {
          _refreshCompleter = null;
        }
      });
    }
  }

  Future<void> _handleSessionExpiry() async {
    await logout();
    onSessionExpired?.call();
  }
}
