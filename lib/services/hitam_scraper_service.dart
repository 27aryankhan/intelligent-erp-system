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

class StudentAttendanceReport {
  final String rollNo;
  final String studentName;
  final String course;
  final String branch;
  final String semester;
  final int totalHeld;
  final int totalAttended;
  final double overallPercentage;
  final List<SubjectAttendance> subjects;

  StudentAttendanceReport({
    required this.rollNo,
    required this.studentName,
    required this.course,
    required this.branch,
    required this.semester,
    required this.totalHeld,
    required this.totalAttended,
    required this.overallPercentage,
    required this.subjects,
  });

  /// Overall Safe Bunks
  int get safeBunks {
    final double surplus = totalAttended - (0.75 * totalHeld);
    if (surplus <= 0) return 0;
    return (surplus / 0.75).floor();
  }

  /// Overall Recovery Classes
  int get classesNeeded {
    final double shortage = (0.75 * totalHeld) - totalAttended;
    if (shortage <= 0) return 0;
    return (shortage / 0.25).ceil();
  }

  String get academicStatus {
    if (overallPercentage >= 75.0) return 'GOOD STANDING';
    if (overallPercentage >= 65.0) return 'CONDONATION WARNING';
    return 'CRITICAL ATTENDANCE';
  }
}

// 2. BACKLOGS MODELS
class StudentBacklogItem {
  final String semester;
  final List<String> subjects;

  StudentBacklogItem({
    required this.semester,
    required this.subjects,
  });

  Map<String, dynamic> toMap() => {
        'semester': semester,
        'subjects': subjects,
      };
}

class StudentBacklogsReport {
  final List<StudentBacklogItem> backlogs;
  final int totalCount;

  StudentBacklogsReport({
    required this.backlogs,
    required this.totalCount,
  });
}

// 5. PROFILE MODELS
class StudentProfileDetails {
  final String rollNo;
  final String name;
  final String admissionNo;
  final String course;
  final String branch;
  final String semester;
  final String gender;
  final String dob;
  final String nationality;
  final String religion;
  final String entranceType;
  final String rank;
  final String seatType;
  final String caste;
  final String lastStudied;
  final String joiningDate;
  final String mobile;
  final String email;
  final String aadharNo;
  final String guardianName;
  final String guardianMobile;
  final String fatherName;
  final String fatherMobile;
  final String fatherOccupation;
  final String motherName;
  final String motherMobile;
  final String motherOccupation;
  final String annualIncome;
  final String cgpa;
  final String credits;
  final String percentage;
  final Map<String, String> extraDetails;

  StudentProfileDetails({
    required this.rollNo,
    required this.name,
    required this.admissionNo,
    required this.course,
    required this.branch,
    required this.semester,
    required this.gender,
    required this.dob,
    required this.nationality,
    required this.religion,
    required this.entranceType,
    required this.rank,
    required this.seatType,
    required this.caste,
    required this.lastStudied,
    required this.joiningDate,
    required this.mobile,
    required this.email,
    required this.aadharNo,
    required this.guardianName,
    required this.guardianMobile,
    required this.fatherName,
    required this.fatherMobile,
    required this.fatherOccupation,
    required this.motherName,
    required this.motherMobile,
    required this.motherOccupation,
    required this.annualIncome,
    required this.cgpa,
    required this.credits,
    required this.percentage,
    required this.extraDetails,
  });
}

// 6. TIME TABLE MODELS
class DaySchedule {
  final String day;
  final List<String> subjects;

  DaySchedule({
    required this.day,
    required this.subjects,
  });
}

class SubjectFacultyAllocation {
  final String code;
  final String name;
  final String facultyName;

  SubjectFacultyAllocation({
    required this.code,
    required this.name,
    required this.facultyName,
  });
}

class StudentTimeTableReport {
  final List<String> periodHeaders;
  final List<DaySchedule> schedules;
  final List<SubjectFacultyAllocation> allocations;

  StudentTimeTableReport({
    required this.periodHeaders,
    required this.schedules,
    required this.allocations,
  });
}

// 7. ACADEMIC REGISTER MODELS
class AcademicRegisterEntry {
  final String slNo;
  final String subject;
  final Map<String, String> attendanceByDate;
  final String attendedHeld;
  final double percentage;
  final String cieA1;
  final String cieB1;
  final String cieC1;

  AcademicRegisterEntry({
    required this.slNo,
    required this.subject,
    required this.attendanceByDate,
    required this.attendedHeld,
    required this.percentage,
    required this.cieA1,
    required this.cieB1,
    required this.cieC1,
  });
}

class StudentAcademicRegisterReport {
  final String rollNo;
  final String studentName;
  final String semester;
  final List<String> dates;
  final List<AcademicRegisterEntry> entries;

  StudentAcademicRegisterReport({
    required this.rollNo,
    required this.studentName,
    required this.semester,
    required this.dates,
    required this.entries,
  });
}

class HitamScraperService {
  static final HitamScraperService _instance = HitamScraperService._internal();
  factory HitamScraperService({HitamAuthService? auth}) {
    if (auth != null) {
      _instance.authService = auth;
    }
    return _instance;
  }
  HitamScraperService._internal() : authService = HitamAuthService();

  HitamAuthService authService;

  StudentAttendanceReport? latestAttendanceReport;
  StudentMarksReport? latestMarksReport;
  StudentFeeReport? latestFeeReport;
  StudentBacklogsReport? latestBacklogs;
  StudentProfileDetails? latestProfile;
  StudentTimeTableReport? latestTimeTable;
  StudentAcademicRegisterReport? latestAcademicRegister;

  static const String attendancePageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentAttendance.aspx?showtype=SA';
  static const String backlogsPageUrl =
      'https://www.webprosindia.com/hitam/Academics/studentbacklogs.aspx';
  static const String marksPageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentMarksReport.aspx';
  static const String feePageUrl =
      'https://www.webprosindia.com/hitam/FeePayments/studentpayments.aspx';
  static const String profilePageUrl =
      'https://www.webprosindia.com/hitam/Academics/StudentProfile.aspx';
  static const String timetablePageUrl =
      'https://www.webprosindia.com/hitam/Academics/TimeTableReport.aspx';
  static const String academicRegisterPageUrl =
      'https://www.webprosindia.com/hitam/Academics/studentacadamicregister.aspx';

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

  /// 1. Fetches full real-time student attendance report
  Future<StudentAttendanceReport?> fetchStudentAttendanceReport(String rollNo) async {
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
        return null;
      }

      final rawHtml = _cleanAjaxProHtml(response.body);
      final document = html_parser.parse(rawHtml);
      final List<SubjectAttendance> results = [];

      String parsedStudentName = '';
      String parsedBranch = '';
      String parsedSemester = '';
      String parsedCourse = 'B.Tech';
      int overallHeld = 0;
      int overallAttended = 0;
      double overallPct = 0.0;

      final rows = document.querySelectorAll('table tr');
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length == 3 && cells[1].text.trim() == ':') {
          final label = cells[0].text.trim().toLowerCase();
          final val = cells[2].text.trim();
          if (label.contains('student name')) parsedStudentName = val;
          if (label.contains('course')) parsedCourse = val;
          if (label.contains('branch')) parsedBranch = val;
          if (label.contains('semester')) parsedSemester = val;
        } else if (cells.length >= 5) {
          final sl = cells[0].text.trim();
          if (RegExp(r'^\d+$').hasMatch(sl)) {
            final subject = cells[1].text.trim();
            final held = int.tryParse(cells[2].text.trim()) ?? 0;
            final attended = int.tryParse(cells[3].text.trim()) ?? 0;
            final pctStr = cells[4].text.trim().replaceAll('%', '');
            final pct = double.tryParse(pctStr) ??
                (held > 0 ? (attended / held) * 100 : 0.0);

            if (held > 0 && subject.isNotEmpty) {
              results.add(SubjectAttendance(
                subjectCode: subject,
                subjectName: subject,
                classesHeld: held,
                classesAttended: attended,
                percentage: double.parse(pct.toStringAsFixed(2)),
              ));
            }
          } else if (cells.length >= 6) {
            // Alternate table layout with Code and Subject separate
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
                percentage: double.parse(pct.toStringAsFixed(2)),
              ));
            }
          }
        } else if (cells.isNotEmpty && cells.any((c) => c.text.trim().toUpperCase() == 'TOTAL')) {
          final numStrings = cells
              .map((c) => c.text.trim().replaceAll('%', ''))
              .where((t) => RegExp(r'^\d+(\.\d+)?$').hasMatch(t))
              .toList();
          if (numStrings.length >= 3) {
            overallHeld = int.tryParse(numStrings[0]) ?? 0;
            overallAttended = int.tryParse(numStrings[1]) ?? 0;
            overallPct = double.tryParse(numStrings[2]) ?? 0.0;
          } else if (cells.length >= 4 && cells[0].text.trim().toUpperCase() == 'TOTAL') {
            overallHeld = int.tryParse(cells[1].text.trim()) ?? 0;
            overallAttended = int.tryParse(cells[2].text.trim()) ?? 0;
            overallPct = double.tryParse(cells[3].text.trim().replaceAll('%', '')) ?? 0.0;
          }
        }
      }

      // If AJAX returned no subjects, attempt fallback to StudentMaster.aspx
      if (results.isEmpty) {
        try {
          final masterRes = await http.get(
            Uri.parse('https://www.webprosindia.com/hitam/StudentMaster.aspx'),
            headers: {
              'Cookie': authService.cookieHeader,
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
            },
          );
          if (masterRes.statusCode == 200 && masterRes.body.isNotEmpty) {
            final masterDoc = html_parser.parse(masterRes.body);
            final masterRows = masterDoc.querySelectorAll('table tr');
            for (var row in masterRows) {
              final cells = row.querySelectorAll('td');
              if (cells.length >= 5) {
                final sl = cells[0].text.trim();
                if (RegExp(r'^\d+$').hasMatch(sl)) {
                  final subject = cells[1].text.trim();
                  final held = int.tryParse(cells[2].text.trim()) ?? 0;
                  final attended = int.tryParse(cells[3].text.trim()) ?? 0;
                  final pctStr = cells[4].text.trim().replaceAll('%', '');
                  final pct = double.tryParse(pctStr) ??
                      (held > 0 ? (attended / held) * 100 : 0.0);

                  if (held > 0 && subject.isNotEmpty) {
                    results.add(SubjectAttendance(
                      subjectCode: subject,
                      subjectName: subject,
                      classesHeld: held,
                      classesAttended: attended,
                      percentage: double.parse(pct.toStringAsFixed(2)),
                    ));
                  }
                }
              } else if (cells.isNotEmpty && cells.any((c) => c.text.trim().toUpperCase() == 'TOTAL')) {
                final numStrings = cells
                    .map((c) => c.text.trim().replaceAll('%', ''))
                    .where((t) => RegExp(r'^\d+(\.\d+)?$').hasMatch(t))
                    .toList();
                if (numStrings.length >= 3) {
                  overallHeld = int.tryParse(numStrings[0]) ?? 0;
                  overallAttended = int.tryParse(numStrings[1]) ?? 0;
                  overallPct = double.tryParse(numStrings[2]) ?? 0.0;
                }
              }
            }
          }
        } catch (_) {}
      }

      if (overallHeld == 0 && results.isNotEmpty) {
        overallHeld = results.fold(0, (sum, s) => sum + s.classesHeld);
        overallAttended = results.fold(0, (sum, s) => sum + s.classesAttended);
        overallPct = overallHeld > 0 ? (overallAttended / overallHeld) * 100 : 0.0;
      } else if (overallPct == 0.0 && overallHeld > 0) {
        overallPct = (overallAttended / overallHeld) * 100;
      }

      final report = StudentAttendanceReport(
        rollNo: rollNo,
        studentName: parsedStudentName.isNotEmpty ? parsedStudentName : 'HITAM Student',
        course: parsedCourse,
        branch: parsedBranch.isNotEmpty ? parsedBranch : 'Engineering',
        semester: parsedSemester.isNotEmpty ? parsedSemester : 'Semester',
        totalHeld: overallHeld,
        totalAttended: overallAttended,
        overallPercentage: double.parse(overallPct.toStringAsFixed(2)),
        subjects: results,
      );

      latestAttendanceReport = report;
      return report;
    } catch (_) {
      return null;
    }
  }

  /// Fetches real-time student attendance subject list
  Future<List<SubjectAttendance>> fetchStudentAttendance(String rollNo) async {
    final report = await fetchStudentAttendanceReport(rollNo);
    return report?.subjects ?? [];
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

      final report = StudentMarksReport(
        exams: exams,
        cieMarks: cieMarks,
        sgpaHistory: sgpaHistory,
      );
      latestMarksReport = report;
      return report;
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

      final report = StudentFeeReport(
        items: items,
        totalPayable: totalPayable,
        totalPaid: totalPaid,
        totalDue: totalDue,
        balanceText: balanceText,
      );
      latestFeeReport = report;
      return report;
    } catch (_) {
      return null;
    }
  }

  /// 4. Fetches student backlogs history
  Future<StudentBacklogsReport?> fetchStudentBacklogs(String rollNo) async {
    try {
      final response = await http.get(
        Uri.parse(backlogsPageUrl),
        headers: {
          'Cookie': authService.cookieHeader,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
        },
      );

      if (response.statusCode != 200) return null;

      final doc = html_parser.parse(response.body);
      final div = doc.querySelector('#ctl00_CapPlaceHolder_divBacklogs');
      final List<StudentBacklogItem> list = [];
      int count = 0;

      if (div != null) {
        final rows = div.querySelectorAll('table tr');
        for (int i = 1; i < rows.length; i++) {
          final cells = rows[i].querySelectorAll('td');
          if (cells.length >= 2) {
            final sem = cells[0].text.trim();
            final subjs = cells[1].innerHtml
                .split(RegExp(r'<br\s*/?>', caseSensitive: false))
                .map((s) => s.replaceAll('*', '').replaceAll('&amp;', '&').trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (subjs.isNotEmpty) {
              list.add(StudentBacklogItem(semester: sem, subjects: subjs));
              count += subjs.length;
            }
          }
        }
      }

      final report = StudentBacklogsReport(backlogs: list, totalCount: count);
      latestBacklogs = report;
      return report;
    } catch (_) {
      return null;
    }
  }

  /// 5. Fetches student comprehensive profile details
  Future<StudentProfileDetails?> fetchStudentProfile(String rollNo) async {
    try {
      final endpoint =
          'https://www.webprosindia.com/hitam/ajax/StudentProfile,App_Web_studentprofile.aspx.a2a1b31c.ashx?_method=ShowStudentProfileNew&_session=rw';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Cookie': authService.cookieHeader,
          'Content-Type': 'text/plain; charset=utf-8',
          'Referer': profilePageUrl,
        },
        body: 'RollNo=$rollNo\r\nisImageDisplay=false',
      );

      if (response.statusCode != 200 || response.body.trim().isEmpty) return null;

      final rawHtml = _cleanAjaxProHtml(response.body);
      final doc = html_parser.parse(rawHtml);

      final Map<String, String> kv = {};
      String currentSection = 'personal';
      String studentName = '';
      String guardianName = '';
      String fatherName = '';
      String motherName = '';

      final rows = doc.querySelectorAll('tr');
      for (var r in rows) {
        final rowText = r.text.toLowerCase();
        if (rowText.contains('guardian details')) {
          currentSection = 'guardian';
        } else if (rowText.contains("parent's details") || rowText.contains("parents details")) {
          currentSection = 'parent';
        } else if (rowText.contains('personal details')) {
          currentSection = 'personal';
        }

        final cells = r.querySelectorAll('td, th').map((c) => c.text.trim()).toList();
        int i = 0;
        while (i < cells.length) {
          if (i + 2 < cells.length && (cells[i + 1] == ':' || cells[i + 1].isEmpty)) {
            final key = cells[i].replaceAll(':', '').replaceAll(r"\'", "'").trim();
            final val = cells[i + 2].replaceAll(r"\'", "'").trim();
            if (key.isNotEmpty) {
              final lowerKey = key.toLowerCase();
              kv[lowerKey] = val;
              if (lowerKey == 'name') {
                if (currentSection == 'personal' && studentName.isEmpty) {
                  studentName = val;
                } else if (currentSection == 'guardian') {
                  guardianName = val;
                }
              } else if (lowerKey.contains('father name')) {
                fatherName = val;
              } else if (lowerKey.contains('mother name')) {
                motherName = val;
              }
            }
            i += 3;
          } else if (i + 1 < cells.length && cells[i].endsWith(':')) {
            final key = cells[i].replaceAll(':', '').replaceAll(r"\'", "'").trim();
            final val = cells[i + 1].replaceAll(r"\'", "'").trim();
            if (key.isNotEmpty) {
              final lowerKey = key.toLowerCase();
              kv[lowerKey] = val;
              if (lowerKey == 'name') {
                if (currentSection == 'personal' && studentName.isEmpty) {
                  studentName = val;
                } else if (currentSection == 'guardian') {
                  guardianName = val;
                }
              }
            }
            i += 2;
          } else {
            i++;
          }
        }
      }

      String cgpa = '';
      String credits = '';
      String percentage = '';
      final fullText = doc.body?.text ?? '';
      final cgpaMatch = RegExp(r'CGPA\s*:\s*([\d\.]+)').firstMatch(fullText);
      if (cgpaMatch != null) cgpa = cgpaMatch.group(1) ?? '';
      final credMatch = RegExp(r'Credits\s*:\s*([\d\/]+)').firstMatch(fullText);
      if (credMatch != null) credits = credMatch.group(1) ?? '';
      final pctMatch = RegExp(r'([\d\.]+)\s*%').firstMatch(fullText);
      if (pctMatch != null) percentage = pctMatch.group(1) ?? '';

      final profile = StudentProfileDetails(
        rollNo: kv['rollno'] ?? kv['roll no'] ?? rollNo,
        name: studentName.isNotEmpty ? studentName : (kv['name'] ?? ''),
        admissionNo: kv['admission.no'] ?? kv['admission no'] ?? '',
        course: kv['course'] ?? '',
        branch: kv['branch'] ?? '',
        semester: kv['semester'] ?? '',
        gender: kv['gender'] ?? '',
        dob: kv['dob'] ?? '',
        nationality: kv['nationality'] ?? '',
        religion: kv['religion'] ?? '',
        entranceType: kv['entrance type'] ?? '',
        rank: kv['eamcet/ecet rank'] ?? kv['rank'] ?? '',
        seatType: kv['seat type'] ?? '',
        caste: kv['caste'] ?? '',
        lastStudied: kv['last studied'] ?? '',
        joiningDate: kv['joining date'] ?? '',
        mobile: kv['mobile.no'] ?? kv['mobile'] ?? '',
        email: kv['email'] ?? '',
        aadharNo: kv['aadhar.no'] ?? kv['aadhar'] ?? '',
        guardianName: guardianName.isNotEmpty ? guardianName : (kv['guardian details'] ?? kv['guardian name'] ?? ''),
        guardianMobile: kv['guardian mobile'] ?? kv['mobile'] ?? '',
        fatherName: fatherName.isNotEmpty ? fatherName : (kv['father name'] ?? ''),
        fatherMobile: kv['father mobile.no'] ?? kv['father mobile'] ?? '',
        fatherOccupation: kv['father occupation'] ?? '',
        motherName: motherName.isNotEmpty ? motherName : (kv['mother name'] ?? ''),
        motherMobile: kv['mother mobile.no'] ?? kv['mother mobile'] ?? '',
        motherOccupation: kv['mother occupation'] ?? '',
        annualIncome: kv['annual income'] ?? '',
        cgpa: cgpa,
        credits: credits,
        percentage: percentage,
        extraDetails: kv,
      );
      latestProfile = profile;
      return profile;
    } catch (_) {
      return null;
    }
  }

  /// 6. Fetches student weekly period timetable and faculty allocation
  Future<StudentTimeTableReport?> fetchStudentTimeTable() async {
    try {
      final String endpoint =
          'https://www.webprosindia.com/hitam/ajax/Academics_TimeTableReport,App_Web_timetablereport.aspx.a2a1b31c.ashx?_method=getTimeTableReport&_session=r';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Cookie': authService.cookieHeader,
          'Content-Type': 'text/plain; charset=utf-8',
          'Referer': timetablePageUrl,
        },
      );

      if (response.statusCode != 200 || response.body.trim().isEmpty) return null;

      final rawHtml = _cleanAjaxProHtml(response.body);
      final doc = html_parser.parse(rawHtml);
      final tables = doc.querySelectorAll('table');

      List<String> periodHeaders = [];
      List<DaySchedule> schedules = [];
      List<SubjectFacultyAllocation> allocations = [];

      for (var tbl in tables) {
        final headerRow = tbl.querySelector('tr.reportHeading2WithBackground');
        if (headerRow != null && headerRow.text.contains('Day of week')) {
          final thCols = headerRow.querySelectorAll('td');
          periodHeaders = thCols.map((c) => c.text.replaceAll('\r', ' ').trim()).toList();

          final rows = tbl.querySelectorAll('tr');
          for (var r in rows) {
            if (r == headerRow) continue;
            final cells = r.querySelectorAll('td');
            if (cells.isNotEmpty) {
              final day = cells[0].text.trim();
              if (['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].contains(day)) {
                final subjs = cells.sublist(1).map((c) => c.text.replaceAll('&nbsp;', ' ').trim()).toList();
                schedules.add(DaySchedule(day: day, subjects: subjs));
              }
            }
          }
        } else if (headerRow != null && headerRow.text.contains('Subject Code') && headerRow.text.contains('Name of Faculty')) {
          final rows = tbl.querySelectorAll('tr');
          for (var r in rows) {
            if (r == headerRow) continue;
            final cells = r.querySelectorAll('td');
            if (cells.length >= 3) {
              final code = cells[0].text.trim();
              final name = cells[1].text.trim();
              final fac = cells[2].text.trim();
              if (code.isNotEmpty && code != 'Subject Code') {
                allocations.add(SubjectFacultyAllocation(code: code, name: name, facultyName: fac));
              }
            }
          }
        }
      }

      final report = StudentTimeTableReport(
        periodHeaders: periodHeaders,
        schedules: schedules,
        allocations: allocations,
      );
      latestTimeTable = report;
      return report;
    } catch (_) {
      return null;
    }
  }

  /// 7. Fetches comprehensive academic day-by-day attendance and CIE register
  Future<StudentAcademicRegisterReport?> fetchStudentAcademicRegister(String rollNo) async {
    try {
      final response = await http.get(
        Uri.parse(academicRegisterPageUrl),
        headers: {
          'Cookie': authService.cookieHeader,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
        },
      );

      if (response.statusCode != 200) return null;

      final doc = html_parser.parse(response.body);
      String studentName = '';
      String sem = '';

      // Cleanly extract Student Name & Semester from info cells
      for (final tr in doc.querySelectorAll('tr')) {
        final tds = tr.querySelectorAll('td');
        for (int i = 0; i < tds.length; i++) {
          final label = tds[i].text.trim().toLowerCase();
          if (label.contains('student name') || label == 'name') {
            if (i + 1 < tds.length) {
              final val = tds[i + 1].text.replaceAll('&nbsp;', ' ').replaceAll(':', '').trim();
              if (val.isNotEmpty &&
                  !val.contains('Sl.No') &&
                  !val.contains('Subject') &&
                  !val.contains('Semester') &&
                  val.length < 50) {
                studentName = val;
              }
            }
          }
          if (label.contains('semester')) {
            if (i + 1 < tds.length) {
              final val = tds[i + 1].text.replaceAll('&nbsp;', ' ').replaceAll(':', '').trim();
              if (val.isNotEmpty &&
                  !val.contains('Sl.No') &&
                  !val.contains('Subject') &&
                  val.length < 50) {
                sem = val;
              }
            }
          }
        }
      }

      // Safe fallbacks to prevent any table data from ever appearing as student name
      if (studentName.isEmpty ||
          studentName.contains('Sl.No') ||
          studentName.contains('Subject') ||
          studentName.contains('Semester') ||
          studentName.length > 50) {
        studentName = latestProfile?.name.trim() ??
            latestAttendanceReport?.studentName.trim() ??
            '';
      }
      if (studentName.isEmpty) {
        studentName = rollNo.isNotEmpty ? rollNo : 'Student';
      }

      if (sem.isEmpty || sem.contains('Sl.No') || sem.contains('Subject') || sem.length > 50) {
        sem = latestProfile?.semester.trim() ??
            latestAttendanceReport?.semester.trim() ??
            'IV/IV B.Tech I Semester';
      }

      final tables = doc.querySelectorAll('table');
      List<String> dates = [];
      List<AcademicRegisterEntry> entries = [];

      for (var tbl in tables) {
        final headerRow = tbl.querySelector('tr.reportHeading2WithBackground');
        if (headerRow != null && headerRow.text.contains('Sl.No') && headerRow.text.contains('Subject')) {
          final thCells = headerRow.querySelectorAll('td').map((c) => c.text.trim()).toList();
          int attIndex = thCells.indexWhere((c) => c.toLowerCase().contains('atted') || c.toLowerCase().contains('held'));
          if (attIndex == -1) attIndex = thCells.length - 5;

          if (attIndex > 2) {
            dates = thCells.sublist(2, attIndex);
          }

          final rows = tbl.querySelectorAll('tr');
          for (var r in rows) {
            if (r == headerRow) continue;
            final cells = r.querySelectorAll('td');
            if (cells.length >= thCells.length && RegExp(r'^\d+$').hasMatch(cells[0].text.trim())) {
              final sl = cells[0].text.trim();
              final subj = cells[1].text.trim();
              final Map<String, String> dateStatus = {};
              for (int d = 0; d < dates.length; d++) {
                if (2 + d < cells.length) {
                  dateStatus[dates[d]] = cells[2 + d].text.replaceAll('&nbsp;', ' ').trim();
                }
              }

              String attHeld = '';
              double pct = 0.0;
              String cieA1 = '';
              String cieB1 = '';
              String cieC1 = '';

              if (attIndex < cells.length) attHeld = cells[attIndex].text.trim();
              if (attIndex + 1 < cells.length) pct = double.tryParse(cells[attIndex + 1].text.trim()) ?? 0.0;
              if (attIndex + 2 < cells.length) cieA1 = cells[attIndex + 2].text.replaceAll('&nbsp;', '').trim();
              if (attIndex + 3 < cells.length) cieB1 = cells[attIndex + 3].text.replaceAll('&nbsp;', '').trim();
              if (attIndex + 4 < cells.length) cieC1 = cells[attIndex + 4].text.replaceAll('&nbsp;', '').trim();

              entries.add(AcademicRegisterEntry(
                slNo: sl,
                subject: subj,
                attendanceByDate: dateStatus,
                attendedHeld: attHeld,
                percentage: pct,
                cieA1: cieA1,
                cieB1: cieB1,
                cieC1: cieC1,
              ));
            }
          }
        }
      }

      final report = StudentAcademicRegisterReport(
        rollNo: rollNo,
        studentName: studentName,
        semester: sem,
        dates: dates,
        entries: entries,
      );
      latestAcademicRegister = report;
      return report;
    } catch (_) {
      return null;
    }
  }
}

