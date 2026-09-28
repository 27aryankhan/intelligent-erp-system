import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/services/crypto_service.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';
import 'package:intelligent_erp/services/hitam_ai_service.dart';

void main() {
  group('HITAM ERP Core Services Tests', () {
    test('CryptoService properly encrypts password with WebPros AES key', () {
      final plain = 'Student@123';
      final encrypted = CryptoService.encryptPassword(plain);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plain)));
      // Base64 string verification
      expect(RegExp(r'^[a-zA-Z0-9+/=]+$').hasMatch(encrypted), isTrue);
    });

    test('SubjectAttendance calculates exact Safe Bunks & Recovery classes', () {
      // Case 1: High attendance (Safe)
      // Held: 40, Attended: 36 (90%)
      // Safe bunks = floor((36 - (0.75 * 40)) / 0.75) = floor((36 - 30) / 0.75) = floor(8) = 8
      final safeSubject = SubjectAttendance(
        subjectCode: 'CS501',
        subjectName: 'Operating Systems',
        classesHeld: 40,
        classesAttended: 36,
        percentage: 90.0,
      );

      expect(safeSubject.safeBunks, equals(8));
      expect(safeSubject.classesNeeded, equals(0));
      expect(safeSubject.status, equals('SAFE'));

      // Case 2: Low attendance (Needs recovery)
      // Held: 40, Attended: 24 (60% - Critical)
      // Shortage = (0.75 * 40) - 24 = 30 - 24 = 6
      // Classes needed = ceil(6 / 0.25) = 24
      final lowSubject = SubjectAttendance(
        subjectCode: 'CS502',
        subjectName: 'Database Management Systems',
        classesHeld: 40,
        classesAttended: 24,
        percentage: 60.0,
      );

      expect(lowSubject.safeBunks, equals(0));
      expect(lowSubject.classesNeeded, equals(24));
      expect(lowSubject.status, equals('CRITICAL'));

      // Case 3: Condonation bracket (65% - 74.9%)
      final condonationSubject = SubjectAttendance(
        subjectCode: 'CS503',
        subjectName: 'Computer Networks',
        classesHeld: 40,
        classesAttended: 28,
        percentage: 70.0,
      );

      expect(condonationSubject.status, equals('WARNING'));
    });

    test('HitamAiService returns offline academic advice when device is offline', () async {
      final aiService = HitamAiService();
      final subjects = [
        SubjectAttendance(
          subjectCode: 'CS501',
          subjectName: 'Operating Systems',
          classesHeld: 30,
          classesAttended: 27,
          percentage: 90.0,
        ),
      ];

      final response = await aiService.ask(
        query: 'Can I bunk today?',
        attendance: subjects,
        role: 'student',
        rollNo: '21H51A0501',
      );

      expect(response, isNotEmpty);
      expect(response.toLowerCase().contains('safe bunk') || response.toLowerCase().contains('operating systems'), isTrue);
    });
  });
}
