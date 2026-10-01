import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/services/update_service.dart';

void main() {
  group('UpdateService & AppUpdateInfo Tests', () {
    test('AppUpdateInfo correctly parses update payload and detects newer version', () {
      final json = {
        'latest_version': '1.0.1',
        'version_code': 2,
        'min_supported_version_code': 1,
        'download_url': 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/download/v1.0.1/Intelligent_ERP.apk',
        'release_notes': [
          'Live attendance updates',
          'Fast video loading',
        ],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.latestVersion, equals('1.0.1'));
      expect(info.latestVersionCode, equals(2));
      expect(info.hasUpdate, isTrue); // 2 > 1
      expect(info.isMandatory, isFalse);
      expect(info.releaseNotes.length, equals(2));
      expect(info.downloadUrl, contains('Intelligent_ERP.apk'));
    });

    test('AppUpdateInfo detects same version as NOT needing update', () {
      final json = {
        'latest_version': '1.0.0',
        'version_code': 1,
        'min_supported_version_code': 1,
        'download_url': 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/latest',
        'release_notes': [],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.hasUpdate, isFalse); // 1 is not > 1
    });

    test('AppUpdateInfo detects mandatory update when min_supported_version_code is higher', () {
      final json = {
        'latest_version': '2.0.0',
        'version_code': 5,
        'min_supported_version_code': 2,
        'download_url': 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/latest',
        'release_notes': ['Major core upgrade'],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.hasUpdate, isTrue);
      expect(info.isMandatory, isTrue); // Current 1 < min 2
    });
  });
}
