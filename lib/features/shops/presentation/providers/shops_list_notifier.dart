import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/domain/usecases/get_shops_usecase.dart';
import 'shops_list_state.dart';

class ShopsListNotifier extends StateNotifier<ShopsListState> {
  ShopsListNotifier(this._getShopsUseCase) : super(const ShopsListInitial()) {
    fetch();
  }

  final GetShopsUseCase _getShopsUseCase;

  Future<void> fetch() async {
    state = const ShopsListLoading();
    final result = await _getShopsUseCase();
    switch (result) {
      case Success(:final data):
        state = ShopsListSuccess(data);
      case Failure(:final exception):
        state = ShopsListError(
          exception is AppException ? exception.message : 'Something went wrong',
        );
    }
  }
}
