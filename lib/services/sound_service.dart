import 'package:audioplayers/audioplayers.dart';

import 'settings_service.dart';

/// Efectos de sonido del juego (archivos en assets/sonidos).
enum Sfx { flip, match, wrong, win, lose }

class SoundService {
  static final Map<Sfx, AudioPlayer> _players = {};

  static Future<void> play(Sfx sfx) async {
    if (!SettingsService.soundOn) return;
    try {
      final player = _players.putIfAbsent(sfx, () => AudioPlayer());
      await player.stop();
      await player.play(AssetSource('sonidos/${sfx.name}.wav'));
    } catch (_) {
      // Si el navegador o el dispositivo bloquea el audio, el juego sigue sin sonido.
    }
  }
}
