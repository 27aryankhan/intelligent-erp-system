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

class HitamScraperService {
  final HitamAuthService authService;

  HitamScraperService({HitamAuthService? auth})
      : authService = auth ?? HitamAuthService();

  static const String attendancePageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentAttendance.aspx?showtype=SA';

  /// Fetches real-time student attendance using the AjaxPro backend RPC endpoint
  Future<List<SubjectAttendance>> fetchStudentAttendance(String rollNo) async {
    try {
      // Step 1: Probe attendance page to discover the dynamic .ashx hash handler
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
      } catch (_) {
        // Fallback to known default ashx endpoint
      }

      final String fullEndpoint = ashxUrl.startsWith('http')
          ? '$ashxUrl?_method=ShowAttendance&_session=r'
          : ashxUrl.startsWith('/')
              ? 'https://www.webprosindia.com$ashxUrl?_method=ShowAttendance&_session=r'
              : 'https://www.webprosindia.com/hitam/Academics/$ashxUrl?_method=ShowAttendance&_session=r';

      // Step 2: Call the AjaxPro RPC endpoint with text/plain body
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

      // Step 3: Unescape AjaxPro string wrapper
      String rawHtml = response.body.trim();
      if (rawHtml.startsWith('"') && rawHtml.endsWith('"')) {
        rawHtml = rawHtml.substring(1, rawHtml.length - 1);
      } else if (rawHtml.startsWith("'") && rawHtml.endsWith("'")) {
        rawHtml = rawHtml.substring(1, rawHtml.length - 1);
      }
      rawHtml = rawHtml
          .replaceAll(r'\"', '"')
          .replaceAll(r"\'", "'")
          .replaceAll(r'\r\n', '\n')
          .replaceAll(r'\n', '\n');

      final document = html_parser.parse(rawHtml);
      final List<SubjectAttendance> results = [];

      final rows = document.querySelectorAll('table tr');
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        // Typical structure: [S.No, Subject Code, Subject Name, Held, Attended, Percentage]
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
    } catch (e) {
      return [];
    }
  }
}
