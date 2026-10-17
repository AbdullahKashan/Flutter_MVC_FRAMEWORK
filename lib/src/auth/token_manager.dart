import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';
import '../storage/storage.dart';

/// Encapsulates authentication credentials and expiration data.
@immutable
class TokenPair {
  /// The access token used in authorization headers.
  final String accessToken;

  /// The refresh token used to obtain a new access token.
  final String? refreshToken;

  /// The HTTP authorization scheme (default: 'Bearer').
  final String tokenType;

  /// Optional expiration timestamp.
  final DateTime? expiresAt;

  const TokenPair({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
  });

  /// Returns true if an expiration time is present and has elapsed.
  bool get isExpired {
    if (expiresAt == null) return false;
    // Buffer by 5 seconds to prevent race conditions during network latency
    return DateTime.now().isAfter(expiresAt!.subtract(const Duration(seconds: 5)));
  }

  /// Converts this token pair to a JSON map.
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        'token_type': tokenType,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };

  /// Constructs a [TokenPair] from a JSON map.
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    DateTime? expires;
    if (json['expires_at'] != null) {
      expires = DateTime.tryParse(json['expires_at'].toString());
    } else if (json['expires_in'] != null) {
      final seconds = int.tryParse(json['expires_in'].toString());
      if (seconds != null) {
        expires = DateTime.now().add(Duration(seconds: seconds));
      }
    }

    return TokenPair(
      accessToken: (json['access_token'] ?? json['accessToken'] ?? '').toString(),
      refreshToken: json['refresh_token']?.toString() ?? json['refreshToken']?.toString(),
      tokenType: json['token_type']?.toString() ?? json['tokenType']?.toString() ?? 'Bearer',
      expiresAt: expires,
    );
  }

  @override
  String toString() =>
      'TokenPair(tokenType: $tokenType, hasRefreshToken: ${refreshToken != null}, isExpired: $isExpired)';
}

/// Manages retrieval, storage, and lifecycle of authentication tokens.
class TokenManager {
  static const String _storageKey = 'flutter_mvc_auth_tokens';

  final Storage _storage;
  TokenPair? _cachedTokens;

  TokenManager({Storage? storage}) : _storage = storage ?? DefaultSecureStorage();

  /// Saves the active token pair.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String tokenType = 'Bearer',
    DateTime? expiresAt,
  }) async {
    final tokens = TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresAt: expiresAt,
    );
    await saveTokenPair(tokens);
  }

  /// Saves a [TokenPair] instance to storage and local cache.
  Future<void> saveTokenPair(TokenPair tokens) async {
    _cachedTokens = tokens;
    await _storage.writeJson(_storageKey, tokens.toJson());
  }

  /// Retrieves the active [TokenPair], reading from storage if not cached.
  Future<TokenPair?> getTokens() async {
    if (_cachedTokens != null) {
      return _cachedTokens;
    }

    final json = await _storage.readJson(_storageKey);
    if (json != null) {
      _cachedTokens = TokenPair.fromJson(json);
      return _cachedTokens;
    }
    return null;
  }

  /// Retrieves the raw access token string.
  Future<String?> getAccessToken() async {
    final tokens = await getTokens();
    return tokens?.accessToken;
  }

  /// Retrieves the refresh token string.
  Future<String?> getRefreshToken() async {
    final tokens = await getTokens();
    return tokens?.refreshToken;
  }

  /// Checks if an access token exists and is not expired.
  Future<bool> hasValidToken() async {
    final tokens = await getTokens();
    if (tokens == null || tokens.accessToken.isEmpty) {
      return false;
    }
    return !tokens.isExpired;
  }

  /// Clears stored and cached tokens.
  Future<void> clearTokens() async {
    _cachedTokens = null;
    await _storage.delete(_storageKey);
  }
}
