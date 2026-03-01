import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassWidget extends StatelessWidget {
  final double heading; // 0-360 degrees
  final double size;
  final bool showDegrees;

  const CompassWidget({
    super.key,
    required this.heading,
    this.size = 60,
    this.showDegrees = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0xFFE4E4E7).withOpacity(
                0.95,
              ) // Bright zinc-200 for map visibility
            : Colors.white.withOpacity(0.95),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF4F4F5)
              : const Color(0xFFE4E4E7), // zinc-100 : zinc-200
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass rose background
          CustomPaint(
            size: Size(size, size),
            painter: _CompassRosePainter(isDark: isDark),
          ),

          // Rotating needle
          Transform.rotate(
            angle: heading * math.pi / 180,
            child: CustomPaint(
              size: Size(size, size),
              painter: _CompassNeedlePainter(),
            ),
          ),

          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // Degree text
          if (showDegrees)
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${heading.toInt()}°',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  final bool isDark;

  _CompassRosePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA);

    // Draw cardinal direction markers
    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final x = center.dx + radius * math.sin(angle);
      final y = center.dy - radius * math.cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: i == 0
                ? Colors.red
                : (isDark ? Colors.white70 : Colors.black54),
            fontSize: 12,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw tick marks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final isCardinal = i % 9 == 0;
      final tickLength = isCardinal ? 8.0 : 4.0;

      final startX = center.dx + (radius - tickLength) * math.sin(angle);
      final startY = center.dy - (radius - tickLength) * math.cos(angle);
      final endX = center.dx + radius * math.sin(angle);
      final endY = center.dy - radius * math.cos(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // North arrow (red)
    final northPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - 4, center.dy)
      ..lineTo(center.dx + 4, center.dy)
      ..close();

    canvas.drawPath(northPath, northPaint);

    // South arrow (white/gray)
    final southPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - 4, center.dy)
      ..lineTo(center.dx + 4, center.dy)
      ..close();

    canvas.drawPath(southPath, southPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
