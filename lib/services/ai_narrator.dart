import 'dart:math';

import '../models/card_symbol.dart';
import 'api_service.dart';

/// Resultado de la narración: el texto del dato y si vino del modelo de IA
/// o del respaldo.
class AiNarration {
  final String text;
  final bool fromAi;

  const AiNarration({required this.text, required this.fromAi});
}

/// "Narrador" del juego. Cuando el jugador encuentra un par, la app le pide el
/// dato curioso al servidor Rocky Linux. Es el servidor el que consulta a la
/// IA y el que guarda la clave, la app solo muestra el resultado.
/// Si el servidor no responde, se usa un dato guardado en la app para que el
/// juego nunca se rompa.
class AiNarrator {
  final Random _rnd = Random();
  final ApiService _api = ApiService();

  Future<AiNarration> narrate(CardSymbol symbol) async {
    try {
      final base = symbol.isDepartment ? 'departamentos' : 'simbolos';
      final resp = await _api.get('/api/$base/${symbol.id}/dato', auth: true);
      if (resp.ok && resp.data is Map) {
        final data = resp.data as Map<String, dynamic>;
        final text = ((data['texto'] as String?) ?? '').trim();
        if (text.isNotEmpty) {
          return AiNarration(text: text, fromAi: data['ia'] == true);
        }
      }
    } catch (_) {
      // Cualquier error cae al respaldo local.
    }
    return AiNarration(text: _localFact(symbol), fromAi: false);
  }

  String _localFact(CardSymbol symbol) {
    if (symbol.facts.isEmpty) return symbol.description;
    return symbol.facts[_rnd.nextInt(symbol.facts.length)];
  }
}
