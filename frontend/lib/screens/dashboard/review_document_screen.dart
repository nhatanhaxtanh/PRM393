import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dashboard_screen.dart';
import '../../services/submission_service.dart';
import '../../services/batch_service.dart';

class ReviewDocumentScreen extends StatefulWidget {
  final ReviewInfo review;
  final VoidCallback onBack;
  const ReviewDocumentScreen({super.key, required this.review, required this.onBack});

  @override
  State<ReviewDocumentScreen> createState() => _ReviewDocumentScreenState();
}

class _ReviewDocumentScreenState extends State<ReviewDocumentScreen> {
  static const _navy = Color(0xFF1B2D8B);
  static const _orange = Color(0xFFF97316);

  int _activeTab = 0;
  String? _documentText;
  bool _loadingDoc = true;
  
  bool _loadingExamPaper = true;
  bool _submitting = false;
  bool _autoGrading = false;
  bool _usedAI = false;
  
  String? _pdfError;
  Uint8List? _pdfBytes;

  static const _rubricItems = [
    _RubricItem('Request 1: Narrative Charter', 20),
    _RubricItem('Request 2: Budget Items', 20),
    _RubricItem('Request 3: Project Risks', 30),
    _RubricItem('Request 4: Project Schedule/WBS', 30),
  ];

  late final List<TextEditingController> _scores;
  late final List<TextEditingController> _comments;

  @override
  void initState() {
    super.initState();
    _scores = List.generate(_rubricItems.length, (_) => TextEditingController(text: '0'));
    _comments = List.generate(_rubricItems.length, (_) => TextEditingController());
    for (final c in _scores) {
      c.addListener(() => setState(() {}));
    }
    _loadDocument();
    _loadExamPaper();
  }

  Future<void> _loadDocument() async {
    final text = await SubmissionService.getDocument(widget.review.submissionId);
    if (mounted) setState(() { _documentText = text; _loadingDoc = false; });
  }

  Future<void> _loadExamPaper() async {
    final info = await BatchService.getExamPaper(widget.review.batchId);
    if (info == null || info.examPaperUrl.isEmpty) {
      if (mounted) setState(() { _loadingExamPaper = false; _pdfError = 'Không tìm thấy URL đề thi.'; });
      return;
    }

    try {
      final response = await http.get(Uri.parse(info.examPaperUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.length < 5) {
          if (mounted) setState(() {
            _pdfError = 'Backend trả về file rỗng (0 bytes).';
            _loadingExamPaper = false;
          });
          return;
        }

        // Kiểm tra xem Backend có trả về đúng file PDF không (File PDF luôn bắt đầu bằng %PDF-)
        final header = String.fromCharCodes(bytes.sublist(0, 5));
        if (header != '%PDF-') {
          String preview = String.fromCharCodes(bytes.take(50).toList()).replaceAll('\n', ' ');
          if (mounted) setState(() {
            _pdfError = 'Backend đang không trả về PDF!\nNội dung nhận được: "$preview..."\n\n=> CÁCH FIX: Tắt Spring Boot, bấm "Clean and Build" (Reload Maven) rồi chạy lại để Server nhận file mock-exam.pdf.';
            _loadingExamPaper = false;
          });
          return;
        }

        if (mounted) setState(() {
          _pdfBytes = bytes;
          _loadingExamPaper = false;
        });
      } else {
        if (mounted) setState(() {
          _pdfError = 'Lỗi tải PDF (Status: ${response.statusCode})';
          _loadingExamPaper = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _pdfError = 'Lỗi mạng (CORS hoặc sai URL): $e';
        _loadingExamPaper = false;
      });
    }
  }

  Future<void> _autoGrade() async {
    setState(() => _autoGrading = true);
    final aiGrades = await SubmissionService.autoGrade(widget.review.submissionId);
    if (!mounted) return;
    setState(() => _autoGrading = false);
    
    if (aiGrades != null) {
      _usedAI = true;
      for (int i = 0; i < aiGrades.length && i < _scores.length; i++) {
        _scores[i].text = aiGrades[i].awardedScore.toStringAsFixed(1);
        _comments[i].text = aiGrades[i].comments;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI grading completed successfully'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to get AI grading. Please try again.'),
        backgroundColor: Color(0xFFE53935),
        duration: Duration(seconds: 3),
      ));
    }
  }

  List<GradeItem> _buildGradeItems() {
    return List.generate(_rubricItems.length, (i) => GradeItem(
      requestNo: i + 1,
      awardedScore: double.tryParse(_scores[i].text) ?? 0,
      comments: _comments[i].text.trim(),
    ));
  }

  Future<void> _submit({bool isDraft = false}) async {
    final validationError = _validateScores();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(validationError),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    setState(() => _submitting = true);
    final ok = await SubmissionService.saveGrades(
      widget.review.submissionId,
      _buildGradeItems(),
      isDraft: isDraft,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    
    if (ok) {
      if (!isDraft) {
        widget.onBack();
        
        // 1. Ghi Analytics
        FirebaseAnalytics.instance.logEvent(
          name: 'grade_submission_success',
          parameters: {
            'score': _totalScore,
            'exam_code': widget.review.examCode,
          },
        );

        // 2. GHI LOG LÊN FIRESTORE (Tính năng mới)
        try {
          await FirebaseFirestore.instance.collection('grading_logs').add({
            'studentId': widget.review.studentId,
            'studentName': widget.review.studentName,
            'score': _totalScore,
            'method': _usedAI ? 'AI' : 'Manual', 
            'examCode': widget.review.examCode,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Lỗi ghi Firestore: $e');
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isDraft ? 'Draft saved' : 'Grades submitted successfully'),
        backgroundColor: isDraft ? const Color(0xFF1B2D8B) : const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save grades. Please try again.'),
        backgroundColor: Color(0xFFE53935),
        duration: Duration(seconds: 3),
      ));
    }
  }

  String? _validateScores() {
    for (int i = 0; i < _rubricItems.length; i++) {
      final score = double.tryParse(_scores[i].text);
      if (score == null) {
        return 'Request ${i + 1}: score must be a valid number';
      }
      if (score < 0 || score > _rubricItems[i].maxScore) {
        return 'Request ${i + 1}: score must be between 0 and ${_rubricItems[i].maxScore}';
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [..._scores, ..._comments]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalScore => _scores.fold(0.0, (sum, c) => sum + (double.tryParse(c.text) ?? 0.0));
  String get _totalScoreLabel {
    final rounded = (_totalScore * 10).round() / 10;
    return rounded == rounded.truncateToDouble() ? rounded.toInt().toString() : rounded.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _documentPanel()),
              const VerticalDivider(width: 1),
              SizedBox(width: 360, child: _rubricPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('Back to Batch', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Student: ${widget.review.studentId} - ${widget.review.studentName}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy),
                ),
                const SizedBox(height: 2),
                Text(
                  'Project Management PE | ${widget.review.campus} Campus',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Auto-save active', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _tabButton('Student Submission', 0),
              const SizedBox(width: 4),
              _tabButton('Exam Paper', 1),
              const Spacer(),
              if (_activeTab == 0) ...[
                Icon(Icons.zoom_out, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text('100%', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Icon(Icons.zoom_in, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 20),
                Text('Page 1 of 4', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _activeTab == 0
              ? Container(
                  color: const Color(0xFFF5F6FA),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _studentSubmissionContent(),
                  ),
                )
              : _examPaperContent(),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border.all(color: active ? Colors.grey.shade300 : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _studentSubmissionContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student: ${widget.review.studentId} - ${widget.review.studentName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
          const SizedBox(height: 4),
          Text('Exam Code: ${widget.review.examCode}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Divider(height: 32),
          if (_loadingDoc)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ))
          else if (_documentText == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Failed to load document',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            SelectableText(
              _documentText!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.7),
            ),
        ],
      ),
    );
  }

  Widget _examPaperContent() {
    if (_loadingExamPaper) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Giao diện khi xảy ra lỗi tải PDF hoặc Parse PDF
    if (_pdfError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('LỖI ĐỌC ĐỀ THI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              Text(_pdfError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final info = await BatchService.getExamPaper(widget.review.batchId);
                  if (info != null && info.examPaperUrl.isNotEmpty) {
                    final uri = Uri.parse(info.examPaperUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở Đề thi ở Browser (Phương án dự phòng)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_pdfBytes == null) {
      return Center(child: Text('Empty PDF data', style: TextStyle(color: Colors.grey.shade500)));
    }

    // Load PDF trực tiếp từ mảng Byte
    return SfPdfViewer.memory(
      _pdfBytes!,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() => _pdfError = 'Lỗi Syncfusion PDF Viewer:\n${details.description}\n\n*Nếu chạy trên Web, hãy đảm bảo đã thêm pdf.js vào web/index.html*');
      },
    );
  }

  Widget _rubricPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Grading Rubric',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navy)),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(_rubricItems.length, (i) => _rubricCard(i)),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _navy),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Score:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('$_totalScoreLabel / 100',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _autoGrading ? null : _autoGrade,
                  icon: _autoGrading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16),
                  iconAlignment: IconAlignment.start,
                  label: Text(_autoGrading ? 'AI Grading...' : 'Auto-grade with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _navy.withAlpha(150),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _submit(),
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.arrow_forward, size: 16),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Submit & Next Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _orange.withAlpha(150),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _submit(isDraft: true),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rubricCard(int index) {
    final item = _rubricItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _scores[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _navy),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text('/ ${item.maxScore}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comments[index],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Lecturer comments...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _navy),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RubricItem {
  final String title;
  final int maxScore;
  const _RubricItem(this.title, this.maxScore);
}