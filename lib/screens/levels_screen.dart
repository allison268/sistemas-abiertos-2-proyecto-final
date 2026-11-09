import 'package:flutter/material.dart';

import '../models/card_symbol.dart';
import '../models/profile_avatars.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'server_stats_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';
import '../services/store_service.dart';

class _LevelStyle {
  final Color accent;
  const _LevelStyle(this.accent);
}

_LevelStyle _styleFor(int level) {
  switch (level) {
    case 1:
      return const _LevelStyle(Color(0xFF2E7D32));
    case 2:
      return const _LevelStyle(Color(0xFFEF6C00));
    case 3:
      return const _LevelStyle(Color(0xFFC62828));
    default:
      return const _LevelStyle(Color(0xFF607D8B));
  }
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
  final ApiService _api = ApiService();
  AvatarSelection _avatar = const AvatarSelection();
  Map<String, dynamic>? _stats;
  Set<String> _owned = {};
  GameMode _mode = GameMode.simbolos;
  bool _isAdmin = false;

  String get _username => widget.user?.username ?? 'Jugador';

  @override
  void initState() {
    super.initState();
    _unlockedLevel = widget.user?.unlockedLevel ?? 1;
    _bestScores = Map<int, int>.from(widget.user?.bestScores ?? {});
    _loadAvatar();
    _loadStats();
    _loadOwned();
    _loadRole();
  }

  /// El servidor decide si la cuenta es de administrador.
  Future<void> _loadRole() async {
    await _authService.getCurrentUser();
    final admin = await _authService.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = admin);
  }

  Future<void> _loadAvatar() async {
    final saved = await _avatarService.load();
    if (!mounted) return;
    setState(() => _avatar = saved);
  }

  /// Estadísticas del jugador, calculadas por el servidor.
  Future<void> _loadStats() async {
    try {
      final resp = await _api.get('/api/usuarios/me/estadisticas', auth: true);
      if (!mounted) return;
      if (resp.ok && resp.data is Map) {
        setState(() => _stats = Map<String, dynamic>.from(resp.data as Map));
      }
    } catch (_) {
      // Sin conexión: simplemente no se muestran las estadísticas.
    }
  }

  /// Productos que el jugador ya compró en la tienda.
  Future<void> _loadOwned() async {
    try {
      final list = await StoreService().myPurchases();
      if (!mounted) return;
      setState(() => _owned = list.map((c) => c.clave).toSet());
    } catch (_) {
      // Sin conexión: no se muestran insignias.
    }
  }

  Future<void> _openStore() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
    _loadOwned();
  }

  /// Abre el selector de icono. Solo cambia el avatar si el usuario lo confirma.
  Future<void> _changeAvatar() async {
    final selection = await showAvatarPicker(context, _avatar);
    if (selection == null) return;
    await _avatarService.save(selection);
    if (!mounted) return;
    setState(() => _avatar = selection);
  }

  void _openServerStats() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ServerStatsScreen()));
  }

  void _openRanking() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RankingScreen()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openLevel(int level) async {
    if (level > _unlockedLevel) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => GameScreen(level: level, mode: _mode),
        fullscreenDialog: false,
      ),
    );
    if (!mounted) return;
    // El juego ya guardó la partida en el servidor; aquí solo se refresca.
    final updated = await _authService.getCurrentUser();
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _unlockedLevel = updated.unlockedLevel;
        _bestScores = Map<int, int>.from(updated.bestScores);
      });
    }
    _loadStats();
    if (result != null && result['won'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            level < 3
                ? '¡Nivel $level completado! Nivel ${level + 1} desbloqueado'
                : '¡Nivel máximo completado!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Memory Honduras',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tienda',
            onPressed: _openStore,
            icon: const Icon(Icons.storefront_rounded),
          ),
          if (_isAdmin)
            IconButton(
              tooltip: 'Panel del administrador',
              onPressed: _openServerStats,
              icon: const Icon(Icons.admin_panel_settings_rounded),
            ),
          IconButton(
            tooltip: 'Ranking',
            onPressed: _openRanking,
            icon: const Icon(Icons.emoji_events_rounded),
          ),
          IconButton(
            tooltip: 'Configuración',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    if (_stats != null) ...[
                      const SizedBox(height: 14),
                      _buildStats(),
                    ],
                    const SizedBox(height: 20),
                    _buildModeSelector(),
                    const SizedBox(height: 22),
                    const SectionTitle(
                      icon: Icons.flag_rounded,
                      text: 'Selecciona un nivel',
                    ),
                    const SizedBox(height: 14),
                    ...LevelConfig.levels.map(_buildLevelCard),
                    const SizedBox(height: 4),
                    _outlineAction(
                      Icons.emoji_events_rounded,
                      'Ver ranking global',
                      _openRanking,
                    ),
                    const SizedBox(height: 26),
                    _buildSymbols(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlineAction(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }

  Widget _buildHero() {
    final completed = _bestScores.values.where((v) => v > 0).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.hero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                      child: ProfileAvatar(selection: _avatar, radius: 28),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 13,
                          color: AppColors.blue,
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
                        color: Color(0xFFD6E4FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_isAdmin ||
                        _owned.contains('premium') ||
                        _owned.contains('insignia_catracho') ||
                        _owned.contains('donacion')) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_isAdmin)
                            _badge(
                              Icons.admin_panel_settings_rounded,
                              'Administrador',
                            ),
                          if (_owned.contains('premium'))
                            _badge(Icons.workspace_premium_rounded, 'Premium'),
                          if (_owned.contains('insignia_catracho'))
                            _badge(Icons.flag_rounded, 'Catracho'),
                          if (_owned.contains('donacion'))
                            _badge(
                              Icons.volunteer_activism_rounded,
                              'Colaborador',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nivel $_unlockedLevel/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tu progreso',
                style: TextStyle(color: Color(0xFFD6E4FF), fontSize: 12.5),
              ),
              Text(
                '$completed de 3 niveles completados',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completed / 3,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats ?? const <String, dynamic>{};
    final played = (s['intentos'] as num?)?.toInt() ?? 0;
    final won = (s['ganadas'] as num?)?.toInt() ?? 0;
    final pct = ((s['promedioVictorias'] as num?)?.toDouble() ?? 0).round();
    return Row(
      children: [
        Expanded(
          child: _statTile(Icons.sports_esports_rounded, '$played', 'Partidas'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(Icons.emoji_events_rounded, '$won', 'Victorias'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(Icons.percent_rounded, '$pct%', 'Efectividad'),
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blueLight, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelConfig config) {
    final unlocked = config.level <= _unlockedLevel;
    final best = _bestScores[config.level] ?? 0;
    final accent = unlocked
        ? _styleFor(config.level).accent
        : const Color(0xFF90A4AE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: unlocked ? 0.14 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: unlocked ? () => _openLevel(config.level) : null,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: unlocked
                      ? accent.withValues(alpha: 0.45)
                      : AppColors.line,
                  width: 1.5,
                ),
              ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: unlocked
                          ? LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: unlocked ? null : const Color(0xFFCFD8DC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: unlocked
                          ? Text(
                              '${config.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                config.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: unlocked
                                      ? AppColors.ink
                                      : const Color(0xFF78909C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InfoPill(text: 'Nivel ${config.level}', color: accent),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unlocked
                              ? config.description
                              : 'Completa el nivel anterior para desbloquearlo',
                          style: TextStyle(
                            color: unlocked
                                ? AppColors.muted
                                : const Color(0xFF90A4AE),
                            fontSize: 12.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            InfoPill(
                              icon: Icons.timer_rounded,
                              text: '${config.timeSeconds}s',
                              color: accent,
                            ),
                            InfoPill(
                              icon: Icons.style_rounded,
                              text: '${config.pairs} pares',
                              color: accent,
                            ),
                            if (unlocked && best > 0)
                              InfoPill(
                                icon: Icons.star_rounded,
                                text: '$best pts',
                                color: const Color(0xFFB8860B),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    unlocked
                        ? Icons.play_circle_fill_rounded
                        : Icons.lock_outline_rounded,
                    color: accent,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    Widget chip(GameMode mode, IconData icon, String label, String sub) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.hero : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.line,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.gold : AppColors.blueLight,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? const Color(0xFFD6E4FF) : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          icon: Icons.sports_esports_rounded,
          text: 'Modo de juego',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            chip(
              GameMode.simbolos,
              Icons.flag_rounded,
              'Símbolos patrios',
              '13 símbolos',
            ),
            const SizedBox(width: 12),
            chip(
              GameMode.departamentos,
              Icons.map_rounded,
              'Departamentos',
              '18 departamentos',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymbols() {
    final isSymbols = _mode == GameMode.simbolos;
    final symbols = isSymbols ? HonduranSymbols.all : HonduranDepartments.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          icon: Icons.collections_bookmark_rounded,
          text: isSymbols
              ? 'Símbolos patrios de Honduras'
              : 'Departamentos de Honduras',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: symbols.map((s) {
            return Container(
              width: 96,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      s.image,
                      width: 80,
                      height: 70,
                      fit: isSymbols ? BoxFit.cover : BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 80,
                        height: 70,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
