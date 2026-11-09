import 'package:flutter/material.dart';

import '../models/card_symbol.dart';
import '../models/user_model.dart';
import '../widgets/ui_kit.dart';
import 'levels_screen.dart';

/// Pantalla que se muestra al iniciar sesión con las instrucciones del juego,
/// el sistema de puntaje y los niveles disponibles. Al final lleva al menú
/// de niveles para comenzar a jugar.
class InstructionsScreen extends StatelessWidget {
  /// Usuario que inició sesión. Se pasa al menú de niveles.
  final UserModel? user;

  const InstructionsScreen({super.key, this.user});

  void _startPlaying(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LevelsScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 16),
                          _buildHowToPlay(),
                          const SizedBox(height: 14),
                          _buildScoring(),
                          const SizedBox(height: 14),
                          _buildLevels(),
                          const SizedBox(height: 14),
                          _buildStarsInfo(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: GradientButton(
                    label: '¡Empezar a jugar!',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _startPlaying(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.hero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/splash y icono/icono_app.jpg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: Text('🇭🇳', style: TextStyle(fontSize: 38)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓMO JUGAR',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Descubre y aprende sobre los símbolos patrios de Honduras '
                  'mientras pones a prueba tu memoria.',
                  style: TextStyle(
                    color: Color(0xFFD6E4FF),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlay() {
    final steps = <_Step>[
      _Step(
        Icons.touch_app_rounded,
        'Voltea dos cartas',
        'Toca una carta para descubrir su símbolo y luego otra para buscar su par.',
      ),
      _Step(
        Icons.check_circle_rounded,
        'Encuentra los pares',
        'Si las dos cartas coinciden, se quedan destapadas y cuentan como acierto.',
      ),
      _Step(
        Icons.lightbulb_rounded,
        'Aprende datos curiosos',
        'Cada par encontrado activa la IA del servidor, que te cuenta un dato curioso del símbolo.',
      ),
      _Step(
        Icons.timer_rounded,
        '¡Contra el reloj!',
        'Tienes 60 segundos por nivel. Encuentra todos los pares antes de que se agote el tiempo.',
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.sports_esports_rounded,
            text: '¿Cómo se juega?',
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(s.icon, color: AppColors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 12.8,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoring() {
    final rows = <_ScoreRow>[
      _ScoreRow(
        Icons.gps_fixed_rounded,
        'Por cada par encontrado',
        '+100 pts',
        AppColors.success,
      ),
      _ScoreRow(
        Icons.timer_rounded,
        'Por cada segundo que te quede',
        '+5 pts',
        AppColors.success,
      ),
      _ScoreRow(
        Icons.touch_app_rounded,
        'Por cada movida de más',
        '-5 pts',
        AppColors.danger,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.stars_rounded,
            text: '¿Cómo se ganan puntos?',
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(r.icon, color: r.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  InfoPill(text: r.value, color: r.color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFFB26A00)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las movidas de más son las que haces después de encontrar '
                    'todos los pares posibles. ¡Pocas movidas = más puntos!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6D4C41),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevels() {
    const colors = <Color>[
      Color(0xFF2E7D32),
      Color(0xFFEF6C00),
      Color(0xFFC62828),
    ];
    final cards = <Widget>[];
    for (var i = 0; i < LevelConfig.levels.length; i++) {
      final config = LevelConfig.levels[i];
      final color = colors[i % colors.length];
      if (i > 0) cards.add(const SizedBox(width: 10));
      cards.add(
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Text(
                  '${config.level}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  config.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${config.pairs} pares',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '${config.timeSeconds} s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.flag_rounded, text: 'Niveles'),
          const SizedBox(height: 14),
          Row(children: cards),
        ],
      ),
    );
  }

  Widget _buildStarsInfo() {
    return AppCard(
      color: AppColors.goldSoft,
      borderColor: const Color(0xFFFFE082),
      child: const Row(
        children: [
          Icon(Icons.star_rounded, color: AppColors.gold, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gana estrellas al completar un nivel. Mientras más rápido y con '
              'menos movidas termines, más estrellas obtendrás. Tus mejores '
              'puntajes entran al ranking del servidor.',
              style: TextStyle(
                fontSize: 12.8,
                color: Color(0xFF5D4037),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String description;
  const _Step(this.icon, this.title, this.description);
}

class _ScoreRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ScoreRow(this.icon, this.label, this.value, this.color);
}
