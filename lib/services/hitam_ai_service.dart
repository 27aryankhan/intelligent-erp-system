import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'hitam_scraper_service.dart';

/// HITAM Campus AI Assistant & Domain-Trained Knowledge Engine
/// Embeds HITAM academic regulations (HR21/HR22/HR24), attendance math, and autonomous rules.
/// Works online via Gemini API backend or offline via the embedded local reasoning engine.
class HitamAiService {
  static final HitamAiService _instance = HitamAiService._internal();
  factory HitamAiService() => _instance;
  HitamAiService._internal();

  /// HITAM System Rules & Academic Context (System Prompt)
  static const String hitamSystemKnowledge = '''
You are the Official AI Academic Advisor for HITAM (Hyderabad Institute of Technology and Management).
Autonomous college under JNTUH, adhering to HR21, HR22, and HR24 regulations.

KEY ACADEMIC RULES:
1. Minimum Attendance: 75% aggregate attendance is MANDATORY to sit for Semester End Examinations (SEE).
2. Condonation: Attendance between 65% and 74.9% may be condoned on valid medical grounds upon payment of the prescribed condonation fee and approval by the Principal/Academic Committee.
3. Detention: Attendance below 65% results in immediate DETENTION. The student cannot write exams and must repeat the semester in the next academic year.
4. Safe Bunks Formula: floor((Attended - (0.75 * Held)) / 0.75).
5. Recovery Classes Needed: ceil(((0.75 * Held) - Attended) / 0.25).
6. Grading System: O (10, Outstanding), A+ (9, Excellent), A (8, Very Good), B+ (7, Good), B (6, Above Average), C (5, Pass), F (0, Fail).
7. Mid Exams: Two Mid-Examinations per semester (Mid 1 and Mid 2) consisting of descriptive, objective, and assignment components.

TONE & PERSONALITY:
- Supportive, encouraging, precise with numbers, and authoritative on HITAM college policies.
- Always provide actionable advice (e.g. exactly how many classes to attend or if safe to miss).
''';

  /// Ask the HITAM AI Agent
  Future<String> ask({
    required String query,
    required List<SubjectAttendance> attendance,
    String role = 'student',
    String rollNo = 'Student',
  }) async {
    // 1. Try cloud AI backend with Gemini if reachable
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'role': role,
              'rollNo': rollNo,
              'attendance': attendance.map((a) => a.toMap()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reply'] != null && data['reply'].toString().isNotEmpty) {
          return data['reply'].toString();
        }
      }
    } catch (_) {
      // Backend not running or device offline: Fall through to embedded local reasoning engine
    }

    // 2. Embedded On-Device Trained Reasoning Engine (Offline-First)
    return _generateLocalResponse(query, attendance, role);
  }

  /// On-Device Offline Rule Engine (Works 100% without internet or server)
  String _generateLocalResponse(
    String query,
    List<SubjectAttendance> attendance,
    String role,
  ) {
    final lower = query.toLowerCase();

    // Overall summary & attendance check
    if (lower.contains('attendance') ||
        lower.contains('summary') ||
        lower.contains('status') ||
        lower.contains('how am i doing')) {
      if (attendance.isEmpty) {
        return "I don't have your attendance records cached yet. Pull down to refresh or log into Webpros to sync your subjects!";
      }

      int totalHeld = 0;
      int totalAttended = 0;
      List<String> criticalSubjects = [];
      List<String> safeSubjects = [];

      for (var s in attendance) {
        totalHeld += s.classesHeld;
        totalAttended += s.classesAttended;
        if (s.percentage < 75.0) {
          criticalSubjects.add('${s.subjectName} (${s.percentage}%) - Needs ${s.classesNeeded} classes');
        } else {
          safeSubjects.add('${s.subjectName} (${s.percentage}%) - ${s.safeBunks} safe bunks');
        }
      }

      final double aggregate =
          totalHeld > 0 ? (totalAttended / totalHeld) * 100 : 0.0;

      final buffer = StringBuffer();
      buffer.writeln('📊 **HITAM Academic Attendance Summary**\n');
      buffer.writeln('• **Aggregate Attendance:** ${aggregate.toStringAsFixed(2)}%');
      buffer.writeln(aggregate >= 75.0
          ? '✅ You are safely above the mandatory 75% threshold!'
          : aggregate >= 65.0
              ? '⚠️ You are in the condonation bracket (65%-75%). Submit medical certificates if applicable.'
              : '🚨 CRITICAL: Below 65%. You are at risk of semester detention under HITAM HR regulations.');

      if (criticalSubjects.isNotEmpty) {
        buffer.writeln('\n⚠️ **Subjects Needing Attention (< 75%):**');
        for (var c in criticalSubjects) {
          buffer.writeln('• $c');
        }
      }

      if (safeSubjects.isNotEmpty) {
        buffer.writeln('\n🛡️ **Safe Subjects:**');
        for (var s in safeSubjects) {
          buffer.writeln('• $s');
        }
      }

      return buffer.toString();
    }

    // Safe bunks / Can I skip question
    if (lower.contains('bunk') ||
        lower.contains('miss') ||
        lower.contains('skip') ||
        lower.contains('leave') ||
        lower.contains('holiday')) {
      if (attendance.isEmpty) {
        return "Please sync your attendance first so I can calculate your exact safe bunks!";
      }

      final buffer = StringBuffer();
      buffer.writeln('🎯 **Safe Bunk Analysis (HITAM 75% Rule):**\n');
      bool hasSafe = false;

      for (var s in attendance) {
        if (s.safeBunks > 0) {
          hasSafe = true;
          buffer.writeln('• **${s.subjectName}:** You can safely skip **${s.safeBunks}** upcoming class(es) while staying at or above 75%.');
        } else {
          buffer.writeln('• **${s.subjectName}:** ⚠️ **0 safe bunks**. You need to attend **${s.classesNeeded}** consecutive classes to reach 75%.');
        }
      }

      if (!hasSafe) {
        buffer.writeln('\n⚠️ You do not have safe bunks in any subject right now. Regular attendance is recommended!');
      }

      return buffer.toString();
    }

    // Condonation / Detention Rules
    if (lower.contains('condonation') ||
        lower.contains('detention') ||
        lower.contains('rule') ||
        lower.contains('medical') ||
        lower.contains('fee')) {
      return '''
📋 **HITAM Academic Regulations on Attendance:**

1. **>= 75% Attendance:**
   • Eligible to appear for all Semester End Examinations (SEE) without restrictions.

2. **65% to 74.9% Attendance (Condonation Bracket):**
   • May be condoned by the Academic Committee on genuine medical grounds.
   • Requires authentic medical certificates and payment of the prescribed condonation fee before hall ticket issuance.

3. **< 65% Attendance (Detention):**
   • Under no circumstances will condonation be granted below 65%.
   • Student will be detained and must repeat the semester during the next academic year.
''';
    }

    // Default intelligent greeting & suggestions
    return '''
Hello! I am your **HITAM Campus AI Assistant**. I can help you with:

• 📊 **"Check my attendance"** – Get an aggregate breakdown and subject-wise status.
• 🎯 **"Can I bunk class today?"** – Calculate your safe bunks without risking your 75% eligibility.
• 📈 **"How many classes do I need to attend?"** – Get your exact recovery plan.
• 📜 **"Explain condonation rules"** – Understand HITAM academic policies and regulations.

What would you like to know?
''';
  }
}
