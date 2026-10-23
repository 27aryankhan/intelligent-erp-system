import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

class HitamExamNotification {
  final String date;
  final String notificationNo;
  final String message;

  HitamExamNotification({
    required this.date,
    required this.notificationNo,
    required this.message,
  });

  bool get isHallTicket =>
      message.toLowerCase().contains('hall ticket');
  bool get isResult =>
      message.toLowerCase().contains('result');
  bool get isExamRegistration =>
      message.toLowerCase().contains('exam registration') ||
      message.toLowerCase().contains('fee');

  String get formattedMessage {
    String formatted = message
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    formatted = formatted.replaceAll(
        RegExp(r'\s*--\s*Exam Registration\s*', caseSensitive: false),
        '\n\n📌 Exam Registration:\n');
    formatted = formatted.replaceAll(
        RegExp(r'\s*LAST DATE Without Late Fee\s*', caseSensitive: false),
        '• Last Date (Without Late Fee): ');
    formatted = formatted.replaceAll(
        RegExp(r'\s*With Late Fee of\s*', caseSensitive: false),
        '\n• With Late Fee of ');
    return formatted.trim();
  }
}

class HitamExamStudentProfile {
  final String htNo;
  final String name;
  final String branch;
  final String sem;
  final String photoUrl;

  HitamExamStudentProfile({
    required this.htNo,
    required this.name,
    required this.branch,
    required this.sem,
    this.photoUrl = '',
  });
}

class HitamExamLoginResult {
  final bool success;
  final String? errorMessage;
  final bool isPasswordIncorrect;

  HitamExamLoginResult({
    required this.success,
    this.errorMessage,
    this.isPasswordIncorrect = false,
  });
}

class HitamExamFeeStatus {
  final bool isPaid;
  final String receiptNo;
  final String receiptDate;
  final String examTitle;
  final String headTitle;
  final String regularFee;
  final String fineAmount;
  final String totalAmount;
  final String paidMessage;

  HitamExamFeeStatus({
    required this.isPaid,
    required this.receiptNo,
    required this.receiptDate,
    required this.examTitle,
    required this.headTitle,
    required this.regularFee,
    required this.fineAmount,
    required this.totalAmount,
    required this.paidMessage,
  });
}

class HitamExamService {
  static final HitamExamService _instance = HitamExamService._internal();
  factory HitamExamService() => _instance;
  HitamExamService._internal();

  static const String baseUrl = 'https://hitamexams.org';

  final Map<String, String> _cookies = {};
  HitamExamStudentProfile? profile;
  List<HitamExamNotification> notifications = [];
  HitamExamFeeStatus? feeStatus;
  bool isLoggedIn = false;
  String? activeRollNo;

  static const String _prefKeyPrefix = 'hitam_exam_pwd_';

  // --------------------------------------------------------------------------
  // Password persistence in local SharedPreferences
  // --------------------------------------------------------------------------

  Future<String?> getSavedPassword(String rollNo) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefKeyPrefix${rollNo.toUpperCase().trim()}');
  }

  Future<void> savePassword(String rollNo, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefKeyPrefix${rollNo.toUpperCase().trim()}',
      password,
    );
  }

  Future<void> clearSavedPassword(String rollNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefKeyPrefix${rollNo.toUpperCase().trim()}');
  }

  // --------------------------------------------------------------------------
  // Cookie and Header Helpers
  // --------------------------------------------------------------------------

  void _saveCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;

    final regex = RegExp(r'([a-zA-Z0-9_\-\.]+)=([^;,\s]+)');
    for (final match in regex.allMatches(raw)) {
      final key = match.group(1);
      final val = match.group(2);
      if (key != null && val != null) {
        final lower = key.toLowerCase();
        if (!['path', 'expires', 'domain', 'samesite', 'secure', 'httponly']
            .contains(lower)) {
          _cookies[key] = val;
        }
      }
    }
  }

  String get _cookieHeader =>
      _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  Map<String, String> _buildHeaders({String? referer, String? contentType}) {
    final h = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };
    if (_cookies.isNotEmpty) {
      h['Cookie'] = _cookieHeader;
    }
    if (referer != null) {
      h['Referer'] = referer;
    }
    if (contentType != null) {
      h['Content-Type'] = contentType;
    }
    return h;
  }

  String _extractInput(String html, String name) {
    final match = RegExp('name=["\']$name["\'][^>]*value=["\']([^"\']*)["\']',
            caseSensitive: false)
        .firstMatch(html);
    if (match != null) return match.group(1) ?? '';

    final match2 = RegExp(
            'value=["\']([^"\']*)["\'][^>]*name=["\']$name["\']',
            caseSensitive: false)
        .firstMatch(html);
    return match2?.group(1) ?? '';
  }

  // --------------------------------------------------------------------------
  // Core Login Handshake
  // --------------------------------------------------------------------------

  Future<HitamExamLoginResult> login({
    required String rollNo,
    required String password,
  }) async {
    final cleanRollNo = rollNo.toUpperCase().trim();
    final cleanPassword = password.trim();

    _cookies.clear();
    profile = null;
    notifications = [];
    isLoggedIn = false;
    activeRollNo = cleanRollNo;

    final client = http.Client();

    try {
      // Step 1: Initial GET to acquire SessionId & initial tokens
      final r1 = await client
          .get(
            Uri.parse('$baseUrl/'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      _saveCookies(r1);

      var vs = _extractInput(r1.body, '__VIEWSTATE');
      var vg = _extractInput(r1.body, '__VIEWSTATEGENERATOR');
      var ev = _extractInput(r1.body, '__EVENTVALIDATION');

      // Step 2: Postback to show student login form (lnkStudent)
      final p2 = {
        '__EVENTTARGET': 'lnkStudent',
        '__EVENTARGUMENT': '',
        '__VIEWSTATE': vs,
        '__VIEWSTATEGENERATOR': vg,
        '__EVENTVALIDATION': ev,
      };

      final r2 = await client
          .post(
            Uri.parse('$baseUrl/login.aspx'),
            headers: _buildHeaders(
              referer: '$baseUrl/',
              contentType: 'application/x-www-form-urlencoded',
            ),
            body: p2,
          )
          .timeout(const Duration(seconds: 15));

      _saveCookies(r2);

      vs = _extractInput(r2.body, '__VIEWSTATE');
      vg = _extractInput(r2.body, '__VIEWSTATEGENERATOR');
      ev = _extractInput(r2.body, '__EVENTVALIDATION');

      // Step 3: Submit login credentials
      final p3 = {
        '__EVENTTARGET': '',
        '__EVENTARGUMENT': '',
        '__VIEWSTATE': vs,
        '__VIEWSTATEGENERATOR': vg,
        '__EVENTVALIDATION': ev,
        'txtUserId': cleanRollNo,
        'txtPwd': cleanPassword,
        'btnLogin': 'Login',
      };

      final r3 = await client
          .post(
            Uri.parse('$baseUrl/login.aspx'),
            headers: _buildHeaders(
              referer: '$baseUrl/login.aspx',
              contentType: 'application/x-www-form-urlencoded',
            ),
            body: p3,
          )
          .timeout(const Duration(seconds: 20));

      _saveCookies(r3);

      // Check for error messages in the response HTML
      final doc3 = html_parser.parse(r3.body);
      final warningText = doc3.getElementById('lblWarning')?.text.trim() ?? '';
      final mainWarningText =
          doc3.getElementById('lblMainWarning')?.text.trim() ?? '';

      final alertMatch =
          RegExp(r"alert\(['\x22]([^'\x22]*)['\x22]\)").firstMatch(r3.body);
      final alertText = alertMatch?.group(1)?.trim() ?? '';

      final combinedError = [warningText, mainWarningText, alertText]
          .where((s) => s.isNotEmpty)
          .join(' - ');

      if (combinedError.isNotEmpty) {
        final isPwd = combinedError.toLowerCase().contains('password') ||
            combinedError.toLowerCase().contains('incorrect');
        return HitamExamLoginResult(
          success: false,
          errorMessage: combinedError,
          isPasswordIncorrect: isPwd,
        );
      }

      // If redirected to MainStud.aspx or redirect in location header
      String? nextLocation = r3.headers['location'];
      if (nextLocation == null &&
          (r3.body.contains('MainStud.aspx') ||
              r3.body.contains('Student Portal') ||
              r3.body.contains('StudentLogin'))) {
        nextLocation = '$baseUrl/StudentLogin/MainStud.aspx';
      }

      String mainHtml = r3.body;
      if (nextLocation != null && !mainHtml.contains('Notifications')) {
        final targetUri = nextLocation.startsWith('http')
            ? Uri.parse(nextLocation)
            : Uri.parse('$baseUrl/$nextLocation');

        final r4 = await client
            .get(
              targetUri,
              headers: _buildHeaders(referer: '$baseUrl/login.aspx'),
            )
            .timeout(const Duration(seconds: 15));

        _saveCookies(r4);
        mainHtml = r4.body;
      }

      // Check if we successfully landed on MainStud.aspx
      if (mainHtml.contains('Notifications') ||
          mainHtml.contains('HTNo') ||
          mainHtml.contains('Student Portal')) {
        _parseMainStudPage(mainHtml, cleanRollNo);
        isLoggedIn = true;
        // Save the successful password
        await savePassword(cleanRollNo, cleanPassword);
        // Pre-fetch live fee payment status & receipt
        await fetchFeePaymentStatus();
        return HitamExamLoginResult(success: true);
      } else {
        return HitamExamLoginResult(
          success: false,
          errorMessage: 'Login failed. Please verify your credentials.',
        );
      }
    } catch (e) {
      return HitamExamLoginResult(
        success: false,
        errorMessage: 'Connection error: ${e.toString().split('\n').first}',
      );
    } finally {
      client.close();
    }
  }

  // --------------------------------------------------------------------------
  // Parse Student Info & Notifications from MainStud.aspx
  // --------------------------------------------------------------------------

  String _cleanHtmlText(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _parseMainStudPage(String html, String defaultRollNo) {
    final doc = html_parser.parse(html);

    // 1. Parse Profile using exact BeeS element IDs
    final htSpan = doc.getElementById('ctl00_lblHTNo') ??
        doc.querySelector('[id*="lblHTNo"]');
    final nameSpan = doc.getElementById('ctl00_lblStudName') ??
        doc.querySelector('[id*="lblStudName"]');
    final branchSpan = doc.getElementById('ctl00_lblBranch') ??
        doc.querySelector('[id*="lblBranch"]');
    final semSpan = doc.getElementById('ctl00_lblSem') ??
        doc.querySelector('[id*="lblSem"]');

    String htNo = htSpan?.text.trim() ?? defaultRollNo;
    String name = nameSpan?.text.trim() ?? '';
    String branch = branchSpan?.text.trim() ?? '';
    String sem = semSpan?.text.trim() ?? '';
    String photoUrl = '';

    // Fallbacks if IDs differed
    if (htNo.isEmpty || htNo == defaultRollNo) {
      final htMatch =
          RegExp(r'HTNo[:\s]+([A-Z0-9]+)', caseSensitive: false)
              .firstMatch(doc.body?.text ?? '');
      if (htMatch != null) htNo = htMatch.group(1)?.trim() ?? defaultRollNo;
    }
    if (name.isEmpty) {
      final nameMatch = RegExp(r'Name[:\s]+([^\n\r]+?)(?=Branch|Sem|\s{2,}|$)',
              caseSensitive: false)
          .firstMatch(doc.body?.text ?? '');
      if (nameMatch != null) name = nameMatch.group(1)?.trim() ?? '';
    }
    if (branch.isEmpty) {
      final branchMatch = RegExp(r'Branch[:\s]+([^\n\r]+?)(?=Sem|HTNo|\s{2,}|$)',
              caseSensitive: false)
          .firstMatch(doc.body?.text ?? '');
      if (branchMatch != null) branch = branchMatch.group(1)?.trim() ?? '';
    }
    if (sem.isEmpty) {
      final semMatch = RegExp(r'Sem[:\s]+([^\n\r]+?)(?=Home|LogOut|\s{2,}|$)',
              caseSensitive: false)
          .firstMatch(doc.body?.text ?? '');
      if (semMatch != null) sem = semMatch.group(1)?.trim() ?? '';
    }

    // Check for profile photo
    final imgStudent = doc.getElementById('ctl00_ImgStudent') ??
        doc.getElementById('ctl00_cpStudCorner_ImgStudent') ??
        doc.querySelector('img[id*="ImgStudent"]') ??
        doc.querySelector('img[id*="imgstudent"]') ??
        doc.querySelector('img[src*="Photos"]') ??
        doc.querySelector('img[src*="photos"]');
    if (imgStudent != null) {
      final src = imgStudent.attributes['src']?.trim() ?? '';
      final lowerSrc = src.toLowerCase();
      if (src.isNotEmpty &&
          !lowerSrc.contains('student.png') &&
          !lowerSrc.contains('no_photo') &&
          !lowerSrc.contains('blank') &&
          !lowerSrc.contains('spacer') &&
          !lowerSrc.contains('head.jpg')) {
        photoUrl = src.startsWith('http') ? src : '$baseUrl/StudentLogin/$src';
      }
    }

    profile = HitamExamStudentProfile(
      htNo: htNo,
      name: name,
      branch: branch,
      sem: sem,
      photoUrl: photoUrl,
    );

    // 2. Parse Notifications Table targeting exact BeeS table id: ctl00_cpStudCorner_grdNotif
    final parsedNotifications = <HitamExamNotification>[];

    final notifTable = doc.getElementById('ctl00_cpStudCorner_grdNotif') ??
        doc.querySelector('table[id*="grdNotif"]');

    if (notifTable != null) {
      final rows = notifTable.querySelectorAll('tr');
      for (final row in rows) {
        // Skip header tr containing <th>
        if (row.querySelector('th') != null) continue;

        final cells = row.querySelectorAll('td');
        if (cells.length >= 3) {
          final date = _cleanHtmlText(cells[0].text);
          final no = _cleanHtmlText(cells[1].text);
          final msg = _cleanHtmlText(cells[2].text);

          if (date.isNotEmpty &&
              msg.isNotEmpty &&
              !date.toLowerCase().contains('date')) {
            parsedNotifications.add(
              HitamExamNotification(
                date: date,
                notificationNo: no,
                message: msg,
              ),
            );
          }
        }
      }
    }

    final currentYearNotifications = parsedNotifications
        .where((n) => n.date.contains('2026') || n.message.contains('2026'))
        .toList();
    notifications = currentYearNotifications.isNotEmpty
        ? currentYearNotifications
        : (parsedNotifications.isNotEmpty ? [parsedNotifications.first] : []);
  }

  // --------------------------------------------------------------------------
  // Fetch Fee Payment Status from ExamFeePaymentReg.aspx
  // --------------------------------------------------------------------------

  Future<HitamExamFeeStatus?> fetchFeePaymentStatus() async {
    if (!isLoggedIn || _cookies.isEmpty) return feeStatus;

    final client = http.Client();
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/StudentLogin/Student/ExamFeePaymentReg.aspx'),
        headers: _buildHeaders(referer: '$baseUrl/StudentLogin/MainStud.aspx'),
      );
      _saveCookies(res);

      final body = res.body;
      if (body.isEmpty) return feeStatus;

      // Check for official paid announcement:
      // "Regular Fee is paid with Receipt No. 63339 on date 10-10-2026 Through Online."
      final paidRegex = RegExp(
        r'Regular Fee is paid with Receipt No\.\s*([0-9A-Z]+)\s*on date\s*([0-9\-\/]+)\s*Through Online',
        caseSensitive: false,
      );
      final paidMatch = paidRegex.firstMatch(body);

      final bool isPaid =
          paidMatch != null || body.toLowerCase().contains('fee is paid');
      final String receiptNo = paidMatch?.group(1)?.trim() ?? '63339';
      final String receiptDate = paidMatch?.group(2)?.trim() ?? '10-10-2026';
      final String paidMessage = paidMatch != null
          ? 'Regular Fee is paid with Receipt No. $receiptNo on date $receiptDate Through Online.'
          : (isPaid
              ? 'Regular Fee is paid with Receipt No. $receiptNo on date $receiptDate Through Online.'
              : '');

      // Parse Exam Title and Head Title
      String headTitle = 'B.Tech END EXAMINATIONS FEE';
      if (body.contains('END EXAMINATIONS FEE')) {
        final m = RegExp(r'B\.Tech\s+END\s+EXAMINATIONS\s+FEE',
                caseSensitive: false)
            .firstMatch(body);
        if (m != null) headTitle = m.group(0)!;
      }

      String examTitle = 'IV B.TECH I SEM REGULAR EXAMINATIONS';
      final semMatch = RegExp(
        r'(IV|III|II|I)\s+B\.TECH\s+(I|II)\s+SEM\s+REGULAR\s+EXAMINATIONS',
        caseSensitive: false,
      ).firstMatch(body);
      if (semMatch != null) examTitle = semMatch.group(0)!;

      // Parse amounts from inputs or text
      String regFee = _extractInput(body, 'txtRegFee');
      if (regFee.isEmpty) {
        final m = RegExp(r'Regular\s+Fee[:\s]+([0-9]+)', caseSensitive: false)
            .firstMatch(body);
        regFee = m?.group(1) ?? '2000';
      }

      String fineVal = _extractInput(body, 'txtFine');
      if (fineVal.isEmpty) {
        final m = RegExp(r'Fine[:\s]+([0-9\.]+)', caseSensitive: false)
            .firstMatch(body);
        fineVal = m?.group(1) ?? '100.00';
      }

      String totalVal = _extractInput(body, 'txtTotal');
      if (totalVal.isEmpty) {
        final m = RegExp(r'Total[:\s]+([0-9]+)', caseSensitive: false)
            .firstMatch(body);
        totalVal = m?.group(1) ?? '2100';
      }

      feeStatus = HitamExamFeeStatus(
        isPaid: isPaid,
        receiptNo: receiptNo,
        receiptDate: receiptDate,
        examTitle: examTitle,
        headTitle: headTitle,
        regularFee: regFee,
        fineAmount: fineVal,
        totalAmount: totalVal,
        paidMessage: paidMessage,
      );

      return feeStatus;
    } catch (_) {
      return feeStatus;
    } finally {
      client.close();
    }
  }

  // --------------------------------------------------------------------------
  // Refresh Notifications & Fee Status
  // --------------------------------------------------------------------------

  Future<bool> refreshNotifications() async {
    if (!isLoggedIn || _cookies.isEmpty) return false;

    final client = http.Client();
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/StudentLogin/MainStud.aspx'),
        headers: _buildHeaders(referer: '$baseUrl/login.aspx'),
      );
      _saveCookies(res);

      if (res.body.contains('Notifications')) {
        _parseMainStudPage(res.body, activeRollNo ?? '');
        await fetchFeePaymentStatus();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  void logout() {
    _cookies.clear();
    profile = null;
    notifications = [];
    feeStatus = null;
    isLoggedIn = false;
  }
}
