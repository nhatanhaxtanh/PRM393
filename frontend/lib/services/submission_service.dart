import 'package:http/http.dart' as http;

class SubmissionService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<String?> getDocument(int submissionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/submissions/$submissionId/document'),
      );
      if (response.statusCode == 200) {
        return response.body.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]+>'), '');
      }
    } catch (_) {}
    return null;
  }
}
