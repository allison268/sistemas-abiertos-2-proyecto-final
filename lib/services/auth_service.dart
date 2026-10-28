import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  Future<Map<String, UserModel>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = json.decode(raw);
    return decoded.map(
      (k, v) => MapEntry(k, UserModel.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> _saveUsers(Map<String, UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(users.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_usersKey, encoded);
  }

  Future<AuthResult> register(String username, String password) async {
    if (username.trim().isEmpty) {
      return AuthResult(
        success: false,
        message: 'El usuario no puede estar vacío',
      );
    }
    if (password.length < 4) {
      return AuthResult(
        success: false,
        message: 'La contraseña debe tener al menos 4 caracteres',
      );
    }
    final users = await _loadUsers();
    if (users.containsKey(username.toLowerCase())) {
      return AuthResult(success: false, message: 'El usuario ya existe');
    }
    final user = UserModel(
      username: username.trim(),
      password: password,
      unlockedLevel: 1,
    );
    users[username.toLowerCase()] = user;
    await _saveUsers(users);
    await _setCurrentUser(user);
    return AuthResult(success: true, message: 'Registro exitoso', user: user);
  }

  /// Cuenta de prueba: permite entrar sin estar registrada en la base de datos.
  static const String demoUsername = 'prueba';
  static const String demoPassword = 'prueba';

  Future<AuthResult> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Complete todos los campos');
    }
    // Acceso directo con la cuenta de prueba.
    if (username.trim().toLowerCase() == demoUsername &&
        password == demoPassword) {
      final demoUser = UserModel(
        username: demoUsername,
        password: demoPassword,
        unlockedLevel: 1,
      );
      await _setCurrentUser(demoUser);
      return AuthResult(
        success: true,
        message: 'Bienvenido (cuenta de prueba)',
        user: demoUser,
      );
    }
    final users = await _loadUsers();
    final user = users[username.toLowerCase()];
    if (user == null) {
      return AuthResult(success: false, message: 'Usuario no encontrado');
    }
    if (user.password != password) {
      return AuthResult(success: false, message: 'Contraseña incorrecta');
    }
    await _setCurrentUser(user);
    return AuthResult(success: true, message: 'Bienvenido', user: user);
  }

  Future<void> _setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(json.decode(raw));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> updateUserProgress({
    required int levelCompleted,
    required int score,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    final newBestScores = Map<int, int>.from(currentUser.bestScores);
    final currentBest = newBestScores[levelCompleted] ?? 0;
    if (score > currentBest) {
      newBestScores[levelCompleted] = score;
    }

    final newUnlocked = levelCompleted < 3
        ? (currentUser.unlockedLevel > levelCompleted + 1
              ? currentUser.unlockedLevel
              : levelCompleted + 1)
        : currentUser.unlockedLevel;

    final updated = currentUser.copyWith(
      unlockedLevel: newUnlocked,
      bestScores: newBestScores,
    );

    final users = await _loadUsers();
    users[updated.username.toLowerCase()] = updated;
    await _saveUsers(users);
    await _setCurrentUser(updated);
  }
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({required this.success, required this.message, this.user});
}
