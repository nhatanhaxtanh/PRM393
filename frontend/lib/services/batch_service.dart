import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_session.dart';

class ExamPaperInfo {
  final String examCode;
  final String examPaperUrl;

  const ExamPaperInfo({required this.examCode, required this.examPaperUrl});

  factory ExamPaperInfo.fromJson(Map<String, dynamic> json) => ExamPaperInfo(
    examCode: json['examCode'] ?? '',
    examPaperUrl: json['examPaperUrl'] ?? '',
  );
}

class BatchSummary {
  final int batchId;
  final String campusCode;
  final String examCode;
  final String examType;
  final int totalStudents;
  final int gradedCount;
  final String graderName;
  final String graderEmail;

  const BatchSummary({
    required this.batchId,
    required this.campusCode,
    required this.examCode,
    required this.examType,
    required this.totalStudents,
    required this.gradedCount,
    this.graderName = '',
    this.graderEmail = '',
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) => BatchSummary(
    batchId: json['batchId'] as int,
    campusCode: json['campusCode'] ?? '',
    examCode: json['examCode'] ?? '',
    examType: json['examType'] ?? '',
    totalStudents: json['totalStudents'] as int? ?? 0,
    gradedCount: json['gradedCount'] as int? ?? 0,
    graderName: json['graderName'] ?? '',
    graderEmail: json['graderEmail'] ?? '',
  );
}

class StudentSubmission {
  final int submissionId;
  final String studentId;
  final String fullName;
  final String submissionTime;
  final String status;
  final double? totalScore;
  final bool isAIGraded;

  const StudentSubmission({
    required this.submissionId,
    required this.studentId,
    required this.fullName,
    required this.submissionTime,
    required this.status,
    required this.totalScore,
    this.isAIGraded = false,
  });

  bool get isGraded => status == 'GRADED';

  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    final raw = json['submissionTime'];
    String time = '';
    if (raw is String && raw.length >= 16) {
      time = '${raw.substring(0, 10)} ${raw.substring(11, 16)}';
    } else if (raw is List && raw.length >= 5) {
      final y = raw[0], mo = raw[1].toString().padLeft(2, '0');
      final d = raw[2].toString().padLeft(2, '0');
      final h = raw[3].toString().padLeft(2, '0');
      final mi = raw[4].toString().padLeft(2, '0');
      time = '$y-$mo-$d $h:$mi';
    }

    return StudentSubmission(
      submissionId: json['submissionId'] as int,
      studentId: json['studentId'] ?? '',
      fullName: json['fullName'] ?? '',
      submissionTime: time,
      status: json['status'] ?? 'NOT_GRADED',
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      isAIGraded: json['isAIGraded'] as bool? ?? false,
    );
  }
}

class BatchService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<List<BatchSummary>> getAssignedBatches() async {
    try {
      final lecturerId = AppSession.instance.userId ?? 1;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batches/assigned?lecturerId=$lecturerId'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => BatchSummary.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<BatchSummary>> getAllActiveBatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batches/all-active'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => BatchSummary.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<StudentSubmission>> getSubmissionsByBatch(
    int batchId, {
    String keyword = '',
    String status = 'ALL',
  }) async {
    try {
      String url = '$_baseUrl/api/submissions/batch/$batchId?page=0&size=50';
      if (keyword.isNotEmpty) url += '&keyword=$keyword';
      if (status != 'ALL') url += '&status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data']['content'] ?? [];
          return list.map((e) => StudentSubmission.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<ExamPaperInfo?> getExamPaper(int batchId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batches/$batchId/exam-paper'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          String rawUrl = body['data']['examPaperUrl'] ?? '';

          if (rawUrl.contains('localhost')) {
            final uri = Uri.parse(_baseUrl);
            rawUrl = rawUrl.replaceAll('localhost', uri.host);
          }

          return ExamPaperInfo(
            examCode: body['data']['examCode'] ?? '',
            examPaperUrl: rawUrl,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BatchSummary>> getGradingHistory() async {
    try {
      final lecturerId = AppSession.instance.userId ?? 1;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batches/history?lecturerId=$lecturerId'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => BatchSummary.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> autoGradeAll(int batchId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/batches/$batchId/auto-grade-all'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return body['data'];
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BatchSummary>> getAllHistoryBatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batches/all-history'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => BatchSummary.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
