import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'package:field_guard_re/core/network/dio_client.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/features/geofence/data/datasources/geofence_visit_datasource.dart';
import 'package:field_guard_re/features/geofence/data/models/geofence_visit.dart';

enum _GeofenceState { disarmed, armed, inside }

/// Serialises async sections so interleaved position fixes, recovery, the
/// watchdog tick, and queue writes can never corrupt persisted state.
///
/// NOT re-entrant: only the public entry points acquire it. Internal
/// `*Locked` helpers run inside an already-held section and must never
/// re-acquire (that would deadlock). [GeofenceVisitService.flushQueue] is the
/// one exception — it acquires the lock for its short queue-access sections
/// but is only ever invoked outside a held section (fire-and-forget / timer).
class _Mutex {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final prior = _tail;
    _tail = completer.future;
    return prior.then((_) => action()).whenComplete(completer.complete);
  }
}

/// Detects when a field agent enters/leaves the ~20 m geofence around the
/// shop of the active IN_PROGRESS task, and reports each completed visit to
/// the backend.
///
/// Designed as a recoverable background event-tracker rather than simple
/// in-memory detection:
///
///  * **Single source of truth** — fed only by [LiveTrackingService]'s
///    position stream; the map screens never trigger visit detection.
///  * **Serialised state** — a [_Mutex] guards every state mutation.
///  * **Persisted open visit** — the in-progress visit is mirrored to disk so
///    an app-kill / process-death mid-visit is recoverable.
///  * **Stale-anchor watchdog** — actively probes location while inside and
///    closes the visit `exitEstimated` if location becomes genuinely
///    unavailable (permission revoked / GPS off) without an app restart.
///  * **Persisted retry queue** — completed visits are queued on disk and
///    uploaded with exponential backoff; the queue survives restarts/reboots.
///  * **Jitter guards** — hysteresis, accuracy gating, sustained-exit
///    confirmation, min-stay filter, and teleport rejection.
///
/// Lifetime is coupled to the tracking session: detection is only armed while
/// a task is IN_PROGRESS (see `geofenceVisitSyncProvider`).
class GeofenceVisitService {
  GeofenceVisitService._();
  static final GeofenceVisitService instance = GeofenceVisitService._();

  // ── Tuning ─────────────────────────────────────────────────────────────
  /// Confirm ENTER at or below this distance from the shop. Also the radius
  /// drawn on the route map so the visible fence matches detection.
  ///
  /// 30 m (not 20) is the trigger zone: GPS carries 5-10 m error and saved
  /// shop coordinates are rarely pinpoint, so a tight 20 m fence misses real
  /// arrivals. The consecutive-fix + hysteresis logic still guards against
  /// false positives.
  static const enterRadiusMeters = 30.0;
  static const _enterRadius = enterRadiusMeters;

  /// Only treat the agent as OUTSIDE past this distance — the 30–40 m band is
  /// a hysteresis dead-zone so a jittery fix can't flap enter/exit.
  static const _exitRadius = 40.0;

  /// Ignore fixes whose accuracy is too coarse to trust against the fence.
  static const _maxAccuracy = 35.0;

  /// An exit is only confirmed after this many consecutive outside fixes …
  static const _exitConfirmFixes = 3;

  /// … or after this long continuously outside, whichever comes first.
  static const _exitConfirmWindow = Duration(seconds: 30);

  /// Visits shorter than this are discarded as boundary noise / drive-bys.
  static const _minStaySeconds = 45;

  /// Implied speed (m/s, ~216 km/h) above which a fix is a teleport/outlier.
  static const _maxImpliedSpeed = 60.0;

  /// While inside, the watchdog probes location this often.
  static const _watchdogInterval = Duration(seconds: 45);

  /// If no in-geofence fix has arrived for this long while inside, the anchor
  /// is considered stale and the visit is closed `exitEstimated`.
  static const _staleAnchorTimeout = Duration(minutes: 4);

  /// Give up on a queued record (mark DEAD) after this many upload attempts.
  static const _maxAttempts = 8;

  static const _kOpenVisitKey = 'geofence_open_visit';
  static const _kQueueKey = 'geofence_visit_queue';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Its own Dio (with the auth + refresh interceptors) so queued uploads
  /// work independent of any widget/provider being alive.
  late final GeofenceVisitDataSource _dataSource =
      GeofenceVisitDataSource(DioClient.createDio());

  final _Mutex _mutex = _Mutex();

  // ── Event callbacks ───────────────────────────────────────────────────────
  // Set by the app (e.g. a provider mounted in MainShell) to react to live
  // geofence transitions — notifications, map UI, auto-complete. Kept as plain
  // function fields so the service stays framework-agnostic. Fired outside the
  // mutex via microtask so a slow listener can't stall detection or deadlock.

  /// Called when the agent ENTERS the geofence (a visit opens). [taskId] is the
  /// active task.
  void Function(int taskId)? onEnter;

  /// Called when the agent EXITS after a real, observed exit (not an
  /// app-kill/permission-loss estimate). [taskId] is the task whose visit just
  /// closed. This is the signal used to auto-complete the task.
  void Function(int taskId)? onRealExit;

  /// Fired when a queued visit is successfully uploaded to the backend (i.e.
  /// the network round-trip just succeeded). The app uses this as a
  /// "connectivity is back for this task" trigger to retry any auto-complete
  /// PATCH that failed earlier while offline.
  void Function(int taskId)? onVisitUploaded;

  // ── Live detection state ────────────────────────────────────────────────
  _GeofenceState _state = _GeofenceState.disarmed;
  int? _armedTaskId;
  int? _armedShopId;
  double? _shopLat;
  double? _shopLng;

  OpenVisit? _openVisit;

  int _outsideCount = 0;
  DateTime? _firstOutsideAt;

  // Teleport rejection — last accepted fix + run of rejected outliers.
  double? _lastFixLat;
  double? _lastFixLng;
  DateTime? _lastFixAt;
  int _rejectStreak = 0;

  Timer? _watchdog;

  // ── Upload state ────────────────────────────────────────────────────────
  bool _flushing = false;
  Timer? _retryTimer;
  int _retryBackoffIndex = 0;

  /// Set on logout/session-expiry — suppresses uploads (so queued visits
  /// don't fire under a cleared or a different user's token) until the next
  /// session arms a task or [recover] runs.
  bool _stopped = false;

  /// The task id whose geofence the agent is *currently inside*, or `null` if
  /// not inside any. Lets UI rebuilt from scratch (e.g. after the app returns
  /// from background) know the user has already arrived — so it won't redraw a
  /// route to a destination they're already standing at.
  int? get insideTaskId =>
      _state == _GeofenceState.inside ? _armedTaskId : null;

  // ── Arming (public entry points — acquire the lock) ───────────────────────

  /// Arms the geofence for the active task's shop. Idempotent — re-arming the
  /// same task is a no-op. Arming a *different* task while the agent is still
  /// inside the previous geofence closes the previous visit first.
  Future<void> arm({
    required int taskId,
    required int? shopId,
    required double shopLat,
    required double shopLng,
  }) =>
      _mutex.run(() async {
        _stopped = false; // a fresh session is active
        if (_armedTaskId == taskId && _state != _GeofenceState.disarmed) {
          _log('arm: already armed task=$taskId state=$_state — no-op');
          return; // already armed for this task
        }
        _log('arm: task=$taskId shop=$shopId @($shopLat,$shopLng) '
            'radius=${_enterRadius}m');

        // Switching tasks while inside → close the previous visit deliberately.
        final previous = _detachOpenVisit();

        _armedTaskId = taskId;
        _armedShopId = shopId;
        _shopLat = shopLat;
        _shopLng = shopLng;
        _state = _GeofenceState.armed;
        _resetDetection();

        if (previous != null) {
          await _closeAndEnqueueLocked(
            previous,
            exitedAt: DateTime.now().toUtc(),
            exitLat: previous.lastInsideLatitude,
            exitLng: previous.lastInsideLongitude,
            exitEstimated: false,
          );
        }
      });

  /// Disarms detection — called when no task is IN_PROGRESS (task completed,
  /// cancelled, or none active). A task ending is a deliberate end-of-visit,
  /// so any open visit is closed and sent immediately.
  Future<void> disarm() => _mutex.run(() async {
        if (_state == _GeofenceState.disarmed) return;
        _log('disarm: task=$_armedTaskId state=$_state '
            '(open visit will close if inside)');

        final open = _detachOpenVisit();

        _state = _GeofenceState.disarmed;
        _armedTaskId = null;
        _armedShopId = null;
        _shopLat = null;
        _shopLng = null;
        _resetDetection();

        if (open != null) {
          await _closeAndEnqueueLocked(
            open,
            exitedAt: DateTime.now().toUtc(),
            exitLat: open.lastInsideLatitude,
            exitLng: open.lastInsideLongitude,
            exitEstimated: false,
          );
        }
      });

  /// Detaches the in-memory open visit (if inside) and stops the watchdog,
  /// synchronously — callers finish their state mutation, then `await` the
  /// close. Returns null when not inside.
  OpenVisit? _detachOpenVisit() {
    _stopWatchdog();
    if (_state != _GeofenceState.inside) return null;
    final ov = _openVisit;
    _openVisit = null;
    return ov;
  }

  void _resetDetection() {
    _outsideCount = 0;
    _firstOutsideAt = null;
    _lastFixLat = null;
    _lastFixLng = null;
    _lastFixAt = null;
    _rejectStreak = 0;
  }

  /// Halts detection and uploads for the current session — call on logout /
  /// session expiry. The persisted open visit and retry queue are deliberately
  /// left on disk so they survive logout/login and are recovered (estimated
  /// close) by the next [recover]. The open visit is NOT closed here: a logout
  /// is an interruption, not a real exit.
  Future<void> stop() {
    _stopped = true;
    _stopWatchdog();
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryBackoffIndex = 0;
    return _mutex.run(() async {
      _state = _GeofenceState.disarmed;
      _armedTaskId = null;
      _armedShopId = null;
      _shopLat = null;
      _shopLng = null;
      _openVisit = null; // disk copy remains for recovery
      _resetDetection();
    });
  }

  // ── Detection (public entry point — acquires the lock) ────────────────────

  /// Feed every GPS fix from [LiveTrackingService] here. No-op while
  /// disarmed; ignores fixes too coarse or physically implausible to trust.
  Future<void> onPositionUpdate(Position pos) =>
      _mutex.run(() => _onPositionLocked(pos));

  Future<void> _onPositionLocked(Position pos) async {
    if (_state == _GeofenceState.disarmed) {
      _log('fix ignored: disarmed (no IN_PROGRESS task / tracking off?)');
      return;
    }
    if (pos.accuracy > _maxAccuracy) {
      _log('fix rejected: accuracy ${pos.accuracy.toStringAsFixed(0)}m '
          '> ${_maxAccuracy}m gate');
      return; // accuracy gate
    }

    // Teleport rejection — drop a single physically-impossible jump, but
    // accept a sustained relocation (2+ consecutive) so we don't lock up.
    final ts = pos.timestamp.toUtc();
    if (_lastFixAt != null && _lastFixLat != null && _lastFixLng != null) {
      final dt = ts.difference(_lastFixAt!).inMilliseconds / 1000.0;
      if (dt > 0) {
        final moved = Geolocator.distanceBetween(
          _lastFixLat!, _lastFixLng!, pos.latitude, pos.longitude,
        );
        if (moved / dt > _maxImpliedSpeed) {
          _rejectStreak++;
          if (_rejectStreak < 2) return; // single outlier — discard
        }
      }
    }
    _rejectStreak = 0;
    _lastFixLat = pos.latitude;
    _lastFixLng = pos.longitude;
    _lastFixAt = ts;

    final shopLat = _shopLat;
    final shopLng = _shopLng;
    if (shopLat == null || shopLng == null) return;

    final dist = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, shopLat, shopLng,
    );
    _log('fix: dist=${dist.toStringAsFixed(1)}m '
        'acc=${pos.accuracy.toStringAsFixed(0)}m state=$_state '
        '(enter<=${_enterRadius}m exit>${_exitRadius}m)');

    switch (_state) {
      case _GeofenceState.disarmed:
        return;

      case _GeofenceState.armed:
        if (dist <= _enterRadius) {
          _log('ENTER confirmed @ ${dist.toStringAsFixed(1)}m');
          await _enterLocked(pos);
        }

      case _GeofenceState.inside:
        if (dist <= _exitRadius) {
          // Still inside (incl. the hysteresis band) — refresh the last known
          // in-geofence fix used for crash/permission-loss exit estimation.
          _outsideCount = 0;
          _firstOutsideAt = null;
          final ov = _openVisit;
          if (ov != null) {
            ov.lastInsideLatitude = pos.latitude;
            ov.lastInsideLongitude = pos.longitude;
            ov.lastInsideAt = ts;
            await _persistOpenVisit();
          }
        } else {
          // Past the exit threshold — require sustained confirmation before
          // closing so a single jittery outside fix doesn't end the visit.
          _outsideCount++;
          _firstOutsideAt ??= DateTime.now();
          final longEnough =
              DateTime.now().difference(_firstOutsideAt!) >= _exitConfirmWindow;
          if (_outsideCount >= _exitConfirmFixes || longEnough) {
            _log('EXIT confirmed @ ${dist.toStringAsFixed(1)}m '
                '(outsideCount=$_outsideCount)');
            final ov = _openVisit;
            _openVisit = null;
            _state = _GeofenceState.armed; // re-armable → re-entry = new visit
            _outsideCount = 0;
            _firstOutsideAt = null;
            _stopWatchdog();
            if (ov != null) {
              await _closeAndEnqueueLocked(
                ov,
                exitedAt: ts,
                exitLat: pos.latitude,
                exitLng: pos.longitude,
                exitEstimated: false,
              );
              // Real, observed exit after a genuine entry — the signal the app
              // uses to auto-complete the task. Fired off the mutex.
              final taskId = ov.taskId;
              final cb = onRealExit;
              if (cb != null) scheduleMicrotask(() => cb(taskId));
            }
          }
        }
    }
  }

  Future<void> _enterLocked(Position pos) async {
    final ts = pos.timestamp.toUtc();
    _openVisit = OpenVisit(
      visitId: _uuidV4(),
      taskId: _armedTaskId!,
      shopId: _armedShopId,
      enteredAt: ts,
      enterLatitude: pos.latitude,
      enterLongitude: pos.longitude,
      lastInsideLatitude: pos.latitude,
      lastInsideLongitude: pos.longitude,
      lastInsideAt: ts,
    );
    _state = _GeofenceState.inside;
    _outsideCount = 0;
    _firstOutsideAt = null;
    _log('visit opened: id=${_openVisit!.visitId} task=$_armedTaskId '
        '— now INSIDE, watchdog started');
    await _persistOpenVisit();
    _startWatchdog();

    // Notify listeners off the mutex so a slow handler can't stall detection.
    final taskId = _openVisit!.taskId;
    final cb = onEnter;
    if (cb != null) scheduleMicrotask(() => cb(taskId));
  }

  // ── Stale-anchor watchdog ─────────────────────────────────────────────────

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog =
        Timer.periodic(_watchdogInterval, (_) => _mutex.run(_watchdogTickLocked));
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  /// While inside, detects that location has become genuinely unavailable
  /// (GPS off / permission revoked) or that fixes have silently stopped, and
  /// closes the visit `exitEstimated` from the last in-geofence fix — covering
  /// interruption *without* needing an app restart.
  Future<void> _watchdogTickLocked() async {
    if (_state != _GeofenceState.inside) {
      _stopWatchdog();
      return;
    }
    final ov = _openVisit;
    if (ov == null) {
      _stopWatchdog();
      return;
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    final permOk = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
    final stale =
        DateTime.now().toUtc().difference(ov.lastInsideAt) > _staleAnchorTimeout;

    if (serviceOn && permOk && !stale) return; // still healthy

    _openVisit = null;
    _state = _GeofenceState.armed;
    _outsideCount = 0;
    _firstOutsideAt = null;
    _stopWatchdog();
    await _closeAndEnqueueLocked(
      ov,
      exitedAt: ov.lastInsideAt,
      exitLat: ov.lastInsideLatitude,
      exitLng: ov.lastInsideLongitude,
      exitEstimated: true,
    );
  }

  // ── Recovery (public entry point) ─────────────────────────────────────────

  /// Call once on app launch. If a visit was left open by an app-kill /
  /// process-death the real exit was never observed — close it at the last
  /// persisted in-geofence fix, flagged `exitEstimated: true`. Then flush any
  /// visits queued before the previous run ended.
  Future<void> recover() async {
    await _mutex.run(() async {
      _stopped = false; // new app session
      final raw = await _storage.read(key: _kOpenVisitKey);
      if (raw == null || raw.isEmpty) return;
      try {
        final ov = OpenVisit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        await _storage.delete(key: _kOpenVisitKey);
        await _closeAndEnqueueLocked(
          ov,
          exitedAt: ov.lastInsideAt,
          exitLat: ov.lastInsideLatitude,
          exitLng: ov.lastInsideLongitude,
          exitEstimated: true,
        );
      } catch (_) {
        // Corrupt record — drop it rather than wedge every launch.
        await _storage.delete(key: _kOpenVisitKey);
      }
    });
    await flushQueue();
  }

  // ── Closing & queueing (lock-held context only) ───────────────────────────

  Future<void> _closeAndEnqueueLocked(
    OpenVisit ov, {
    required DateTime exitedAt,
    required double exitLat,
    required double exitLng,
    required bool exitEstimated,
  }) async {
    await _storage.delete(key: _kOpenVisitKey);
    final visit = ov.close(
      exitedAt: exitedAt,
      exitLatitude: exitLat,
      exitLongitude: exitLng,
      exitEstimated: exitEstimated,
    );
    // Min-stay filter — drop boundary noise and drive-bys.
    if (visit.stayDurationSeconds < _minStaySeconds) {
      _log('visit DROPPED: stay=${visit.stayDurationSeconds}s '
          '< min ${_minStaySeconds}s (id=${visit.visitId})');
      return;
    }

    _log('visit closed & queued: id=${visit.visitId} '
        'stay=${visit.stayDurationSeconds}s estimated=$exitEstimated '
        '— uploading');
    final queue = await _readQueue();
    queue.add(visit);
    await _writeQueue(queue);
    // Outside-the-lock upload kicks off after this section releases.
    unawaited(flushQueue());
  }

  Future<void> _persistOpenVisit() async {
    final ov = _openVisit;
    if (ov == null) {
      await _storage.delete(key: _kOpenVisitKey);
      return;
    }
    await _storage.write(key: _kOpenVisitKey, value: jsonEncode(ov.toJson()));
  }

  // ── Upload queue ──────────────────────────────────────────────────────────

  /// Uploads every queued visit oldest-first. Successful records are removed;
  /// records that hit a permanent error or [_maxAttempts] are marked DEAD
  /// (kept on disk but skipped). A backoff retry is scheduled on transient
  /// failure. Network calls run *outside* the lock; only the short
  /// read-modify-write of the queue is serialised. Re-entrant calls no-op.
  Future<void> flushQueue() async {
    if (_stopped || _flushing) return;
    _flushing = true;
    try {
      while (true) {
        if (_stopped) return; // session ended mid-flush
        // Pick the next still-uploadable record under the lock.
        final visit = await _mutex.run<GeofenceVisit?>(() async {
          final queue = await _readQueue();
          for (final v in queue) {
            if (v.attempts < _maxAttempts) return v;
          }
          return null;
        });
        if (visit == null) break;

        final result = await _dataSource.submit(visit); // network — no lock
        _log('upload result=$result for id=${visit.visitId}');

        if (result == SubmitResult.success) {
          // Network just succeeded for this task — signal listeners so they
          // can retry any auto-complete PATCH that failed earlier offline.
          final taskId = visit.taskId;
          final cb = onVisitUploaded;
          if (cb != null) scheduleMicrotask(() => cb(taskId));
        }

        final transient = await _mutex.run<bool>(() async {
          final queue = await _readQueue();
          final idx = queue.indexWhere((v) => v.visitId == visit.visitId);
          if (idx < 0) return false; // already gone
          switch (result) {
            case SubmitResult.success:
              queue.removeAt(idx);
            case SubmitResult.permanent:
              queue[idx].attempts = _maxAttempts; // mark DEAD
            case SubmitResult.transient:
              queue[idx].attempts++;
          }
          await _writeQueue(queue);
          return result == SubmitResult.transient;
        });

        if (transient) {
          // Network is down — stop now, retry the whole queue with backoff
          // (unless the session ended while the request was in flight).
          if (!_stopped) _scheduleRetry();
          return;
        }
      }
      // Drained (or only DEAD records remain) — cancel any pending retry.
      _retryTimer?.cancel();
      _retryBackoffIndex = 0;
    } finally {
      _flushing = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    const delays = [
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 30),
    ];
    final delay = delays[_retryBackoffIndex.clamp(0, delays.length - 1)];
    if (_retryBackoffIndex < delays.length - 1) _retryBackoffIndex++;
    _retryTimer = Timer(delay, flushQueue);
  }

  Future<List<GeofenceVisit>> _readQueue() async {
    final raw = await _storage.read(key: _kQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GeofenceVisit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<GeofenceVisit> queue) async {
    if (queue.isEmpty) {
      await _storage.delete(key: _kQueueKey);
      return;
    }
    await _storage.write(
      key: _kQueueKey,
      value: jsonEncode(queue.map((e) => e.toJson()).toList()),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Debug-only trace of the detection pipeline. Compiled out of release
  /// builds (guarded by [kDebugMode]); grep logcat for `[geofence]`.
  static void _log(String msg) {
    // Mirror to the console (debug) AND the on-device file so geofence traces
    // can be reviewed in the field without a laptop attached.
    if (kDebugMode) debugPrint('[geofence] $msg');
    DebugLogService.instance.log('[geofence] $msg');
  }

  /// Generates a RFC-4122 v4 UUID using a cryptographic RNG — used as the
  /// per-visit idempotency key the backend dedupes on.
  static String _uuidV4() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
