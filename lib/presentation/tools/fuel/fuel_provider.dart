import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuelState {
  final double distance;
  final double fuelUsed;
  final double gasPrice;
  final double fuelEfficiency;
  final double costPerKm;
  final double totalFuelCost;

  const FuelState({
    this.distance = 0,
    this.fuelUsed = 0,
    this.gasPrice = 0,
    this.fuelEfficiency = 0,
    this.costPerKm = 0,
    this.totalFuelCost = 0,
  });

  FuelState copyWith({
    double? distance,
    double? fuelUsed,
    double? gasPrice,
    double? fuelEfficiency,
    double? costPerKm,
    double? totalFuelCost,
  }) =>
      FuelState(
        distance: distance ?? this.distance,
        fuelUsed: fuelUsed ?? this.fuelUsed,
        gasPrice: gasPrice ?? this.gasPrice,
        fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
        costPerKm: costPerKm ?? this.costPerKm,
        totalFuelCost: totalFuelCost ?? this.totalFuelCost,
      );
}

class FuelNotifier extends StateNotifier<FuelState> {
  FuelNotifier() : super(const FuelState());

  void setDistance(double v) {
    state = state.copyWith(distance: v);
    _calculate();
  }

  void setFuelUsed(double v) {
    state = state.copyWith(fuelUsed: v);
    _calculate();
  }

  void setGasPrice(double v) {
    state = state.copyWith(gasPrice: v);
    _calculate();
  }

  void _calculate() {
    final d = state.distance;
    final f = state.fuelUsed;
    final g = state.gasPrice;

    if (f <= 0) {
      state = state.copyWith(fuelEfficiency: 0, costPerKm: 0, totalFuelCost: 0);
      return;
    }

    final efficiency = d / f;
    final costKm = efficiency > 0 ? g / efficiency : 0.0;
    final totalCost = f * g;

    state = state.copyWith(
      fuelEfficiency: efficiency,
      costPerKm: costKm,
      totalFuelCost: totalCost,
    );
  }
}

final fuelProvider = StateNotifierProvider<FuelNotifier, FuelState>(
  (ref) => FuelNotifier(),
);
