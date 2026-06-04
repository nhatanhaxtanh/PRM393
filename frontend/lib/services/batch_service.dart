import 'dart:convert';
import 'package:http/http.dart' as http;

class BatchSummary {
  final int batchId;
  final String campusCode;
  final String examCode;
  final String examType;
  final int totalStudents;
  final int gradedCount;

  const BatchSummary({
    required this.batchId,
    required this.campusCode,
    required this.examCode,
    required this.examType,
    required this.totalStudents,
    required this.gradedCount,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) => BatchSummary(
        batchId: json['batchId'] as int,
        campusCode: json['campusCode'] ?? '',
        examCode: json['examCode'] ?? '',
        examType: json['examType'] ?? '',
        totalStudents: json['totalStudents'] as int? ?? 0,
        gradedCount: json['gradedCount'] as int? ?? 0,
      );
}

class StudentSubmission {
  final int submissionId;
  final String studentId;
  final String fullName;
  final String submissionTime;
  final String status;
  final double? totalScore;

  const StudentSubmission({
    required this.submissionId,
    required this.studentId,
    required this.fullName,
    required this.submissionTime,
    required this.status,
    required this.totalScore,
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
      time = '$y-$mo-$d $h:$mi'; // format from LocalDateTime array
    }
    return StudentSubmission(
      submissionId: json['submissionId'] as int,
      studentId: json['studentId'] ?? '',
      fullName: json['fullName'] ?? '',
      submissionTime: time,
      status: json['status'] ?? 'NOT_GRADED',
      totalScore: (json['totalScore'] as num?)?.toDouble(),
    );
  }
}

class BatchService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<List<BatchSummary>> getAssignedBatches() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/batches/assigned'));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => BatchSummary.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<StudentSubmission>> getSubmissionsByBatch(int batchId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/batches/$batchId/submissions'));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => StudentSubmission.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<BatchSummary>> getGradingHistory() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/batches/history'));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => BatchSummary.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
