/// State for the tracking toggle. It is a small product type
/// (active × loading × error) rather than a sum type, so a single
/// immutable class with copyWith fits better than a sealed class here.
class TrackingState {
  const TrackingState({
    this.isActive = false,
    this.isLoading = false,
    this.error,
  });

  /// Whether a tracking session is currently running.
  final bool isActive;

  /// True while a start/stop request is in flight.
  final bool isLoading;

  /// Set when the last start/stop request failed; null otherwise.
  final String? error;

  TrackingState copyWith({
    bool? isActive,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrackingState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
