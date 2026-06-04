import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class BatchDetailScreen extends StatelessWidget {
  final BatchInfo batch;
  final VoidCallback onBack;
  final ValueChanged<ReviewInfo> onReviewSelected;

  const BatchDetailScreen({
    super.key,
    required this.batch,
    required this.onBack,
    required this.onReviewSelected,
  });

  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  static const _submissions = [
    _Submission(id: 'SE123456', name: 'Nguyen Van An',    time: '2026-05-20 14:30', score: null),
    _Submission(id: 'SE123457', name: 'Tran Thi Binh',    time: '2026-05-20 15:12', score: 8.5),
    _Submission(id: 'SE123458', name: 'Le Van Cuong',     time: '2026-05-20 16:45', score: 7.0),
    _Submission(id: 'SE123459', name: 'Pham Thi Dung',    time: '2026-05-20 13:20', score: null),
    _Submission(id: 'SE123460', name: 'Hoang Van En',     time: '2026-05-20 14:55', score: null),
    _Submission(id: 'SE123461', name: 'Vo Thi Phuong',    time: '2026-05-20 16:10', score: 9.0),
    _Submission(id: 'SE123462', name: 'Nguyen Thi Giang', time: '2026-05-20 15:40', score: null),
    _Submission(id: 'SE123463', name: 'Bui Thi Ha',       time: '2026-05-20 17:05', score: 6.5),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 20),
          _batchInfoCard(),
          const SizedBox(height: 20),
          _submissionsCard(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: onBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text('Back to Dashboard', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _batchInfoCard() {
    final isFirst = batch.examType == 'First Attempt';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PMG Batch Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 4),
                Text('Project Management Practical Exam',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _metaItem('Campus:', batch.campus, isLink: true),
                    _metaItem('Exam Code:', batch.examCode),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Type: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFirst ? const Color(0xFFEEF2FF) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            batch.examType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isFirst ? const Color(0xFF4F6FD9) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _metaItem('Total Students:', batch.total.toString()),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('View Exam Paper'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _navy),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),
              Text('Grading Progress', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text('${batch.completed}/${batch.total}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isLink ? _navy : Colors.black87,
            )),
      ],
    );
  }

  Widget _submissionsCard() {
    return Container(
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
          const Text('Student Submissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy)),
          const SizedBox(height: 4),
          Text('All documents have been automatically fetched from the secure server',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          _tableHeader(),
          ...List.generate(_submissions.length, (i) => Column(
            children: [
              Divider(height: 1, color: Colors.grey.shade200),
              _submissionRow(_submissions[i]),
            ],
          )),
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
          Expanded(child: _headerCell('FULL NAME')),
          Expanded(child: _headerCell('SUBMISSION TIME')),
          Expanded(flex: 2, child: _headerCell('STATUS')),
          Expanded(child: _headerCell('ACTION')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Text(text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.grey.shade500, letterSpacing: 0.5));

  Widget _submissionRow(_Submission s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text(s.id,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _navy))),
          Expanded(child: Text(s.name,
              style: const TextStyle(fontSize: 14, color: Colors.black87))),
          Expanded(child: Text(s.time,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: s.score != null ? _gradedBadge(s.score!) : _notGradedBadge(),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => onReviewSelected(ReviewInfo(
                  studentId: s.id,
                  studentName: s.name,
                  examCode: batch.examCode,
                  campus: batch.campus,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Review Document'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notGradedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
        child: const Text('Not Graded',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFE53935))),
      );

  Widget _gradedBadge(double score) {
    final label = score == score.truncateToDouble() ? score.toInt().toString() : score.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 14, color: Color(0xFF4CAF50)),
          const SizedBox(width: 4),
          Text('Graded (Score: $label)',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4CAF50))),
        ],
      ),
    );
  }
}

class _Submission {
  final String id;
  final String name;
  final String time;
  final double? score;
  const _Submission({required this.id, required this.name, required this.time, required this.score});
}
