import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscountState {
  final double originalPrice;
  final double discountPercent;
  final double savedAmount;
  final double finalPrice;

  const DiscountState({
    this.originalPrice = 0,
    this.discountPercent = 0,
    this.savedAmount = 0,
    this.finalPrice = 0,
  });

  DiscountState copyWith({
    double? originalPrice,
    double? discountPercent,
    double? savedAmount,
    double? finalPrice,
  }) =>
      DiscountState(
        originalPrice: originalPrice ?? this.originalPrice,
        discountPercent: discountPercent ?? this.discountPercent,
        savedAmount: savedAmount ?? this.savedAmount,
        finalPrice: finalPrice ?? this.finalPrice,
      );
}

class DiscountNotifier extends StateNotifier<DiscountState> {
  DiscountNotifier() : super(const DiscountState());

  void setOriginalPrice(double v) {
    state = state.copyWith(originalPrice: v);
    _calculate();
  }

  void setDiscountPercent(double v) {
    state = state.copyWith(discountPercent: v.clamp(0, 100));
    _calculate();
  }

  void _calculate() {
    final saved = state.originalPrice * state.discountPercent / 100;
    final finalP = state.originalPrice - saved;
    state = state.copyWith(
      savedAmount: saved,
      finalPrice: finalP,
    );
  }
}

final discountProvider =
    StateNotifierProvider<DiscountNotifier, DiscountState>(
  (ref) => DiscountNotifier(),
);
