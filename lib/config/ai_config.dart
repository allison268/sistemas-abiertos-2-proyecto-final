/// Configuración del modelo de IA (Google Gemini).
///
/// La clave se lee de la variable de compilación GEMINI_API_KEY.
/// Puedes pasarla al ejecutar la app así:
///
///   flutter run -d web-server --dart-define=GEMINI_API_KEY=TU_CLAVE
///
/// Si no hay clave, el juego sigue funcionando: usa un respaldo local
/// que elige uno de los 3 datos al azar (sin internet).
class AiConfig {
  /// Clave de la API de Google AI Studio (Gemini).
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Modelo de Gemini a usar. Se puede cambiar con --dart-define=GEMINI_MODEL=...
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// Tiempo máximo de espera de la respuesta del modelo.
  static const Duration timeout = Duration(seconds: 12);

  /// Indica si hay una clave configurada.
  static bool get hasKey => geminiApiKey.trim().isNotEmpty;
}
