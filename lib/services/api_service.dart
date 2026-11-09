import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Error de conexión con el servidor (sin internet, servidor apagado, etc.).
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiResponse {
  final int status;
  final dynamic data;

  const ApiResponse(this.status, this.data);

  bool get ok => status >= 200 && status < 300;

  /// Mensaje que manda la API cuando algo sale mal.
  String get message {
    if (data is Map && data['mensaje'] is String) {
      return data['mensaje'] as String;
    }
    return 'Error del servidor ($status)';
  }
}

/// Cliente sencillo para hablar con la API REST del juego.
/// Guarda el token de sesión y lo manda en cada petición que lo necesita.
class ApiService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse> get(String path, {bool auth = false}) {
    return _send(() async {
      final headers = await _headers(auth);
      return http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers);
    });
  }

  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) {
    return _send(() async {
      final headers = await _headers(auth);
      return http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  Future<ApiResponse> _send(Future<http.Response> Function() request) async {
    try {
      final resp = await request().timeout(ApiConfig.timeout);
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(resp.bodyBytes));
      } catch (_) {
        data = null;
      }
      return ApiResponse(resp.statusCode, data);
    } on TimeoutException {
      throw const ApiException('El servidor no respondió, intenta de nuevo');
    } catch (_) {
      throw const ApiException('No se pudo conectar con el servidor');
    }
  }
}
