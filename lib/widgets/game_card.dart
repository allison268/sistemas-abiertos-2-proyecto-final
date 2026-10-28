import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/card_symbol.dart';

class GameCard extends StatefulWidget {
  final CardSymbol symbol;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;
  final double size;

  const GameCard({
    super.key,
    required this.symbol,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
    this.size = 80,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: (widget.isFlipped || widget.isMatched) ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 420),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowOpen = widget.isFlipped || widget.isMatched;
    final wasOpen = oldWidget.isFlipped || oldWidget.isMatched;
    if (nowOpen != wasOpen) {
      if (nowOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.isMatched ? null : widget.onTap,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);
              final showFront = _animation.value > 0.5;
              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: showFront
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _buildFront(),
                      )
                    : _buildBack(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0033A0).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          CardAssets.back,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0033A0), Color(0xFF1E56C7)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.flag_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final matched = widget.isMatched;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: matched ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: matched ? const Color(0xFF66BB6A) : const Color(0xFF0033A0),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                widget.symbol.image,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: widget.size * 0.4,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: widget.size * 0.22,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              color: matched
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFE3F2FD),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.symbol.name,
                    style: TextStyle(
                      fontSize: widget.size * 0.12,
                      fontWeight: FontWeight.bold,
                      color: matched
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF0033A0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
