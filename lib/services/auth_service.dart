import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_service.dart';

/// Registro, inicio de sesión y avance del jugador.
/// Ahora todo pasa por la API del servidor Rocky Linux; en el dispositivo solo
/// queda una copia del usuario para no pedirlo a cada rato.
class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _adminKey = 'is_admin';

  /// Partida que se está guardando en este momento (para no leer datos viejos).
  static Future<void>? _pendingSave;

  final ApiService _api = ApiService();

  /// Cuenta de prueba: se crea sola en el servidor la primera vez que se usa.
  static const String demoUsername = 'prueba';
  static const String demoPassword = 'prueba';

  UserModel _userFromApi(Map<String, dynamic> u) {
    final rawScores = (u['mejoresPuntajes'] as Map<String, dynamic>?) ?? {};
    return UserModel(
      username: u['usuario'] as String,
      password: '',
      unlockedLevel: (u['nivelDesbloqueado'] as num?)?.toInt() ?? 1,
      bestScores: rawScores.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
      ),
    );
  }

  /// Guarda si la cuenta es de administrador (el servidor es quien lo decide).
  Future<void> _saveRole(Map<String, dynamic> u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminKey, u['rol'] == 'admin');
  }

  /// true si la cuenta con sesión iniciada es de administrador.
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminKey) ?? false;
  }

  Future<AuthResult> register(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty) {
      return AuthResult(
        success: false,
        message: 'El usuario no puede estar vacío',
      );
    }
    if (name.length < 3) {
      return AuthResult(
        success: false,
        message: 'El usuario debe tener al menos 3 caracteres',
      );
    }
    if (password.length < 4) {
      return AuthResult(
        success: false,
        message: 'La contraseña debe tener al menos 4 caracteres',
      );
    }
    return _authenticate('/api/registro', name, password);
  }

  Future<AuthResult> login(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Complete todos los campos');
    }
    final result = await _authenticate('/api/login', name, password);

    // La cuenta de prueba se registra sola si todavía no existe en el servidor.
    if (!result.success &&
        name.toLowerCase() == demoUsername &&
        password == demoPassword &&
        result.message == 'Usuario no encontrado') {
      return _authenticate('/api/registro', demoUsername, demoPassword);
    }
    return result;
  }

  Future<AuthResult> _authenticate(
    String path,
    String username,
    String password,
  ) async {
    try {
      final resp = await _api.post(path, {
        'usuario': username,
        'contrasena': password,
      });
      if (!resp.ok) {
        return AuthResult(success: false, message: resp.message);
      }
      final data = resp.data as Map<String, dynamic>;
      await _api.saveToken(data['token'] as String);
      final rawUser = data['usuario'] as Map<String, dynamic>;
      final user = _userFromApi(rawUser);
      await _setCurrentUser(user);
      await _saveRole(rawUser);
      return AuthResult(
        success: true,
        message: (data['mensaje'] as String?) ?? 'Bienvenido',
        user: user,
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<void> _setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  Future<UserModel?> _cachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(json.decode(raw));
  }

  /// Devuelve el usuario con la sesión iniciada, actualizado desde el servidor.
  /// Si no hay conexión, usa la copia guardada en el dispositivo.
  Future<UserModel?> getCurrentUser() async {
    final pending = _pendingSave;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    final token = await _api.getToken();
    if (token == null) return null;
    try {
      final resp = await _api.get('/api/usuarios/me', auth: true);
      if (resp.ok) {
        final raw = resp.data as Map<String, dynamic>;
        final user = _userFromApi(raw);
        await _setCurrentUser(user);
        await _saveRole(raw);
        return user;
      }
      if (resp.status == 401) {
        await logout();
        return null;
      }
    } on ApiException catch (_) {
      // Sin conexión: se usa la copia guardada.
    }
    return _cachedUser();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_adminKey);
    await _api.clearToken();
  }

  /// Guarda una partida (ganada o perdida) en el servidor.
  Future<void> recordGame({
    required int level,
    required bool won,
    required int score,
    required int moves,
    required int pairs,
    required int durationSeconds,
    String mode = 'simbolos',
  }) {
    final saving = _sendGame(
      level: level,
      won: won,
      score: score,
      moves: moves,
      pairs: pairs,
      durationSeconds: durationSeconds,
      mode: mode,
    );
    _pendingSave = saving;
    return saving;
  }

  Future<void> _sendGame({
    required int level,
    required bool won,
    required int score,
    required int moves,
    required int pairs,
    required int durationSeconds,
    required String mode,
  }) async {
    try {
      final resp = await _api.post('/api/partidas', {
        'nivel': level,
        'resultado': won ? 'ganada' : 'perdida',
        'puntaje': won ? score : 0,
        'errores': max(0, moves - pairs),
        'intentos': moves,
        'parejas': pairs,
        'duracion': max(0, durationSeconds),
        'modo': mode,
      }, auth: true);
      if (resp.ok) {
        final data = resp.data as Map<String, dynamic>;
        final rawUser = data['usuario'] as Map<String, dynamic>;
        await _setCurrentUser(_userFromApi(rawUser));
        await _saveRole(rawUser);
      }
    } on ApiException catch (_) {
      // Sin conexión: la partida no se pudo guardar en el servidor.
    }
  }

  /// Ya no se usa: el servidor calcula el avance a partir de las partidas.
  /// Se deja para no romper pantallas que todavía la llamen.
  Future<void> updateUserProgress({
    required int levelCompleted,
    required int score,
  }) async {}
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({required this.success, required this.message, this.user});
}
