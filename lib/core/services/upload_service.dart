import 'dart:io';

import 'package:dio/dio.dart';
import '../constants/api_constant.dart';

/// Handles the two-step S3 pre-signed upload flow:
///   1. GET presigned URL from backend (authenticated Dio).
///   2. PUT file bytes directly to S3 (plain Dio, no auth headers).
///
/// Returns the `imageKey` string to include in subsequent create/update calls.
class UploadService {
  const UploadService(this._authDio);

  final Dio _authDio;

  // Separate Dio with NO interceptors for the direct S3 PUT.
  static final Dio _s3Dio = Dio(
    BaseOptions(
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<String> uploadCancelPhoto(File file, int taskId) =>
      _upload(file, category: 'cancel', entityId: taskId);

  Future<String> uploadShopPhoto(File file) =>
      _upload(file, category: 'shops', entityId: 0);

  /// [userId] must be the authenticated user's own id — the backend's
  /// `validateAndConfirmImageKey` ties the uploaded key's `profiles/<id>/`
  /// path to the caller, so an `entityId` of 0 fails the confirm step with 403.
  Future<String> uploadProfilePhoto(File file, int userId) =>
      _upload(file, category: 'profiles', entityId: userId);

  Future<String> _upload(
    File file, {
    required String category,
    required int entityId,
  }) async {
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;

    // Determine extension and MIME type from the file path.
    final rawExt = file.path.split('.').last.toLowerCase();
    final ext = const ['jpg', 'jpeg', 'png', 'webp'].contains(rawExt)
        ? rawExt
        : 'jpg';
    final mimeType = (ext == 'jpg' || ext == 'jpeg')
        ? 'image/jpeg'
        : ext == 'png'
            ? 'image/png'
            : 'image/webp';

    // Step 1 ── GET presigned URL from backend (auth token needed).
    final resp = await _authDio.get<Map<String, dynamic>>(
      ApiConstant.presignedUrlEndpoint,
      queryParameters: {
        'category': category,
        'entityId': entityId,
        'ext': ext,
        'mimeType': mimeType,
        'fileSize': fileSize,
      },
    );

    final body = resp.data!;
    // Backend returns the pre-signed PUT URL under `uploadUrl`; tolerate the
    // legacy `url` key too so this doesn't silently break on contract drift.
    final uploadUrl = (body['uploadUrl'] ?? body['url']) as String;
    final imageKey = body['imageKey'] as String;

    // Step 2 ── PUT file bytes directly to S3 (no auth header).
    await _s3Dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          'Content-Length': fileSize,
        },
        // Prevent Dio from adding its own Content-Type boundary.
        contentType: mimeType,
      ),
    );

    return imageKey;
  }
}
