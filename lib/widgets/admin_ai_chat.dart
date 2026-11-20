import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ui_kit.dart';

/// Un mensaje del chat: lo que escribió el administrador o lo que respondió la IA.
class _ChatMessage {
  final String text;
  final bool fromAdmin;
  final bool isError;

  const _ChatMessage(this.text, {this.fromAdmin = false, this.isError = false});
}

/// Caja de chat del panel del administrador.
///
/// El administrador escribe una pregunta y la app la manda al servidor
/// (/api/ia/admin/preguntar). El servidor lee las métricas actuales de MySQL,
/// se las pasa a Gemini y devuelve la respuesta. La app solo muestra el chat.
class AdminAiChat extends StatefulWidget {
  const AdminAiChat({super.key});

  @override
  State<AdminAiChat> createState() => _AdminAiChatState();
}

class _AdminAiChatState extends State<AdminAiChat> {
  final ApiService _api = ApiService();
  final TextEditingController _input = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  /// Preguntas de ejemplo para que el administrador no empiece en blanco.
  static const List<String> _suggestions = [
    '¿Cómo va el juego hoy?',
    '¿Qué nivel pierden más?',
    '¿Cuánto hemos vendido?',
    '¿El servidor está bien?',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _input.text).trim();
    if (question.length < 2 || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(question, fromAdmin: true));
      _sending = true;
      _input.clear();
    });
    try {
      // La IA puede tardar más que una petición normal, por eso 40 segundos.
      final resp = await _api.post(
        '/api/ia/admin/preguntar',
        {'pregunta': question},
        auth: true,
        timeout: const Duration(seconds: 40),
      );
      if (!mounted) return;
      final answer = resp.ok && resp.data is Map
          ? ((resp.data as Map)['respuesta'] as String? ?? '').trim()
          : '';
      setState(() {
        _messages.add(answer.isNotEmpty
            ? _ChatMessage(answer)
            : _ChatMessage(resp.message, isError: true));
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(e.message, isError: true)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pregúntale a la IA sobre los datos del juego. Responde con las '
            'métricas actuales del servidor.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (_messages.isEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: _sending ? null : () => _send(s),
                        backgroundColor: AppColors.sky,
                        side: const BorderSide(color: AppColors.line),
                        labelStyle: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ))
                  .toList(),
            ),
          ..._messages.map(_bubble),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('La IA está revisando los datos...',
                      style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_sending,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: _sending ? null : () => _send(),
                style: IconButton.styleFrom(backgroundColor: AppColors.blue),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage m) {
    final color = m.fromAdmin
        ? AppColors.blue
        : (m.isError ? const Color(0xFFFDECEA) : AppColors.goldSoft);
    final textColor = m.fromAdmin
        ? Colors.white
        : (m.isError ? AppColors.danger : AppColors.ink);
    return Align(
      alignment: m.fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!m.fromAdmin) ...[
              Icon(
                m.isError ? Icons.error_outline : Icons.auto_awesome,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: SelectableText(
                m.text,
                style: TextStyle(color: textColor, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
