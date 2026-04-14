import 'package:flutter/material.dart';

class Person {
  // Warm-toned avatar colors matching the new palette
  static const List<Color> avatarColors = [
    Color(0xFF22D3EE), // amber gold
    Color(0xFF4ECDC4), // mint
    Color(0xFFFF6B6B), // coral
    Color(0xFFA78BFA), // peach
    Color(0xFF7C5CFC), // violet
    Color(0xFF3BCEAC), // teal
    Color(0xFFE84393), // pink
    Color(0xFF0984E3), // blue
  ];

  final String id;
  String name;
  Color avatarColor;
  int? userId;
  String? avatarUrl;

  Person({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.userId,
    this.avatarUrl,
  });
}
