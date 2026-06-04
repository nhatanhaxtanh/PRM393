import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProfile {
  final String username;
  final String fullName;
  final String role;

  const UserProfile({required this.username, required this.fullName, required this.role});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        username: json['username'] ?? '',
        fullName: json['fullName'] ?? '',
        role: json['role'] ?? '',
      );
}

class UserService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<UserProfile?> getProfile() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/users/me'));
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }
}
