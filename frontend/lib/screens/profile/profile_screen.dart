import 'package:flutter/material.dart';
import '../../services/user_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
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
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      decoration: BoxDecoration(
        color: _navy.withAlpha(8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _navy),
              ),
              const SizedBox(height: 4),
              Text(displayId, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayRole,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _orange),
                ),
              ),
            ],
          ),
          const Spacer(),
          _statBadge('31', 'Completed'),
          const SizedBox(width: 24),
          _statBadge('44', 'Pending'),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _navy),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _infoSection() {
    final fullName = _profile?.fullName ?? '—';
    final username = _profile?.username ?? '—';
    final role = _profile?.role ?? '—';

    return Padding(
      padding: const EdgeInsets.all(32),
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
              const SizedBox(width: 24),
              Expanded(
                child: _infoRow(
                  icon: Icons.badge_outlined,
                  label: 'Username',
                  value: username,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  icon: Icons.work_outline,
                  label: 'Role',
                  value: role,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _infoRow(
                  icon: Icons.business_outlined,
                  label: 'Campus',
                  value: 'Ho Chi Minh City',
                ),
              ),
            ],
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _navy.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _navy),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
