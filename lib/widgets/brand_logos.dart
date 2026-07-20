import 'package:flutter/material.dart';

/// Official four-color Google "G" mark, drawn to match Google's brand
/// guidelines for "Sign in with Google" buttons (required to use the
/// unmodified multi-color G, not a generic icon).
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: r - stroke / 2);

    // Blue (right arc)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.95, 1.9, false, paint);
    // Green (bottom arc)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.95, 1.55, false, paint);
    // Yellow (left arc)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.5, 1.35, false, paint);
    // Red (top arc)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.85, 1.7, false, paint);

    // Horizontal crossbar of the G, blue, matching the logo's cut-in
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke / 2, r - stroke * 0.15, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Facebook "f" logo — blue rounded square with the white
/// lowercase f mark, matching Meta's brand guidelines.
class FacebookLogo extends StatelessWidget {
  final double size;
  const FacebookLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FacebookFPainter()),
    );
  }
}

class _FacebookFPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1877F2));

    final path = Path();
    final w = size.width;
    final h = size.height;
    // Simplified lowercase "f" glyph proportioned to the square.
    path.moveTo(w * 0.58, h * 0.98);
    path.lineTo(w * 0.58, h * 0.53);
    path.lineTo(w * 0.72, h * 0.53);
    path.lineTo(w * 0.75, h * 0.36);
    path.lineTo(w * 0.58, h * 0.36);
    path.lineTo(w * 0.58, h * 0.26);
    path.cubicTo(w * 0.58, h * 0.19, w * 0.60, h * 0.16, w * 0.68, h * 0.16);
    path.lineTo(w * 0.76, h * 0.16);
    path.lineTo(w * 0.76, h * 0.02);
    path.cubicTo(w * 0.74, h * 0.015, w * 0.65, h * 0.0, w * 0.57, h * 0.0);
    path.cubicTo(w * 0.42, h * 0.0, w * 0.42, h * 0.20, w * 0.42, h * 0.24);
    path.lineTo(w * 0.42, h * 0.36);
    path.lineTo(w * 0.30, h * 0.36);
    path.lineTo(w * 0.30, h * 0.53);
    path.lineTo(w * 0.42, h * 0.53);
    path.lineTo(w * 0.42, h * 0.98);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
