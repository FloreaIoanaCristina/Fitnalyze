import 'package:flutter/material.dart';

class IconMapper {
  static const Map<String, IconData> _map = {
    //EXERCITII
    'airline_seat_legroom_normal': Icons.airline_seat_legroom_normal,
    'fitness_center_outlined': Icons.fitness_center_outlined,
    'sports_gymnastics': Icons.sports_gymnastics,
    'straighten': Icons.straighten,
    'hourglass_empty': Icons.hourglass_empty,
    'directions_walk': Icons.directions_walk,
    'person': Icons.person,
    'sync': Icons.sync,
    'accessibility': Icons.accessibility,

    // BADGE-URI
    'bronze_medal': Icons.workspace_premium_outlined,
    'silver_medal': Icons.workspace_premium,
    'gold_medal': Icons.military_tech,
    'fire_bronze': Icons.local_fire_department_outlined,
    'fire_silver': Icons.local_fire_department_rounded,
    'fire_gold': Icons.whatshot,
    'emoji_events': Icons.emoji_events,
    'star': Icons.star,
  };

  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.fitness_center;
    return _map[iconName.trim().toLowerCase()] ?? Icons.fitness_center;
  }
}