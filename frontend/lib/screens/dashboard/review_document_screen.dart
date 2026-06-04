import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

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
  }

  @override
  void dispose() {
    for (final c in [..._scores, ..._comments]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalScore => _scores.fold(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0));

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
              Icon(Icons.zoom_out, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text('100%', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Icon(Icons.zoom_in, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 20),
              Text('Page 1 of 4', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _activeTab == 0 ? _studentSubmissionContent() : _examPaperContent(),
            ),
          ),
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
          const Text(
            'Project Management - Practical Exam',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text('Student: ${widget.review.studentId} - ${widget.review.studentName}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text('Exam Code: ${widget.review.examCode}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Divider(height: 32),
          _docSection('Request 1: Narrative Charter (20%)',
              'The project aims to develop a comprehensive learning management system for FPT University. '
              'This system will streamline course registration, assignment submission, and grade tracking for students and faculty. '
              'The initiative is driven by increasing enrollment numbers and the need for a more scalable digital infrastructure.'),
          _docSection('Request 2: Budget Items (20%)', null,
              bullets: [
                'Server Infrastructure: \$15,000',
                'Software Licenses: \$8,500',
                'Development Team: \$45,000',
                'Testing and QA: \$12,000',
              ]),
          _docSection('Request 3: Project Risks (30%)',
              'Key risks include potential delays in third-party API integration, budget overruns due to scope changes, '
              'and technical challenges with scalability. Mitigation strategies include weekly risk reviews, '
              'buffer budgeting of 15%, and use of proven cloud infrastructure.'),
          _docSection('Request 4: Project Schedule/WBS (30%)',
              'Phase 1: Requirements gathering (2 weeks), Phase 2: Design and architecture (3 weeks), '
              'Phase 3: Development (8 weeks), Phase 4: Testing and deployment (3 weeks). '
              'Total project duration: 16 weeks with bi-weekly stakeholder reviews.'),
        ],
      ),
    );
  }

  Widget _examPaperContent() {
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
          const Text(
            'PMG301 - Project Management Practical Exam',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text('Duration: 180 minutes  |  Total: 100 points',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Divider(height: 32),
          _docSection('Request 1: Narrative Charter (20 points)',
              'Write a project narrative charter for a software development project at FPT University. '
              'Include project objectives, stakeholders, scope, and success criteria.'),
          _docSection('Request 2: Budget Items (20 points)',
              'Prepare a detailed budget breakdown for the project. Include at least 4 major cost categories '
              'with justification for each line item.'),
          _docSection('Request 3: Project Risks (30 points)',
              'Identify and analyze at least 5 key project risks. For each risk, provide probability, '
              'impact assessment, and a mitigation strategy.'),
          _docSection('Request 4: Project Schedule/WBS (30 points)',
              'Create a Work Breakdown Structure and project schedule with phases, tasks, durations, '
              'and dependencies. Use a Gantt chart or equivalent format.'),
        ],
      ),
    );
  }

  Widget _docSection(String title, String? body, {List<String>? bullets}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy)),
          const SizedBox(height: 8),
          if (body != null)
            Text(body, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
          if (bullets != null)
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(child: Text(b,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _rubricPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const Text('Grading Rubric',
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
                      const Text('Total Score:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('$_totalScore / 100',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Submit & Next Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
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
          Text(item.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
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
              Text('/ ${item.maxScore}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
