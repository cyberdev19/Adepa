import 'package:flutter/material.dart';

class AdepaColors {
  static const ghGold = Color(0xFFFFB800);
  static const ghGreen = Color(0xFF006B3F);
  static const ghRed = Color(0xFFCF0921);
  static const ghBlue = Color(0xFF0077B6);
  static const ghPurple = Color(0xFF7B2D8B);

  static const bg = Color(0xFF0F0F0F);
  static const bg2 = Color(0xFF1A1A1A);
  static const bg3 = Color(0xFF232323);
  static const textPrimary = Color(0xFFF0EDE6);
  static const textSecondary = Color(0xFFA09990);
  static const border = Color(0x14FFFFFF);

  static const List<Color> postColors = [
    ghGreen, ghGold, ghRed, ghBlue, ghPurple,
  ];

  // Stored as hex strings in Firestore
  static const List<String> postColorHex = [
    '#006B3F', '#FFB800', '#CF0921', '#0077B6', '#7B2D8B',
  ];

  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class AdepaTags {
  static const Map<String, String> tags = {
    'accra':    '📍 Accra',
    'gossip':   '🗣 Gossip',
    'football': '⚽ Football',
    'politics': '🏛 Politics',
    'food':     '🍲 Chop Bar',
    'campus':   '🎓 Campus',
  };

  static const List<String> emojis = [
    '😂', '🔥', '💔', '🙌', '😤', '❤️', '👀', '😭'
  ];
}
