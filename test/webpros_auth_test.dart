import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:intelligent_erp/services/hitam_auth_service.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

void main() {
  test('Live WebPros authentication & attendance verification with real credentials', () async {
    final authService = HitamAuthService();
    final success = await authService.login(
      userId: '23E51A05E8',
      password: 'webcap',
      role: UserRole.student,
    );

    print('Login success result: $success');
    print('Session cookies: ${authService.sessionCookies}');
    expect(success, isTrue);

    final scraper = HitamScraperService(auth: authService);
    final report = await scraper.fetchStudentAttendanceReport('23E51A05E8');
    print('Overall: Held=${report?.totalHeld}, Attended=${report?.totalAttended}, Pct=${report?.overallPercentage}');
    final attendance = report?.subjects ?? [];
    print('Scraped attendance count: ${attendance.length}');
    for (var a in attendance) {
      print('${a.subjectCode} | ${a.subjectName} | ${a.percentage}% | safe bunks: ${a.safeBunks}');
    }
    expect(attendance.isNotEmpty, isTrue);

    final marks = await scraper.fetchStudentMarks('23E51A05E8');
    print('Scraped marks exams count: ${marks?.exams.length}');
    print('Scraped SGPA count: ${marks?.sgpaHistory.length}');
    if (marks != null) {
      for (var s in marks.sgpaHistory) {
        print('${s.semester}: SGPA ${s.sgpa}');
      }
    }
    expect(marks, isNotNull);

    final fees = await scraper.fetchStudentFees('23E51A05E8');
    print('Scraped fee items: ${fees?.items.length}');
    print('Balance: ${fees?.balanceText}');
    expect(fees, isNotNull);
  });
}
