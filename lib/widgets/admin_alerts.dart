import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ui_kit.dart';

/// Alertas del panel del administrador.
///
/// El servidor Rocky revisa las métricas cada vez que el panel se actualiza
/// (cada 5 segundos) y manda una lista de alertas. Aquí se muestran, y con un
/// botón el administrador le puede pedir a la IA que le explique qué hacer.
class AdminAlerts extends StatefulWidget {
  final List alertas;

  const AdminAlerts({super.key, required this.alertas});

  @override
  State<AdminAlerts> createState() => _AdminAlertsState();
}

class _AdminAlertsState extends State<AdminAlerts> {
  final ApiService _api = ApiService();
  String? _advice;
  bool _adviceIsError = false;
  bool _loading = false;

  Future<void> _askAi() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _advice = null;
    });
    String text;
    var isError = false;
    try {
      final resp = await _api.post(
        '/api/ia/admin/preguntar',
        {
          'pregunta':
              'Explícame brevemente las alertas actuales del panel y dime qué '
              'hacer con cada una.',
        },
        auth: true,
        timeout: const Duration(seconds: 40),
      );
      final answer = resp.ok && resp.data is Map
          ? ((resp.data as Map)['respuesta'] as String? ?? '').trim()
          : '';
      if (answer.isNotEmpty) {
        text = answer;
      } else {
        text = resp.message;
        isError = true;
      }
    } on ApiException catch (e) {
      text = e.message;
      isError = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _advice = text;
      _adviceIsError = isError;
    });
  }

  Color _color(String nivel) {
    switch (nivel) {
      case 'alta':
        return AppColors.danger;
      case 'media':
        return const Color(0xFFB8860B);
      default:
        return AppColors.blueLight;
    }
  }

  IconData _icon(String nivel) {
    switch (nivel) {
      case 'alta':
        return Icons.error_rounded;
      case 'media':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertas = widget.alertas
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();

    if (alertas.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Todo en orden: no hay alertas en este momento.',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...alertas.map((a) {
            final nivel = '${a['nivel']}';
            final color = _color(nivel);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icon(nivel), color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a['titulo']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a['detalle']}',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          if (_advice != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _adviceIsError
                    ? const Color(0xFFFDECEA)
                    : AppColors.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _adviceIsError ? Icons.error_outline : Icons.auto_awesome,
                    size: 18,
                    color: _adviceIsError ? AppColors.danger : AppColors.ink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      _advice!,
                      style: TextStyle(
                        color: _adviceIsError ? AppColors.danger : AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loading ? null : _askAi,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'La IA está revisando...' : '¿Qué hago? Pregúntale a la IA'),
            ),
          ),
        ],
      ),
    );
  }
}
