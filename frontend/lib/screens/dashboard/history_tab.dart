import 'package:flutter/material.dart';
import '../../services/batch_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const _navy = Color(0xFF1B2D8B);
  static const _green = Color(0xFF4CAF50);

  List<BatchSummary> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final batches = await BatchService.getGradingHistory();
    if (mounted) {
      setState(() {
        _batches = batches;
        _loading = false;
      });
    }
  }

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
                  'Completed Batches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project Management Practical Exams',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),

                _tableHeader(),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_batches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No completed batches',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ...List.generate(_batches.length, (i) => Column(
                    children: [
                      Divider(height: 1, color: Colors.grey.shade200),
                      _batchRow(_batches[i]),
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
          Expanded(child: _headerCell('CAMPUS')),
          Expanded(child: _headerCell('EXAM CODE')),
          Expanded(child: _headerCell('EXAM TYPE')),
          Expanded(child: _headerCell('STUDENTS GRADED')),
          Expanded(child: _headerCell('STATUS')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5),
      );

  Widget _batchRow(BatchSummary batch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(batch.campusCode,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: _navy)),
          ),
          Expanded(
            child: Text(batch.examCode,
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _examTypeBadge(batch.examType),
            ),
          ),
          Expanded(
            child: Text(
              '${batch.gradedCount}/${batch.totalStudents}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _completedBadge(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examTypeBadge(String type) {
    final isFirst = type == 'FIRST_ATTEMPT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFEEF2FF) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFirst ? 'First Attempt' : 'Retake',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isFirst ? const Color(0xFF4F6FD9) : const Color(0xFFF59E0B),
        ),
      ),
    );
  }

  Widget _completedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _green.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: _green),
          const SizedBox(width: 4),
          const Text(
            'Completed',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _green),
          ),
        ],
      ),
    );
  }
}
