import 'package:flutter/material.dart';

/// Helper mapping string icon keys to Material Icons.
class IconResolver {
  IconResolver._();

  static const Map<String, IconData> _icons = {
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'directions_bus': Icons.directions_bus,
    'local_gas_station': Icons.local_gas_station,
    'receipt_long': Icons.receipt_long,
    'electrical_services': Icons.electrical_services,
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'school': Icons.school,
    'medical_services': Icons.medical_services,
    'local_hospital': Icons.local_hospital,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'account_balance_wallet': Icons.account_balance_wallet,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'card_giftcard': Icons.card_giftcard,
    'home': Icons.home,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'fitness_center': Icons.fitness_center,
  };

  static IconData getIcon(String key) {
    return _icons[key] ?? Icons.category_outlined;
  }

  static List<String> get availableKeys => _icons.keys.toList();
}
