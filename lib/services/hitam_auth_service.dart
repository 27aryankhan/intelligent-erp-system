import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';
import 'background_service.dart';

enum UserRole { faculty, student, parent }

class HitamAuthService {
  static final HitamAuthService _instance = HitamAuthService._internal();
  factory HitamAuthService() => _instance;
  HitamAuthService._internal();

  static const String baseUrl = 'https://www.webprosindia.com/hitam/default.aspx';

  // Stores session cookies for subsequent authenticated requests
  Map<String, String> sessionCookies = {};
  String? activeUserId;
  UserRole? activeRole;

  /// Authenticates student, faculty, or parent with WebPros ERP
  Future<bool> login({
    required String userId,
    required String password,
    required UserRole role,
  }) async {
    // Always wipe previous credentials & session cookies before each attempt
    sessionCookies.clear();
    activeUserId = null;
    activeRole = null;

    final client = http.Client();

    try {
      // Step A: Harvest ASP.NET hidden tokens
      final getResponse = await client.get(
        Uri.parse(baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (getResponse.statusCode != 200) return false;

      final document = html_parser.parse(getResponse.body);
      final viewState = document.querySelector('#__VIEWSTATE')?.attributes['value'] ?? '';
      final viewStateGen = document.querySelector('#__VIEWSTATEGENERATOR')?.attributes['value'] ?? '';
      final eventValidation = document.querySelector('#__EVENTVALIDATION')?.attributes['value'] ?? '';

      // Step B: Encrypt password with WebPros AES-128-CBC
      final encryptedPassword = CryptoService.encryptPassword(password);

      // Step C: Build exact payload for chosen role
      final Map<String, String> payload = {
        '__VIEWSTATE': viewState,
        '__VIEWSTATEGENERATOR': viewStateGen,
        '__EVENTVALIDATION': eventValidation,
        'txtId1': role == UserRole.faculty ? userId : '',
        'txtPwd1': role == UserRole.faculty ? encryptedPassword : '',
        'hdnpwd1': role == UserRole.faculty ? encryptedPassword : '',
        'txtId2': role == UserRole.student ? userId : '',
        'txtPwd2': role == UserRole.student ? encryptedPassword : '',
        'hdnpwd2': role == UserRole.student ? encryptedPassword : '',
        'txtId3': role == UserRole.parent ? userId : '',
        'txtPwd3': role == UserRole.parent ? encryptedPassword : '',
        'hdnpwd3': role == UserRole.parent ? encryptedPassword : '',
      };

      if (role == UserRole.faculty) {
        payload['imgBtn1.x'] = '30';
        payload['imgBtn1.y'] = '15';
      } else if (role == UserRole.student) {
        payload['imgBtn2.x'] = '30';
        payload['imgBtn2.y'] = '15';
      } else {
        payload['imgBtn3.x'] = '30';
        payload['imgBtn3.y'] = '15';
      }

      // Step D: Send POST with followRedirects: false to catch the 302 and Set-Cookie
      final request = http.Request('POST', Uri.parse(baseUrl))
        ..followRedirects = false
        ..headers.addAll({
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': baseUrl,
          'Origin': 'https://www.webprosindia.com',
        })
        ..bodyFields = payload;

      final streamedResponse = await client.send(request);
      final postResponse = await http.Response.fromStream(streamedResponse);

      final location = postResponse.headers['location']?.toLowerCase() ?? '';

      // Strict WebPros Authentication Check:
      // - Must return HTTP 302
      // - Must redirect to an authenticated master page (e.g. StudentMaster.aspx, StaffMaster.aspx, ParentMaster.aspx)
      // - Must NOT redirect to an error page or default.aspx
      final bool isRedirectToMaster = postResponse.statusCode == 302 &&
          (location.contains('studentmaster') ||
              location.contains('staffmaster') ||
              location.contains('parentmaster') ||
              location.contains('master')) &&
          !location.contains('errorpage') &&
          !location.contains('default.aspx');

      if (isRedirectToMaster) {
        // Harvest cookies only on confirmed successful redirect
        final rawCookie = postResponse.headers['set-cookie'];
        if (rawCookie != null) {
          _saveCookies(rawCookie);
        }
        activeUserId = userId;
        activeRole = role;
        // Store credentials for background sync
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hitam_user_id', userId);
          await prefs.setString('hitam_user_pwd', password);
          await prefs.setString('hitam_user_role', role.name);
        } catch (_) {
          // Graceful ignore
        }
        return true;
      }

      // Authentication rejected or invalid credentials
      sessionCookies.clear();
      activeUserId = null;
      activeRole = null;
      return false;
    } catch (e) {
      sessionCookies.clear();
      activeUserId = null;
      activeRole = null;
      return false;
    } finally {
      client.close();
    }
  }

  void _saveCookies(String rawCookies) {
    final parts = rawCookies.split(',');
    for (var part in parts) {
      final cookie = part.split(';')[0].trim();
      final keyValue = cookie.split('=');
      if (keyValue.length == 2) {
        sessionCookies[keyValue[0].trim()] = keyValue[1].trim();
      }
    }
  }

  String get cookieHeader =>
      sessionCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  /// Ensures valid session cookies are loaded or re-authenticates automatically
  /// using stored credentials in SharedPreferences
  Future<bool> ensureAuthenticated() async {
    if (sessionCookies.isNotEmpty && activeUserId != null) {
      return true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('hitam_user_id');
      final savedPwd = prefs.getString('hitam_user_pwd');
      final savedRoleStr = prefs.getString('hitam_user_role') ?? 'student';
      if (savedId != null &&
          savedPwd != null &&
          savedId.isNotEmpty &&
          savedPwd.isNotEmpty) {
        final role = UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == savedRoleStr.toLowerCase(),
          orElse: () => UserRole.student,
        );
        return await login(userId: savedId, password: savedPwd, role: role);
      }
    } catch (_) {}
    return false;
  }

  Future<void> logout() async {
    sessionCookies.clear();
    activeUserId = null;
    activeRole = null;
    try {
      await BackgroundService().cancelAttendanceSyncTask();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hitam_user_id');
      await prefs.remove('hitam_user_pwd');
      await prefs.remove('hitam_user_role');
    } catch (_) {}
  }
}
