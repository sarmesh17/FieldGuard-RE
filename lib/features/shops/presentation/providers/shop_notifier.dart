import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/upload_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/domain/usecases/create_shop_usecase.dart';
import 'shop_state.dart';

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier(this._createShopUseCase, this._uploadService)
      : super(const ShopInitial());

  final CreateShopUseCase _createShopUseCase;
  final UploadService _uploadService;

  Future<bool> createShop(CreateShopRequest request) async {
    state = const ShopLoading();
    try {
      // If a photo was picked, upload to S3 first and attach the imageKey.
      var finalRequest = request;
      if (request.photoFile != null) {
        final imageKey =
            await _uploadService.uploadShopPhoto(request.photoFile!);
        finalRequest = request.withImageKey(imageKey);
      }

      final result = await _createShopUseCase(finalRequest);
      switch (result) {
        case Success():
          state = const ShopSuccess();
          return true;
        case Failure(:final exception):
          state = ShopError(
            exception is AppException
                ? exception.message
                : 'Something went wrong',
          );
          return false;
      }
    } catch (e) {
      state = ShopError('Photo upload failed: $e');
      return false;
    }
  }

  void reset() => state = const ShopInitial();
}
