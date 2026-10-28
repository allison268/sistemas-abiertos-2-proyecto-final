import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../models/card_symbol.dart';

/// Resultado de la narración: el texto del dato y si vino del modelo de IA
/// o del respaldo local.
class AiNarration {
  final String text;
  final bool fromAi;

  const AiNarration({required this.text, required this.fromAi});
}

/// "Narrador" del juego. Cuando el jugador encuentra un par, este servicio
/// pide al modelo de IA que elija UNO de los 3 datos del símbolo y lo
/// redacte como una frase breve. Si no hay clave o la IA falla, se usa un
/// respaldo local que elige un dato al azar (el juego nunca se rompe).
class AiNarrator {
  final Random _rnd = Random();

  Future<AiNarration> narrate(CardSymbol symbol) async {
    if (AiConfig.hasKey) {
      try {
        final text = await _askGemini(symbol);
        if (text != null && text.trim().isNotEmpty) {
          return AiNarration(text: text.trim(), fromAi: true);
        }
      } catch (_) {
        // Cualquier error (sin internet, cuota, timeout...) cae al respaldo.
      }
    }
    return AiNarration(text: _localFact(symbol), fromAi: false);
  }

  String _localFact(CardSymbol symbol) {
    if (symbol.facts.isEmpty) return symbol.description;
    return symbol.facts[_rnd.nextInt(symbol.facts.length)];
  }

  /// Llama a la API REST de Gemini (generateContent).
  Future<String?> _askGemini(CardSymbol symbol) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${AiConfig.geminiModel}:generateContent?key=${AiConfig.geminiApiKey}',
    );

    final factsList = symbol.facts.map((f) => '- $f').join('\n');
    final prompt =
        'Eres el narrador del juego de memoria "Memory Honduras", para estudiantes. '
        'El jugador acaba de encontrar el par del símbolo patrio "${symbol.name}" '
        '(${symbol.description}).\n'
        'Elige AL AZAR UNO de estos tres datos y cuéntaselo en UNA sola frase '
        'breve (máximo 22 palabras), en español, con tono amigable. '
        'No enumeres ni repitas la lista:\n'
        '$factsList\n'
        'Responde únicamente con la frase, sin comillas.';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 1.0, 'maxOutputTokens': 120},
    });

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(AiConfig.timeout);

    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;

    return parts.first['text'] as String?;
  }
}
