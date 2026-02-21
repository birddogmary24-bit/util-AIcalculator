import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/region.dart';

enum Gender { male, female }

class BmiState {
  final double height;
  final double weight;
  final Gender gender;
  final double age;
  final double bmi;
  final String categoryKey; // internal key: underweight, normal, overweight, obese1, obese2, morbid
  final double bmr;

  const BmiState({
    this.height = 0,
    this.weight = 0,
    this.gender = Gender.male,
    this.age = 0,
    this.bmi = 0,
    this.categoryKey = '',
    this.bmr = 0,
  });

  BmiState copyWith({
    double? height,
    double? weight,
    Gender? gender,
    double? age,
    double? bmi,
    String? categoryKey,
    double? bmr,
  }) {
    return BmiState(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      bmi: bmi ?? this.bmi,
      categoryKey: categoryKey ?? this.categoryKey,
      bmr: bmr ?? this.bmr,
    );
  }

  /// Get localized category label
  String categoryLabel(RegionMode region) {
    return _categoryLabels[region]?[categoryKey] ?? '';
  }

  static const Map<RegionMode, Map<String, String>> _categoryLabels = {
    RegionMode.kr: {
      'underweight': '저체중',
      'normal': '정상',
      'overweight': '과체중',
      'obese1': '비만 1단계',
      'obese2': '비만 2단계',
      'morbid': '고도비만',
    },
    RegionMode.global: {
      'underweight': 'Underweight',
      'normal': 'Normal',
      'overweight': 'Overweight',
      'obese1': 'Obese I',
      'obese2': 'Obese II',
      'morbid': 'Morbidly Obese',
    },
  };
}

class BmiNotifier extends StateNotifier<BmiState> {
  BmiNotifier() : super(const BmiState());

  void setHeight(double v) {
    state = state.copyWith(height: v);
    _calculate();
  }

  void setWeight(double v) {
    state = state.copyWith(weight: v);
    _calculate();
  }

  void setGender(Gender v) {
    state = state.copyWith(gender: v);
    _calculate();
  }

  void setAge(double v) {
    state = state.copyWith(age: v);
    _calculate();
  }

  void _calculate() {
    final h = state.height;
    final w = state.weight;
    final a = state.age;

    if (h <= 0 || w <= 0) {
      state = state.copyWith(bmi: 0, categoryKey: '', bmr: 0);
      return;
    }

    // BMI = weight / (height in meters)^2
    final heightM = h / 100.0;
    final bmi = w / (heightM * heightM);

    // BMI category keys (Korean thresholds)
    String categoryKey;
    if (bmi < 18.5) {
      categoryKey = 'underweight';
    } else if (bmi < 23.0) {
      categoryKey = 'normal';
    } else if (bmi < 25.0) {
      categoryKey = 'overweight';
    } else if (bmi < 30.0) {
      categoryKey = 'obese1';
    } else if (bmi < 35.0) {
      categoryKey = 'obese2';
    } else {
      categoryKey = 'morbid';
    }

    // BMR (Harris-Benedict)
    double bmr = 0;
    if (a > 0) {
      if (state.gender == Gender.male) {
        bmr = 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a);
      } else {
        bmr = 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a);
      }
    }

    state = state.copyWith(
      bmi: bmi,
      categoryKey: categoryKey,
      bmr: bmr > 0 ? bmr : 0,
    );
  }
}

final bmiProvider =
    StateNotifierProvider<BmiNotifier, BmiState>((ref) => BmiNotifier());
