import 'package:flutter/material.dart';

import '../models/card_symbol.dart';
import '../models/profile_avatars.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../widgets/avatar_picker.dart';
import 'game_screen.dart';
import 'login_screen.dart';

Color _darken(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

class LevelsScreen extends StatefulWidget {
  /// Usuario que inició sesión. De él se obtiene el progreso guardado.
  final UserModel? user;

  const LevelsScreen({super.key, this.user});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late int _unlockedLevel;
  late Map<int, int> _bestScores;

  final AvatarService _avatarService = AvatarService();
  final AuthService _authService = AuthService();
  AvatarSelection _avatar = const AvatarSelection();

  String get _username => widget.user?.username ?? 'Jugador';

  @override
  void initState() {
    super.initState();
    _unlockedLevel = widget.user?.unlockedLevel ?? 1;
    _bestScores = Map<int, int>.from(widget.user?.bestScores ?? {});
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final saved = await _avatarService.load();
    if (!mounted) return;
    setState(() => _avatar = saved);
  }

  /// Abre el selector de icono. Solo cambia el avatar si el usuario lo confirma.
  Future<void> _changeAvatar() async {
    final selection = await showAvatarPicker(context, _avatar);
    if (selection == null) return;
    await _avatarService.save(selection);
    if (!mounted) return;
    setState(() => _avatar = selection);
  }

  /// Cierra la sesión y regresa a la pantalla de inicio de sesión.
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text('¿Deseas salir de la cuenta "$_username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Salir',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _openLevel(int level) async {
    if (level > _unlockedLevel) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => GameScreen(level: level),
        fullscreenDialog: false,
      ),
    );
    if (!mounted) return;
    // El juego ya guardó el avance en la cuenta; aquí solo se refresca.
    final updated = await _authService.getCurrentUser();
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _unlockedLevel = updated.unlockedLevel;
        _bestScores = Map<int, int>.from(updated.bestScores);
      });
    }
    if (result != null && result['won'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            level < 3
                ? '¡Nivel $level completado! Nivel ${level + 1} desbloqueado 🎉'
                : '¡Nivel máximo completado! 🏆',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Memory Honduras'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
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
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                const Text(
                  'Selecciona un Nivel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0033A0),
                  ),
                ),
                const SizedBox(height: 16),
                ...LevelConfig.levels.map((config) => _buildLevelCard(config)),
                const SizedBox(height: 24),
                _buildLegend(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(selection: _avatar, radius: 28),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF0033A0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nivel $_unlockedLevel/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelConfig config) {
    final unlocked = config.level <= _unlockedLevel;
    final bestScore = _bestScores[config.level] ?? 0;

    late Color bgColor;
    late Color accentColor;
    switch (config.level) {
      case 1:
        bgColor = const Color(0xFFE8F5E9);
        accentColor = Colors.green;
        break;
      case 2:
        bgColor = const Color(0xFFFFF8E1);
        accentColor = Colors.orange;
        break;
      case 3:
        bgColor = const Color(0xFFFFEBEE);
        accentColor = Colors.red;
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        accentColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unlocked ? () => _openLevel(config.level) : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: unlocked ? bgColor : const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked ? accentColor : const Color(0xFFB0BEC5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Opacity(
                    opacity: unlocked ? 1.0 : 0.5,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: unlocked ? 0.15 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: unlocked
                            ? Text(
                                '${config.level}',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              )
                            : const Icon(
                                Icons.lock,
                                size: 36,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nivel ${config.level}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: unlocked
                                    ? _darken(accentColor, 0.3)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: unlocked
                                    ? accentColor.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                config.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: unlocked ? accentColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unlocked
                              ? config.description
                              : 'Completa el nivel anterior',
                          style: TextStyle(
                            color: unlocked
                                ? const Color(0xFF424242)
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            _miniStat(
                              Icons.timer,
                              '${config.timeSeconds}s',
                              accentColor,
                              unlocked,
                            ),
                            _miniStat(
                              Icons.style,
                              '${config.pairs} pares',
                              accentColor,
                              unlocked,
                            ),
                            if (unlocked && bestScore > 0)
                              _miniStat(
                                Icons.star,
                                '$bestScore pts',
                                accentColor,
                                unlocked,
                                filledStar: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (unlocked)
                    Icon(Icons.arrow_forward_ios, color: accentColor, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
    IconData icon,
    String text,
    Color accent,
    bool unlocked, {
    bool filledStar = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: unlocked ? accent : Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: unlocked ? _darken(accent, 0.2) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final symbols = HonduranSymbols.all;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Símbolos Patrios de Honduras',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0033A0),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: symbols.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        s.image,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
