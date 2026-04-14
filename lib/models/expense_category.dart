import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double defaultServicePercent;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.defaultServicePercent = 0.0,
  });

  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      id: 'restaurant',
      name: 'Ресторан',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF22D3EE),
      defaultServicePercent: 10.0,
    ),
    ExpenseCategory(
      id: 'groceries',
      name: 'Продукты',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFF34D399),
    ),
    ExpenseCategory(
      id: 'travel',
      name: 'Путешествие',
      icon: Icons.flight_rounded,
      color: Color(0xFFA78BFA),
    ),
    ExpenseCategory(
      id: 'rent',
      name: 'Аренда',
      icon: Icons.home_rounded,
      color: Color(0xFFF59E0B),
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Транспорт',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6),
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Развлечения',
      icon: Icons.movie_rounded,
      color: Color(0xFFEC4899),
    ),
    ExpenseCategory(
      id: 'gifts',
      name: 'Подарки',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFF43F5E),
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Прочее',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF94A3B8),
    ),
  ];

  static ExpenseCategory findById(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => all.last);
  }
}
