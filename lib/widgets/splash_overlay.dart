import 'package:flutter/material.dart';

import 'ui_kit.dart';

/// Pantalla de bienvenida: el escudo aparece con rebote y luego se desvanece.
class SplashOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const SplashOverlay({super.key, required this.onDone});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _leaving = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: const Duration(milliseconds: 450),
      onEnd: () {
        if (_leaving) widget.onDone();
      },
      child: Material(
        type: MaterialType.transparency,
        child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.hero),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final logoT = Curves.elasticOut.transform(
                (_c.value / 0.6).clamp(0.0, 1.0),
              );
              final textT = Curves.easeOut.transform(
                ((_c.value - 0.45) / 0.4).clamp(0.0, 1.0),
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: logoT,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.45),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'lib/splash y icono/icono_app.jpg',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 130,
                            height: 130,
                            child: Icon(Icons.flag_rounded, size: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: textT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - textT) * 14),
                      child: const Column(
                        children: [
                          Text(
                            'Memory Honduras',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Descubre los símbolos patrios',
                            style: TextStyle(
                              color: Color(0xFFD6E4FF),
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}
