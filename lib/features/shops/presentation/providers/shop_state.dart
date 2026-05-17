sealed class ShopState {
  const ShopState();
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopSuccess extends ShopState {
  const ShopSuccess();
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);
}
