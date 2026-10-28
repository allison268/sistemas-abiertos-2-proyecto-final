/// Iconos de perfil prediseñados que el usuario puede elegir.
class ProfileAvatars {
  static const String basePath = 'lib/iconos_perfil';

  /// Rutas de los iconos de perfil incluidos en el proyecto.
  static const List<String> presets = [
    '$basePath/perfil1.png',
    '$basePath/perfil2.jpg',
    '$basePath/perfil3.png',
    '$basePath/perfil4.png',
    '$basePath/perfil5.png',
    '$basePath/perfil6.jpg',
    '$basePath/perfil7.png',
    '$basePath/perfil8.png',
    '$basePath/perfil9.png',
    '$basePath/perfil10.png',
  ];

  static const String defaultMode = 'default';
  static const String presetMode = 'preset';
  static const String customMode = 'custom';
}

/// Avatar elegido por el usuario: uno por defecto, uno de los prediseñados
/// o una imagen importada desde la galería.
class AvatarSelection {
  final String mode;
  final String? preset;
  final String? customBase64;

  const AvatarSelection({
    this.mode = ProfileAvatars.defaultMode,
    this.preset,
    this.customBase64,
  });

  bool get isPreset => mode == ProfileAvatars.presetMode && preset != null;

  bool get isCustom =>
      mode == ProfileAvatars.customMode &&
      customBase64 != null &&
      customBase64!.isNotEmpty;
}
