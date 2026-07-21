import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../services/presence_service.dart';
import '../services/user_service.dart';
import '../services/app_session.dart';

enum SidebarItem { dashboard, gradingHistory, admin, profile }

class Sidebar extends StatefulWidget {
  final SidebarItem selected;
  final ValueChanged<SidebarItem> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Gọi API lấy thông tin người dùng đang đăng nhập
  Future<void> _loadProfile() async {
    final profile = await UserService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: _navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PE Grading System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'FPT University',
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            active: widget.selected == SidebarItem.dashboard,
            onTap: () => widget.onSelect(SidebarItem.dashboard),
          ),
          _NavItem(
            icon: Icons.access_time_outlined,
            activeIcon: Icons.access_time,
            label: 'Grading History',
            active: widget.selected == SidebarItem.gradingHistory,
            onTap: () => widget.onSelect(SidebarItem.gradingHistory),
          ),
          // CHỈ HIỂN THỊ MENU ADMIN NẾU LÀ TÀI KHOẢN ADMIN
          if (_profile?.role == 'ADMIN')
            _NavItem(
              icon: Icons.admin_panel_settings_outlined,
              activeIcon: Icons.admin_panel_settings,
              label: 'Admin Dashboard',
              active: widget.selected == SidebarItem.admin,
              onTap: () => widget.onSelect(SidebarItem.admin),
            ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile & Settings',
            active: widget.selected == SidebarItem.profile,
            onTap: () => widget.onSelect(SidebarItem.profile),
          ),
          const Spacer(),
          
          // KHU VỰC HIỂN THỊ THÔNG TIN USER (DYNAMIC)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?.fullName ?? 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _profile != null ? '${_profile!.role} | ${_profile!.username}' : '...',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    final key = user.email!.replaceAll('@', '_').replaceAll('.', '_');
                    await PresenceService.setOffline(key);
                    await FirebaseAuth.instance.signOut();
                  }
                  AppSession.instance.clear();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white.withAlpha(153),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: active ? _orange : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? Colors.white : Colors.white.withAlpha(153),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white.withAlpha(153),
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}