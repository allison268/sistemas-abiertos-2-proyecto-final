import 'dart:math';

import 'package:flutter/material.dart';

/// Celebración de victoria: dos cañones de confeti y serpentinas disparan desde
/// las esquinas de abajo, y después cae una lluvia de papelitos y estrellas.
/// Va encima de la pantalla y no bloquea los toques.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

enum _Shape { rect, circle, star, streamer }

class _Piece {
  final _Shape shape;
  final Color color;
  final double size;
  final double angle;
  final double spin;
  final double delay; // segundos antes de aparecer
  // Cañón: nacen abajo y salen disparados hacia arriba.
  final bool cannon;
  final double originX; // 0..1 del ancho
  final double vx; // en anchos de pantalla por segundo
  final double vy; // en altos de pantalla por segundo (negativo = arriba)
  // Lluvia: caen desde arriba moviéndose de lado a lado.
  final double sway;
  final double swayFreq;
  final double fall;

  const _Piece({
    required this.shape,
    required this.color,
    required this.size,
    required this.angle,
    required this.spin,
    required this.delay,
    required this.cannon,
    this.originX = 0,
    this.vx = 0,
    this.vy = 0,
    this.sway = 0,
    this.swayFreq = 0,
    this.fall = 0,
  });
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  static const double _seconds = 5.6;

  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  static const List<Color> _colors = [
    Color(0xFF0033A0),
    Color(0xFF3B6BD0),
    Color(0xFF7FA6F5),
    Color(0xFFF2B705),
    Color(0xFFFFD54F),
    Color(0xFFFFFFFF),
    Color(0xFFE53935),
    Color(0xFF43A047),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    final list = <_Piece>[];

    _Shape pick(bool streamers) {
      final r = rnd.nextInt(10);
      if (streamers && r < 3) return _Shape.streamer;
      if (r < 6) return _Shape.rect;
      if (r < 8) return _Shape.circle;
      return _Shape.star;
    }

    // Dos volleys desde cada esquina de abajo.
    for (final volley in [0.0, 0.85]) {
      for (final left in [true, false]) {
        for (var i = 0; i < 38; i++) {
          final spread = (rnd.nextDouble() - 0.5) * 0.55; // abanico
          final power = 0.85 + rnd.nextDouble() * 0.6;
          list.add(
            _Piece(
              shape: pick(true),
              color: _colors[rnd.nextInt(_colors.length)],
              size: 8 + rnd.nextDouble() * 9,
              angle: rnd.nextDouble() * pi * 2,
              spin: (rnd.nextDouble() - 0.5) * 16,
              delay: volley + rnd.nextDouble() * 0.08,
              cannon: true,
              originX: left ? 0.02 : 0.98,
              vx: (left ? 1 : -1) * (0.45 + rnd.nextDouble() * 0.5) * power + spread,
              vy: -(1.0 + rnd.nextDouble() * 0.7) * power,
            ),
          );
        }
      }
    }

    // Lluvia que cae desde arriba.
    for (var i = 0; i < 70; i++) {
      list.add(
        _Piece(
          shape: pick(false),
          color: _colors[rnd.nextInt(_colors.length)],
          size: 7 + rnd.nextDouble() * 8,
          angle: rnd.nextDouble() * pi * 2,
          spin: (rnd.nextDouble() - 0.5) * 12,
          delay: 0.6 + rnd.nextDouble() * 1.6,
          cannon: false,
          originX: rnd.nextDouble(),
          sway: 0.015 + rnd.nextDouble() * 0.04,
          swayFreq: 2 + rnd.nextDouble() * 4,
          fall: 0.28 + rnd.nextDouble() * 0.22,
        ),
      );
    }
    _pieces = list;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_seconds * 1000).round()),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value * _seconds),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double time; // segundos transcurridos

  _ConfettiPainter(this.pieces, this.time);

  static const double _drag = 1.7; // resistencia del aire
  static const double _gravity = 1.35; // alturas de pantalla / s²

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final p in pieces) {
      final s = time - p.delay;
      if (s <= 0) continue;

      double x;
      double y;
      double life; // 0..1
      if (p.cannon) {
        // Movimiento con resistencia del aire y gravedad.
        final k = (1 - exp(-_drag * s)) / _drag;
        x = (p.originX + p.vx * k) * size.width;
        y = (1.04 + p.vy * k + _gravity * (s - k) / _drag) * size.height;
        life = (s / 3.4).clamp(0.0, 1.0);
      } else {
        final base = s * p.fall;
        y = (-0.06 + base) * size.height;
        x = (p.originX + sin(s * p.swayFreq) * p.sway) * size.width;
        life = (y / size.height / 1.1).clamp(0.0, 1.0);
      }
      if (y > size.height * 1.08 || life >= 1) continue;
      final fade = life > 0.82 ? (1 - life) / 0.18 : 1.0;
      final color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + s * p.spin * 0.5);
      // El giro en 3D se imita aplastando la pieza.
      final flip = cos(s * p.spin * 1.3).abs();
      canvas.scale(1, 0.25 + 0.75 * flip);

      switch (p.shape) {
        case _Shape.rect:
          fill.color = color;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 0.55,
              ),
              const Radius.circular(2),
            ),
            fill,
          );
        case _Shape.circle:
          fill.color = color;
          canvas.drawCircle(Offset.zero, p.size * 0.4, fill);
        case _Shape.star:
          fill.color = color;
          canvas.drawPath(_star(p.size * 0.62), fill);
        case _Shape.streamer:
          // Serpentina: cinta ondulada.
          line
            ..color = color
            ..strokeWidth = max(2.5, p.size * 0.3);
          final path = Path()..moveTo(-p.size * 1.6, 0);
          const steps = 14;
          for (var i = 1; i <= steps; i++) {
            final t = i / steps;
            path.lineTo(
              -p.size * 1.6 + t * p.size * 3.2,
              sin(t * pi * 3 + s * 9) * p.size * 0.38,
            );
          }
          canvas.drawPath(path, line);
      }
      canvas.restore();
    }
  }

  Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(cos(a) * radius, sin(a) * radius);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.time != time;
}
