import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.initials,
    required this.colorHex,
    this.imageUrl,
    this.radius = 28,
    super.key,
  });

  final String initials;
  final String colorHex;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color(colorHex),
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * .65,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Color _color(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x6D597A;
    return Color(0xff000000 | value);
  }
}
