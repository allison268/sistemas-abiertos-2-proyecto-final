import 'package:flutter/material.dart';

import '../models/card_symbol.dart';
import '../models/user_model.dart';
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
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Cómo Jugar'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F0FE), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildHowToPlay(),
                const SizedBox(height: 20),
                _buildScoring(),
                const SizedBox(height: 20),
                _buildLevels(),
                const SizedBox(height: 20),
                _buildStarsInfo(),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _startPlaying(context),
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      '¡Empezar a Jugar!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0033A0),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '🇭🇳 Encuentra todos los pares antes de que se acabe el tiempo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF616161),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0033A0), Color(0xFF3B6BD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0033A0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'lib/splash y icono/icono_app.jpg',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Text('🇭🇳', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Descubre y aprende sobre los símbolos patrios de Honduras '
                  'mientras pones a prueba tu memoria.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
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
        'Cada par encontrado activa la IA que te cuenta un dato curioso del símbolo.',
      ),
      _Step(
        Icons.timer_rounded,
        '¡Contra el reloj!',
        'Tienes 60 segundos por nivel. Encuentra todos los pares antes de que se agote el tiempo.',
      ),
    ];
    return _section(
      title: '¿Cómo se juega?',
      icon: Icons.sports_esports_rounded,
      children: steps
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      s.icon,
                      color: const Color(0xFF0033A0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF616161),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildScoring() {
    final rows = <_ScoreRow>[
      _ScoreRow(
        '🎯',
        'Por cada par encontrado',
        '+100 pts',
        const Color(0xFF2E7D32),
      ),
      _ScoreRow(
        '⏱️',
        'Por cada segundo que te quede',
        '+5 pts',
        const Color(0xFF2E7D32),
      ),
      _ScoreRow(
        '👆',
        'Por cada movida de más',
        '-5 pts',
        const Color(0xFFC62828),
      ),
    ];
    return _section(
      title: '¿Cómo se gana puntos?',
      icon: Icons.stars_rounded,
      children: [
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: r.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFFF57F17)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Las movidas de más son las que haces después de encontrar '
                  'todos los pares posibles. ¡Poca movidas = más puntos!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF795548),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevels() {
    return _section(
      title: 'Niveles',
      icon: Icons.flag_rounded,
      children: LevelConfig.levels.map((config) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${config.level}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0033A0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${config.pairs} pares · ${config.timeSeconds}s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStarsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 34),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Gana estrellas al completar un nivel. Mientras más rápido y con '
              'menos movidas termines, más estrellas obtendrás.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF424242),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0033A0), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0033A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
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
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _ScoreRow(this.emoji, this.label, this.value, this.color);
}
