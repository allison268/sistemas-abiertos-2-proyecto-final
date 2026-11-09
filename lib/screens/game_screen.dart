import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_symbol.dart';
import '../services/ai_narrator.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/store_service.dart';
import '../widgets/confetti.dart';
import '../widgets/fact_banner.dart';
import '../widgets/game_card.dart';
import '../widgets/ui_kit.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final GameMode mode;

  const GameScreen({
    super.key,
    required this.level,
    this.mode = GameMode.simbolos,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LevelConfig _config;
  late List<CardSymbol> _deck;
  late List<bool> _flipped;
  late List<bool> _matched;
  int? _firstIndex;
  bool _processing = false;
  int _moves = 0;
  int _matches = 0;
  late int _timeLeft;
  Timer? _timer;
  bool _finished = false;
  bool _won = false;
  int _score = 0;

  final AiNarrator _narrator = AiNarrator();
  CardSymbol? _factSymbol;
  String? _factText;
  bool _factFromAi = false;
  bool _showFact = false;
  Timer? _factTimer;

  bool _gold = false;
  int _round = 0;
  Set<int> _wrong = <int>{};

  @override
  void initState() {
    super.initState();
    _config = LevelConfig.get(widget.level);
    _timeLeft = _config.timeSeconds;
    _initDeck();
    _startTimer();
    _loadTheme();
    SettingsService.load();
  }

  /// Si el jugador compró el diseño dorado en la tienda, se usa en las cartas.
  Future<void> _loadTheme() async {
    try {
      final list = await StoreService().myPurchases();
      if (!mounted) return;
      setState(() => _gold = list.any((c) => c.clave == 'cartas_doradas'));
    } catch (_) {
      // Sin conexión: se usa el diseño normal.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _factTimer?.cancel();
    super.dispose();
  }

  void _initDeck() {
    final symbols = widget.mode == GameMode.departamentos
        ? HonduranDepartments.randomForLevel(widget.level)
        : HonduranSymbols.getForLevel(widget.level);
    _deck = <CardSymbol>[];
    for (final s in symbols) {
      _deck.add(s);
      _deck.add(s);
    }
    final rnd = Random();
    for (var i = _deck.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = _deck[i];
      _deck[i] = _deck[j];
      _deck[j] = tmp;
    }
    _flipped = List<bool>.filled(_deck.length, false, growable: false);
    _matched = List<bool>.filled(_deck.length, false, growable: false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        timer.cancel();
        _endGame(win: false);
      }
    });
  }

  Future<void> _onCardTap(int index) async {
    if (_processing || _flipped[index] || _matched[index] || _finished) return;

    setState(() => _flipped[index] = true);
    SettingsService.haptic(HapticFeedback.selectionClick);
    SoundService.play(Sfx.flip);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    if (first == index) return;

    setState(() {
      _processing = true;
      _moves++;
    });

    if (_deck[first].id == _deck[index].id) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
        _matches++;
        _firstIndex = null;
        _processing = false;
      });
      SettingsService.haptic(HapticFeedback.lightImpact);
      SoundService.play(Sfx.match);
      _tellFact(_deck[first]);
      if (_matches == _config.pairs) {
        _timer?.cancel();
        _endGame(win: true);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _wrong = {first, index});
      SoundService.play(Sfx.wrong);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _wrong = <int>{};
        _flipped[first] = false;
        _flipped[index] = false;
        _firstIndex = null;
        _processing = false;
      });
    }
  }

  /// Pide a la IA un dato del símbolo y lo muestra sin interrumpir el juego.
  Future<void> _tellFact(CardSymbol symbol) async {
    _factTimer?.cancel();
    setState(() {
      _factSymbol = symbol;
      _factText = null;
      _factFromAi = false;
      _showFact = true;
    });
    final narration = await _narrator.narrate(symbol);
    if (!mounted) return;
    setState(() {
      _factText = narration.text;
      _factFromAi = narration.fromAi;
    });
    _factTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _showFact = false);
    });
  }

  void _hideFact() {
    _factTimer?.cancel();
    if (mounted) setState(() => _showFact = false);
  }

  void _endGame({required bool win}) {
    if (_finished) return;
    if (win) {
      final baseScore = _config.pairs * 100;
      final timeBonus = _timeLeft * 5;
      final movesPenalty = max(0, _moves - _config.pairs) * 5;
      _score = max(0, baseScore + timeBonus - movesPenalty);
      SettingsService.haptic(HapticFeedback.heavyImpact);
      SoundService.play(Sfx.win);
    } else {
      SettingsService.haptic(HapticFeedback.vibrate);
      SoundService.play(Sfx.lose);
    }
    _saveProgress(win: win);
    if (!mounted) return;
    setState(() {
      _finished = true;
      _won = win;
    });
  }

  /// Guarda la partida (ganada o perdida) en el servidor.
  Future<void> _saveProgress({required bool win}) async {
    await AuthService().recordGame(
      level: widget.level,
      won: win,
      score: win ? _score : 0,
      moves: _moves,
      pairs: _matches,
      durationSeconds: _config.timeSeconds - _timeLeft,
      mode: widget.mode == GameMode.departamentos ? 'departamentos' : 'simbolos',
    );
  }

  void _restart() {
    _timer?.cancel();
    _factTimer?.cancel();
    setState(() {
      _moves = 0;
      _matches = 0;
      _timeLeft = _config.timeSeconds;
      _firstIndex = null;
      _processing = false;
      _finished = false;
      _won = false;
      _score = 0;
      _showFact = false;
      _factText = null;
      _wrong = <int>{};
      _round++;
      _initDeck();
    });
    _startTimer();
  }

  void _backToMenu() {
    _timer?.cancel();
    Navigator.of(context).pop({'won': _won, 'score': _score});
  }

  int get _crossAxisCount {
    final total = _deck.length;
    if (total <= 16) return 4;
    return MediaQuery.of(context).size.width >= 620 ? 6 : 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.mode == GameMode.departamentos
              ? 'Departamentos · Nivel ${widget.level}'
              : 'Nivel ${widget.level} · ${_config.name}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToMenu,
        ),
        actions: [
          IconButton(
            tooltip: 'Reiniciar',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    children: [
                      _buildHud(),
                      Expanded(child: _buildBoard()),
                    ],
                  ),
                ),
              ),
              if (_showFact && !_finished)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: FactBanner(
                        symbolName: _factSymbol?.name ?? '',
                        text: _factText,
                        fromAi: _factFromAi,
                        onClose: _hideFact,
                      ),
                    ),
                  ),
                ),
              if (_finished) Positioned.fill(child: _buildResultOverlay()),
              if (_finished && _won)
                Positioned.fill(child: Confetti(key: ValueKey('confeti-$_round'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final timeLow = _timeLeft <= 10;
    final ratio = (_timeLeft / _config.timeSeconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              _buildStat(
                Icons.timer_rounded,
                '$_timeLeft s',
                'Tiempo',
                alert: timeLow,
              ),
              const SizedBox(width: 10),
              _buildStat(
                Icons.style_rounded,
                '$_matches/${_config.pairs}',
                'Pares',
              ),
              const SizedBox(width: 10),
              _buildStat(Icons.touch_app_rounded, '$_moves', 'Movidas'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation<Color>(
                timeLow ? AppColors.danger : AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String label, {
    bool alert = false,
  }) {
    final color = alert ? AppColors.danger : AppColors.blue;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert ? const Color(0xFFEF5350) : AppColors.line,
            width: alert ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cols = _crossAxisCount;
        final rows = (_deck.length / cols).ceil();
        final availW = constraints.maxWidth - 32;
        final availH = constraints.maxHeight - 90;
        final byW = (availW - (cols - 1) * gap) / cols;
        final byH = (availH - (rows - 1) * gap) / rows;
        final cardSize = (byW < byH ? byW : byH).clamp(44.0, 190.0);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: List.generate(_deck.length, (index) {
                return GameCard(
                  key: ValueKey('$_round-$index'),
                  gold: _gold,
                  shake: _wrong.contains(index),
                  entranceDelay: min(index * 35, 700),
                  symbol: _deck[index],
                  isFlipped: _flipped[index],
                  isMatched: _matched[index],
                  onTap: () => _onCardTap(index),
                  size: cardSize,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultOverlay() {
    final win = _won;
    final nextUnlocked = win && widget.level < 3;
    final timeSpent = _config.timeSeconds - _timeLeft;
    final accent = win ? AppColors.success : AppColors.danger;
    final ratio = _score / (_config.pairs * 100 + 60 * 5);
    final stars = !win ? 0 : (ratio > 0.7 ? 3 : (ratio > 0.4 ? 2 : 1));

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey('trofeo-$_round-$win'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: win ? 1100 : 400),
                    curve: win ? Curves.elasticOut : Curves.easeOut,
                    builder: (context, t, child) => Transform.scale(
                      scale: t.clamp(0.0, 1.5),
                      child: Transform.rotate(
                        angle: win ? (1 - t.clamp(0.0, 1.0)) * -0.5 : 0,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: win
                            ? AppColors.hero
                            : const LinearGradient(
                                colors: [Color(0xFF8E1B1B), Color(0xFFD32F2F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: Border.all(color: AppColors.gold, width: 3),
                        boxShadow: win
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.55),
                                  blurRadius: 26,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        win
                            ? Icons.emoji_events_rounded
                            : Icons.hourglass_bottom_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    win ? '¡Felicidades!' : '¡Tiempo agotado!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    win
                        ? 'Has completado el Nivel ${widget.level}'
                        : 'No te rindas, sigue intentando',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statMini(Icons.timer_rounded, '${timeSpent}s', 'Tiempo'),
                            _statMini(Icons.touch_app_rounded, '$_moves', 'Movidas'),
                            _statMini(
                              Icons.style_rounded,
                              '$_matches/${_config.pairs}',
                              'Pares',
                            ),
                          ],
                        ),
                        if (win) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              final icon = Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.gold,
                                size: 34,
                              );
                              if (i >= stars) return icon;
                              return TweenAnimationBuilder<double>(
                                key: ValueKey('estrella-$_round-$i'),
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 700 + i * 450),
                                curve: Curves.elasticOut,
                                builder: (context, t, child) => Transform.scale(
                                  scale: t.clamp(0.0, 1.6),
                                  child: child,
                                ),
                                child: icon,
                              );
                            }),
                          ),
                          Text(
                            '$_score pts',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB8860B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (nextUnlocked) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sky,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, color: AppColors.blue),
                          SizedBox(width: 8),
                          Text(
                            '¡Nivel siguiente desbloqueado!',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _backToMenu,
                          icon: const Icon(Icons.menu_rounded),
                          label: const Text(
                            'Menú',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            foregroundColor: AppColors.blue,
                            side: const BorderSide(
                              color: AppColors.blue,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          label: 'Reintentar',
                          icon: Icons.refresh_rounded,
                          onPressed: _restart,
                        ),
                      ),
                    ],
                  ),
                  if (nextUnlocked) ...[
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Jugar Nivel ${widget.level + 1}',
                      icon: Icons.skip_next_rounded,
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              level: widget.level + 1,
                              mode: widget.mode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statMini(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.blue),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
