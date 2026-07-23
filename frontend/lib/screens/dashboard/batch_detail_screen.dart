import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Bổ sung thư viện
import 'dashboard_screen.dart';
import '../../services/batch_service.dart';

class BatchDetailScreen extends StatefulWidget {
  final BatchInfo batch;
  final VoidCallback onBack;
  final ValueChanged<ReviewInfo> onReviewSelected;

  const BatchDetailScreen({
    super.key,
    required this.batch,
    required this.onBack,
    required this.onReviewSelected,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  List<StudentSubmission> _submissions = [];
  bool _loading = true;
  bool _autoGradingAll = false;

  // Search & Filter State
  String _keyword = '';
  String _status = 'ALL';

  // Remote Config State
  bool _isAIGradingEnabled = true; // Mặc định là bật

  @override
  void initState() {
    super.initState();
    _initRemoteConfig(); // Gọi hàm cấu hình Firebase
    _loadSubmissions();
  }

  // Khởi tạo và fetch dữ liệu từ Firebase Remote Config
  Future<void> _initRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(
          seconds: 0,
        ), // Lấy data ngay lập tức để test
      ),
    );

    // Đặt giá trị dự phòng nếu không có mạng
    await remoteConfig.setDefaults(const {"enable_ai_grading": true});

    try {
      await remoteConfig.fetchAndActivate();
      if (mounted) {
        setState(() {
          _isAIGradingEnabled = remoteConfig.getBool('enable_ai_grading');
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải Remote Config: $e');
    }
  }

  Future<void> _openExamPaper() async {
    final info = await BatchService.getExamPaper(widget.batch.batchId);
    if (info == null || info.examPaperUrl.isEmpty) return;
    final uri = Uri.parse(info.examPaperUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    final submissions = await BatchService.getSubmissionsByBatch(
      widget.batch.batchId,
      keyword: _keyword,
      status: _status,
    );
    if (mounted) {
      setState(() {
        _submissions = submissions;
        _loading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() => _keyword = value.trim());
    if (_keyword.isNotEmpty) {
      FirebaseAnalytics.instance.logEvent(
        name: 'search_student',
        parameters: {'keyword': _keyword},
      );
    }
    _loadSubmissions();
  }

  Future<void> _autoGradeAll() async {
    setState(() => _autoGradingAll = true);
    final result = await BatchService.autoGradeAll(widget.batch.batchId);
    if (!mounted) return;
    setState(() => _autoGradingAll = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI grading completed: ${result['gradedCount']}/${result['totalSubmissions']} submissions graded',
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );
      _loadSubmissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to auto-grade all submissions. Please try again.',
          ),
          backgroundColor: Color(0xFFE53935),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 20),
          _batchInfoCard(),
          const SizedBox(height: 20),
          _submissionsCard(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: widget.onBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'Back to Dashboard',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _batchInfoCard() {
    final isFirst = widget.batch.examType == 'FIRST_ATTEMPT';
    final typeLabel = isFirst ? 'First Attempt' : 'Retake';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PMG Batch Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project Management Practical Exam',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _openExamPaper,
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('View Exam Paper'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _navy),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _metaItem('Campus:', widget.batch.campus, isLink: true),
              _metaItem('Exam Code:', widget.batch.examCode),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Type: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isFirst
                            ? const Color(0xFF4F6FD9)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
              _metaItem('Total Students:', widget.batch.total.toString()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Progress: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${widget.batch.completed}/${widget.batch.total}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLink ? _navy : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _submissionsCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Submissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All documents have been automatically fetched from the secure server',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
              // Nút AI chỉ hiển thị nếu _isAIGradingEnabled = true trên Remote Config
              if (_isAIGradingEnabled)
                ElevatedButton.icon(
                  onPressed: _autoGradingAll ? null : _autoGradeAll,
                  icon: _autoGradingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _autoGradingAll
                        ? 'AI Grading All...'
                        : 'Auto-grade All with AI',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _navy.withAlpha(150),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _searchAndFilterBar(),
          const SizedBox(height: 20),
          _tableHeader(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_submissions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No submissions found',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...List.generate(
              _submissions.length,
              (i) => Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade200),
                  _submissionRow(_submissions[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by Student ID or Name...',
              prefixIcon: const Icon(Icons.search, size: 20, color: _navy),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _onSearch,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _status,
                isExpanded: true,
                icon: const Icon(Icons.filter_list, size: 20, color: _navy),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                  DropdownMenuItem(value: 'GRADED', child: Text('Graded')),
                  DropdownMenuItem(
                    value: 'NOT_GRADED',
                    child: Text('Not Graded'),
                  ),
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                    _loadSubmissions();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _headerCell('STUDENT ID')),
          Expanded(child: _headerCell('FULL NAME')),
          Expanded(child: _headerCell('SUBMISSION TIME')),
          Expanded(flex: 2, child: _headerCell('STATUS')),
          if (!isMobile) Expanded(child: _headerCell('ACTION')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade500,
      letterSpacing: 0.5,
    ),
  );

  Widget _submissionRow(StudentSubmission s) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.studentId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _navy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              s.fullName,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              s.submissionTime,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (s.status == 'GRADED')
                    _gradedBadge(s.totalScore!)
                  else if (s.status == 'DRAFT')
                    _draftBadge()
                  else
                    _notGradedBadge(),
                  if (s.isAIGraded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isMobile)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () => widget.onReviewSelected(
                    ReviewInfo(
                      submissionId: s.submissionId,
                      batchId: widget.batch.batchId,
                      studentId: s.studentId,
                      studentName: s.fullName,
                      examCode: widget.batch.examCode,
                      campus: widget.batch.campus,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Review Document'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notGradedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Not Graded',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFFE53935),
      ),
    ),
  );

  Widget _draftBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Draft',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF57C00),
      ),
    ),
  );

  Widget _gradedBadge(double score) {
    final label = score == score.truncateToDouble()
        ? score.toInt().toString()
        : score.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 14,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 4),
          Text(
            'Graded (Score: $label)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
