import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/topbar.dart';
import 'home_tab.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SidebarItem _selected = SidebarItem.dashboard;

  String get _title => switch (_selected) {
    SidebarItem.dashboard => 'Dashboard',
    SidebarItem.grading => 'Chấm bài',
    SidebarItem.history => 'Lịch sử',
    SidebarItem.profile => 'Cá nhân',
  };

  Widget get _body => switch (_selected) {
    SidebarItem.dashboard => const HomeTab(),
    SidebarItem.grading => const _GradingTab(),
    SidebarItem.history => const _HistoryTab(),
    SidebarItem.profile => const ProfileTab(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selected: _selected,
            onSelect: (item) => setState(() => _selected = item),
          ),
          Expanded(
            child: Column(
              children: [
                Topbar(
                  title: _title,
                  userName: 'Nguyễn Văn A',
                  onProfileTap: () => setState(() => _selected = SidebarItem.profile),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F7FF),
                    child: _body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradingTab extends StatelessWidget {
  const _GradingTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.upload_file, size: 64, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upload tài liệu để chấm bài',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hỗ trợ PDF, DOCX, TXT',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 80),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF7C3AED),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF7C3AED)),
                SizedBox(height: 12),
                Text(
                  'Kéo & thả file vào đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                SizedBox(height: 4),
                Text('hoặc click để chọn file', style: TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Lịch sử chấm bài',
        style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
      ),
    );
  }
}
