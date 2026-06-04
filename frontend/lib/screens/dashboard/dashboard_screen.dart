import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'batch_detail_screen.dart';
import 'review_document_screen.dart';
import '../profile/profile_screen.dart';

class BatchInfo {
  final int batchId;
  final String campus;
  final String examCode;
  final String examType;
  final int completed;
  final int total;

  const BatchInfo({
    required this.batchId,
    required this.campus,
    required this.examCode,
    required this.examType,
    required this.completed,
    required this.total,
  });
}

class ReviewInfo {
  final int submissionId;
  final String studentId;
  final String studentName;
  final String examCode;
  final String campus;

  const ReviewInfo({
    required this.submissionId,
    required this.studentId,
    required this.studentName,
    required this.examCode,
    required this.campus,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SidebarItem _selected = SidebarItem.dashboard;
  BatchInfo? _selectedBatch;
  ReviewInfo? _selectedReview;

  Widget get _body {
    if (_selectedReview != null) {
      return ReviewDocumentScreen(
        review: _selectedReview!,
        onBack: () => setState(() => _selectedReview = null),
      );
    }
    if (_selectedBatch != null) {
      return BatchDetailScreen(
        batch: _selectedBatch!,
        onBack: () => setState(() => _selectedBatch = null),
        onReviewSelected: (r) => setState(() => _selectedReview = r),
      );
    }
    return switch (_selected) {
      SidebarItem.dashboard => HomeTab(
          onBatchSelected: (b) => setState(() => _selectedBatch = b),
        ),
      SidebarItem.gradingHistory => const HistoryTab(),
      SidebarItem.profile => const ProfileTab(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(
            selected: _selected,
            onSelect: (item) => setState(() {
              _selectedBatch = null;
              _selectedReview = null;
              _selected = item;
            }),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _body,
            ),
          ),
        ],
      ),
    );
  }
}
