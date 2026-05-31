import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';

/// Fetches the current legal document version from the server.
/// Public endpoint — no auth required.
/// Falls back to today's date (ISO) if the request fails so login is
/// never blocked by a legal-version network error.
final legalVersionProvider = FutureProvider<String>((ref) async {
  try {
    final res = await Dio().get<Map<String, dynamic>>(
      ApiConstant.legalVersionEndpoint,
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final version = res.data?['version'];
    if (version is String && version.isNotEmpty) return version;
  } catch (_) {
    // Network error — fall back to today so login is never blocked.
  }
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});
