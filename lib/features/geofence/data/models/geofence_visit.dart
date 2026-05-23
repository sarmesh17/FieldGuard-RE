/// A completed shop-visit record, ready to POST to the backend. Also the
/// unit stored in the on-disk retry queue, so it carries a local [attempts]
/// counter that is never sent over the wire.
class GeofenceVisit {
  final String visitId;
  final int taskId;
  final int? shopId;
  final DateTime enteredAt;
  final DateTime exitedAt;
  final int stayDurationSeconds;
  final bool exitEstimated;
  final double enterLatitude;
  final double enterLongitude;
  final double exitLatitude;
  final double exitLongitude;

  /// Local-only upload-attempt counter. Not part of the request payload;
  /// once it reaches the service's max it marks the record DEAD.
  int attempts;

  GeofenceVisit({
    required this.visitId,
    required this.taskId,
    required this.shopId,
    required this.enteredAt,
    required this.exitedAt,
    required this.stayDurationSeconds,
    required this.exitEstimated,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.exitLatitude,
    required this.exitLongitude,
    this.attempts = 0,
  });

  /// The exact request body the backend expects — camelCase keys, UTC
  /// ISO-8601 timestamps. `shopId` is omitted when null so the backend
  /// backfills it from `task.shop_id`.
  Map<String, dynamic> toPayload() => {
        'visitId': visitId,
        'taskId': taskId,
        if (shopId != null) 'shopId': shopId,
        'enteredAt': enteredAt.toUtc().toIso8601String(),
        'exitedAt': exitedAt.toUtc().toIso8601String(),
        'stayDurationSeconds': stayDurationSeconds,
        'exitEstimated': exitEstimated,
        'enterLatitude': enterLatitude,
        'enterLongitude': enterLongitude,
        'exitLatitude': exitLatitude,
        'exitLongitude': exitLongitude,
      };

  /// Storage form — the payload plus the local [attempts] counter.
  Map<String, dynamic> toJson() => {
        ...toPayload(),
        'attempts': attempts,
      };

  factory GeofenceVisit.fromJson(Map<String, dynamic> j) => GeofenceVisit(
        visitId: j['visitId'] as String,
        taskId: j['taskId'] as int,
        shopId: j['shopId'] as int?,
        enteredAt: DateTime.parse(j['enteredAt'] as String),
        exitedAt: DateTime.parse(j['exitedAt'] as String),
        stayDurationSeconds: j['stayDurationSeconds'] as int,
        exitEstimated: j['exitEstimated'] as bool,
        enterLatitude: (j['enterLatitude'] as num).toDouble(),
        enterLongitude: (j['enterLongitude'] as num).toDouble(),
        exitLatitude: (j['exitLatitude'] as num).toDouble(),
        exitLongitude: (j['exitLongitude'] as num).toDouble(),
        attempts: (j['attempts'] as int?) ?? 0,
      );
}

/// An in-progress visit — the agent is currently inside the geofence. Held
/// in memory AND mirrored to disk so an app-kill mid-visit is recoverable.
class OpenVisit {
  final String visitId;
  final int taskId;
  final int? shopId;
  final DateTime enteredAt;
  final double enterLatitude;
  final double enterLongitude;

  /// The most recent fix still considered inside the geofence. Used as the
  /// exit coordinate/time when the visit must be closed without observing a
  /// real exit (app-kill / permission-loss recovery).
  double lastInsideLatitude;
  double lastInsideLongitude;
  DateTime lastInsideAt;

  OpenVisit({
    required this.visitId,
    required this.taskId,
    required this.shopId,
    required this.enteredAt,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.lastInsideLatitude,
    required this.lastInsideLongitude,
    required this.lastInsideAt,
  });

  Map<String, dynamic> toJson() => {
        'visitId': visitId,
        'taskId': taskId,
        if (shopId != null) 'shopId': shopId,
        'enteredAt': enteredAt.toUtc().toIso8601String(),
        'enterLatitude': enterLatitude,
        'enterLongitude': enterLongitude,
        'lastInsideLatitude': lastInsideLatitude,
        'lastInsideLongitude': lastInsideLongitude,
        'lastInsideAt': lastInsideAt.toUtc().toIso8601String(),
      };

  factory OpenVisit.fromJson(Map<String, dynamic> j) => OpenVisit(
        visitId: j['visitId'] as String,
        taskId: j['taskId'] as int,
        shopId: j['shopId'] as int?,
        enteredAt: DateTime.parse(j['enteredAt'] as String),
        enterLatitude: (j['enterLatitude'] as num).toDouble(),
        enterLongitude: (j['enterLongitude'] as num).toDouble(),
        lastInsideLatitude: (j['lastInsideLatitude'] as num).toDouble(),
        lastInsideLongitude: (j['lastInsideLongitude'] as num).toDouble(),
        lastInsideAt: DateTime.parse(j['lastInsideAt'] as String),
      );

  /// Closes this visit into a sendable [GeofenceVisit]. [exitedAt] is clamped
  /// to never precede [enteredAt] (clock skew / NTP correction) so the stay
  /// duration is never negative and the backend's `exitedAt >= enteredAt`
  /// validation passes.
  GeofenceVisit close({
    required DateTime exitedAt,
    required double exitLatitude,
    required double exitLongitude,
    required bool exitEstimated,
  }) {
    final entered = enteredAt.toUtc();
    var exited = exitedAt.toUtc();
    if (exited.isBefore(entered)) exited = entered;
    return GeofenceVisit(
      visitId: visitId,
      taskId: taskId,
      shopId: shopId,
      enteredAt: entered,
      exitedAt: exited,
      stayDurationSeconds: exited.difference(entered).inSeconds,
      exitEstimated: exitEstimated,
      enterLatitude: enterLatitude,
      enterLongitude: enterLongitude,
      exitLatitude: exitLatitude,
      exitLongitude: exitLongitude,
    );
  }
}
