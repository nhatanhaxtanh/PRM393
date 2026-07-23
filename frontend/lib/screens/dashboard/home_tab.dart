import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../../services/batch_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeTab extends StatefulWidget {
  final ValueChanged<BatchInfo> onBatchSelected;
  const HomeTab({super.key, required this.onBatchSelected});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  List<BatchSummary> _batches = [];
  bool _loading = true;
  StreamSubscription? _batchSubscription;

  @override
  void initState() {
    super.initState();
    _loadBatches();
    _listenForNewBatches();
  }

  void _listenForNewBatches() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final key = user.email!.replaceAll('@', '_').replaceAll('.', '_');
      _batchSubscription = FirebaseDatabase.instance
          .ref('status/$key/batch_update')
          .onValue
          .listen((event) {
            if (event.snapshot.value != null) {
              _loadBatches();
            }
          });
    }
  }

  @override
  void dispose() {
    _batchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    final batches = await BatchService.getAssignedBatches();
    if (mounted) {
      setState(() {
        _batches = batches;
        _loading = false;
      });
    }
  }

  int get _totalStudents => _batches.fold(0, (s, b) => s + b.totalStudents);
  int get _totalGraded => _batches.fold(0, (s, b) => s + b.gradedCount);
  int get _pending => _totalStudents - _totalGraded;
  String get _progressLabel => _totalStudents == 0
      ? '0%'
      : '${(_totalGraded / _totalStudents * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

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

          if (isMobile)
            Column(
              children: [
                _StatCard(
                  label: 'Overall Progress',
                  value: _loading ? '...' : _progressLabel,
                  valueColor: _navy,
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F6FD9),
                ),
                const SizedBox(height: 16),
                _StatCard(
                  label: 'Pending Reviews',
                  value: _loading ? '...' : '$_pending',
                  valueColor: _orange,
                  icon: Icons.access_time_outlined,
                  iconBg: const Color(0xFFFFF3E8),
                  iconColor: _orange,
                ),
                const SizedBox(height: 16),
                _StatCard(
                  label: 'Completed Reviews',
                  value: _loading ? '...' : '$_totalGraded',
                  valueColor: _navy,
                  icon: Icons.check_circle_outline,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF4CAF50),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Overall Progress',
                    value: _loading ? '...' : _progressLabel,
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
                    value: _loading ? '...' : '$_pending',
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
                    value: _loading ? '...' : '$_totalGraded',
                    valueColor: _navy,
                    icon: Icons.check_circle_outline,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
          _batchesTable(isMobile),
        ],
      ),
    );
  }

  Widget _batchesTable(bool isMobile) {
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
          _tableHeader(isMobile),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_batches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No batches assigned',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...List.generate(
              _batches.length,
              (i) => Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade200),
                  _batchRow(_batches[i], isMobile),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerCell('CAMPUS')),
          Expanded(flex: 2, child: _headerCell('EXAM CODE')),
          Expanded(flex: 2, child: _headerCell('EXAM TYPE')),
          Expanded(flex: 2, child: _headerCell('PROGRESS')),
          if (!isMobile)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _headerCell('ACTION'),
              ),
            ),
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

  Widget _batchRow(BatchSummary batch, bool isMobile) {
    return InkWell(
      onTap: isMobile
          ? null
          : () => widget.onBatchSelected(
              BatchInfo(
                batchId: batch.batchId,
                campus: batch.campusCode,
                examCode: batch.examCode,
                examType: batch.examType,
                completed: batch.gradedCount,
                total: batch.totalStudents,
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                batch.campusCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                batch.examCode,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _examTypeBadge(batch.examType),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${batch.gradedCount}/${batch.totalStudents}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (!isMobile)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment
                      .centerRight, // Đẩy nút sang phải tạo khoảng cách thoáng
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onBatchSelected(
                      BatchInfo(
                        batchId: batch.batchId,
                        campus: batch.campusCode,
                        examCode: batch.examCode,
                        examType: batch.examType,
                        completed: batch.gradedCount,
                        total: batch.totalStudents,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Grade Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _examTypeBadge(String type) {
    final isFirst = type == 'FIRST_ATTEMPT';
    final label = isFirst ? 'First Attempt' : 'Retake';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xFFEEF2FF) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isFirst ? const Color(0xFF4F6FD9) : const Color(0xFFF59E0B),
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
