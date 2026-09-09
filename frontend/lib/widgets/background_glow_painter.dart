import 'package:flutter/material.dart';

class BackgroundGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-Left Violet Flare
    final Paint violetGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withOpacity(0.18),
          const Color(0xFF7C3AED).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.15, size.height * 0.1),
        radius: size.width * 0.45,
      ));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.1), size.width * 0.45, violetGlow);

    // 2. Bottom-Right Cyan Flare
    final Paint cyanGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF06B6D4).withOpacity(0.14),
          const Color(0xFF06B6D4).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.9),
        radius: size.width * 0.4,
      ));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.9), size.width * 0.4, cyanGlow);

    // 3. Subtle Cybernetic Dot Matrix Grid
    final Paint dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.fill;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
