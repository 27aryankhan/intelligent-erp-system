import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/services/update_service.dart';

void main() {
  group('UpdateService & AppUpdateInfo Tests', () {
    test('AppUpdateInfo correctly parses update payload and detects newer version', () {
      final newerCode = UpdateService.currentVersionCode + 1;
      final json = {
        'latest_version': '1.0.2',
        'version_code': newerCode,
        'min_supported_version_code': 1,
        'download_url': 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/download/v1.0.2/Intelligent_ERP.apk',
        'release_notes': [
          'Live attendance updates',
          'Fast video loading',
        ],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.latestVersion, equals('1.0.2'));
      expect(info.latestVersionCode, equals(newerCode));
      expect(info.hasUpdate, isTrue);
      expect(info.isMandatory, isFalse);
      expect(info.releaseNotes.length, equals(2));
      expect(info.downloadUrl, contains('Intelligent_ERP.apk'));
    });

    test('UpdateService has correct current version 1.0.7 and code 8', () {
      expect(UpdateService.currentVersion, equals('1.0.7'));
      expect(UpdateService.currentVersionCode, equals(8));
      expect(UpdateService.effectiveVersionCode, greaterThanOrEqualTo(8));
    });

    test('AppUpdateInfo detects same version as NOT needing update', () {
      final json = {
        'latest_version': UpdateService.currentVersion,
        'version_code': UpdateService.currentVersionCode,
        'min_supported_version_code': 1,
        'download_url': 'https://github.com/27aryankhan/intelligent-erp-system/releases/latest',
        'release_notes': [],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.hasUpdate, isFalse);
    });

    test('AppUpdateInfo detects mandatory update when min_supported_version_code is higher', () {
      final mandatoryMin = UpdateService.currentVersionCode + 1;
      final json = {
        'latest_version': '2.0.0',
        'version_code': mandatoryMin + 1,
        'min_supported_version_code': mandatoryMin,
        'download_url': 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/latest',
        'release_notes': ['Major core upgrade'],
        'is_critical': false,
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.hasUpdate, isTrue);
      expect(info.isMandatory, isTrue);
    });

    test('UpdateService resolves direct APK download URL properly', () {
      final directApk = 'https://example.com/app.apk';
      expect(UpdateService.resolveDirectDownloadUrl(directApk), equals(directApk));

      final githubLatest = 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/latest';
      expect(
        UpdateService.resolveDirectDownloadUrl(githubLatest),
        contains('Intelligent.ERP.apk'),
      );
    });
  });
}
