/// Dirección de la API que corre en el servidor Rocky Linux.
///
/// Si la IP de Rocky cambia, no hace falta tocar el código: se pasa al correr
/// la app con --dart-define=API_URL=http://NUEVA_IP:3000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.42:3000',
  );

  static const Duration timeout = Duration(seconds: 10);
}
