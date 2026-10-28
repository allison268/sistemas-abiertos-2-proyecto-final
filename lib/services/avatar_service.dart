import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_avatars.dart';

/// Guarda y recupera el icono de perfil elegido por el usuario.
///
/// La elección se conserva entre sesiones: una vez que el usuario escoge
/// un avatar, se mantiene hasta que él mismo lo cambie.
class AvatarService {
  static const String _modeKey = 'avatar_mode';
  static const String _presetKey = 'avatar_preset';
  static const String _customKey = 'avatar_custom_base64';

  /// Carga el avatar guardado. Si no hay ninguno, devuelve el modo por defecto.
  Future<AvatarSelection> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AvatarSelection(
      mode: prefs.getString(_modeKey) ?? ProfileAvatars.defaultMode,
      preset: prefs.getString(_presetKey),
      customBase64: prefs.getString(_customKey),
    );
  }

  /// Guarda la selección del usuario.
  Future<void> save(AvatarSelection selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, selection.mode);
    if (selection.preset != null) {
      await prefs.setString(_presetKey, selection.preset!);
    } else {
      await prefs.remove(_presetKey);
    }
    if (selection.customBase64 != null) {
      await prefs.setString(_customKey, selection.customBase64!);
    } else {
      await prefs.remove(_customKey);
    }
  }
}
