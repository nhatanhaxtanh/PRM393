import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class HomeTab extends StatelessWidget {
  final ValueChanged<BatchInfo> onBatchSelected;
  const HomeTab({super.key, required this.onBatchSelected});

  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Lecturer',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here are your PMG exam batches pending for grading',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Overall Progress',
                  value: '41%',
                  valueColor: _navy,
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F6FD9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Pending Reviews',
                  value: '44',
                  valueColor: _orange,
                  icon: Icons.access_time_outlined,
                  iconBg: const Color(0xFFFFF3E8),
                  iconColor: _orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Completed Reviews',
                  value: '31',
                  valueColor: _navy,
                  icon: Icons.check_circle_outline,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _BatchesTable(onBatchSelected: onBatchSelected),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }
}

class _BatchData {
  final String campus;
  final String examCode;
  final String examType;
  final int completed;
  final int total;

  const _BatchData({
    required this.campus,
    required this.examCode,
    required this.examType,
    required this.completed,
    required this.total,
  });
}

class _BatchesTable extends StatelessWidget {
  final ValueChanged<BatchInfo> onBatchSelected;
  const _BatchesTable({required this.onBatchSelected});

  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  static const _batches = [
    _BatchData(campus: 'HCM', examCode: 'PE_201_Spring26', examType: 'First Attempt', completed: 15, total: 30),
    _BatchData(campus: 'HN', examCode: 'PE_201_Spring26', examType: 'Retake', completed: 8, total: 12),
    _BatchData(campus: 'DN', examCode: 'PE_201_Fall25', examType: 'First Attempt', completed: 0, total: 25),
    _BatchData(campus: 'HCM', examCode: 'PE_201_Fall25', examType: 'Retake', completed: 8, total: 8),
  ];

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'My Assigned PMG Batches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Project Management Practical Exam',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          _tableHeader(),

          ...List.generate(_batches.length, (i) => Builder(
            builder: (context) => Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                _batchRow(context, _batches[i]),
              ],
            ),
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
          Expanded(child: _headerCell('CAMPUS')),
          Expanded(child: _headerCell('EXAM CODE')),
          Expanded(child: _headerCell('EXAM TYPE')),
          Expanded(child: _headerCell('PROGRESS')),
          Expanded(child: _headerCell('ACTION')),
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

  Widget _batchRow(BuildContext context, _BatchData batch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              batch.campus,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              batch.examCode,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _examTypeBadge(batch.examType),
            ),
          ),
          Expanded(child: _progressBar(batch.completed, batch.total)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => onBatchSelected(BatchInfo(
                campus: batch.campus,
                examCode: batch.examCode,
                examType: batch.examType,
                completed: batch.completed,
                total: batch.total,
              )),
                icon: const Icon(Icons.arrow_forward, size: 16),
                iconAlignment: IconAlignment.end,
                label: const Text('Grade Batch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examTypeBadge(String type) {
    final isFirst = type == 'First Attempt';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFEEF2FF) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isFirst ? const Color(0xFF4F6FD9) : const Color(0xFFF59E0B),
        ),
      ),
    );
  }

  Widget _progressBar(int completed, int total) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 10, color: Colors.grey.shade200),
                if (progress > 0)
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$completed/$total',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
