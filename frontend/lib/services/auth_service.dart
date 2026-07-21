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
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          // Lấy ID của User từ cục data
          return LoginResult.success(body['data']['id']);
        } else {
          return LoginResult.failure(body['message'] ?? 'Login failed');
        }
      } else if (response.statusCode == 401) {
        final body = jsonDecode(response.body);
        return LoginResult.failure(body['message'] ?? 'Invalid ID or password');
      } else {
        return LoginResult.failure('Server error (${response.statusCode})');
      }
    } catch (_) {
      return LoginResult.failure('Cannot connect to server');
    }
  }

  static Future<LoginResult> loginWithFirebase(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return LoginResult.success(body['data']['id']);
        } else {
          return LoginResult.failure(body['message'] ?? 'Login failed');
        }
      } else {
        return LoginResult.failure('Lỗi xác thực hệ thống nội bộ');
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