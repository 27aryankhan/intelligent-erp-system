import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/main.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';
import 'package:intelligent_erp/services/notification_service.dart';

void main() {
  tearDown(() {
    NotificationService().stopAttendanceWatcher();
  });

  testWidgets('StudentDashboard renders visionOS Frosted Glass Bento Grid', (tester) async {
    final mockReport = StudentAttendanceReport(
      studentName: 'Test Student',
      rollNo: '22KD1A0501',
      branch: 'Computer Science and Engineering',
      semester: 'III Year I Semester',
      course: 'B.Tech',
      totalHeld: 100,
      totalAttended: 85,
      overallPercentage: 85.0,
      subjects: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboard(
          initialReport: mockReport,
          studentId: '22KD1A0501',
        ),
      ),
    );

    await tester.pump();

    // Verify Dashboard title and Section Header
    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(find.text('ACADEMIC PORTAL SERVICES'), findsOneWidget);

    // Verify Bento Cards
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('85.0%'), findsOneWidget);
    expect(find.text('Backlogs'), findsOneWidget);
    expect(find.text('Fee Details'), findsOneWidget);
    expect(find.text('Time table'), findsOneWidget);
    expect(find.text('Marks'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('SPF Performance'), findsOneWidget);

    // Stop watcher before test completes
    NotificationService().stopAttendanceWatcher();
  });
}
