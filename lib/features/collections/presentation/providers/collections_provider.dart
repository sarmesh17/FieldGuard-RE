import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';

import '../../data/datasources/collections_datasource.dart';
import '../../data/models/collection_request.dart';
import '../../data/models/shop_outstanding.dart';

/// Single shared datasource; cheap to construct, no state of its own.
final collectionsDataSourceProvider = Provider<CollectionsDataSource>(
  (ref) => CollectionsDataSource(ref.watch(dioProvider)),
);

/// Outstanding ledger for a given shop. Family-keyed so multiple screens
/// can read different shops without collision; auto-disposed when no longer
/// watched. Refresh by invalidating: `ref.invalidate(shopOutstandingProvider(shopId))`.
final shopOutstandingProvider =
    FutureProvider.autoDispose.family<ShopOutstanding, int>((ref, shopId) {
  return ref.watch(collectionsDataSourceProvider).getOutstanding(shopId);
});

/// One-shot submit. We model only the three states the UI cares about —
/// idle, in-flight, terminal (success/error) — rather than a full Result
/// type, because the screen only needs to (a) disable the button while
/// in-flight and (b) navigate or show an error on completion.
sealed class CollectionSubmitState {
  const CollectionSubmitState();
}

class CollectionSubmitIdle extends CollectionSubmitState {
  const CollectionSubmitIdle();
}

class CollectionSubmitLoading extends CollectionSubmitState {
  const CollectionSubmitLoading();
}

class CollectionSubmitSuccess extends CollectionSubmitState {
  const CollectionSubmitSuccess();
}

class CollectionSubmitError extends CollectionSubmitState {
  final String message;
  const CollectionSubmitError(this.message);
}

class CollectionSubmitNotifier extends StateNotifier<CollectionSubmitState> {
  CollectionSubmitNotifier(this._dataSource)
      : super(const CollectionSubmitIdle());

  final CollectionsDataSource _dataSource;

  Future<void> submit(CollectionRequest req) async {
    state = const CollectionSubmitLoading();
    try {
      await _dataSource.submit(req);
      if (!mounted) return;
      state = const CollectionSubmitSuccess();
    } catch (e) {
      if (!mounted) return;
      state = CollectionSubmitError(e.toString());
    }
  }

  void reset() {
    if (!mounted) return;
    state = const CollectionSubmitIdle();
  }
}

/// Auto-disposed so each visit to the screen starts from `Idle`.
final collectionSubmitProvider = StateNotifierProvider.autoDispose<
    CollectionSubmitNotifier, CollectionSubmitState>(
  (ref) => CollectionSubmitNotifier(ref.watch(collectionsDataSourceProvider)),
);
