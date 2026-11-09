import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/ui_kit.dart';

/// Muestra en la app las métricas que calcula el servidor Rocky Linux.
/// Todos los números salen de MySQL; la app solo los presenta.
class ServerStatsScreen extends StatefulWidget {
  const ServerStatsScreen({super.key});

  @override
  State<ServerStatsScreen> createState() => _ServerStatsScreenState();
}

class _ServerStatsScreenState extends State<ServerStatsScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final resp = await _api.get('/api/metricas', auth: true);
      if (!mounted) return;
      if (resp.ok && resp.data is Map) {
        setState(() {
          _data = Map<String, dynamic>.from(resp.data as Map);
          _error = null;
        });
      } else {
        setState(() => _error = resp.message);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  String _dur(int seg) {
    if (seg < 60) return '$seg s';
    final m = seg ~/ 60;
    final s = seg % 60;
    if (m < 60) return '$m min $s s';
    final h = m ~/ 60;
    return '$h h ${m % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Panel del administrador',
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
          child: _data == null ? _buildWaiting() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 54, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: GradientButton(
                  label: 'Reintentar',
                  icon: Icons.refresh_rounded,
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    final d = _data!;
    final p = Map<String, dynamic>.from(d['partidas'] as Map? ?? {});
    final srv = Map<String, dynamic>.from(d['servidor'] as Map? ?? {});
    final total = _n(p['total']);
    final won = _n(p['ganadas']);
    final pct = total == 0 ? 0 : (won * 100 / total).round();
    final niveles = (d['porNivel'] as List? ?? []);
    final dias = (d['partidasPorDia'] as List? ?? []);
    final totalMB = _n(srv['memoriaTotalMB']);
    final libreMB = _n(srv['memoriaLibreMB']);
    final usoMB = totalMB - libreMB;
    final usoRatio = totalMB == 0 ? 0.0 : usoMB / totalMB;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const InfoPill(
                    icon: Icons.circle,
                    text: 'Servidor en línea',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  InfoPill(
                    icon: Icons.auto_awesome,
                    text: srv['iaConfigurada'] == true
                        ? 'IA activa'
                        : 'IA: respaldo local',
                    color: srv['iaConfigurada'] == true
                        ? AppColors.success
                        : AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _kpi(Icons.people_alt_rounded, '${_n(d['usuarios'])}',
                        'Usuarios'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child:
                        _kpi(Icons.sports_esports_rounded, '$total', 'Partidas'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpi(Icons.emoji_events_rounded, '$pct%', 'Ganadas'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                icon: Icons.bar_chart_rounded,
                text: 'Partidas por nivel',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: niveles.map((raw) {
                    final f = Map<String, dynamic>.from(raw as Map);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nivel ${_n(f['nivel'])} · ${f['dificultad'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          InfoPill(
                            text: '${_n(f['jugadas'])} jugadas',
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 6),
                          InfoPill(
                            text: 'Mejor ${_n(f['mejorPuntaje'])}',
                            color: const Color(0xFFB8860B),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                icon: Icons.calendar_month_rounded,
                text: 'Últimos 7 días',
              ),
              const SizedBox(height: 12),
              AppCard(child: _buildBars(dias)),
              const SizedBox(height: 22),
              const SectionTitle(
                icon: Icons.dns_rounded,
                text: 'Servidor',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _row('Sistema', '${srv['sistema'] ?? '-'}'),
                    _row('Equipo', '${srv['equipo'] ?? '-'}'),
                    _row('Procesadores', '${_n(srv['cpus'])}'),
                    _row('Carga del CPU', '${srv['cargaCpu'] ?? 0}'),
                    _row('Node.js', '${srv['node'] ?? '-'}'),
                    _row('Encendido hace', _dur(_n(srv['encendidoSeg']))),
                    _row('API activa hace', _dur(_n(srv['apiActivaSeg']))),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Memoria: $usoMB MB de $totalMB MB',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: usoRatio.clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Datos calculados por el servidor, se actualizan cada 5 segundos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpi(IconData icon, String value, String label) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blueLight, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
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

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(List dias) {
    if (dias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Todavía no hay partidas en los últimos 7 días',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    final items = dias.map((raw) => Map<String, dynamic>.from(raw as Map)).toList();
    var maxV = 1;
    for (final f in items) {
      if (_n(f['total']) > maxV) maxV = _n(f['total']);
    }
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((f) {
          final v = _n(f['total']);
          final dia = '${f['dia']}';
          final label = dia.length >= 10 ? '${dia.substring(8, 10)}/${dia.substring(5, 7)}' : dia;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$v',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 6 + 70 * v / maxV,
                  decoration: BoxDecoration(
                    gradient: AppColors.hero,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.muted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
