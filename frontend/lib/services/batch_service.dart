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
}
