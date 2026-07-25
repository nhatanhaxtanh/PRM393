import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/batch_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  UserProfile? _profile;
  bool _loading = true;
  int _completedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileAndStats();
  }

  Future<void> _loadProfileAndStats() async {
    final profile = await UserService.getProfile();
    final assignedBatches = await BatchService.getAssignedBatches();
    final historyBatches = await BatchService.getGradingHistory();

    // Tính toán số liệu thực tế từ dữ liệu API
    int totalCompleted = 0;
    for (var b in historyBatches) {
      totalCompleted += b.gradedCount;
    }
    for (var b in assignedBatches) {
      totalCompleted += b.gradedCount;
    }

    int totalPending = 0;
    for (var b in assignedBatches) {
      totalPending += (b.totalStudents - b.gradedCount);
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _completedCount = totalCompleted;
        _pendingCount = totalPending;
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
            'Profile & Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _navy),
          ),
          const SizedBox(height: 6),
          Text(
            'Your account information and system preferences',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _profileHeader(),
                  _infoSection(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    final displayName = _profile?.fullName ?? 'Lecturer';
    final displayId = _profile?.username ?? 'GV1234';
    final displayRole = _profile?.role ?? 'Lecturer';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _navy.withAlpha(8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy),
                  ),
                  const SizedBox(height: 2),
                  Text(displayId, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayRole,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _orange),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statBadge(_completedCount.toString(), 'Completed'),
              const SizedBox(width: 24),
              _statBadge(_pendingCount.toString(), 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _infoSection() {
    final fullName = _profile?.fullName ?? '';
    final username = _profile?.username ?? '';
    final role = _profile?.role ?? '';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: fullName,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _infoRow(
                  icon: Icons.badge_outlined,
                  label: 'Username',
                  value: username,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  icon: Icons.work_outline,
                  label: 'Role',
                  value: role,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _infoRow(
                  icon: Icons.business_outlined,
                  label: 'Campus',
                  value: 'Ho Chi Minh City',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Lệnh này ép ứng dụng sập ngay lập tức
                FirebaseCrashlytics.instance.crash();
              },
              icon: const Icon(Icons.warning, color: Colors.red, size: 16),
              label: const Text(
                'Simulate App Crash (Demo)', 
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _navy.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
}