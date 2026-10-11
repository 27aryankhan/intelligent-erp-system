import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_erp/services/hitam_scraper_service.dart';

void main() {
  group('Student Photo Blacklist Validation', () {
    test('Blacklists college banner logo URLs and keywords', () {
      expect(
        HitamScraperService.isBlacklistedPhoto('https://www.webprosindia.com/hitam/CollegeImages/title_head.jpg'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('CollegeImages/title_head.jpg'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('images/logo.png'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('spacer.gif'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('dot.gif'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('header_banner.jpg'),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto(null),
        isTrue,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto(''),
        isTrue,
      );
    });

    test('Blacklists exact 52868 byte title_head base64 payload', () {
      final fakeLogoBytes = List<int>.filled(52868, 0x42);
      final b64 = base64Encode(fakeLogoBytes);
      final dataUri = 'data:image/jpeg;base64,$b64';

      expect(HitamScraperService.isBlacklistedPhoto(dataUri), isTrue);
    });

    test('Allows genuine student photo URLs', () {
      expect(
        HitamScraperService.isBlacklistedPhoto('https://www.webprosindia.com/hitam/photos/24E51A0001.jpg'),
        isFalse,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('https://www.webprosindia.com/hitam/StudentPhotos/24E51A0001.jpg'),
        isFalse,
      );
      expect(
        HitamScraperService.isBlacklistedPhoto('https://www.webprosindia.com/hitam/Academics/photos/24E51A0001.jpg'),
        isFalse,
      );
    });
  });
}
