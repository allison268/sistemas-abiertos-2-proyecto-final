import 'package:flutter/material.dart';

import '../models/profile_avatars.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../services/settings_service.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  final AvatarService _avatarService = AvatarService();
  AvatarSelection _avatar = const AvatarSelection();
  String _username = '';
  bool _isAdmin = false;
  bool _sound = SettingsService.soundOn;
  bool _vibration = SettingsService.vibrationOn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SettingsService.load();
    final avatar = await _avatarService.load();
    final user = await _auth.getCurrentUser();
    final admin = await _auth.isAdmin();
    if (!mounted) return;
    setState(() {
      _sound = SettingsService.soundOn;
      _vibration = SettingsService.vibrationOn;
      _avatar = avatar;
      _username = user?.username ?? '';
      _isAdmin = admin;
    });
  }

  Future<void> _changeAvatar() async {
    final selection = await showAvatarPicker(context, _avatar);
    if (selection == null) return;
    await _avatarService.save(selection);
    if (!mounted) return;
    setState(() => _avatar = selection);
  }

  Future<void> _changePassword() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: Text('¿Deseas salir de la cuenta "$_username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Salir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileCard(),
                    const SizedBox(height: 22),
                    const SectionTitle(
                      icon: Icons.tune_rounded,
                      text: 'Juego',
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _sound,
                            activeTrackColor: AppColors.blue,
                            secondary: const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.blueLight,
                            ),
                            title: const Text(
                              'Sonido',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('Efectos al jugar y al ganar'),
                            onChanged: (v) {
                              setState(() => _sound = v);
                              SettingsService.setSound(v);
                            },
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          SwitchListTile(
                            value: _vibration,
                            activeTrackColor: AppColors.blue,
                            secondary: const Icon(
                              Icons.vibration_rounded,
                              color: AppColors.blueLight,
                            ),
                            title: const Text(
                              'Vibración',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('Solo en celulares'),
                            onChanged: (v) {
                              setState(() => _vibration = v);
                              SettingsService.setVibration(v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle(
                      icon: Icons.manage_accounts_rounded,
                      text: 'Cuenta',
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _tile(
                            Icons.face_rounded,
                            'Icono de perfil',
                            'Elige tu imagen',
                            _changeAvatar,
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          _tile(
                            Icons.lock_reset_rounded,
                            'Cambiar contraseña',
                            'Actualiza la clave de tu cuenta',
                            _changePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle(
                      icon: Icons.info_outline_rounded,
                      text: 'Información',
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _tile(
                        Icons.info_rounded,
                        'Acerca de Memory Honduras',
                        'Equipo, clase y tecnologías',
                        () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.hero,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: ProfileAvatar(selection: _avatar, radius: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username.isEmpty ? 'Jugador' : _username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    _isAdmin ? 'Administrador' : 'Jugador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.blueLight),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    );
  }
}

/// Ventana para cambiar la contraseña. Devuelve true si se cambió.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty || _new.text.isEmpty || _confirm.text.isEmpty) {
      setState(() => _error = 'Complete todos los campos');
      return;
    }
    if (_new.text.length < 4) {
      setState(() => _error = 'La contraseña nueva debe tener al menos 4 caracteres');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Las contraseñas nuevas no coinciden');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService().post('/api/usuarios/me/contrasena', {
        'actual': _current.text,
        'nueva': _new.text,
      }, auth: true);
      if (!mounted) return;
      if (resp.ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _loading = false;
          _error = resp.message;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: c,
        obscureText: true,
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.sky.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cambiar contraseña'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_current, 'Contraseña actual'),
            _field(_new, 'Contraseña nueva'),
            _field(_confirm, 'Repite la contraseña nueva'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
