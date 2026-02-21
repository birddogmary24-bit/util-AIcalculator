import 'package:flutter/material.dart';
import '../../core/constants/region.dart';

class ToolDefinition {
  final String id;
  final String routePath;
  final String label;
  final String labelKey;
  final String descriptionKey;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final String categoryKey;
  final Set<RegionMode> regions;

  const ToolDefinition({
    required this.id,
    required this.routePath,
    required this.label,
    this.labelKey = '',
    this.descriptionKey = '',
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.categoryKey = '',
    this.regions = const {RegionMode.kr, RegionMode.global},
  });

  String localizedLabel(RegionMode region) {
    if (labelKey.isEmpty) return label;
    return AppStrings.of(region)[labelKey] ?? label;
  }

  String localizedDescription(RegionMode region) {
    if (descriptionKey.isEmpty) return description;
    return AppStrings.of(region)[descriptionKey] ?? description;
  }

  String localizedCategory(RegionMode region) {
    if (categoryKey.isEmpty) return category;
    return AppStrings.of(region)[categoryKey] ?? category;
  }
}
