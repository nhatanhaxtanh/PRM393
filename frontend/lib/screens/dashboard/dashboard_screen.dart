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
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/presence_service.dart';
import '../../services/app_session.dart';
import '../auth/login_screen.dart';
import '../../services/batch_service.dart';

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
  UserProfile? _profile;
  StreamSubscription? _disableSubscription;
  StreamSubscription? _remindSubscription;
  StreamSubscription? _batchUpdateSubscription;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'view_dashboard');
    _loadProfile();
    _listenForAccountDisable();
    _listenForReminders();
    _listenForBatchUpdates();
  }

  void _listenForAccountDisable() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final key = user.email!.replaceAll('@', '_').replaceAll('.', '_');
      _disableSubscription = FirebaseDatabase.instance
          .ref('status/$key/is_disabled')
          .onValue
          .listen((event) {
            if (event.snapshot.value == true) {
              _showDisabledDialog();
            }
          });
    }
  }

  void _showDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Bắt buộc user phải bấm nút Đăng xuất, không cho bấm ra ngoài
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Account Disabled', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Your account has been disabled by the administrator.\nYou cannot continue using the system. Please contact support.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // 1. Dọn dẹp cờ khóa để sau này Admin mở lại thì không bị văng tiếp
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && user.email != null) {
                final key = user.email!
                    .replaceAll('@', '_')
                    .replaceAll('.', '_');
                await FirebaseDatabase.instance
                    .ref('status/$key/is_disabled')
                    .remove();
                await PresenceService.setOffline(
                  key,
                ); // Hiện đèn xám Offline cho Admin thấy
              }
              // 2. Clear Session & Đăng xuất
              await FirebaseAuth.instance.signOut();
              AppSession.instance.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _listenForReminders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final key = user.email!.replaceAll('@', '_').replaceAll('.', '_');
      _remindSubscription = FirebaseDatabase.instance
          .ref('status/$key/remind_time')
          .onValue
          .listen((event) {
            if (event.snapshot.value != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🔔 ADMIN ALERT: You have an urgent batch to grade!',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
    }
  }

  void _listenForBatchUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final key = user.email!.replaceAll('@', '_').replaceAll('.', '_');
      _batchUpdateSubscription = FirebaseDatabase.instance
          .ref('status/$key/force_update')
          .onValue
          .listen((event) async {
        if (event.snapshot.value != null && _selectedBatch != null) {
          final batches = await BatchService.getAssignedBatches();
          final stillExists =
              batches.any((b) => b.batchId == _selectedBatch!.batchId);

          if (!stillExists && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('System Alert'),
                  ],
                ),
                content: const Text(
                    'The current batch has been reassigned or cancelled by the admin.\nPlease return to dashboard.'),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedBatch = null;
                        _selectedReview = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white),
                    child: const Text('Acknowledge'),
                  ),
                ],
              ),
            );
          }
        }
      });
    }
  }

  // TẮT LUỒNG LẮNG NGHE KHI THOÁT TRANG ĐỂ TRÁNH TRÀN RAM
  @override
  void dispose() {
    _disableSubscription?.cancel();
    _remindSubscription?.cancel();
    _batchUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        if (profile?.role == 'ADMIN' && _selected == SidebarItem.dashboard) {
          _selected = SidebarItem.admin;
        }
      });
    }
  }

  Widget get _body {
    // Xác định index cho IndexedStack
    int currentIndex = 0;
    if (_selected == SidebarItem.dashboard)
      currentIndex = 0;
    else if (_selected == SidebarItem.gradingHistory)
      currentIndex = 1;
    else if (_selected == SidebarItem.admin)
      currentIndex = 2;
    else if (_selected == SidebarItem.profile)
      currentIndex = 3;

    return Stack(
      children: [
        // ==========================================
        // LỚP 1: CÁC TAB CHÍNH (Giữ nguyên State 100%)
        // ==========================================
        Offstage(
          offstage: _selectedBatch != null || _selectedReview != null,
          child: IndexedStack(
            index: currentIndex,
            children: [
              HomeTab(
                onBatchSelected: (b) => setState(() => _selectedBatch = b),
              ),
              const HistoryTab(),
              // Chỉ load ngầm AdminTab nếu tài khoản là ADMIN
              _profile?.role == 'ADMIN'
                  ? const AdminTab()
                  : const SizedBox.shrink(),
              const ProfileTab(),
            ],
          ),
        ),

        // ==========================================
        // LỚP 2: MÀN HÌNH CHI TIẾT LÔ BÀI
        // ==========================================
        if (_selectedBatch != null && _selectedReview == null)
          BatchDetailScreen(
            batch: _selectedBatch!,
            onBack: () => setState(() => _selectedBatch = null),
            onReviewSelected: (r) => setState(() => _selectedReview = r),
          ),

        // ==========================================
        // LỚP 3: MÀN HÌNH CHẤM BÀI PDF
        // ==========================================
        if (_selectedReview != null)
          ReviewDocumentScreen(
            review: _selectedReview!,
            onBack: () => setState(() => _selectedReview = null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isMobile = MediaQuery.of(context).size.width < 850;
    final isAdmin = _profile?.role == 'ADMIN';

    // ------------------------------------
    // GIAO DIỆN MOBILE
    // ------------------------------------
    if (isMobile) {
      final navItems = isAdmin
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ];

      int getIndex() {
        if (isAdmin) {
          return _selected == SidebarItem.admin ? 0 : 1;
        } else {
          if (_selected == SidebarItem.dashboard) return 0;
          if (_selected == SidebarItem.gradingHistory) return 1;
          return 2;
        }
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B2D8B),
          title: const Text(
            'PE Grading System',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout, // Nút Logout trên góc phải
            ),
          ],
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
              if (isAdmin) {
                _selected = index == 0
                    ? SidebarItem.admin
                    : SidebarItem.profile;
              } else {
                if (index == 0)
                  _selected = SidebarItem.dashboard;
                else if (index == 1)
                  _selected = SidebarItem.gradingHistory;
                else
                  _selected = SidebarItem.profile;
              }
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    AppSession.instance.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
