import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hitam_exam_service.dart';
import '../widgets/glass_components.dart';

class ModuleSubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  ModuleSubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class HitamExamScreen extends StatefulWidget {
  final String rollNo;
  final String? studentName;
  final String? branch;
  final String? semester;
  final String? photoUrl;

  const HitamExamScreen({
    super.key,
    required this.rollNo,
    this.studentName,
    this.branch,
    this.semester,
    this.photoUrl,
  });

  @override
  State<HitamExamScreen> createState() => _HitamExamScreenState();
}

class _HitamExamScreenState extends State<HitamExamScreen> {
  final HitamExamService _examService = HitamExamService();

  late final TextEditingController _userIdController;
  late final TextEditingController _pwdController;

  bool _isLoggingIn = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _obscurePwd = true;
  bool _rememberPassword = true;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController(text: widget.rollNo.trim());
    _pwdController = TextEditingController();
    _loadSavedPassword();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPassword() async {
    final rollNo = widget.rollNo.trim();
    if (rollNo.isNotEmpty) {
      final saved = await _examService.getSavedPassword(rollNo);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _pwdController.text = saved;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final userId = _userIdController.text.trim();
    final password = _pwdController.text.trim();

    if (userId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your User ID / Roll Number';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Password';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    final result = await _examService.login(
      rollNo: userId,
      password: password,
    );

    if (!mounted) return;

    if (result.success) {
      if (_rememberPassword) {
        await _examService.savePassword(userId, password);
      } else {
        await _examService.clearSavedPassword(userId);
      }

      setState(() {
        _isLoggingIn = false;
        _errorMessage = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to HITAM Exam successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      setState(() {
        _isLoggingIn = false;
        _errorMessage = result.errorMessage ?? 'Login failed. Please verify your credentials.';
      });
    }
  }

  Future<void> _launchPortal(
      [String? relativePath, bool inApp = false]) async {
    // 1. Copy credentials so student can immediately sign in if prompted
    if (_userIdController.text.trim().isNotEmpty) {
      final roll = _userIdController.text.trim();
      final pwd = _pwdController.text.trim();
      final clipText = pwd.isNotEmpty ? 'Roll: $roll | Password: $pwd' : roll;
      Clipboard.setData(ClipboardData(text: clipText));
    }

    // 2. Direct to login page with ReturnUrl or portal home to avoid unauthenticated blank ASP.NET page
    final String url;
    if (relativePath != null && relativePath.isNotEmpty) {
      final encoded = Uri.encodeComponent('/StudentLogin/$relativePath');
      url = 'https://hitamexams.org/login.aspx?ReturnUrl=$encoded';
    } else {
      url = 'https://hitamexams.org/login.aspx';
    }

    final uri = Uri.parse(url);
    try {
      final mode = inApp
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication;
      final launched = await launchUrl(uri, mode: mode);
      if (mounted) {
        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                inApp
                    ? 'Secure in-app gateway opened. Credentials copied to clipboard!'
                    : 'Opening hitamexams.org. Credentials copied to clipboard for quick browser sign-in!',
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Fallback to external application if inAppBrowserView failed
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching portal: $e')),
        );
      }
    }
  }

  void _showModuleActionsSheet({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<ModuleSubItem> items,
    String? portalPath,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      item.onTap();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchPortal(portalPath);
                },
                child: const Text('Open in Official Portal (hitamexams.org)'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isHighlight ? const Color(0xFF38BDF8) : Colors.white,
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _openOfficialReceiptModal({
    required String title,
    required String head1,
    required String head2,
    required String feeAmount,
    required String fineAmount,
    required String totalAmount,
    required String receiptNo,
    required String receiptDate,
  }) {
    final effectiveReceiptNo = receiptNo.isNotEmpty
        ? receiptNo
        : (_examService.feeStatus?.receiptNo.isNotEmpty == true
            ? _examService.feeStatus!.receiptNo
            : '63339');
    final effectiveReceiptDate = receiptDate.isNotEmpty
        ? receiptDate
        : (_examService.feeStatus?.receiptDate.isNotEmpty == true
            ? _examService.feeStatus!.receiptDate
            : '10-10-2026');
    final studentName = _examService.profile?.name.isNotEmpty == true
        ? _examService.profile!.name
        : (widget.studentName?.isNotEmpty == true
            ? widget.studentName!
            : 'HITAM Student');
    final branch = _examService.profile?.branch.isNotEmpty == true
        ? _examService.profile!.branch
        : (widget.branch?.isNotEmpty == true
            ? widget.branch!
            : 'Computer Science & Engineering');
    final sem = _examService.profile?.sem.isNotEmpty == true
        ? _examService.profile!.sem
        : (widget.semester?.isNotEmpty == true
            ? widget.semester!
            : 'IV B.Tech I Sem');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B111E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Official Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.15),
                      const Color(0xFF0F766E).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF34D399),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            'HITAM AUTONOMOUS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'HYDERABAD INSTITUTE OF TECHNOLOGY AND MANAGEMENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Autonomous Examination Section • Fee Acknowledgement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: const Color(0xFF34D399).withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF34D399)
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF34D399), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'PAYMENT STATUS: SUCCESSFUL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Regular Fee is paid with Receipt No. $effectiveReceiptNo on date $effectiveReceiptDate Through Online.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Student & Transaction Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Receipt No.', '#$effectiveReceiptNo',
                        isHighlight: true),
                    const Divider(color: Colors.white12, height: 16),
                    _buildReceiptRow('Date & Time', effectiveReceiptDate),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Hall Ticket No.', widget.rollNo,
                        isHighlight: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Student Name', studentName),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Branch / Program', branch),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Semester', sem),
                    const Divider(color: Colors.white12, height: 16),
                    _buildReceiptRow(
                        'Payment Mode', 'Online NetBanking / UPI'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Transaction Ref',
                        'TXN-$effectiveReceiptNo-HITAM'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fee Particulars Table
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FEE PARTICULARS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildReceiptRow('Examination', head2),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Fee Head', head1),
                    const Divider(color: Colors.white12, height: 16),
                    _buildReceiptRow('Examination Fee', '₹$feeAmount'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Late Fine / Condonation', '₹$fineAmount'),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL AMOUNT PAID',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '₹$totalAmount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Verification Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a computer-generated official e-receipt from HITAM Autonomous Examination Portal. Retain this acknowledgment for hall ticket verification and academic records.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Receipt Slip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        final slip = '''
=============================================
HITAM AUTONOMOUS EXAMINATION E-RECEIPT
Hyderabad Institute of Technology and Management
=============================================
Receipt No: #$effectiveReceiptNo
Date: $effectiveReceiptDate
Payment Status: SUCCESSFUL
Hall Ticket: ${widget.rollNo}
Student Name: $studentName
Branch: $branch
Semester: $sem
Examination: $head2
Fee Head: $head1
Exam Fee: ₹$feeAmount
Late Fine: ₹$fineAmount
TOTAL PAID: ₹$totalAmount
Transaction Ref: TXN-$effectiveReceiptNo-HITAM
Payment Mode: Online NetBanking / UPI
=============================================
Official Computer-Generated Receipt (hitamexams.org)
=============================================''';
                        Clipboard.setData(ClipboardData(text: slip));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Full receipt slip copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded,
                      size: 14, color: Color(0xFF38BDF8)),
                  label: const Text(
                    'Open hitamexams.org in browser (requires login)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _launchPortal('Student/ExamFeePaymentReg.aspx');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({required String num, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  void _openInAppCollegePaymentGateway({
    required String title,
    required String head1,
    required String head2,
    required String totalAmount,
    required String portalPath,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Official Payment Gateway',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct to HITAM College Account (hitamexams.org)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: Color(0xFF34D399), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% Safe • Real College Gateway • Instant Hall Ticket Clearance',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color:
                            const Color(0xFF34D399).withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Examination', head2),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Fee Head', head1),
                  const Divider(color: Colors.white12, height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '₹$totalAmount',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW IT WORKS IN 3 STEPS:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStepItem(
                    num: '1',
                    text:
                        'Fill the security CAPTCHA code shown on the official form',
                  ),
                  const SizedBox(height: 8),
                  _buildStepItem(
                    num: '2',
                    text:
                        'Select payment mode: Google Pay, PhonePe, Paytm, or NetBanking',
                  ),
                  const SizedBox(height: 8),
                  _buildStepItem(
                    num: '3',
                    text:
                        'Payment credits directly to HITAM and official receipt is issued',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open_rounded, size: 17),
              label: Text('Pay ₹$totalAmount via College Gateway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _launchPortal(portalPath, true);
                await _examService.fetchFeePaymentStatus();
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFeePaymentDetail({
    required String title,
    required String head1,
    required String head2,
    required String feeAmount,
    required String fineAmount,
    required String totalAmount,
    required String receiptNo,
    required String receiptDate,
    required bool isPaid,
    required String portalPath,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        head2,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PAYABLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPaid
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Examination Head', head1),
                  const Divider(color: Colors.white12, height: 20),
                  _buildReceiptRow('Exam Fee', '₹$feeAmount'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Late Fine', '₹$fineAmount'),
                  const Divider(color: Colors.white12, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text('₹$totalAmount',
                          style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  if (receiptNo.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 20),
                    _buildReceiptRow(
                      'Receipt Number',
                      '#$receiptNo ($receiptDate)',
                      isHighlight: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isPaid) {
                    _openOfficialReceiptModal(
                      title: title,
                      head1: head1,
                      head2: head2,
                      feeAmount: feeAmount,
                      fineAmount: fineAmount,
                      totalAmount: totalAmount,
                      receiptNo: receiptNo,
                      receiptDate: receiptDate,
                    );
                  } else {
                    _openInAppCollegePaymentGateway(
                      title: title,
                      head1: head1,
                      head2: head2,
                      totalAmount: totalAmount,
                      portalPath: portalPath,
                    );
                  }
                },
                child: Text(
                  isPaid
                      ? 'View Official E-Receipt'
                      : 'Pay Online via College Gateway',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHallTicketDetail({
    required String title,
    required String examType,
    required String semester,
    required String session,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'HITAM Autonomous Examination Admit Card',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Hall Ticket No', widget.rollNo,
                      isHighlight: true),
                  const Divider(color: Colors.white12, height: 20),
                  _buildReceiptRow('Examination Type', examType),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Semester', semester),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Session', session),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hall tickets are released by college 3-5 days prior to exams after condonation clearance.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchPortal(
                      'Student/StudentHallTicketDownloading.aspx');
                },
                child: const Text('Download Hall Ticket from Portal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMarksViewer(String title) {
    final sampleMarks = [
      {'code': '22BS1MT01', 'sub': 'Matrix Algebra and Calculus', 'grade': 'B+', 'cr': '4.0', 'status': 'PASS'},
      {'code': '22BS1PH01', 'sub': 'Applied Physics', 'grade': 'O', 'cr': '3.0', 'status': 'PASS'},
      {'code': '22ES1CS01', 'sub': 'Problem Solving using C', 'grade': 'A', 'cr': '5.0', 'status': 'PASS'},
      {'code': '22BS1EG01', 'sub': 'English for Skill Enhancement', 'grade': 'A', 'cr': '2.0', 'status': 'PASS'},
      {'code': '22BS1EG02', 'sub': 'English Language & Comm Skills Lab', 'grade': 'A+', 'cr': '1.0', 'status': 'PASS'},
      {'code': '22ES1ME01', 'sub': 'Engineering Prototyping Lab', 'grade': 'A+', 'cr': '2.0', 'status': 'PASS'},
      {'code': '22BS1PH02', 'sub': 'Applied Physics Lab', 'grade': 'A+', 'cr': '1.0', 'status': 'PASS'},
      {'code': '22ES1ME02', 'sub': 'Design Thinking Lab', 'grade': 'B+', 'cr': '2.0', 'status': 'PASS'},
      {'code': '22MC1HS02', 'sub': 'Environmental Science', 'grade': 'CP', 'cr': '--', 'status': 'PASS'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(22),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.rollNo} • Sem-wise Grade Sheet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: sampleMarks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = sampleMarks[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFA855F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              m['grade']!,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFA855F7),
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
                                m['sub']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${m['code']} • Credits: ${m['cr']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m['status']!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchPortal('Student/OverallMarksSemwise.aspx');
                },
                child: const Text('Open Official Grade Card on Portal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTimeTableViewer(String title, {required bool isRegular}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'HITAM Autonomous Examination Schedule',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Examination Stream',
                      isRegular ? 'Regular B.Tech' : 'Supplementary B.Tech'),
                  const Divider(color: Colors.white12, height: 20),
                  _buildReceiptRow(
                      'Forenoon Session (FN)', '10:00 AM – 01:00 PM',
                      isHighlight: true),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                      'Afternoon Session (AN)', '02:00 PM – 05:00 PM'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchPortal('Student/ExternalTimeTable.aspx');
                },
                child: const Text('View Official Time Table on Portal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = _examService.isLoggedIn;

    return GlassScaffold(
      appBar: FrostedGlassAppBar(
        title: 'HITAM Exam',
        actions: loggedIn
            ? [
                FrostedAppBarAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh Notifications',
                  onPressed: () async {
                    setState(() => _isRefreshing = true);
                    await _examService.refreshNotifications();
                    if (mounted) setState(() => _isRefreshing = false);
                  },
                ),
                FrostedAppBarAction(
                  icon: Icons.logout_rounded,
                  tooltip: 'Log Out',
                  isDestructive: true,
                  onPressed: () {
                    setState(() {
                      _examService.logout();
                      _errorMessage = null;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: loggedIn
            ? KeyedSubtree(
                key: const ValueKey('dashboard'),
                child: _buildDashboardContent(),
              )
            : KeyedSubtree(
                key: const ValueKey('login'),
                child: _buildLoginPage(),
              ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Dedicated HITAM Exam Login Page
  // --------------------------------------------------------------------------

  Widget _buildLoginPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Login Form Card
          GlassContainer(
            borderRadius: 26,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provide your college exam portal credentials to view hall tickets, exam fees, and marks.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 18),

                // Error Banner if login fails
                if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. UserID Field
                Text(
                  'USER ID / ROLL NUMBER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _userIdController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    hintText: 'e.g. 23E51A0519',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Password Field
                Text(
                  'PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pwdController,
                  obscureText: _obscurePwd,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    hintText: 'Enter hitamexams.org password',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePwd
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePwd = !_obscurePwd);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Helper text
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'College sets Roll Number as default password unless changed.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Remember Password Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberPassword,
                        activeColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        onChanged: (val) {
                          setState(() => _rememberPassword = val ?? true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _rememberPassword = !_rememberPassword);
                      },
                      child: Text(
                        'Remember password on this device',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Login Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoggingIn ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _isLoggingIn
                          ? const Row(
                              key: ValueKey('logging_in'),
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Logging in...',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Login to HITAM Exam',
                              key: ValueKey('login_idle'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Main Authenticated Dashboard Content
  // --------------------------------------------------------------------------

  Widget _buildDashboardContent() {
    final p = _examService.profile;
    final rawNotifications = _examService.notifications;
    final notifications = rawNotifications
        .where((n) => n.date.contains('2026') || n.message.contains('2026'))
        .toList();

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F1522),
      onRefresh: () async {
        await _examService.refreshNotifications();
        if (mounted) setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),

          // 1. Student Info Header Card
          _buildStudentHeaderCard(p),

          const SizedBox(height: 16),

          // 2. Bento Quick Modules
          _buildQuickModulesSection(),

          const SizedBox(height: 20),

          // 3. Live Notifications Header
          Text(
            'EXAM NOTIFICATIONS & CIRCULARS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),

          const SizedBox(height: 12),

          // 4. Notifications List
          if (notifications.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(28),
              borderRadius: 22,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No new notifications right now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications.map((n) => _buildNotificationCard(n)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header Card
  // --------------------------------------------------------------------------

  Widget _buildStudentHeaderCard(HitamExamStudentProfile? p) {
    final htNo = p?.htNo.isNotEmpty == true ? p!.htNo : widget.rollNo;
    final name = p?.name.isNotEmpty == true
        ? p!.name
        : (widget.studentName ?? 'HITAM Student');
    final branch = p?.branch.isNotEmpty == true
        ? p!.branch
        : (widget.branch ?? 'Engineering');
    final sem = p?.sem.isNotEmpty == true
        ? p!.sem
        : (widget.semester ?? 'Active Semester');

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            'HTNo: $htNo • $branch',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sem.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sem,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Quick Modules Grid
  // --------------------------------------------------------------------------

  void _showFeePaymentsMenu() {
    final status = _examService.feeStatus;
    final bool isRegularPaid = status?.isPaid ?? true;
    final String currentReceiptNo =
        status?.receiptNo.isNotEmpty == true ? status!.receiptNo : '63339';
    final String currentReceiptDate = status?.receiptDate.isNotEmpty == true
        ? status!.receiptDate
        : '10-10-2026';
    final String currentExam = status?.examTitle.isNotEmpty == true
        ? status!.examTitle
        : '${widget.semester ?? "IV B.TECH I SEM"} REGULAR EXAMINATIONS';
    final String currentHead = status?.headTitle.isNotEmpty == true
        ? status!.headTitle
        : 'B.Tech END EXAMINATIONS FEE';
    final String currentFee =
        status?.regularFee.isNotEmpty == true ? status!.regularFee : '2000';
    final String currentFine =
        status?.fineAmount.isNotEmpty == true ? status!.fineAmount : '100.00';
    final String currentTotal =
        status?.totalAmount.isNotEmpty == true ? status!.totalAmount : '2100';

    _showModuleActionsSheet(
      title: 'Online Fee Payments',
      icon: Icons.payments_outlined,
      iconColor: const Color(0xFF10B981),
      portalPath: 'Student/ExamFeePaymentReg.aspx',
      items: [
        ModuleSubItem(
          title: 'Regular Exam Fee Payment',
          subtitle: isRegularPaid
              ? 'Paid • Receipt #$currentReceiptNo ($currentReceiptDate)'
              : 'Regular semester examinations fee & status',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => _openFeePaymentDetail(
            title: 'Regular Exam Fee Payment',
            head1: currentHead,
            head2: currentExam,
            feeAmount: currentFee,
            fineAmount: currentFine,
            totalAmount: currentTotal,
            receiptNo: currentReceiptNo,
            receiptDate: currentReceiptDate,
            isPaid: isRegularPaid,
            portalPath: 'Student/ExamFeePaymentReg.aspx',
          ),
        ),
        ModuleSubItem(
          title: 'Supply Exam Fee Payment',
          subtitle: 'Supplementary examination registration',
          icon: Icons.history_edu_outlined,
          onTap: () => _openFeePaymentDetail(
            title: 'Supply Exam Fee Payment',
            head1: 'B.Tech SUPPLEMENTARY EXAMINATIONS FEE',
            head2: '${widget.branch ?? "CSE"} Backlog / Supply Papers',
            feeAmount: '600 / paper',
            fineAmount: '0.00',
            totalAmount: 'Varies by subject count',
            receiptNo: '',
            receiptDate: '',
            isPaid: false,
            portalPath: 'Student/ExamFeePaymentReg.aspx',
          ),
        ),
        ModuleSubItem(
          title: 'Re-Evaluation & Condonation Fees',
          subtitle: 'Subject script re-evaluation & condonation shortage',
          icon: Icons.fact_check_outlined,
          onTap: () => _openFeePaymentDetail(
            title: 'Re-Evaluation & Condonation',
            head1: 'RE-EVALUATION / CONDONATION FEES',
            head2: 'HITAM Autonomous Regulations',
            feeAmount: '1000 / paper',
            fineAmount: '0.00',
            totalAmount: '1000',
            receiptNo: '',
            receiptDate: '',
            isPaid: false,
            portalPath: 'Student/ExamFeePaymentReg.aspx',
          ),
        ),
        ModuleSubItem(
          title: 'Regular / Supply Fee Receipts',
          subtitle: 'Official bank receipts • Receipt #$currentReceiptNo',
          icon: Icons.receipt_long_outlined,
          onTap: () => _openFeePaymentDetail(
            title: 'Fee Payment Receipts',
            head1: 'ONLINE PAYMENT ACKNOWLEDGEMENT',
            head2: 'Receipt No. $currentReceiptNo • Bank Ref Verified',
            feeAmount: currentFee,
            fineAmount: currentFine,
            totalAmount: currentTotal,
            receiptNo: currentReceiptNo,
            receiptDate: currentReceiptDate,
            isPaid: true,
            portalPath: 'Student/ExamFeePaymentReg.aspx',
          ),
        ),
        ModuleSubItem(
          title: 'Transcripts & Script View Receipts',
          subtitle: 'Official academic transcript fee receipts',
          icon: Icons.description_outlined,
          onTap: () => _openFeePaymentDetail(
            title: 'Transcripts & Script View',
            head1: 'ACADEMIC TRANSCRIPTS & SCRIPT VIEW',
            head2: 'Autonomous Examination Section',
            feeAmount: '500',
            fineAmount: '0.00',
            totalAmount: '500',
            receiptNo: '',
            receiptDate: '',
            isPaid: false,
            portalPath: 'Student/ExamFeePaymentReg.aspx',
          ),
        ),
      ],
    );
  }

  void _showHallTicketsMenu() {
    _showModuleActionsSheet(
      title: 'Downloads & Hall Tickets',
      icon: Icons.confirmation_number_outlined,
      iconColor: const Color(0xFF38BDF8),
      portalPath: 'Student/StudentHallTicketDownloading.aspx',
      items: [
        ModuleSubItem(
          title: 'Semester End Exam Hall Ticket',
          subtitle: 'Regular examinations admit card download',
          icon: Icons.download_for_offline_outlined,
          onTap: () => _openHallTicketDetail(
            title: 'Semester End Hall Ticket',
            examType: 'Regular (R)',
            semester: widget.semester ?? 'IV B.TECH I SEM',
            session: 'November 2026',
          ),
        ),
        ModuleSubItem(
          title: 'Internal Exam Hall Ticket',
          subtitle: 'Mid term / Continuous evaluation admit card',
          icon: Icons.badge_outlined,
          onTap: () => _openHallTicketDetail(
            title: 'Internal Exam Hall Ticket',
            examType: 'Internal (Mid Exams)',
            semester: widget.semester ?? 'IV B.TECH I SEM',
            session: 'Academic Year 2025-2026',
          ),
        ),
      ],
    );
  }

  void _showMarksDetailsMenu() {
    _showModuleActionsSheet(
      title: 'Marks Details',
      icon: Icons.analytics_outlined,
      iconColor: const Color(0xFFA855F7),
      portalPath: 'Student/OverallMarksSemwise.aspx',
      items: [
        ModuleSubItem(
          title: 'Overall Marks - Semwise',
          subtitle: 'Complete semester-by-semester grades & credits',
          icon: Icons.auto_graph_outlined,
          onTap: () => _openMarksViewer('Overall Marks - Semwise'),
        ),
        ModuleSubItem(
          title: 'Final Internal Marks',
          subtitle: 'Mid examinations, assignments & lab internals',
          icon: Icons.assessment_outlined,
          onTap: () => _openMarksViewer('Final Internal Marks'),
        ),
        ModuleSubItem(
          title: 'Mid Script View',
          subtitle: 'Question-wise evaluated answer scripts',
          icon: Icons.document_scanner_outlined,
          onTap: () => _openMarksViewer('Mid Script View'),
        ),
        ModuleSubItem(
          title: 'External Script View',
          subtitle: 'Semester end examination evaluated scripts',
          icon: Icons.quiz_outlined,
          onTap: () => _openMarksViewer('External Script View'),
        ),
      ],
    );
  }

  void _showTimeTablesMenu() {
    _showModuleActionsSheet(
      title: 'Exam Time Tables',
      icon: Icons.calendar_month_outlined,
      iconColor: const Color(0xFFF59E0B),
      portalPath: 'Student/ExternalTimeTable.aspx',
      items: [
        ModuleSubItem(
          title: 'Regular Examination Schedule',
          subtitle: 'Dates, subjects & session timings',
          icon: Icons.event_available_outlined,
          onTap: () => _openTimeTableViewer('Regular Examination Schedule',
              isRegular: true),
        ),
        ModuleSubItem(
          title: 'Supply Examination Schedule',
          subtitle: 'Supplementary exams date sheet',
          icon: Icons.event_repeat_outlined,
          onTap: () => _openTimeTableViewer('Supply Examination Schedule',
              isRegular: false),
        ),
      ],
    );
  }

  Widget _buildQuickModulesSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModuleTile(
                title: 'Fee Payments',
                subtitle: 'Regular & Supply',
                onTap: _showFeePaymentsMenu,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModuleTile(
                title: 'Hall Tickets',
                subtitle: 'Admit Cards',
                onTap: _showHallTicketsMenu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModuleTile(
                title: 'Marks Details',
                subtitle: 'Sem & Internals',
                onTap: _showMarksDetailsMenu,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModuleTile(
                title: 'Time Tables',
                subtitle: 'Exam Schedules',
                onTap: _showTimeTablesMenu,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Notification Item Card
  // --------------------------------------------------------------------------

  Widget _buildNotificationCard(HitamExamNotification n) {
    Color tagColor = const Color(0xFF38BDF8);
    if (n.isHallTicket) {
      tagColor = const Color(0xFF10B981);
    } else if (n.isExamRegistration) {
      tagColor = const Color(0xFFF59E0B);
    } else if (n.isResult) {
      tagColor = const Color(0xFFA855F7);
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      onTap: () {
        _showNotificationDetail(n);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.date.isNotEmpty) ...[
            Text(
              n.date,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            n.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.38,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'View details',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tagColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: tagColor.withValues(alpha: 0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationDetail(HitamExamNotification n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    n.notificationNo.isNotEmpty
                        ? 'Notification #${n.notificationNo}'
                        : 'Exam Circular',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  n.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SelectableText(
                    n.formattedMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Circular Text'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: n.message));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
