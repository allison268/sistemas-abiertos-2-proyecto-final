import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/card_symbol.dart';
import 'ui_kit.dart';

/// Carta del juego. Tiene animación de entrada, giro, rebote al acertar,
/// sacudida al fallar y un efecto al pasar el mouse. Si el jugador compró el
/// diseño dorado en la tienda, usa el tema dorado.
class GameCard extends StatefulWidget {
  final CardSymbol symbol;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;
  final double size;
  final bool gold;
  final bool shake;
  final int entranceDelay;

  const GameCard({
    super.key,
    required this.symbol,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
    this.size = 80,
    this.gold = false,
    this.shake = false,
    this.entranceDelay = 0,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _pop;
  late final AnimationController _shake;
  late final AnimationController _enter;
  late final Animation<double> _flipCurve;
  bool _hover = false;

  static const Color _goldMain = Color(0xFFF2B705);
  static const Color _goldLight = Color(0xFFFFE08A);
  static const Color _goldDark = Color(0xFF9A6B00);

  bool get _open => widget.isFlipped || widget.isMatched;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 460),
    );
    _flipCurve = CurvedAnimation(parent: _flip, curve: Curves.easeInOutCubic);
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future.delayed(Duration(milliseconds: widget.entranceDelay), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasOpen = oldWidget.isFlipped || oldWidget.isMatched;
    if (_open != wasOpen) {
      if (_open) {
        _flip.forward();
      } else {
        _flip.reverse();
      }
    }
    if (!oldWidget.isMatched && widget.isMatched) {
      _pop.forward(from: 0);
    }
    if (!oldWidget.shake && widget.shake) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _pop.dispose();
    _shake.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canTap = !widget.isMatched;
    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canTap ? widget.onTap : null,
        child: AnimatedScale(
          scale: (_hover && !_open) ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: Listenable.merge([_flipCurve, _pop, _shake, _enter]),
            builder: (context, child) {
              final enter = Curves.easeOutBack.transform(_enter.value);
              final pop = 1 + 0.16 * math.sin(_pop.value * math.pi);
              final dx =
                  math.sin(_shake.value * math.pi * 5) *
                  8 *
                  (1 - _shake.value);
              final angle = _flipCurve.value * math.pi;
              final showFront = _flipCurve.value > 0.5;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);
              return Opacity(
                opacity: _enter.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.scale(
                    scale: enter * pop,
                    child: SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: Transform(
                        transform: transform,
                        alignment: Alignment.center,
                        child: showFront
                            ? Transform(
                                transform: Matrix4.identity()
                                  ..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: _buildFront(),
                              )
                            : _buildBack(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    final gold = widget.gold;
    final radius = widget.size * 0.11;
    Widget art = Image.asset(
      CardAssets.back,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: const BoxDecoration(gradient: AppColors.hero),
        child: const Center(
          child: Icon(Icons.flag_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
    if (gold) {
      art = ColorFiltered(
        colorFilter: const ColorFilter.mode(_goldMain, BlendMode.modulate),
        child: art,
      );
    }
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: gold ? _goldLight : AppColors.gold,
          width: gold ? 3.5 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: gold
                ? _goldMain.withValues(alpha: 0.55)
                : AppColors.blue.withValues(alpha: 0.30),
            blurRadius: gold ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            art,
            if (gold)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.25, 0.5, 0.75],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFront() {
    final gold = widget.gold;
    final matched = widget.isMatched;
    final radius = widget.size * 0.11;
    final Color border = matched
        ? (gold ? _goldMain : AppColors.success)
        : (gold ? _goldDark : AppColors.blue);
    final Color ribbonA = matched && !gold ? AppColors.success : AppColors.blue;
    final Color ribbonB = matched && !gold
        ? const Color(0xFF43A047)
        : AppColors.blueDark;
    final pad = widget.size * 0.06;

    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: gold ? const Color(0xFFFFFAE8) : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: gold ? 3.5 : 3),
            boxShadow: [
              BoxShadow(
                color: matched
                    ? (gold ? _goldMain : AppColors.gold).withValues(
                        alpha: 0.55,
                      )
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: matched ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius * 0.8),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(pad),
                    color: gold ? const Color(0xFFFFFAE8) : Colors.white,
                    child: Center(
                      child: Image.asset(
                        widget.symbol.image,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: widget.size * 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: widget.size * 0.24,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [ribbonA, ribbonB]),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.symbol.name,
                        style: TextStyle(
                          fontSize: widget.size * 0.125,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: gold ? _goldLight : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (matched)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: gold ? _goldDark : AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.check_rounded,
                size: widget.size * 0.16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
