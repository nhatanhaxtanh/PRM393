import 'package:flutter/material.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  static const _navy = Color(0xFF1B2D8B);
  static const _green = Color(0xFF4CAF50);

  static const _records = [
    _GradeRecord(studentId: 'SE123457', studentName: 'Tran Thi Binh', examCode: 'PE_201_Spring26', campus: 'HCM', score: 8.5, gradedDate: '2026-05-21 10:30'),
    _GradeRecord(studentId: 'SE123458', studentName: 'Le Van Cuong', examCode: 'PE_201_Spring26', campus: 'HCM', score: 7.0, gradedDate: '2026-05-21 11:15'),
    _GradeRecord(studentId: 'SE123461', studentName: 'Vo Thi Phuong', examCode: 'PE_201_Fall25', campus: 'HN', score: 9.0, gradedDate: '2026-05-21 14:20'),
    _GradeRecord(studentId: 'SE123463', studentName: 'Bui Thi Ha', examCode: 'PE_201_Spring26', campus: 'HCM', score: 6.5, gradedDate: '2026-05-21 15:45'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grading History',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _navy),
          ),
          const SizedBox(height: 6),
          Text(
            'View all your completed PMG exam grading submissions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completed Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project Management Practical Exams',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),

                _tableHeader(),
                ...List.generate(_records.length, (i) => Column(
                  children: [
                    Divider(height: 1, color: Colors.grey.shade200),
                    _recordRow(_records[i]),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _headerCell('STUDENT ID')),
          Expanded(child: _headerCell('STUDENT NAME')),
          Expanded(child: _headerCell('EXAM CODE')),
          Expanded(child: _headerCell('CAMPUS')),
          Expanded(child: _headerCell('SCORE')),
          Expanded(child: _headerCell('GRADED DATE')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _recordRow(_GradeRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              record.studentId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _navy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              record.studentName,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              record.examCode,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              record.campus,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _scoreBadge(record.score),
            ),
          ),
          Expanded(
            child: Text(
              record.gradedDate,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(double score) {
    final label = score == score.truncateToDouble() ? score.toInt().toString() : score.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _green.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: _green),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeRecord {
  final String studentId;
  final String studentName;
  final String examCode;
  final String campus;
  final double score;
  final String gradedDate;

  const _GradeRecord({
    required this.studentId,
    required this.studentName,
    required this.examCode,
    required this.campus,
    required this.score,
    required this.gradedDate,
  });
}
