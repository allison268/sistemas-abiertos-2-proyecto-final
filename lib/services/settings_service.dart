import 'package:shared_preferences/shared_preferences.dart';

/// Ajustes del jugador guardados en el dispositivo: sonido y vibración.
class SettingsService {
  static const String _soundKey = 'setting_sound';
  static const String _vibrationKey = 'setting_vibration';

  static bool soundOn = true;
  static bool vibrationOn = true;
  static bool _loaded = false;

  /// Lee los ajustes guardados (solo la primera vez).
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      soundOn = prefs.getBool(_soundKey) ?? true;
      vibrationOn = prefs.getBool(_vibrationKey) ?? true;
    } catch (_) {
      // Sin almacenamiento: se quedan los valores por defecto.
    }
    _loaded = true;
  }

  static Future<void> setSound(bool value) async {
    soundOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  static Future<void> setVibration(bool value) async {
    vibrationOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  /// Ejecuta una vibración solo si el jugador la tiene activada.
  static void haptic(Future<void> Function() vibrate) {
    if (vibrationOn) vibrate();
  }
}
