import 'package:flutter/material.dart';

class Person {
  static const List<Color> avatarColors = [
    Color(0xFF4CAF50),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFF8F00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFD81B60),
    Color(0xFF3949AB),
  ];

  final String id;
  String name;
  Color avatarColor;

  Person({required this.id, required this.name, required this.avatarColor});
}
