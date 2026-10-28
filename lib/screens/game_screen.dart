import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_symbol.dart';
import '../services/ai_narrator.dart';
import '../services/auth_service.dart';
import '../widgets/fact_banner.dart';
import '../widgets/game_card.dart';

class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({super.key, required this.level});

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

  @override
  void initState() {
    super.initState();
    _config = LevelConfig.get(widget.level);
    _timeLeft = _config.timeSeconds;
    _initDeck();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _factTimer?.cancel();
    super.dispose();
  }

  void _initDeck() {
    final symbols = HonduranSymbols.getForLevel(widget.level);
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
    HapticFeedback.selectionClick();

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
      HapticFeedback.lightImpact();
      _tellFact(_deck[first]);
      if (_matches == _config.pairs) {
        _timer?.cancel();
        _endGame(win: true);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
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
      HapticFeedback.heavyImpact();
      _saveProgress();
    } else {
      HapticFeedback.vibrate();
    }
    if (!mounted) return;
    setState(() {
      _finished = true;
      _won = win;
    });
  }

  /// Guarda el avance en la cuenta del usuario que inició sesión.
  Future<void> _saveProgress() async {
    await AuthService().updateUserProgress(
      levelCompleted: widget.level,
      score: _score,
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
    if (total <= 8) return 4;
    if (total <= 16) return 4;
    return 6;
  }

  double _cardSizeFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxis = _crossAxisCount;
    final usableWidth = screenWidth - 32 - (crossAxis - 1) * 8;
    final byWidth = usableWidth / crossAxis;
    final total = _deck.length;
    if (total <= 8) return byWidth.clamp(60.0, 90.0);
    if (total <= 16) return byWidth.clamp(56.0, 80.0);
    return byWidth.clamp(46.0, 68.0);
  }

  @override
  Widget build(BuildContext context) {
    final timeLow = _timeLeft <= 10;
    final cardSize = _cardSizeFor(context);
    final timeBg = timeLow ? const Color(0xFFFFEBEE) : Colors.white;
    final timeValueColor = timeLow
        ? const Color(0xFFC62828)
        : const Color(0xFF0033A0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text('Nivel ${widget.level} · ${_config.name}'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToMenu,
        ),
        actions: [
          IconButton(
            tooltip: 'Reiniciar',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F6FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Row(
                      children: [
                        _buildStat(
                          '⏱️',
                          '$_timeLeft s',
                          'Tiempo',
                          bg: timeBg,
                          valueColor: timeValueColor,
                          isTime: timeLow,
                        ),
                        const SizedBox(width: 8),
                        _buildStat('🎯', '$_matches/${_config.pairs}', 'Pares'),
                        const SizedBox(width: 8),
                        _buildStat('👆', '$_moves', 'Movidas'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: _deck.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: GameCard(
                                symbol: _deck[index],
                                isFlipped: _flipped[index],
                                isMatched: _matched[index],
                                onTap: () => _onCardTap(index),
                                size: cardSize,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_finished) _buildResultSheet(),
                ],
              ),
              if (_showFact && !_finished)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FactBanner(
                    symbolName: _factSymbol?.name ?? '',
                    text: _factText,
                    fromAi: _factFromAi,
                    onClose: _hideFact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    String emoji,
    String value,
    String label, {
    Color bg = Colors.white,
    Color valueColor = const Color(0xFF0033A0),
    bool isTime = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTime ? const Color(0xFFEF5350) : const Color(0xFFBBDEFB),
            width: isTime ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              child: Text(value),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSheet() {
    final win = _won;
    final nextUnlocked = win && widget.level < 3;
    final timeSpent = _config.timeSeconds - _timeLeft;

    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: Card(
          elevation: 14,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  win ? '🎉 ¡Felicidades!' : '⏰ ¡Tiempo Agotado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: win
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  win
                      ? 'Has completado el Nivel ${widget.level}'
                      : 'No te rindas, ¡sigue intentando!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: win
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statMini('⏱️', '${timeSpent}s', 'Tiempo'),
                          _statMini('👆', '$_moves', 'Movidas'),
                          _statMini(
                            '🎯',
                            '$_matches/${_config.pairs}',
                            'Pares',
                          ),
                        ],
                      ),
                      if (win) ...[
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(height: 1),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final ratio =
                                _score / (_config.pairs * 100 + 60 * 5);
                            if (i == 0) {
                              return const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB300),
                                size: 32,
                              );
                            } else if (i == 1) {
                              return Icon(
                                ratio > 0.4
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFB300),
                                size: 32,
                              );
                            } else {
                              return Icon(
                                ratio > 0.7
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFB300),
                                size: 32,
                              );
                            }
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_score pts',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8F00),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (nextUnlocked) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_open_rounded, color: Color(0xFF0033A0)),
                        SizedBox(width: 8),
                        Text(
                          '¡Nivel siguiente desbloqueado!',
                          style: TextStyle(
                            color: Color(0xFF0033A0),
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
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF0033A0),
                            width: 1.5,
                          ),
                          foregroundColor: const Color(0xFF0033A0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF0033A0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                if (win && widget.level < 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(level: widget.level + 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(
                        'Jugar Nivel ${widget.level + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0033A0),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statMini(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF616161)),
        ),
      ],
    );
  }
}
