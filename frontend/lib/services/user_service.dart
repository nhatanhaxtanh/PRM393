import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_session.dart';

class UserProfile {
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String campusName;

  const UserProfile({
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.campusName = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    role: json['role'] ?? '',
    campusName: json['campusName'] ?? 'System / Global',
  );
}

class UserService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<UserProfile?> getProfile() async {
    try {
      final lecturerId = AppSession.instance.userId ?? 1;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/me?lecturerId=$lecturerId'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return UserProfile.fromJson(body['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/users'));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => UserProfile.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
