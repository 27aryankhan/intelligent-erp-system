import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';
import 'package:intelligent_erp/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Attendance Notification Engine Tests', () {
    test('First attendance check saves local snapshot without error', () async {
      final notifService = NotificationService();
      final report = StudentAttendanceReport(
        rollNo: '22KD1A0501',
        studentName: 'Test Student',
        course: 'B.Tech',
        branch: 'CSE',
        semester: 'Semester 6',
        totalHeld: 100,
        totalAttended: 85,
        overallPercentage: 85.0,
        subjects: [
          SubjectAttendance(
            subjectCode: '22CS601',
            subjectName: 'Computer Networks',
            classesHeld: 25,
            classesAttended: 22,
            percentage: 88.0,
          ),
        ],
      );

      await notifService.checkAndNotifyAttendance(report);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_attendance_snapshot_22KD1A0501');
      expect(raw, isNotNull);

      final data = jsonDecode(raw!);
      expect(data['overallPercentage'], 85.0);
      expect(data['totalHeld'], 100);
      expect(data['subjects']['22CS601']['held'], 25);
      expect(data['subjects']['22CS601']['attended'], 22);
    });

    test('Detects when student is marked PRESENT (+1 attended, +1 held)', () async {
      final notifService = NotificationService();
      final prefs = await SharedPreferences.getInstance();

      // Pre-seed snapshot
      final initialSnapshot = {
        'timestamp': DateTime.now().toIso8601String(),
        'overallPercentage': 80.0,
        'totalHeld': 50,
        'totalAttended': 40,
        'subjects': {
          '22CS601': {
            'name': 'Computer Networks',
            'held': 20,
            'attended': 16,
            'percentage': 80.0,
          }
        }
      };
      await prefs.setString(
          'last_attendance_snapshot_22KD1A0502', jsonEncode(initialSnapshot));

      // Updated report with +1 attended, +1 held (Marked PRESENT)
      final updatedReport = StudentAttendanceReport(
        rollNo: '22KD1A0502',
        studentName: 'Student Present',
        course: 'B.Tech',
        branch: 'CSE',
        semester: 'Semester 6',
        totalHeld: 51,
        totalAttended: 41,
        overallPercentage: 80.4,
        subjects: [
          SubjectAttendance(
            subjectCode: '22CS601',
            subjectName: 'Computer Networks',
            classesHeld: 21,
            classesAttended: 17,
            percentage: 81.0,
          ),
        ],
      );

      await notifService.checkAndNotifyAttendance(updatedReport);

      final updatedRaw =
          prefs.getString('last_attendance_snapshot_22KD1A0502');
      final updatedData = jsonDecode(updatedRaw!);
      expect(updatedData['subjects']['22CS601']['held'], 21);
      expect(updatedData['subjects']['22CS601']['attended'], 17);
    });

    test('Detects when student is marked ABSENT (0 attended, +1 held)', () async {
      final notifService = NotificationService();
      final prefs = await SharedPreferences.getInstance();

      // Pre-seed snapshot
      final initialSnapshot = {
        'timestamp': DateTime.now().toIso8601String(),
        'overallPercentage': 76.0,
        'totalHeld': 50,
        'totalAttended': 38,
        'subjects': {
          '22CS602': {
            'name': 'Operating Systems',
            'held': 25,
            'attended': 20,
            'percentage': 80.0,
          }
        }
      };
      await prefs.setString(
          'last_attendance_snapshot_22KD1A0503', jsonEncode(initialSnapshot));

      // Updated report with 0 attended, +1 held (Marked ABSENT)
      final updatedReport = StudentAttendanceReport(
        rollNo: '22KD1A0503',
        studentName: 'Student Absent',
        course: 'B.Tech',
        branch: 'CSE',
        semester: 'Semester 6',
        totalHeld: 51,
        totalAttended: 38,
        overallPercentage: 74.5,
        subjects: [
          SubjectAttendance(
            subjectCode: '22CS602',
            subjectName: 'Operating Systems',
            classesHeld: 26,
            classesAttended: 20,
            percentage: 76.9,
          ),
        ],
      );

      await notifService.checkAndNotifyAttendance(updatedReport);

      final updatedRaw =
          prefs.getString('last_attendance_snapshot_22KD1A0503');
      final updatedData = jsonDecode(updatedRaw!);
      expect(updatedData['subjects']['22CS602']['held'], 26);
      expect(updatedData['subjects']['22CS602']['attended'], 20);
      expect(updatedData['overallPercentage'], 74.5);
    });

    test('Automatically triggers shortage alert and records when attendance is below 75%', () async {
      final notifService = NotificationService();
      final reportBelow75 = StudentAttendanceReport(
        rollNo: '22KD1A0504',
        studentName: 'Shortage Student',
        course: 'B.Tech',
        branch: 'CSE',
        semester: 'Semester 6',
        totalHeld: 100,
        totalAttended: 70,
        overallPercentage: 70.0,
        subjects: [
          SubjectAttendance(
            subjectCode: '22CS603',
            subjectName: 'Compiler Design',
            classesHeld: 50,
            classesAttended: 35,
            percentage: 70.0,
          ),
        ],
      );

      await notifService.checkShortageWarning(reportBelow75, force: true);

      final prefs = await SharedPreferences.getInstance();
      final lastNotifMs = prefs.getInt('last_shortage_notif_time_22KD1A0504');
      final lastHeld = prefs.getInt('last_shortage_held_22KD1A0504');

      expect(lastNotifMs, isNotNull);
      expect(lastNotifMs, greaterThan(0));
      expect(lastHeld, equals(100));
    });
  });
}
