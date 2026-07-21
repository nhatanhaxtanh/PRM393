import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../widgets/sidebar.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'batch_detail_screen.dart';
import 'review_document_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_tab.dart';
import '../../services/user_service.dart';

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
  final int batchId;
  final String studentId;
  final String studentName;
  final String examCode;
  final String campus;

  const ReviewInfo({
    required this.submissionId,
    required this.batchId,
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
  UserProfile? _profile; // Thêm biến lưu profile

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'view_dashboard');
    _loadProfile();
  }

  // Load profile để biết là ADMIN hay GV
  Future<void> _loadProfile() async {
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

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
      SidebarItem.admin => const AdminTab(),
      SidebarItem.profile => const ProfileTab(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // KÍCH HOẠT RESPONSIVE: Cắt mốc 850px
    final isMobile = MediaQuery.of(context).size.width < 850;
    final isAdmin = _profile?.role == 'ADMIN';

    // ------------------------------------
    // GIAO DIỆN MOBILE
    // ------------------------------------
    if (isMobile) {
      final navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ];
      if (isAdmin) {
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
      }
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

      // Ánh xạ lại index cho Enum
      int getIndex() {
        if (_selected == SidebarItem.dashboard) return 0;
        if (_selected == SidebarItem.gradingHistory) return 1;
        if (isAdmin && _selected == SidebarItem.admin) return 2;
        return isAdmin ? 3 : 2; // Profile tab
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B2D8B),
          title: const Text('PE Grading System', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: _body,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: getIndex(),
          selectedItemColor: const Color(0xFFF97316),
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedBatch = null;
              _selectedReview = null;
              
              if (index == 0) _selected = SidebarItem.dashboard;
              else if (index == 1) _selected = SidebarItem.gradingHistory;
              else if (isAdmin && index == 2) _selected = SidebarItem.admin;
              else _selected = SidebarItem.profile;
            });
          },
          items: navItems,
        ),
      );
    }

    // ------------------------------------
    // GIAO DIỆN PC / WEB
    // ------------------------------------
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