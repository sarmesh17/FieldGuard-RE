import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/services/token_storage.dart';

/// Centralised token-refresh logic shared by [ErrorInterceptor] and the
/// app-lifecycle observer in [MyApp].
class TokenRefreshService {
  /// How many seconds before actual expiry we treat the token as "expired"
  /// and trigger a proactive refresh.  Covers clock skew + round-trip time.
  static const int _expiryBufferSeconds = 30;

  /// Single-flight guard: only one refresh may be in-flight at a time.
  static Future<String?>? _ongoingRefresh;

  /// Proactively refresh the access token if it is expired or will expire
  /// within [_expiryBufferSeconds].  Safe to call on every app resume.
  ///
  /// Returns `true` if the token is valid (refreshed or still fresh).
  /// Returns `false` if the refresh token is also expired / missing (caller
  /// should redirect to login).
  static Future<bool> refreshIfNeeded() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && !_isJwtExpiredOrSoon(accessToken)) {
      return true;
    }
    final newToken = await (_ongoingRefresh ??= _doRefresh());
    _ongoingRefresh = null;
    return newToken != null;
  }

  /// Force a refresh regardless of expiry state (used by [ErrorInterceptor]
  /// after receiving a 401).
  ///
  /// Returns the new access token, or `null` when the refresh token is
  /// missing / the refresh endpoint returned an auth error.
  static Future<String?> forceRefresh() async {
    final newToken = await (_ongoingRefresh ??= _doRefresh());
    _ongoingRefresh = null;
    return newToken;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await Dio().post(
        ApiConstant.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      // Backend may wrap in a `data` envelope (same as login endpoint).
      final raw = response.data;
      final Map<String, dynamic> body;
      if (raw is Map<String, dynamic>) {
        final inner = raw['data'];
        body = inner is Map<String, dynamic> ? inner : raw;
      } else {
        return null;
      }

      final newAccessToken = body['accessToken'] as String?;
      final newRefreshToken =
          (body['refreshToken'] as String?) ?? refreshToken;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return null;
      }

      await TokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Treat auth errors as definitive session expiry.
      if (status == 401 || status == 403) {
        return null;
      }
      // Network / server errors: keep existing tokens untouched.
      rethrow;
    }
  }

  /// Decode the JWT payload and return `true` if it will expire within
  /// [_expiryBufferSeconds] (or is already expired / malformed).
  static bool _isJwtExpiredOrSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (exp as int) * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(
            expiry.subtract(const Duration(seconds: _expiryBufferSeconds)),
          );
    } catch (_) {
      return true;
    }
  }
}
