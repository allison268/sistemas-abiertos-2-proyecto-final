import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_avatars.dart';

/// Muestra el avatar elegido: icono por defecto, un preset o una imagen
/// importada desde la galería.
class ProfileAvatar extends StatelessWidget {
  final AvatarSelection selection;
  final double radius;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.selection,
    this.radius = 28,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    Widget? child;
    if (selection.isPreset) {
      child = Image.asset(
        selection.preset!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _defaultIcon(),
      );
    } else if (selection.isCustom) {
      try {
        final bytes = base64Decode(selection.customBase64!);
        child = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        child = _defaultIcon();
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: child ?? _defaultIcon(),
        ),
      ),
    );
  }

  Widget _defaultIcon() {
    return Icon(
      Icons.person_rounded,
      size: radius * 1.15,
      color: const Color(0xFF0033A0),
    );
  }
}

/// Muestra el selector de icono de perfil y devuelve la nueva selección,
/// o `null` si el usuario cancela.
Future<AvatarSelection?> showAvatarPicker(
  BuildContext context,
  AvatarSelection current,
) {
  return showModalBottomSheet<AvatarSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AvatarPickerSheet(current: current),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  final AvatarSelection current;

  const _AvatarPickerSheet({required this.current});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late AvatarSelection _selection;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selection = widget.current;
  }

  Future<void> _pickFromGallery() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) {
        if (mounted) setState(() => _importing = false);
        return;
      }
      final Uint8List bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      if (!mounted) return;
      final newSelection = AvatarSelection(
        mode: ProfileAvatars.customMode,
        customBase64: encoded,
      );
      setState(() {
        _selection = newSelection;
        _importing = false;
      });
      Navigator.of(context).pop(newSelection);
    } catch (_) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo importar la imagen'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elige tu icono de perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0033A0),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _importing ? null : _pickFromGallery,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: const Text('Importar imagen desde galería'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0033A0),
                side: const BorderSide(color: Color(0xFF0033A0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Iconos disponibles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _optionTile(
                      AvatarSelection(mode: ProfileAvatars.defaultMode),
                      const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Color(0xFF0033A0),
                      ),
                    ),
                    ...ProfileAvatars.presets.map(
                      (path) => _optionTile(
                        AvatarSelection(
                          mode: ProfileAvatars.presetMode,
                          preset: path,
                        ),
                        Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(AvatarSelection selection, Widget child) {
    final selected = _isSelected(selection);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(selection),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF0033A0) : const Color(0xFFE0E0E0),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: ClipOval(child: SizedBox.expand(child: child)),
      ),
    );
  }

  bool _isSelected(AvatarSelection selection) {
    if (selection.mode != _selection.mode) return false;
    if (selection.mode == ProfileAvatars.presetMode) {
      return selection.preset == _selection.preset;
    }
    return true;
  }
}
