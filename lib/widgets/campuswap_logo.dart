import 'package:flutter/material.dart';
import 'app_colors.dart';

class CampuSwapLogo extends StatelessWidget {
  final double size;
  const CampuSwapLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}