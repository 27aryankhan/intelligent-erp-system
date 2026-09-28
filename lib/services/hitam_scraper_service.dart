import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'hitam_auth_service.dart';

class SubjectAttendance {
  final String subjectCode;
  final String subjectName;
  final int classesHeld;
  final int classesAttended;
  final double percentage;

  SubjectAttendance({
    required this.subjectCode,
    required this.subjectName,
    required this.classesHeld,
    required this.classesAttended,
    required this.percentage,
  });

  /// Safe Bunks Formula: Number of upcoming classes student can miss while maintaining >= 75%
  int get safeBunks {
    final double surplus = classesAttended - (0.75 * classesHeld);
    if (surplus <= 0) return 0;
    return (surplus / 0.75).floor();
  }

  /// Recovery Classes Formula: Number of consecutive classes to attend to reach 75%
  int get classesNeeded {
    final double shortage = (0.75 * classesHeld) - classesAttended;
    if (shortage <= 0) return 0;
    return (shortage / 0.25).ceil();
  }

  /// Academic standing status
  String get status {
    if (percentage >= 75.0) return 'SAFE';
    if (percentage >= 65.0) return 'WARNING'; // Eligible for condonation with medical fee
    return 'CRITICAL'; // Detention risk
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'classes_held': classesHeld,
      'classes_attended': classesAttended,
      'percentage': percentage,
      'safe_bunks': safeBunks,
      'classes_needed': classesNeeded,
      'status': status,
    };
  }

  factory SubjectAttendance.fromMap(Map<String, dynamic> map) {
    return SubjectAttendance(
      subjectCode: map['subject_code'] ?? '',
      subjectName: map['subject_name'] ?? '',
      classesHeld: (map['classes_held'] as num?)?.toInt() ?? 0,
      classesAttended: (map['classes_attended'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CieExamMarks {
  final String subject;
  final Map<String, String> examScores;

  CieExamMarks({
    required this.subject,
    required this.examScores,
  });

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'exam_scores': examScores,
      };
}

class SemesterSgpaRecord {
  final String semester;
  final double sgpa;
  final String creditsInfo;
  final int subjectsCount;

  SemesterSgpaRecord({
    required this.semester,
    required this.sgpa,
    required this.creditsInfo,
    required this.subjectsCount,
  });

  Map<String, dynamic> toMap() => {
        'semester': semester,
        'sgpa': sgpa,
        'credits_info': creditsInfo,
        'subjects_count': subjectsCount,
      };
}

class StudentMarksReport {
  final List<String> exams;
  final List<CieExamMarks> cieMarks;
  final List<SemesterSgpaRecord> sgpaHistory;

  StudentMarksReport({
    required this.exams,
    required this.cieMarks,
    required this.sgpaHistory,
  });
}

class FeeItem {
  final String slNo;
  final String feeName;
  final double payable;
  final double paid;
  final double due;

  FeeItem({
    required this.slNo,
    required this.feeName,
    required this.payable,
    required this.paid,
    required this.due,
  });

  Map<String, dynamic> toMap() => {
        'sl_no': slNo,
        'fee_name': feeName,
        'payable': payable,
        'paid': paid,
        'due': due,
      };
}

class StudentFeeReport {
  final List<FeeItem> items;
  final double totalPayable;
  final double totalPaid;
  final double totalDue;
  final String balanceText;

  StudentFeeReport({
    required this.items,
    required this.totalPayable,
    required this.totalPaid,
    required this.totalDue,
    required this.balanceText,
  });
}

class HitamScraperService {
  final HitamAuthService authService;

  HitamScraperService({HitamAuthService? auth})
      : authService = auth ?? HitamAuthService();

  static const String attendancePageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentAttendance.aspx?showtype=SA';
  static const String marksPageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentMarksReport.aspx';
  static const String feePageUrl =
      'https://www.webprosindia.com/hitam/FeePayments/studentpayments.aspx';

  String _cleanAjaxProHtml(String raw) {
    String text = raw.trim();
    if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    } else if (text.startsWith("'") && text.endsWith("'")) {
      text = text.substring(1, text.length - 1);
    }
    return text
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n');
  }

  /// 1. Fetches real-time student attendance using the AjaxPro backend RPC endpoint
  Future<List<SubjectAttendance>> fetchStudentAttendance(String rollNo) async {
    try {
      String ashxUrl =
          '/hitam/ajax/StudentAttendance,App_Web_studentattendance.aspx.a2a1b31c.ashx';

      try {
        final probeResponse = await http.get(
          Uri.parse(attendancePageUrl),
          headers: {
            'Cookie': authService.cookieHeader,
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
          },
        );

        if (probeResponse.statusCode == 200) {
          final probeDoc = html_parser.parse(probeResponse.body);
          for (var script in probeDoc.querySelectorAll('script')) {
            final src = script.attributes['src'] ?? '';
            if (src.contains('StudentAttendance') && src.contains('.ashx')) {
              ashxUrl = src;
              break;
            }
          }
        }
      } catch (_) {}

      final String fullEndpoint = ashxUrl.startsWith('http')
          ? '$ashxUrl?_method=ShowAttendance&_session=r'
          : ashxUrl.startsWith('/')
              ? 'https://www.webprosindia.com$ashxUrl?_method=ShowAttendance&_session=r'
              : 'https://www.webprosindia.com/hitam/Academics/$ashxUrl?_method=ShowAttendance&_session=r';

      final String requestBody =
          'rollNo=$rollNo\r\nfromDate=\r\ntoDate=\r\nsubjecttype=B';

      final response = await http.post(
        Uri.parse(fullEndpoint),
        headers: {
          'Cookie': authService.cookieHeader,
          'Content-Type': 'text/plain; charset=utf-8',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': attendancePageUrl,
        },
        body: requestBody,
      );

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return [];
      }

      final rawHtml = _cleanAjaxProHtml(response.body);
      final document = html_parser.parse(rawHtml);
      final List<SubjectAttendance> results = [];

      final rows = document.querySelectorAll('table tr');
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 6) {
          final code = cells[1].text.trim();
          final subject = cells[2].text.trim();
          final held = int.tryParse(cells[3].text.trim()) ?? 0;
          final attended = int.tryParse(cells[4].text.trim()) ?? 0;
          final pctStr = cells[5].text.trim().replaceAll('%', '');
          final pct = double.tryParse(pctStr) ??
              (held > 0 ? (attended / held) * 100 : 0.0);

          if (held > 0 && subject.isNotEmpty) {
            results.add(SubjectAttendance(
              subjectCode: code,
              subjectName: subject,
              classesHeld: held,
              classesAttended: attended,
              percentage: double.parse(pct.toStringAsFixed(1)),
            ));
          }
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// 2. Fetches student CIE internal marks and semester-wise SGPA history
  Future<StudentMarksReport?> fetchStudentMarks(String rollNo) async {
    try {
      String ashxUrl =
          '/hitam/ajax/Academics_StudentMarksReport,App_Web_studentmarksreport.aspx.a2a1b31c.ashx';

      try {
        final probeResponse = await http.get(
          Uri.parse(marksPageUrl),
          headers: {
            'Cookie': authService.cookieHeader,
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
          },
        );

        if (probeResponse.statusCode == 200) {
          final probeDoc = html_parser.parse(probeResponse.body);
          for (var script in probeDoc.querySelectorAll('script')) {
            final src = script.attributes['src'] ?? '';
            if (src.toLowerCase().contains('studentmarksreport') &&
                src.toLowerCase().contains('.ashx')) {
              ashxUrl = src;
              break;
            }
          }
        }
      } catch (_) {}

      final String endpoint = ashxUrl.startsWith('http')
          ? '$ashxUrl?_method=ShowMarks&_session=r'
          : ashxUrl.startsWith('/')
              ? 'https://www.webprosindia.com$ashxUrl?_method=ShowMarks&_session=r'
              : 'https://www.webprosindia.com/hitam/Academics/$ashxUrl?_method=ShowMarks&_session=r';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Cookie': authService.cookieHeader,
          'Content-Type': 'text/plain; charset=utf-8',
          'Referer': marksPageUrl,
        },
        body: '',
      );

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return null;
      }

      final rawHtml = _cleanAjaxProHtml(response.body);
      final soup = html_parser.parse(rawHtml);

      final List<String> headerSubjects = [];
      final Map<String, List<String>> examData = {};

      final t0 = soup.querySelector('table');
      if (t0 != null) {
        for (var tr in t0.querySelectorAll('tr')) {
          final cols =
              tr.querySelectorAll('th, td').map((c) => c.text.trim()).toList();
          if (cols.isEmpty) continue;
          if (cols[0] == 'Subject') {
            if (headerSubjects.isEmpty) {
              headerSubjects.addAll(cols.sublist(1));
            }
          } else {
            examData[cols[0]] = cols.sublist(1);
          }
        }
      }

      final exams = examData.keys.toList();
      final List<CieExamMarks> cieMarks = [];
      for (int i = 0; i < headerSubjects.length; i++) {
        final subj = headerSubjects[i];
        final Map<String, String> scores = {};
        for (var e in exams) {
          scores[e] = (i < (examData[e]?.length ?? 0)) ? examData[e]![i] : '-';
        }
        cieMarks.add(CieExamMarks(subject: subj, examScores: scores));
      }

      final List<SemesterSgpaRecord> sgpaHistory = [];
      final allTables = soup.querySelectorAll('table');
      int semIndex = 1;
      for (var tbl in allTables) {
        if (tbl.text.contains('SGPA')) {
          final rows = tbl.querySelectorAll('tr');
          if (rows.length >= 2) {
            final subjects = rows[0]
                .querySelectorAll('th, td')
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty && s != 'SGPA')
                .toList();
            final r1Cells = rows[1]
                .querySelectorAll('th, td')
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            double sgpa = 0.0;
            for (var c in r1Cells) {
              final val = double.tryParse(c);
              if (val != null && val >= 0.0 && val <= 10.0) {
                sgpa = val;
                break;
              }
            }

            String creditsInfo = 'Completed';
            for (var r in rows) {
              for (var td in r.querySelectorAll('td, th')) {
                final txt = td.text.trim();
                if (txt.contains('/') && txt.contains(RegExp(r'\d'))) {
                  creditsInfo = txt;
                  break;
                }
              }
            }

            sgpaHistory.add(SemesterSgpaRecord(
              semester: 'Semester $semIndex',
              sgpa: sgpa,
              creditsInfo: creditsInfo,
              subjectsCount: subjects.length,
            ));
            semIndex++;
          }
        }
      }

      return StudentMarksReport(
        exams: exams,
        cieMarks: cieMarks,
        sgpaHistory: sgpaHistory,
      );
    } catch (_) {
      return null;
    }
  }

  /// 3. Fetches student fee breakdown, receipts, and dues
  Future<StudentFeeReport?> fetchStudentFees(String rollNo) async {
    try {
      String ashxUrl =
          '/hitam/ajax/Feepayments_studentpayments,App_Web_studentpayments.aspx.c49df9d1.ashx';

      try {
        final probeResponse = await http.get(
          Uri.parse(feePageUrl),
          headers: {
            'Cookie': authService.cookieHeader,
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
          },
        );

        if (probeResponse.statusCode == 200) {
          final probeDoc = html_parser.parse(probeResponse.body);
          for (var script in probeDoc.querySelectorAll('script')) {
            final src = script.attributes['src'] ?? '';
            if (src.toLowerCase().contains('studentpayments') &&
                src.toLowerCase().contains('.ashx')) {
              ashxUrl = src;
              break;
            }
          }
        }
      } catch (_) {}

      final String endpoint = ashxUrl.startsWith('http')
          ? '$ashxUrl?_method=ShowPaymentsReport&_session=no'
          : ashxUrl.startsWith('/')
              ? 'https://www.webprosindia.com$ashxUrl?_method=ShowPaymentsReport&_session=no'
              : 'https://www.webprosindia.com/hitam/FeePayments/$ashxUrl?_method=ShowPaymentsReport&_session=no';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Cookie': authService.cookieHeader,
          'Content-Type': 'text/plain; charset=utf-8',
          'Referer': feePageUrl,
        },
        body: 'rollNo=$rollNo',
      );

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return null;
      }

      final rawHtml = _cleanAjaxProHtml(response.body);
      final soup = html_parser.parse(rawHtml);

      final List<FeeItem> items = [];
      double totalPayable = 0.0;
      double totalPaid = 0.0;
      double totalDue = 0.0;
      String balanceText = '';

      for (var tr in soup.querySelectorAll('table tr')) {
        final cols =
            tr.querySelectorAll('th, td').map((c) => c.text.trim()).toList();
        if (cols.isEmpty) continue;

        if (cols[0] == 'Balance' && cols.length > 1) {
          balanceText = cols[1];
        }

        if (cols[0].contains(RegExp(r'^\d+$')) && cols.length >= 6) {
          final sl = cols[0];
          final feeName = cols[1];
          final payable = double.tryParse(cols.length > 4 ? cols[4].replaceAll(',', '') : '0') ?? 0.0;
          final paid = double.tryParse(cols.length > 5 ? cols[5].replaceAll(',', '') : '0') ?? 0.0;
          final due = double.tryParse(cols.length > 8 ? cols[8].replaceAll(',', '') : '0') ?? 0.0;

          items.add(FeeItem(
            slNo: sl,
            feeName: feeName,
            payable: payable,
            paid: paid,
            due: due,
          ));
        } else if (cols[0].toLowerCase().contains('totals')) {
          totalPayable = double.tryParse(cols.length > 3 ? cols[3].replaceAll(',', '') : '0') ?? 0.0;
          totalPaid = double.tryParse(cols.length > 4 ? cols[4].replaceAll(',', '') : '0') ?? 0.0;
          totalDue = double.tryParse(cols.length > 7 ? cols[7].replaceAll(',', '') : '0') ?? 0.0;
        }
      }

      return StudentFeeReport(
        items: items,
        totalPayable: totalPayable,
        totalPaid: totalPaid,
        totalDue: totalDue,
        balanceText: balanceText,
      );
    } catch (_) {
      return null;
    }
  }
}
