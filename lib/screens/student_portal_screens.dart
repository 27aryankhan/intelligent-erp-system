import 'package:flutter/material.dart';
import '../services/hitam_auth_service.dart';
import '../services/hitam_scraper_service.dart';

// ============================================================================
// 1. STUDENT BACKLOGS SCREEN
// ============================================================================
class StudentBacklogsScreen extends StatefulWidget {
  const StudentBacklogsScreen({super.key});

  @override
  State<StudentBacklogsScreen> createState() => _StudentBacklogsScreenState();
}

class _StudentBacklogsScreenState extends State<StudentBacklogsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentBacklogsReport? _report;

  @override
  void initState() {
    super.initState();
    _loadBacklogs();
  }

  Future<void> _loadBacklogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNo = HitamAuthService().activeUserId ?? '';
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentBacklogs(rollNo);
      if (mounted) {
        setState(() {
          _report = report ?? scraper.latestBacklogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load backlogs. Please pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _report?.totalCount ?? 0;
    final backlogs = _report?.backlogs ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Backlogs',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBacklogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBacklogs,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null && backlogs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadBacklogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: count == 0
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (count == 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                count == 0
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    count == 0
                                        ? 'All Clear!'
                                        : '$count Active ${count == 1 ? 'Backlog' : 'Backlogs'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    count == 0
                                        ? 'Congratulations, you have no pending backlogs.'
                                        : 'Clear these in upcoming supplementary exams.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (count == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.school_rounded,
                                  size: 64, color: Colors.green.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'Great Academic Record',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'No backlog subjects found on WebPros portal.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            'PENDING SUBJECTS BY SEMESTER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        ...backlogs.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.semester,
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.subjects.length} Pending',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                      height: 24, color: Color(0xFFF1F5F9)),
                                  ...item.subjects.map((subj) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cancel_outlined,
                                              size: 18,
                                              color: Colors.red.shade600),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              subj,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Arrear',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
      ),
    );
  }
}

// ============================================================================
// 2. STUDENT FEE DETAILS SCREEN
// ============================================================================
class StudentFeeDetailsScreen extends StatefulWidget {
  const StudentFeeDetailsScreen({super.key});

  @override
  State<StudentFeeDetailsScreen> createState() => _StudentFeeDetailsScreenState();
}

class _StudentFeeDetailsScreenState extends State<StudentFeeDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentFeeReport? _feeReport;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNo = HitamAuthService().activeUserId ?? '';
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentFees(rollNo);
      if (mounted) {
        setState(() {
          _feeReport = report ?? scraper.latestFeeReport;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load fee details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _feeReport;
    final totalPayable = report?.totalPayable ?? 0.0;
    final totalPaid = report?.totalPaid ?? 0.0;
    final totalDue = report?.totalDue ?? 0.0;
    final items = report?.items ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Fee Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFees,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFees,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadFees,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Total Balance Hero Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'OUTSTANDING BALANCE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: totalDue > 0
                                        ? Colors.amber.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: totalDue > 0
                                          ? Colors.amberAccent
                                          : Colors.greenAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    totalDue > 0 ? 'DUE' : 'CLEARED',
                                    style: TextStyle(
                                      color: totalDue > 0
                                          ? Colors.amberAccent
                                          : Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${totalDue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (report?.balanceText != null &&
                                report!.balanceText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                report.balanceText,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Payable',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${totalPayable.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Paid',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${totalPaid.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'ITEMIZED FEE BREAKDOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),

                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: const Text(
                            'No fee records available.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        ...items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${item.slNo}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.feeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.due > 0
                                              ? Colors.amber.shade50
                                              : Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.due > 0
                                              ? 'Due: ₹${item.due.toStringAsFixed(0)}'
                                              : 'Fully Paid',
                                          style: TextStyle(
                                            color: item.due > 0
                                                ? Colors.amber.shade800
                                                : Colors.green.shade700,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                      height: 20, color: Color(0xFFF1F5F9)),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Payable',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                          Text(
                                            '₹${item.payable.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Paid',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                          Text(
                                            '₹${item.paid.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Due',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                          Text(
                                            '₹${item.due.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: item.due > 0
                                                  ? Colors.red.shade700
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

// ============================================================================
// 3. STUDENT MARKS SCREEN
// ============================================================================
class StudentMarksScreen extends StatefulWidget {
  const StudentMarksScreen({super.key});

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  StudentMarksReport? _marksReport;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNo = HitamAuthService().activeUserId ?? '';
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentMarks(rollNo);
      if (mounted) {
        setState(() {
          _marksReport = report ?? scraper.latestMarksReport;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load marks report.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _marksReport;
    final cieList = report?.cieMarks ?? [];
    final sgpaList = report?.sgpaHistory ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Marks',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMarks,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: Colors.blue.shade700,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'CIE Internal Marks'),
            Tab(text: 'Semester SGPA'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMarks,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: CIE Marks
                  cieList.isEmpty
                      ? const Center(
                          child: Text(
                            'No CIE marks recorded yet.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cieList.length,
                          itemBuilder: (context, index) {
                            final item = cieList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.subject,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          item.examScores.entries.map((e) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${e.key}: ',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                e.value,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: e.value == '-'
                                                      ? const Color(0xFF94A3B8)
                                                      : Colors.blue.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Tab 2: SGPA History
                  sgpaList.isEmpty
                      ? const Center(
                          child: Text(
                            'No SGPA history available.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sgpaList.length,
                          itemBuilder: (context, index) {
                            final sem = sgpaList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.grade_rounded,
                                          color: Colors.indigo.shade600),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sem.semester,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sem.creditsInfo,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'SGPA',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          Text(
                                            sem.sgpa.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 4. STUDENT PROFILE SCREEN
// ============================================================================
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentProfileDetails? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNo = HitamAuthService().activeUserId ?? '';
      final scraper = HitamScraperService();
      final p = await scraper.fetchStudentProfile(rollNo);
      if (mounted) {
        setState(() {
          _profile = p ?? scraper.latestProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(String title, List<Widget> children) {
    final validChildren =
        children.where((w) => w is! SizedBox || (w.height != 0)).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: Color(0xFF0F172A),
              ),
            ),
            const Divider(height: 18, color: Color(0xFFF1F5F9)),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Profile Header Hero
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: (p?.photoUrl != null && p!.photoUrl!.isNotEmpty)
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: Image.network(
                                                p.photoUrl!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.rollNo,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.blue.shade700,
                              child: ClipOval(
                                child: (p?.photoUrl != null && p!.photoUrl!.isNotEmpty)
                                    ? Image.network(
                                        p.photoUrl!,
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Text(
                                          (p.name.isNotEmpty) ? p.name[0].toUpperCase() : 'S',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Text(
                                        (p?.name.isNotEmpty ?? false)
                                            ? p!.name[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p?.name.isNotEmpty ?? false
                              ? p!.name
                              : 'Student Profile',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p?.rollNo ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (p?.cgpa != null && p!.cgpa.isNotEmpty)
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.blueAccent.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'CGPA: ${p.cgpa}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (p?.credits != null && p!.credits.isNotEmpty)
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          Colors.greenAccent.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'Credits: ${p.credits}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Academic Details
                  _buildCardSection('ACADEMIC PROGRAM', [
                    _buildInfoRow('Course', p?.course ?? '', Icons.school_outlined),
                    _buildInfoRow('Branch', p?.branch ?? '', Icons.account_tree_outlined),
                    _buildInfoRow('Semester', p?.semester ?? '', Icons.calendar_view_week_outlined),
                    _buildInfoRow('Admission No', p?.admissionNo ?? '', Icons.confirmation_number_outlined),
                    _buildInfoRow('Entrance Rank', p?.rank ?? '', Icons.military_tech_outlined),
                    _buildInfoRow('Seat Type', p?.seatType ?? '', Icons.airline_seat_recline_normal_outlined),
                    _buildInfoRow('Joining Date', p?.joiningDate ?? '', Icons.event_available_outlined),
                  ]),

                  // Personal Information
                  _buildCardSection('PERSONAL DETAILS', [
                    _buildInfoRow('Gender', p?.gender ?? '', Icons.person_outline),
                    _buildInfoRow('Date of Birth', p?.dob ?? '', Icons.cake_outlined),
                    _buildInfoRow('Nationality', p?.nationality ?? '', Icons.flag_outlined),
                    _buildInfoRow('Religion', p?.religion ?? '', Icons.account_balance_outlined),
                    _buildInfoRow('Caste / Category', p?.caste ?? '', Icons.category_outlined),
                    _buildInfoRow('Last Studied', p?.lastStudied ?? '', Icons.history_edu_outlined),
                  ]),

                  // Contact Details
                  _buildCardSection('CONTACT DETAILS', [
                    _buildInfoRow('Mobile', p?.mobile ?? '', Icons.phone_android_outlined),
                    _buildInfoRow('Email', p?.email ?? '', Icons.email_outlined),
                    _buildInfoRow('Aadhar No', p?.aadharNo ?? '', Icons.badge_outlined),
                  ]),

                  // Parent / Guardian
                  _buildCardSection('PARENT / GUARDIAN', [
                    _buildInfoRow('Father', p?.fatherName ?? '', Icons.person_pin_outlined),
                    _buildInfoRow('Father Mobile', p?.fatherMobile ?? '', Icons.phone_outlined),
                    _buildInfoRow('Father Occupation', p?.fatherOccupation ?? '', Icons.work_outline),
                    _buildInfoRow('Mother', p?.motherName ?? '', Icons.person_pin_outlined),
                    _buildInfoRow('Mother Mobile', p?.motherMobile ?? '', Icons.phone_outlined),
                    _buildInfoRow('Mother Occupation', p?.motherOccupation ?? '', Icons.work_outline),
                  ]),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 5. STUDENT TIME TABLE SCREEN
// ============================================================================
class StudentTimeTableScreen extends StatefulWidget {
  const StudentTimeTableScreen({super.key});

  @override
  State<StudentTimeTableScreen> createState() => _StudentTimeTableScreenState();
}

class _StudentTimeTableScreenState extends State<StudentTimeTableScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentTimeTableReport? _ttReport;
  String _selectedDay = 'Mon';

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    // Default to today if Mon-Sat
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 6) {
      _selectedDay = _days[weekday - 1];
    }
    _loadTimeTable();
  }

  Future<void> _loadTimeTable() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentTimeTable();
      if (mounted) {
        setState(() {
          _ttReport = report ?? scraper.latestTimeTable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load timetable.';
          _isLoading = false;
        });
      }
    }
  }

  String _resolveSubjectName(String code) {
    if (code.isEmpty || code == '-' || code == '&nbsp;') return code;
    final match = _ttReport?.allocations.firstWhere(
      (a) => a.code.toLowerCase() == code.toLowerCase(),
      orElse: () => SubjectFacultyAllocation(code: code, name: code, facultyName: ''),
    );
    return match?.name ?? code;
  }

  String _resolveFacultyName(String code) {
    if (code.isEmpty || code == '-' || code == '&nbsp;') return '';
    final match = _ttReport?.allocations.firstWhere(
      (a) => a.code.toLowerCase() == code.toLowerCase(),
      orElse: () => SubjectFacultyAllocation(code: code, name: '', facultyName: ''),
    );
    return match?.facultyName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final report = _ttReport;
    final schedule = report?.schedules.firstWhere(
      (s) => s.day.toLowerCase() == _selectedDay.toLowerCase(),
      orElse: () => DaySchedule(day: _selectedDay, subjects: []),
    );
    final periodHeaders = report?.periodHeaders ?? [];
    final subjectsForDay = schedule?.subjects ?? [];
    final allocations = report?.allocations ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Time Table',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTimeTable,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTimeTable,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Day Selector Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _days.map((day) {
                        final isSelected = day == _selectedDay;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade700,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : const Color(0xFFCBD5E1),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDay = day;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule Timeline
                  Text(
                    'SCHEDULE FOR $_selectedDay.toUpperCase()',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (subjectsForDay.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text(
                        'No periods scheduled for this day.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    ...List.generate(subjectsForDay.length, (i) {
                      final code = subjectsForDay[i];
                      final isBreak = code.trim().isEmpty || code == '&nbsp;';
                      final periodTiming = (i + 1 < periodHeaders.length)
                          ? periodHeaders[i + 1]
                          : 'Period ${i + 1}';
                      final fullName = _resolveSubjectName(code);
                      final faculty = _resolveFacultyName(code);

                      if (isBreak) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_rounded,
                                  size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 10),
                              Text(
                                'Lunch Break ($periodTiming)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'P${i + 1}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            code,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          periodTiming
                                              .replaceAll('\n', ' • ')
                                              .replaceAll('\r', ' '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (faculty.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline_rounded,
                                              size: 14,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            faculty,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Allocation Directory Section
                  if (allocations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'FACULTY ALLOCATION DIRECTORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allocations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final a = allocations[idx];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                a.code,
                                style: TextStyle(
                                  color: Colors.indigo.shade700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            title: Text(
                              a.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              a.facultyName,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 6. STUDENT ACADEMIC REGISTER SCREEN
// ============================================================================
class StudentAcademicRegisterScreen extends StatefulWidget {
  const StudentAcademicRegisterScreen({super.key});

  @override
  State<StudentAcademicRegisterScreen> createState() =>
      _StudentAcademicRegisterScreenState();
}

class _StudentAcademicRegisterScreenState
    extends State<StudentAcademicRegisterScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentAcademicRegisterReport? _report;
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, SAFE, WARNING, CRITICAL, ACTIVE
  final Map<String, String> _dayLogFilterBySubject = {}; // Subject code -> ALL, PRESENT, ABSENT

  @override
  void initState() {
    super.initState();
    _loadAcademicRegister();
  }

  Future<void> _loadAcademicRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rollNo = HitamAuthService().activeUserId ?? '';
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentAcademicRegister(rollNo);
      if (mounted) {
        setState(() {
          _report = report ?? scraper.latestAcademicRegister;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load Academic Register.';
          _isLoading = false;
        });
      }
    }
  }

  Color _getPercentageColor(double pct, int held) {
    if (held == 0) return const Color(0xFF94A3B8);
    if (pct >= 75.0) return const Color(0xFF10B981);
    if (pct >= 65.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _resolveSubjectName(String code) {
    final clean = code.trim();
    final upper = clean.toUpperCase();

    const known = {
      'CV': 'Computer Vision',
      'NP': 'Network Programming',
      'FSWD': 'Full Stack Web Development',
      'BCT': 'Blockchain Technology',
      'NNDL': 'Neural Networks & Deep Learning',
      'IPR': 'Intellectual Property Rights',
      'MINI': 'Mini Project / Internship',
      'CDCP': 'Career Development & Personality',
      'PS-1': 'Problem Solving & Coding Skills',
      'YSML': 'Yoga, Sports & Mandatory Learning',
      'OH': 'Office Hours / Mentoring',
      'SPRTS/AFF': 'Sports & Affiliated Activities',
      'MDP/HCTC': 'Management Development / Tech Club',
      'NP(R)': 'Network Programming (Remedial)',
      'BCT(R)': 'Blockchain Technology (Remedial)',
      'NNDL(R)': 'Neural Networks (Remedial)',
      'CV LAB': 'Computer Vision Laboratory',
      'FSWD LAB': 'Full Stack Web Development Lab',
    };
    if (known.containsKey(upper)) return known[upper]!;

    final tt = HitamScraperService().latestTimeTable?.allocations ?? [];
    for (final a in tt) {
      if (a.code.trim().toUpperCase() == upper) return a.name;
    }

    final att = HitamScraperService().latestAttendanceReport?.subjects ?? [];
    for (final s in att) {
      if (s.subjectCode.trim().toUpperCase() == upper) return s.subjectName;
    }

    return clean;
  }

  (int, int) _parseAttendedHeld(String attendedHeld) {
    final parts = attendedHeld.split('/');
    if (parts.length == 2) {
      final a = int.tryParse(parts[0].trim()) ?? 0;
      final h = int.tryParse(parts[1].trim()) ?? 0;
      return (a, h);
    }
    return (0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final entries = report?.entries ?? [];

    // Global counts across all entries
    int totalHeldAll = 0;
    int totalAttendedAll = 0;
    int safeCount = 0;
    int warningCount = 0;
    int criticalCount = 0;
    int activeCount = 0;

    for (final e in entries) {
      final (attended, held) = _parseAttendedHeld(e.attendedHeld);
      totalHeldAll += held;
      totalAttendedAll += attended;

      if (held > 0) {
        activeCount++;
        if (e.percentage >= 75.0) {
          safeCount++;
        } else if (e.percentage >= 65.0) {
          warningCount++;
        } else {
          criticalCount++;
        }
      }
    }

    final double overallRegPct =
        totalHeldAll > 0 ? (totalAttendedAll / totalHeldAll) * 100 : 0.0;

    // Filter by query and selected filter
    final filtered = entries.where((e) {
      final (attended, held) = _parseAttendedHeld(e.attendedHeld);

      // Status Filter
      if (_selectedFilter == 'SAFE' && (held == 0 || e.percentage < 75.0)) {
        return false;
      }
      if (_selectedFilter == 'WARNING' &&
          (held == 0 || e.percentage < 65.0 || e.percentage >= 75.0)) {
        return false;
      }
      if (_selectedFilter == 'CRITICAL' &&
          (held == 0 || e.percentage >= 65.0)) {
        return false;
      }
      if (_selectedFilter == 'ACTIVE' && held == 0) {
        return false;
      }

      // Query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final fullName = _resolveSubjectName(e.subject).toLowerCase();
        final code = e.subject.toLowerCase();
        if (!fullName.contains(query) && !code.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Cleaned student meta
    final r = report;
    final rollNo = (r != null &&
            r.rollNo.isNotEmpty &&
            !r.rollNo.contains('Sl.No'))
        ? r.rollNo
        : (HitamAuthService().activeUserId ?? 'Student');

    final studentName = (r != null &&
            r.studentName.isNotEmpty &&
            !r.studentName.contains('Sl.No') &&
            !r.studentName.contains('Subject') &&
            !r.studentName.contains('Semester') &&
            r.studentName.length < 50)
        ? r.studentName
        : (HitamScraperService().latestProfile?.name.trim() ??
            HitamScraperService().latestAttendanceReport?.studentName.trim() ??
            rollNo);

    final sem = (r != null &&
            r.semester.isNotEmpty &&
            !r.semester.contains('Sl.No') &&
            !r.semester.contains('Subject'))
        ? r.semester
        : (HitamScraperService().latestProfile?.semester ??
            HitamScraperService().latestAttendanceReport?.semester ??
            'IV/IV B.Tech I Semester');

    final branch = HitamScraperService().latestProfile?.branch ??
        HitamScraperService().latestAttendanceReport?.branch ??
        'Computer Science & Engineering';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Academic Register',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAcademicRegister,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAcademicRegister,
        color: Colors.blue.shade700,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null && report == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadAcademicRegister,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // 1. EXECUTIVE OVERVIEW HEADER CARD
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Profile Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Roll: $rollNo • $branch',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 13, color: Color(0xFF34D399)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF34D399),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            Divider(
                                color: Colors.white.withOpacity(0.1),
                                height: 1),
                            const SizedBox(height: 12),

                            // Meta info badges: Semester & Date range
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bookmark_border_rounded,
                                          size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        sem,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (report?.dates.isNotEmpty ?? false)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.date_range_rounded,
                                            size: 14, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${report!.dates.first} to ${report.dates.last} (${report.dates.length} sessions)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Metric summary tiles row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'Overall Attendance',
                                    value:
                                        '${overallRegPct.toStringAsFixed(1)}%',
                                    subtitle:
                                        '$totalAttendedAll / $totalHeldAll slots',
                                    color: _getPercentageColor(
                                        overallRegPct, totalHeldAll),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'Registered',
                                    value: '${entries.length}',
                                    subtitle: '$activeCount active courses',
                                    color: const Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    title: 'Standing',
                                    value: '$safeCount Safe',
                                    subtitle:
                                        '${warningCount + criticalCount} Attention',
                                    color: safeCount >= (entries.length / 2)
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFBBF24),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. SEARCH BAR & FILTERS
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText:
                                'Search by course name or code (e.g. CV, NP)...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 20, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Horizontal Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All (${entries.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'SAFE',
                              'Safe ≥75% ($safeCount)',
                              accentColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'WARNING',
                              'Warning 65-74% ($warningCount)',
                              accentColor: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'CRITICAL',
                              'Critical <65% ($criticalCount)',
                              accentColor: const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'ACTIVE',
                              'Active ($activeCount)',
                              accentColor: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. SUBJECT REGISTER CARDS
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(36),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text(
                                'No matching subjects in Academic Register.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((item) {
                          final (attended, held) =
                              _parseAttendedHeld(item.attendedHeld);
                          final pctColor =
                              _getPercentageColor(item.percentage, held);
                          final fullName = _resolveSubjectName(item.subject);

                          // Bunk or recovery calculation
                          String statusBadgeText = '';
                          Color statusBadgeColor = const Color(0xFF64748B);
                          if (held > 0) {
                            if (item.percentage >= 75.0) {
                              final double surplus = attended - (0.75 * held);
                              final int bunks = (surplus / 0.75).floor();
                              statusBadgeText =
                                  bunks > 0 ? '+$bunks bunks' : 'Safe';
                              statusBadgeColor = const Color(0xFF10B981);
                            } else {
                              final double shortage = (0.75 * held) - attended;
                              final int needed = (shortage / 0.25).ceil();
                              statusBadgeText = needed > 0
                                  ? 'Need $needed classes'
                                  : 'Warning';
                              statusBadgeColor = const Color(0xFFEF4444);
                            }
                          } else {
                            statusBadgeText = 'No sessions yet';
                            statusBadgeColor = const Color(0xFF94A3B8);
                          }

                          // Day-by-day filter for this subject
                          final currentDayFilter =
                              _dayLogFilterBySubject[item.subject] ?? 'ALL';

                          final allDates = item.attendanceByDate.entries.toList();
                          final presentDates = allDates
                              .where((d) => d.value.contains('P'))
                              .toList();
                          final absentDates = allDates
                              .where((d) => d.value.contains('A'))
                              .toList();

                          final visibleDates = currentDayFilter == 'PRESENT'
                              ? presentDates
                              : currentDayFilter == 'ABSENT'
                                  ? absentDates
                                  : allDates;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: pctColor.withOpacity(0.12),
                                  child: Text(
                                    held > 0
                                        ? '${item.percentage.toStringAsFixed(0)}%'
                                        : '0%',
                                    style: TextStyle(
                                      color: pctColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      // Subject code tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.subject,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Attended: ${item.attendedHeld}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusBadgeColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusBadgeText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: statusBadgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(
                                            color: Color(0xFFF1F5F9)),

                                        // CIE Marks Section
                                        const Text(
                                          'CONTINUOUS INTERNAL EVALUATION (CIE)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF94A3B8),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        if (item.cieA1.isNotEmpty ||
                                            item.cieB1.isNotEmpty ||
                                            item.cieC1.isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              if (item.cieA1.isNotEmpty)
                                                _buildCieBadge(
                                                    'CIE-A1',
                                                    item.cieA1,
                                                    Colors.blue.shade700,
                                                    Colors.blue.shade50),
                                              if (item.cieB1.isNotEmpty)
                                                _buildCieBadge(
                                                    'CIE-B1',
                                                    item.cieB1,
                                                    Colors.indigo.shade700,
                                                    Colors.indigo.shade50),
                                              if (item.cieC1.isNotEmpty)
                                                _buildCieBadge(
                                                    'CIE-C1',
                                                    item.cieC1,
                                                    Colors.purple.shade700,
                                                    Colors.purple.shade50),
                                            ],
                                          )
                                        else
                                          const Text(
                                            'No CIE evaluations recorded yet for this subject.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),

                                        const SizedBox(height: 16),

                                        // Day by Day Attendance Section Header with sub-filter toggles
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'DAY-BY-DAY ATTENDANCE LOG',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF94A3B8),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _buildLogFilterButton(
                                                  item.subject,
                                                  'ALL',
                                                  'All (${allDates.length})',
                                                  currentDayFilter,
                                                ),
                                                const SizedBox(width: 4),
                                                _buildLogFilterButton(
                                                  item.subject,
                                                  'PRESENT',
                                                  'P (${presentDates.length})',
                                                  currentDayFilter,
                                                  color:
                                                      const Color(0xFF10B981),
                                                ),
                                                const SizedBox(width: 4),
                                                _buildLogFilterButton(
                                                  item.subject,
                                                  'ABSENT',
                                                  'A (${absentDates.length})',
                                                  currentDayFilter,
                                                  color:
                                                      const Color(0xFFEF4444),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        if (visibleDates.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Text(
                                              currentDayFilter == 'PRESENT'
                                                  ? 'No present sessions recorded.'
                                                  : currentDayFilter ==
                                                          'ABSENT'
                                                      ? 'Zero absent sessions (Perfect attendance)!'
                                                      : 'No session dates recorded.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        else
                                          SingleChildScrollView(
                                            scrollDirection:
                                                Axis.horizontal,
                                            child: Row(
                                              children:
                                                  visibleDates.map((d) {
                                                final status = d.value;
                                                Color bg =
                                                    const Color(0xFFF1F5F9);
                                                Color fg =
                                                    const Color(0xFF64748B);
                                                IconData? icon;

                                                if (status.contains('P')) {
                                                  bg = const Color(0xFFDCFCE7);
                                                  fg = const Color(0xFF15803D);
                                                  icon =
                                                      Icons.check_circle_rounded;
                                                } else if (status
                                                    .contains('A')) {
                                                  bg = const Color(0xFFFEE2E2);
                                                  fg = const Color(0xFFB91C1C);
                                                  icon = Icons.cancel_rounded;
                                                }

                                                return Container(
                                                  margin:
                                                      const EdgeInsets.only(
                                                          right: 6),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 9,
                                                          vertical: 7),
                                                  decoration: BoxDecoration(
                                                    color: bg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color: fg.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        d.key,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: fg,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (icon != null) ...[
                                                            Icon(icon,
                                                                size: 11,
                                                                color: fg),
                                                            const SizedBox(
                                                                width: 2),
                                                          ],
                                                          Text(
                                                            status.isEmpty
                                                                ? '-'
                                                                : status,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: fg,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? accentColor}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (accentColor ?? const Color(0xFF0F172A))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (accentColor ?? const Color(0xFF0F172A))
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (accentColor ?? const Color(0xFF0F172A))
                        .withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogFilterButton(
    String subject,
    String filterKey,
    String label,
    String currentFilter, {
    Color? color,
  }) {
    final isSelected = currentFilter == filterKey;
    final activeColor = color ?? const Color(0xFF475569);
    return GestureDetector(
      onTap: () {
        setState(() {
          _dayLogFilterBySubject[subject] = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCieBadge(
      String title, String val, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        '$title: $val',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
