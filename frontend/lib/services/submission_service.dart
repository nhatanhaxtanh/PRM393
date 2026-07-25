import 'dart:convert';
import 'package:http/http.dart' as http;

// Chỉ giữ lại các class liên quan đến Grade/Submission
class GradeItem {
  final int requestNo;
  final double awardedScore;
  final String comments;

  const GradeItem({required this.requestNo, required this.awardedScore, required this.comments});

  Map<String, dynamic> toJson() => {'requestNo': requestNo, 'awardedScore': awardedScore, 'comments': comments};

  factory GradeItem.fromJson(Map<String, dynamic> json) => GradeItem(
    requestNo: json['requestNo'] as int,
    awardedScore: (json['awardedScore'] as num).toDouble(),
    comments: json['comments'] ?? '',
  );
}

class SubmissionService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<String?> getDocument(int submissionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/submissions/$submissionId/document'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['status'] == 200) {
          String text = (body['data'] ?? body['message'] ?? '').toString();
          
          if (text.isNotEmpty) {
            return text.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]+>'), '');
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> saveGrades(int submissionId, List<GradeItem> grades, {bool isDraft = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/submissions/$submissionId/grade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': isDraft ? 'DRAFT' : 'GRADED',
          'grades': grades.map((g) => g.toJson()).toList(),
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<List<GradeItem>?> autoGrade(int submissionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/submissions/$submissionId/auto-grade'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => GradeItem.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return null;
  }
}