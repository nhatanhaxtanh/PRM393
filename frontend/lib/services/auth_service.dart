import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<LoginResult> login(String lecturerId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lecturerId': lecturerId, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResult.success(data['userId']);
      } else if (response.statusCode == 401) {
        return LoginResult.failure('Invalid ID or password');
      } else {
        return LoginResult.failure('Server error (${response.statusCode})');
      }
    } catch (_) {
      return LoginResult.failure('Cannot connect to server');
    }
  }
}

class LoginResult {
  final bool success;
  final int? userId;
  final String? error;

  const LoginResult._({required this.success, this.userId, this.error});

  factory LoginResult.success(int userId) =>
      LoginResult._(success: true, userId: userId);

  factory LoginResult.failure(String error) =>
      LoginResult._(success: false, error: error);
}
