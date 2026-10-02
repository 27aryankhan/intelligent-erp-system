import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/widgets/github_attendance_heatmap.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';

void main() {
  testWidgets('GithubAttendanceHeatmap renders properly with empty or populated register',
      (WidgetTester tester) async {
    // 1. Test fallback deterministic rendering when academicRegister is null
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GithubAttendanceHeatmap(
              academicRegister: null,
              overallAttendance: 78.5,
              totalClasses: 120,
              attendedClasses: 94,
              subjects: [
                {'subject': 'Computer Networks', 'attended': 30, 'total': 36},
                {'subject': 'Operating Systems', 'attended': 28, 'total': 34},
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Attendance Activity'), findsOneWidget);
    expect(find.text('Working days: Monday to Saturday (Sundays excluded)'), findsOneWidget);

    // Verify Legend items
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Verify Mon, Wed, Fri day labels
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);

    // 2. Test rendering with a populated StudentAcademicRegisterReport
    final mockRegister = StudentAcademicRegisterReport(
      rollNo: '21E41A0501',
      studentName: 'TEST STUDENT',
      semester: 'IV/IV B.Tech I Semester',
      dates: ['16/06', '17/06', '18/06', '19/06'],
      entries: [
        AcademicRegisterEntry(
          slNo: '1',
          subject: 'Computer Vision (CV)',
          attendanceByDate: {
            '16/06': 'P',
            '17/06': 'P',
            '18/06': 'A',
            '19/06': 'P',
          },
          attendedHeld: '3/4',
          percentage: 75.0,
          cieA1: '20',
          cieB1: '20',
          cieC1: '20',
        ),
        AcademicRegisterEntry(
          slNo: '2',
          subject: 'Network Programming (NP)',
          attendanceByDate: {
            '16/06': 'P',
            '17/06': 'A',
            '18/06': 'A',
            '19/06': 'P',
          },
          attendedHeld: '2/4',
          percentage: 50.0,
          cieA1: '18',
          cieB1: '18',
          cieC1: '18',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GithubAttendanceHeatmap(
              academicRegister: mockRegister,
              overallAttendance: 62.5,
              totalClasses: 8,
              attendedClasses: 5,
              subjects: const [
                {'subject': 'Computer Vision', 'attended': 3, 'total': 4},
                {'subject': 'Network Programming', 'attended': 2, 'total': 4},
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Attendance Activity'), findsOneWidget);
    expect(find.text('Working days: Monday to Saturday (Sundays excluded)'), findsOneWidget);
    expect(find.byType(GithubAttendanceHeatmap), findsOneWidget);
  });
}
