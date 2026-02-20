import 'package:flutter/material.dart';

class ToolDefinition {
  final String id;
  final String routePath;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String category;

  const ToolDefinition({
    required this.id,
    required this.routePath,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
}
