import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/ui_kit.dart';

/// Ranking global de jugadores, leído de la base de datos del servidor.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  static const List<String> _labels = ['General', 'Nivel 1', 'Nivel 2', 'Nivel 3'];

  final ApiService _api = ApiService();
  int _filter = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  String? _me;

  @override
  void initState() {
    super.initState();
    _loadMe();
    _load();
  }

  Future<void> _loadMe() async {
    final user = await AuthService().getCurrentUser();
    if (!mounted) return;
    setState(() => _me = user?.username);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = _filter == 0 ? '/api/ranking' : '/api/ranking?nivel=$_filter';
      final resp = await _api.get(path);
      if (!mounted) return;
      if (resp.ok && resp.data is List) {
        setState(() {
          _rows = (resp.data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = resp.message;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ranking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Los mejores jugadores de Honduras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_labels.length, (i) {
              final selected = _filter == i;
              return ChoiceChip(
                label: Text(_labels[i]),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.blue,
                backgroundColor: AppColors.sky,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.blue,
                ),
                onSelected: (_) {
                  if (_filter == i) return;
                  setState(() => _filter = i);
                  _load();
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay partidas ganadas.\n¡Sé el primero en el ranking!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildTile(_rows[i], i),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> row, int index) {
    final name = (row['usuario'] as String?) ?? '';
    final points = (row['puntaje'] as num?)?.toInt() ?? 0;
    final isMe = _me != null && name.toLowerCase() == _me!.toLowerCase();
    const medals = ['🥇', '🥈', '🥉'];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: isMe ? AppColors.goldSoft : Colors.white,
      borderColor: isMe ? AppColors.gold : AppColors.line,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: index < 3 ? AppColors.goldSoft : AppColors.sky,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: index < 3
                  ? Text(medals[index], style: const TextStyle(fontSize: 20))
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '$name (tú)' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          InfoPill(
            icon: Icons.star_rounded,
            text: '$points pts',
            color: AppColors.blue,
          ),
        ],
      ),
    );
  }
}
