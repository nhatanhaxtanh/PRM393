import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào buổi sáng! 👋',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bạn có 3 bài chờ chấm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: 'Chấm ngay',
                        onPressed: () {},
                        height: 40,
                        width: 140,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.school, color: Colors.white30, size: 80),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Stats
          const Text(
            'Tổng quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.assignment_turned_in,
                  label: 'Bài đã chấm',
                  value: '128',
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Chờ chấm',
                  value: '3',
                  color: AppColors.pink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.people_outline,
                  label: 'Học sinh',
                  value: '42',
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_outline,
                  label: 'Điểm TB',
                  value: '7.8',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Recent submissions
          const Text(
            'Bài nộp gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SubmissionRow(
                  name: 'Nguyễn Văn A',
                  subject: 'Toán học',
                  status: 'Đã chấm',
                  score: '8.5',
                ),
                const Divider(height: 1, color: AppColors.border),
                _SubmissionRow(
                  name: 'Trần Thị B',
                  subject: 'Vật lý',
                  status: 'Chờ chấm',
                  score: null,
                ),
                const Divider(height: 1, color: AppColors.border),
                _SubmissionRow(
                  name: 'Lê Minh C',
                  subject: 'Hóa học',
                  status: 'Đã chấm',
                  score: '9.0',
                ),
                const Divider(height: 1, color: AppColors.border),
                _SubmissionRow(
                  name: 'Phạm Thị D',
                  subject: 'Sinh học',
                  status: 'Chờ chấm',
                  score: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  final String name;
  final String subject;
  final String status;
  final String? score;

  const _SubmissionRow({
    required this.name,
    required this.subject,
    required this.status,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final bool graded = status == 'Đã chấm';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppColors.softGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subject,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: graded
                  ? AppColors.purple.withAlpha(20)
                  : AppColors.pink.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: graded ? AppColors.purple : AppColors.pink,
              ),
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 16),
            Text(
              score!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
