import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hitam_auth_service.dart';
import '../services/hitam_scraper_service.dart';
import '../widgets/student_photo_widget.dart';
import '../widgets/glass_components.dart';

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

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Backlogs',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadBacklogs,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBacklogs,
        color: const Color(0xFF10B981),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              )
            : _errorMessage != null && backlogs.isEmpty
                ? Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24.0),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Color(0xFFF87171)),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loadBacklogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      if (count == 0)
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 48, horizontal: 24),
                          alignment: Alignment.center,
                          child: Column(
                            children: const [
                              Icon(Icons.school_rounded,
                                  size: 64, color: Color(0xFF34D399)),
                              SizedBox(height: 16),
                              Text(
                                'Great Academic Record',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No backlog subjects found on WebPros portal.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13),
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
                              letterSpacing: 0.6,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                        ...backlogs.map((item) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GlassCapsulePill(
                                      label: item.semester,
                                    ),
                                    const Spacer(),
                                    GlassStatusPill(
                                      label: '${item.subjects.length} Pending',
                                      isWarning: true,
                                    ),
                                  ],
                                ),
                                Divider(
                                  height: 24,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                ...item.subjects.map((subj) {
                                  return GlassSubCard(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subj,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GlassStatusPill(
                                          label: 'Arrear',
                                          isWarning: true,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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

  String _formatCurrency(num amount) {
    final str = amount.toStringAsFixed(0);
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '$formattedRest,$last3';
  }

  @override
  Widget build(BuildContext context) {
    final report = _feeReport;
    final totalPayable = report?.totalPayable ?? 0.0;
    final totalPaid = report?.totalPaid ?? 0.0;
    final totalDue = report?.totalDue ?? 0.0;
    final items = report?.items ?? [];

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Fee Details',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadFees,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFees,
        color: const Color(0xFF10B981),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : _errorMessage != null && items.isEmpty
                ? Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24.0),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Color(0xFFF87171)),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loadFees,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // Total Balance Hero Card
                      GlassContainer(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${_formatCurrency(totalDue)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (totalDue <= 0) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'All academic dues cleared for current semester',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ] else if (report?.balanceText != null &&
                                report!.balanceText.trim().isNotEmpty &&
                                report!.balanceText.trim().toLowerCase() != 'only') ...[
                              const SizedBox(height: 4),
                              Text(
                                report.balanceText,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            GlassSubCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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
                                            color: Colors.white60,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '₹${_formatCurrency(totalPayable)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: Colors.white.withOpacity(0.12),
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
                                            color: Colors.white60,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '₹${_formatCurrency(totalPaid)}',
                                          style: const TextStyle(
                                            color: Color(0xFF34D399),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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
                            letterSpacing: 0.6,
                            color: Colors.white60,
                          ),
                        ),
                      ),

                      if (items.isEmpty)
                        GlassContainer(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: const Text(
                            'No fee records available.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      else
                        ...items.map((item) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GlassCapsulePill(
                                      label: '#${item.slNo}',
                                      textColor: Colors.white70,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.feeName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    GlassStatusPill(
                                      label: item.due > 0
                                          ? 'Due: ₹${_formatCurrency(item.due)}'
                                          : 'Fully Paid',
                                      isSuccess: item.due <= 0,
                                      isWarning: item.due > 0,
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 20,
                                    color: Colors.white.withOpacity(0.08)),
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
                                              color: Colors.white60),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${_formatCurrency(item.payable)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.white),
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
                                              color: Colors.white60),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${_formatCurrency(item.paid)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF34D399),
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
                                              color: Colors.white60),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${_formatCurrency(item.due)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: item.due > 0
                                                ? const Color(0xFFF87171)
                                                : Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Marks',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadMarks,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 3.5, color: Colors.white),
            borderRadius: BorderRadius.circular(3),
          ),
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'CIE Internal Marks'),
            Tab(text: 'Semester SGPA'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMarks,
        color: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: CIE Marks
                  cieList.isEmpty
                      ? const Center(
                          child: Text(
                            'No CIE marks recorded yet.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          itemCount: cieList.length,
                          itemBuilder: (context, index) {
                            final item = cieList[index];
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subject,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Divider(
                                      height: 20,
                                      color: Colors.white.withOpacity(0.08)),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        item.examScores.entries.map((e) {
                                      return GlassSubCard(
                                        borderRadius: 12,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 13, vertical: 7.5),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${e.key}: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withValues(alpha: 0.75),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              e.value,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: e.value == '-'
                                                    ? Colors.white38
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // Tab 2: SGPA History
                  sgpaList.isEmpty
                      ? const Center(
                          child: Text(
                            'No SGPA history available.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          itemCount: sgpaList.length,
                          itemBuilder: (context, index) {
                            final sem = sgpaList[index];
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 15),
                              child: Row(
                                children: [
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
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (sem.creditsInfo.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            sem.creditsInfo,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.65),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E222C).withValues(alpha: 0.60),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.10),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'SGPA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.70),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          sem.sgpa.toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
      final rollNo = (HitamAuthService().activeUserId ?? '').toUpperCase().trim();
      final scraper = HitamScraperService();
      final p = await scraper.fetchStudentProfile(rollNo);
      if (mounted) {
        final loaded = (p != null && p.rollNo.toUpperCase().trim() == rollNo)
            ? p
            : scraper.getProfileFor(rollNo);
        if (loaded != null && (loaded.photoUrl == null || loaded.photoUrl!.isEmpty)) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final cachedPhoto =
                prefs.getString('hitam_student_photo_url_$rollNo');
            if (cachedPhoto != null &&
                cachedPhoto.isNotEmpty &&
                !HitamScraperService.isBlacklistedPhoto(cachedPhoto)) {
              _profile = StudentProfileDetails(
                rollNo: loaded.rollNo,
                name: loaded.name,
                admissionNo: loaded.admissionNo,
                course: loaded.course,
                branch: loaded.branch,
                semester: loaded.semester,
                gender: loaded.gender,
                dob: loaded.dob,
                nationality: loaded.nationality,
                religion: loaded.religion,
                entranceType: loaded.entranceType,
                rank: loaded.rank,
                seatType: loaded.seatType,
                caste: loaded.caste,
                lastStudied: loaded.lastStudied,
                joiningDate: loaded.joiningDate,
                mobile: loaded.mobile,
                email: loaded.email,
                aadharNo: loaded.aadharNo,
                guardianName: loaded.guardianName,
                guardianMobile: loaded.guardianMobile,
                fatherName: loaded.fatherName,
                fatherMobile: loaded.fatherMobile,
                fatherOccupation: loaded.fatherOccupation,
                motherName: loaded.motherName,
                motherMobile: loaded.motherMobile,
                motherOccupation: loaded.motherOccupation,
                annualIncome: loaded.annualIncome,
                cgpa: loaded.cgpa,
                credits: loaded.credits,
                percentage: loaded.percentage,
                photoUrl: cachedPhoto,
                extraDetails: loaded.extraDetails,
                spfBands: loaded.spfBands,
              );
            } else {
              if (cachedPhoto != null && HitamScraperService.isBlacklistedPhoto(cachedPhoto)) {
                prefs.remove('hitam_student_photo_url_$rollNo');
              }
              _profile = loaded;
            }
          } catch (_) {
            _profile = loaded;
          }
        } else {
          _profile = loaded;
        }
        _isLoading = false;
        setState(() {});
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
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(String title, List<Widget> children, {Color? borderColor}) {
    final validChildren =
        children.where((w) => w is! SizedBox || (w.height != 0)).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          Divider(height: 20, color: Colors.white.withValues(alpha: 0.08)),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Profile',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFF10B981),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  // Profile Header Hero with One UI Frosted Glass
                  GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        // Softened Glass Lens Floating Avatar Ring
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.2,
                            ),
                            color: Colors.white.withValues(alpha: 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: StudentPhotoWidget(
                            photoUrl: p?.photoUrl,
                            name: p?.name ?? '',
                            rollNo: p?.rollNo,
                            size: 96,
                            enableZoom: true,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 1.0,
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p?.name.isNotEmpty ?? false
                              ? p!.name.toUpperCase()
                              : 'STUDENT PROFILE',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                        if (p?.rollNo != null && p!.rollNo.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          GlassCapsulePill(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6.5),
                            borderRadius: 20,
                            child: Text(
                              p.rollNo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (p?.cgpa != null && p!.cgpa.isNotEmpty)
                              GlassCapsulePill(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                borderRadius: 22,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'CGPA: ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      TextSpan(
                                        text: p.cgpa,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if ((p?.cgpa.isNotEmpty ?? false) &&
                                (p?.credits.isNotEmpty ?? false))
                              const SizedBox(width: 12),
                            if (p?.credits.isNotEmpty ?? false)
                              GlassCapsulePill(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                borderRadius: 22,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Credits: ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      TextSpan(
                                        text: p?.credits,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Academic Details with intentional subtle green accent border
                  _buildCardSection(
                    'ACADEMIC PROGRAM',
                    [
                      _buildInfoRow('Course', p?.course ?? '', Icons.school_outlined),
                      _buildInfoRow('Branch', p?.branch ?? '', Icons.account_tree_outlined),
                      _buildInfoRow('Semester', p?.semester ?? '', Icons.calendar_view_week_outlined),
                      _buildInfoRow('Admission No', p?.admissionNo ?? '', Icons.confirmation_number_outlined),
                      _buildInfoRow('Entrance Rank', p?.rank ?? '', Icons.military_tech_outlined),
                      _buildInfoRow('Seat Type', p?.seatType ?? '', Icons.airline_seat_recline_normal_outlined),
                      _buildInfoRow('Joining Date', p?.joiningDate ?? '', Icons.event_available_outlined),
                    ],
                    borderColor: const Color(0xFF10B981).withValues(alpha: 0.22),
                  ),

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

  String _formatPeriodTiming(String rawTiming, int periodIndex) {
    if (rawTiming.isEmpty) {
      const hitamPeriodTimings = [
        '09:15 - 10:15 AM',
        '10:15 - 11:15 AM',
        '11:15 AM - 12:15 PM',
        '01:00 - 02:00 PM',
        '02:00 - 03:00 PM',
        '03:00 - 04:00 PM',
      ];
      final timing = periodIndex < hitamPeriodTimings.length
          ? hitamPeriodTimings[periodIndex]
          : '';
      return timing.isNotEmpty
          ? 'Period ${periodIndex + 1}  •  $timing'
          : 'Period ${periodIndex + 1}';
    }

    final clean = rawTiming
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final timeMatches = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM)?)', caseSensitive: false)
        .allMatches(clean)
        .map((m) => m.group(1)!.trim())
        .toList();

    String periodNum = '${periodIndex + 1}';
    final pMatch = RegExp(r'^Period\s*(\d+)', caseSensitive: false).firstMatch(clean);
    if (pMatch != null) {
      final digits = pMatch.group(1)!;
      if (digits.length >= 2 && timeMatches.isNotEmpty) {
        periodNum = digits.substring(0, 1);
      } else {
        periodNum = digits;
      }
    }

    if (timeMatches.length >= 2) {
      return 'Period $periodNum  •  ${timeMatches[0]} - ${timeMatches[1]}';
    } else if (timeMatches.length == 1) {
      return 'Period $periodNum  •  ${timeMatches[0]}';
    }

    const hitamPeriodTimings = [
      '09:15 - 10:15 AM',
      '10:15 - 11:15 AM',
      '11:15 AM - 12:15 PM',
      '01:00 - 02:00 PM',
      '02:00 - 03:00 PM',
      '03:00 - 04:00 PM',
    ];
    final timing = periodIndex < hitamPeriodTimings.length
        ? hitamPeriodTimings[periodIndex]
        : '';
    return timing.isNotEmpty
        ? 'Period $periodNum  •  $timing'
        : 'Period $periodNum';
  }

  String _formatBreakTiming(String rawTiming) {
    final clean = rawTiming
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final timeMatches = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM)?)', caseSensitive: false)
        .allMatches(clean)
        .map((m) => m.group(1)!.trim())
        .toList();

    if (timeMatches.length >= 2) {
      return '${timeMatches[0]} - ${timeMatches[1]}';
    } else if (timeMatches.length == 1) {
      return timeMatches[0];
    }
    return '12:15 PM - 01:00 PM';
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

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Time Table',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadTimeTable,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTimeTable,
        color: const Color(0xFF10B981),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  // Day Selector Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _days.map((day) {
                        final isSelected = day == _selectedDay;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: LiquidGlassPill(
                            borderRadius: 22,
                            isSelected: isSelected,
                            accentColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8.5),
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                              });
                            },
                            child: Text(
                              day,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (subjectsForDay.isEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(36),
                      alignment: Alignment.center,
                      child: const Text(
                        'No periods scheduled for this day.',
                        style: TextStyle(color: Colors.white60),
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
                        return GlassContainer(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              vertical: 13, horizontal: 16),
                          gradientColors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.22),
                            const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          ],
                          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant_rounded,
                                  size: 18, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 10),
                              Text(
                                'Lunch Break (${_formatBreakTiming(periodTiming)})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFFFDE68A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GlassCapsulePill(
                                  label: code,
                                ),
                                const Spacer(),
                                Text(
                                  _formatPeriodTiming(periodTiming, i),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (faculty.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 14,
                                      color: Colors.white60),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      faculty,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
                          letterSpacing: 0.6,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    GlassContainer(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allocations.length,
                        separatorBuilder: (context, index) => Divider(
                            height: 1, color: Colors.white.withOpacity(0.06)),
                        itemBuilder: (context, idx) {
                          final a = allocations[idx];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 60,
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  a.code,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              a.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              a.facultyName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
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
  String? _cachedPhotoUrl;
  String? _cachedStudentName;
  String? _cachedBranch;
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, SAFE, WARNING, CRITICAL, ACTIVE

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
      final rollNo =
          (HitamAuthService().activeUserId ?? '').toUpperCase().trim();
      final scraper = HitamScraperService();

      // Load cached photo and student metadata strictly scoped to this student
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('hitam_student_photo_url_$rollNo');
        final cachedName = prefs.getString('hitam_student_name');
        final cachedBranch = prefs.getString('hitam_student_branch');
        if (mounted) {
          setState(() {
            if (cached != null && cached.isNotEmpty && !HitamScraperService.isBlacklistedPhoto(cached)) {
              _cachedPhotoUrl = cached;
            }
            if (cachedName != null && cachedName.isNotEmpty && cachedName.toUpperCase().trim() != rollNo) {
              _cachedStudentName = cachedName;
            }
            if (cachedBranch != null && cachedBranch.isNotEmpty) {
              _cachedBranch = cachedBranch;
            }
          });
        }
      } catch (_) {}

      // Prefetch student photo and profile metadata in background if not already loaded for rollNo
      final matchingProfile = scraper.getProfileFor(rollNo);
      if (matchingProfile != null) {
        if (matchingProfile.name.trim().isNotEmpty &&
            matchingProfile.name.trim().toUpperCase() != rollNo) {
          _cachedStudentName = matchingProfile.name.trim();
        }
        if (matchingProfile.branch.trim().isNotEmpty) {
          _cachedBranch = matchingProfile.branch.trim();
        }
      }
      if (matchingProfile?.photoUrl == null && rollNo.isNotEmpty) {
        unawaited(scraper.fetchStudentProfile(rollNo).then((prof) {
          if (mounted &&
              prof != null &&
              prof.rollNo.toUpperCase().trim() == rollNo) {
            setState(() {
              _cachedPhotoUrl = (prof.photoUrl != null && !HitamScraperService.isBlacklistedPhoto(prof.photoUrl))
                  ? prof.photoUrl
                  : null;
              if (prof.name.trim().isNotEmpty &&
                  prof.name.trim().toUpperCase() != rollNo) {
                _cachedStudentName = prof.name.trim();
              }
              if (prof.branch.trim().isNotEmpty) {
                _cachedBranch = prof.branch.trim();
              }
            });
          }
        }));
      }

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

    // Robust student name resolution
    String studentName = '';
    if (r != null &&
        r.studentName.trim().isNotEmpty &&
        r.studentName.trim().toUpperCase() != rollNo.trim().toUpperCase() &&
        !r.studentName.contains('Sl.No') &&
        !r.studentName.contains('Subject') &&
        !r.studentName.contains('Semester') &&
        r.studentName.length < 50) {
      studentName = r.studentName.trim();
    }

    if (studentName.isEmpty) {
      final prof = HitamScraperService().getProfileFor(rollNo) ??
          HitamScraperService().latestProfile;
      final profName = prof?.name.trim();
      if (profName != null &&
          profName.isNotEmpty &&
          profName.toUpperCase() != rollNo.toUpperCase()) {
        studentName = profName;
      }
    }

    if (studentName.isEmpty) {
      final attName =
          HitamScraperService().latestAttendanceReport?.studentName.trim();
      if (attName != null &&
          attName.isNotEmpty &&
          attName.toUpperCase() != rollNo.toUpperCase()) {
        studentName = attName;
      }
    }

    if (studentName.isEmpty &&
        _cachedStudentName != null &&
        _cachedStudentName!.trim().isNotEmpty &&
        _cachedStudentName!.trim().toUpperCase() != rollNo.toUpperCase()) {
      studentName = _cachedStudentName!.trim();
    }

    if (studentName.isEmpty) {
      studentName = rollNo.isNotEmpty ? rollNo : 'Student';
    }

    final sem = (r != null &&
            r.semester.isNotEmpty &&
            !r.semester.contains('Sl.No') &&
            !r.semester.contains('Subject'))
        ? r.semester
        : (HitamScraperService().latestProfile?.semester ??
            HitamScraperService().latestAttendanceReport?.semester ??
            '');

    // Robust branch resolution
    String branch = '';
    final prof = HitamScraperService().getProfileFor(rollNo) ??
        HitamScraperService().latestProfile;
    final profBranch = prof?.branch.trim();
    if (profBranch != null && profBranch.isNotEmpty) {
      branch = profBranch;
    }

    if (branch.isEmpty) {
      final attBranch =
          HitamScraperService().latestAttendanceReport?.branch.trim();
      if (attBranch != null && attBranch.isNotEmpty) {
        branch = attBranch;
      }
    }

    if (branch.isEmpty &&
        _cachedBranch != null &&
        _cachedBranch!.trim().isNotEmpty) {
      branch = _cachedBranch!.trim();
    }

    if (branch.isEmpty) {
      final upper = rollNo.toUpperCase();
      if (upper.contains('05')) {
        branch = 'Computer Science & Engineering';
      } else if (upper.contains('66')) {
        branch = 'CSE (AI & ML)';
      } else if (upper.contains('67')) {
        branch = 'CSE (Data Science)';
      } else if (upper.contains('69')) {
        branch = 'CSE (IoT)';
      } else if (upper.contains('70')) {
        branch = 'CSE (Cyber Security)';
      } else if (upper.contains('04')) {
        branch = 'Electronics & Communication Engineering';
      } else if (upper.contains('03')) {
        branch = 'Mechanical Engineering';
      } else if (upper.contains('02')) {
        branch = 'Electrical & Electronics Engineering';
      } else if (upper.contains('01')) {
        branch = 'Civil Engineering';
      } else {
        branch = 'Engineering';
      }
    }

    final rawPhoto =
        HitamScraperService().getProfileFor(rollNo)?.photoUrl ??
            _cachedPhotoUrl;
    final photoUrl = HitamScraperService.isBlacklistedPhoto(rawPhoto) ? null : rawPhoto;

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'Academic Register',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadAcademicRegister,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAcademicRegister,
        color: const Color(0xFF34D399),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF34D399),
                  ),
                ),
              )
            : _errorMessage != null && report == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadAcademicRegister,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 600,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. EXECUTIVE OVERVIEW HEADER CARD
                      GlassContainer(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Profile Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                StudentPhotoWidget(
                                  photoUrl: photoUrl,
                                  name: studentName,
                                  rollNo: rollNo,
                                  size: 48,
                                  enableZoom: true,
                                  fallbackIcon: Icons.school_rounded,
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
                                        branch.isNotEmpty
                                            ? 'Roll: $rollNo • $branch'
                                            : 'Roll: $rollNo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.75),
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

                            // Meta info: Semester & Date range (clean One UI typography)
                            if (sem.isNotEmpty || (report?.dates.isNotEmpty ?? false))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sem.isNotEmpty)
                                    Text(
                                      sem,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  if (sem.isNotEmpty && (report?.dates.isNotEmpty ?? false))
                                    const SizedBox(height: 3),
                                  if (report?.dates.isNotEmpty ?? false)
                                    Text(
                                      '${report!.dates.first} to ${report.dates.last} (${report.dates.length} sessions)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.70),
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
                      GlassContainer(
                        borderRadius: 22,
                        padding: EdgeInsets.zero,
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText:
                                'Search by course name or code...',
                            hintStyle: TextStyle(
                                fontSize: 13.5, color: Colors.white.withValues(alpha: 0.45)),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 21, color: Colors.white.withValues(alpha: 0.75)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 18, color: Colors.white.withValues(alpha: 0.70)),
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
                              accentColor: const Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(36),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40, color: Colors.white.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'No matching subjects in Academic Register.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildSubjectCard(context, filtered[index]);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, AcademicRegisterEntry item) {
                          final (attended, held) =
                              _parseAttendedHeld(item.attendedHeld);
                          final fullName = _resolveSubjectName(item.subject);

                          final visibleDates = item.attendanceByDate.entries.toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: GlassContainer(
                              padding: EdgeInsets.zero,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: Colors.white,
                                  ),
                                ),
                                child: ExpansionTile(
                                  iconColor: Colors.white70,
                                  collapsedIconColor: Colors.white54,
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E222C).withValues(alpha: 0.60),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.10),
                                        width: 1.0,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      held > 0
                                          ? '${item.percentage.toStringAsFixed(0)}%'
                                          : '0%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Attended: ${item.attendedHeld}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                          Divider(
                                              color: Colors.white.withOpacity(0.1)),
                                          const SizedBox(height: 4),

                                          // CIE Marks Section
                                          Text(
                                            'CONTINUOUS INTERNAL EVALUATION (CIE)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white.withOpacity(0.6),
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
                                                      const Color(0xFF38BDF8),
                                                      const Color(0xFF38BDF8).withOpacity(0.12)),
                                                if (item.cieB1.isNotEmpty)
                                                  _buildCieBadge(
                                                      'CIE-B1',
                                                      item.cieB1,
                                                      const Color(0xFF818CF8),
                                                      const Color(0xFF818CF8).withOpacity(0.12)),
                                                if (item.cieC1.isNotEmpty)
                                                  _buildCieBadge(
                                                      'CIE-C1',
                                                      item.cieC1,
                                                      const Color(0xFFA78BFA),
                                                      const Color(0xFFA78BFA).withOpacity(0.12)),
                                              ],
                                            )
                                          else
                                            Text(
                                              'No CIE evaluations recorded yet for this subject.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.white.withOpacity(0.4),
                                              ),
                                            ),

                                          const SizedBox(height: 16),

                                          // Day by Day Attendance Section Header
                                          Text(
                                            'DAY-BY-DAY ATTENDANCE LOG',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white.withOpacity(0.6),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          if (visibleDates.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 8),
                                              child: Text(
                                                'No session dates recorded.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withOpacity(0.5),
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
                                                      Colors.white.withOpacity(0.06);
                                                  Color fg =
                                                      Colors.white70;
                                                  IconData? icon;

                                                  if (status.contains('P')) {
                                                    bg = const Color(0xFF10B981)
                                                        .withOpacity(0.2);
                                                    fg = const Color(0xFF34D399);
                                                    icon =
                                                        Icons.check_circle_rounded;
                                                  } else if (status
                                                      .contains('A')) {
                                                    bg = const Color(0xFFEF4444)
                                                        .withOpacity(0.2);
                                                    fg = const Color(0xFFF87171);
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
                                                        color: fg.withOpacity(0.3),
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
                            ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return GlassSubCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
    final effectiveColor = accentColor ?? const Color(0xFF34D399);

    return LiquidGlassPill(
      borderRadius: 22,
      isSelected: isSelected,
      accentColor: effectiveColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
      onTap: () => setState(() => _selectedFilter = key),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _buildCieBadge(
      String title, String val, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222C).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        '$title: $val',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================================
// 8. STUDENT SPF BAND SCREEN (REFINED EXECUTIVE DESIGN)
// ============================================================================
class StudentSpfBandScreen extends StatefulWidget {
  const StudentSpfBandScreen({super.key});

  @override
  State<StudentSpfBandScreen> createState() => _StudentSpfBandScreenState();
}

class _StudentSpfBandScreenState extends State<StudentSpfBandScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SpfBandEntry> _spfBands = [];

  @override
  void initState() {
    super.initState();
    _loadSpfBands();
  }

  Future<void> _loadSpfBands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scraper = HitamScraperService();
      final bands = await scraper.fetchStudentSpfBands();
      if (mounted) {
        setState(() {
          _spfBands = bands;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load SPF Band performance records.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBandBadge(String band) {
    final clean =
        band.replaceAll(RegExp(r'band\s*', caseSensitive: false), '').trim();
    final b = clean.toUpperCase();
    if (b.isEmpty || b == '-') {
      return Text(
        '—',
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      b,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group SPF Bands by Semester
    final Map<String, List<SpfBandEntry>> grouped = {};
    for (final entry in _spfBands) {
      grouped.putIfAbsent(entry.semester, () => []).add(entry);
    }

    final activeRoll = HitamAuthService().activeUserId ?? '';
    final studentName = HitamScraperService().latestProfile?.name.trim() ??
        HitamScraperService().latestAttendanceReport?.studentName.trim() ??
        '';

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'SPF Performance',
        actions: [
          FrostedAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadSpfBands,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSpfBands,
        color: const Color(0xFF34D399),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF34D399),
                ),
              )
            : _errorMessage != null && _spfBands.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 44, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadSpfBands,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _spfBands.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.military_tech_outlined,
                                    size: 48, color: Colors.white.withOpacity(0.4)),
                                const SizedBox(height: 14),
                                const Text(
                                  'No SPF Records Available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your semester cycle evaluations will appear here once published by the college.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            children: [
                              // 1. Student Info Header Card
                              GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName.isNotEmpty
                                          ? studentName
                                          : 'Academic Record',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (activeRoll.isNotEmpty)
                                      Text(
                                        'HT No: $activeRoll',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 2. Section Heading
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 4),
                                child: Text(
                                  'SEMESTER-WISE PERFORMANCE',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 3. Official Academic SPF Table
                              GlassContainer(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(26),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              'SEMESTER',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'CYCLE 1',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                'CYCLE 2',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.white.withOpacity(0.1),
                                    ),

                                    // Table Rows
                                    ...grouped.entries
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final idx = entry.key;
                                      final semName = entry.value.key;
                                      final cycles = entry.value.value;

                                      final c1 = cycles.isNotEmpty
                                          ? cycles[0].band
                                          : '-';
                                      final c2 = cycles.length > 1
                                          ? cycles[1].band
                                          : '-';
                                      final isEven = idx % 2 == 0;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isEven
                                              ? Colors.white.withOpacity(0.02)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: idx == grouped.length - 1
                                                  ? Colors.transparent
                                                  : Colors.white.withOpacity(0.06),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: Text(
                                                semName,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Center(
                                                child: _buildBandBadge(c1),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Center(
                                                child: _buildBandBadge(c2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 4. Institutional Note
                              GlassSubCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF34D399),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'SPF (Student Performance Framework) bands are evaluated and published on WebPros at the end of each mid-term cycle.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.75),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
