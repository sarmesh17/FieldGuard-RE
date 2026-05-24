import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Persists debug traces (geofence detection, auto-complete, etc.) to a file
/// on the device so they can be reviewed in the field WITHOUT a laptop /
/// `flutter logs` attached. Walk to the shop, trigger enter/exit, come back,
/// then read or share the log.
///
/// Writes are batched and flushed on a short timer so a burst of GPS fixes
/// doesn't hammer the disk. Everything is best-effort — logging must never
/// throw into the caller.
class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  static const _fileName = 'fieldguard_debug.log';
  static const _flushAfter = Duration(seconds: 2);
  static const _maxBytes = 512 * 1024; // ~0.5 MB cap; trims oldest on rollover

  File? _file;
  final StringBuffer _buffer = StringBuffer();
  Timer? _flushTimer;
  bool _initialised = false;

  /// Resolves the log file path. Uses external storage on Android (so it's
  /// reachable via a file manager) and the documents dir elsewhere.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      Directory dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      _file = File('${dir.path}/$_fileName');
      await log('──── log opened ${DateTime.now().toIso8601String()} ────');
    } catch (e) {
      if (kDebugMode) debugPrint('[debuglog] init failed: $e');
    }
  }

  /// Path of the log file (null until [init] ran), useful to show the user
  /// where it lives.
  String? get path => _file?.path;

  /// Appends a timestamped line. Also mirrors to the console in debug builds.
  Future<void> log(String msg) async {
    final line = '${DateTime.now().toIso8601String()}  $msg';
    if (kDebugMode) debugPrint(line);
    _buffer.writeln(line);
    _flushTimer ??= Timer(_flushAfter, _flush);
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final file = _file;
    if (file == null || _buffer.isEmpty) return;
    final chunk = _buffer.toString();
    _buffer.clear();
    try {
      await file.writeAsString(chunk, mode: FileMode.append, flush: true);
      // Rollover: if the file outgrew the cap, keep only the tail.
      if (await file.length() > _maxBytes) {
        final content = await file.readAsString();
        await file.writeAsString(
          content.substring(content.length - _maxBytes ~/ 2),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[debuglog] flush failed: $e');
    }
  }

  /// Returns the full log text (flushing any pending lines first).
  Future<String> read() async {
    await _flush();
    final file = _file;
    if (file == null || !await file.exists()) return '(no log yet)';
    try {
      return await file.readAsString();
    } catch (e) {
      return '(read failed: $e)';
    }
  }

  /// Opens the system share sheet with the log file attached, so it can be
  /// sent to a laptop (email / WhatsApp / Drive) from the phone itself.
  Future<void> share() async {
    await _flush();
    final file = _file;
    if (file == null || !await file.exists()) return;
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'FieldGuard debug log');
    } catch (e) {
      if (kDebugMode) debugPrint('[debuglog] share failed: $e');
    }
  }

  /// Wipes the log so a fresh test run starts clean.
  Future<void> clear() async {
    _buffer.clear();
    final file = _file;
    if (file == null) return;
    try {
      if (await file.exists()) await file.writeAsString('');
    } catch (_) {/* best effort */}
  }
}
