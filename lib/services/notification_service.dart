import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Enterprise-grade Notification Service for Intelligent ERP.
/// Handles native local notifications, OS system tray banners,
/// background triggers, sound/vibration channels, and device token registration.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Stream controller to broadcast notification taps for deep linking
  final StreamController<String?> _payloadStreamController =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _payloadStreamController.stream;

  static const String channelId = 'intelligent_erp_urgent_channel';
  static const String channelName = 'HITAM Campus Alerts & Deadlines';
  static const String channelDescription =
      'Notifications for assignments, exams, fees, and official announcements.';

  /// Initialize local and background notification handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android Setup: use default launcher icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS Setup
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux Setup
    final LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(
      defaultActionName: 'Open Notification',
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
          _payloadStreamController.add(response.payload);
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// Request runtime notification permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted =
            await androidImplementation?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final bool? granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final MacOSFlutterLocalNotificationsPlugin? macOSImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        final bool? granted = await macOSImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  /// Trigger an immediate native heads-up system banner
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'HITAM ERP • ${type.toUpperCase()}',
      ),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload ?? type,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Simulate / trigger a delayed background notification.
  /// Allows the user to minimize the app, wait [delaySeconds], and see the native
  /// system banner appear in the OS notification shade / lock screen!
  Future<void> triggerBackgroundSimulation({
    required String title,
    required String body,
    int delaySeconds = 5,
    String? payload,
    String type = 'urgent',
  }) async {
    debugPrint(
        'Triggering background notification in $delaySeconds seconds. Minimize app now to see notification!');

    Timer(Duration(seconds: delaySeconds), () async {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: payload,
        type: type,
      );
    });
  }

  // Active User Session State for Role-Based Targeting
  String _currentRole = 'student';
  String _currentUserId = '';
  String _currentEmail = '';

  String get currentRole => _currentRole;
  String get currentUserId => _currentUserId;
  String get currentEmail => _currentEmail;

  Timer? _realtimeTimer;
  final Set<String> _presentedNotifIds = <String>{};
  DateTime _lastPollTimestamp =
      DateTime.now().subtract(const Duration(seconds: 15));

  /// Update the active user session for role-targeted notifications
  void setUserSession({
    required String role,
    required String userId,
    String? email,
  }) {
    _currentRole = role.toLowerCase();
    _currentUserId = userId;
    if (email != null && email.isNotEmpty) {
      _currentEmail = email.toLowerCase();
    }
    debugPrint(
        'NotificationService: Session updated -> Role: $_currentRole, User: $_currentUserId');

    // Register role token with backend
    registerDeviceToken(
      userId: _currentUserId,
      role: _currentRole,
      email: _currentEmail,
      token: 'token_${_currentRole}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Restart real-time monitoring for the updated role
    startRealtimePulse();
  }

  /// Starts the continuous zero-delay real-time pulse monitor
  void startRealtimePulse() {
    _realtimeTimer?.cancel();
    _lastPollTimestamp = DateTime.now().subtract(const Duration(seconds: 5));

    // Poll every 5 seconds for zero-delay notification arrival
    _realtimeTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkRealtimeUpdates();
    });
    debugPrint(
        'NotificationService: Real-time notification pulse active for role: $_currentRole');
  }

  /// Stops real-time pulse
  void stopRealtimePulse() {
    _realtimeTimer?.cancel();
    _realtimeTimer = null;
  }

  Future<void> _checkRealtimeUpdates() async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/notifications/poll?role=$_currentRole&userId=$_currentUserId&since=${_lastPollTimestamp.toIso8601String()}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List newAlerts = data['newAlerts'] ?? [];

        if (newAlerts.isNotEmpty) {
          for (var alert in newAlerts) {
            final String id = alert['id']?.toString() ?? '';
            if (!_presentedNotifIds.contains(id)) {
              _presentedNotifIds.add(id);

              final String title = alert['title']?.toString() ?? 'ERP Alert';
              final String body = alert['body']?.toString() ?? '';
              final String type = alert['type']?.toString() ?? 'general';
              final String screen =
                  alert['targetScreen']?.toString() ?? 'dashboard';

              // Fire native alert heads-up notification immediately
              await showNotification(
                id: id.hashCode.abs().remainder(100000),
                title: title,
                body: body,
                payload: screen,
                type: type,
              );
              debugPrint('Real-time notification presented: $title ($type)');
            }
          }
        }
        if (data['timestamp'] != null) {
          _lastPollTimestamp = DateTime.parse(data['timestamp']);
        }
      }
    } catch (e) {
      // Background pulse fails silently without breaking app execution
    }
  }

  /// Simulate a role-specific scenario update with sound and vibration.
  /// If [delaySeconds] > 0, fires after the delay so user can test by minimizing the app!
  Future<void> simulateRoleNotification({
    required String role,
    required String scenario,
    int delaySeconds = 0,
  }) async {
    String title = '';
    String body = '';
    String type = 'general';
    String screen = 'dashboard';

    final normalizedRole = role.toLowerCase();

    if (normalizedRole == 'student') {
      switch (scenario) {
        case 'attendance':
          title = 'Attendance Update: Recorded Present';
          body =
              'Your attendance for Computer Networks was recorded as Present today. Overall: 85%.';
          type = 'attendance';
          screen = 'attendance';
          break;
        case 'fee':
          title = 'Tuition Fee Due Reminder';
          body =
              'Second installment of ₹25,000 is due by 30th September without late fee.';
          type = 'fee';
          screen = 'fees';
          break;
        case 'assignment':
          title = 'Assignment Due in 24 Hours';
          body =
              'Perceptron Implementation in Neural Networks is due tomorrow at 11:59 PM.';
          type = 'assignment';
          screen = 'assignments';
          break;
        case 'exam':
        default:
          title = 'Semester 6 Hall Tickets Released';
          body =
              'Odd semester mid-term examination timetable is published. Check your room allocation.';
          type = 'exam';
          screen = 'exams';
          break;
      }
    } else if (normalizedRole == 'parent') {
      switch (scenario) {
        case 'attendance':
          title = 'Ward Attendance: Present in All Lectures';
          body =
              'Your ward was marked Present for all scheduled classes today. Overall: 85%.';
          type = 'attendance';
          screen = 'attendance';
          break;
        case 'fee':
          title = 'Fee Invoice Reminder: ₹25,000 Pending';
          body =
              'Tuition installment of ₹25,000 for academic year 2025-2026 is due on 30th September.';
          type = 'fee';
          screen = 'fees';
          break;
        case 'ptm':
          title = 'Parent-Teacher Meeting (PTM) Scheduled';
          body =
              'PTM session is scheduled for Saturday 20th September at 10:00 AM in the CSE Block.';
          type = 'announcement';
          screen = 'announcements';
          break;
        case 'progress':
        default:
          title = 'Mid-Term Academic Progress: 8.65 SGPA';
          body =
              'Your ward secured 8.65 SGPA with grade A+ in Data Structures in Semester 6.';
          type = 'academic';
          screen = 'academic';
          break;
      }
    } else if (normalizedRole == 'faculty') {
      switch (scenario) {
        case 'submissions':
          title = '35 New Student Submissions';
          body =
              '35 students submitted "Perceptron Implementation" for Neural Networks awaiting evaluation.';
          type = 'assignment';
          screen = 'assignments';
          break;
        case 'attendance':
          title = 'Attendance Submission Reminder';
          body =
              'Please lock Section-A attendance roster for Computer Networks before 4:30 PM today.';
          type = 'attendance';
          screen = 'attendance';
          break;
        case 'leave':
          title = 'Student Medical Leave Request';
          body =
              'A student submitted a medical leave application for 3 days awaiting review.';
          type = 'system';
          screen = 'dashboard';
          break;
        case 'meeting':
        default:
          title = 'Department Council Meeting';
          body =
              'Board of Studies curriculum revision meeting tomorrow at 3:00 PM in Conference Hall A.';
          type = 'announcement';
          screen = 'announcements';
          break;
      }
    } else {
      // Administrator
      switch (scenario) {
        case 'finance':
          title = 'Daily Fee Collection Milestone';
          body =
              '₹4,85,000 collected today across semester fee installments. 82% collection achieved.';
          type = 'fee';
          screen = 'fees';
          break;
        case 'staff':
          title = 'Faculty Leave Queue Pending';
          body =
              '2 faculty leave applications from CSE department are pending administrative review.';
          type = 'system';
          screen = 'dashboard';
          break;
        case 'security':
          title = 'Biometric Campus Gate Sync Complete';
          body =
              'All 6 campus turnstile gate scanners synced with the central cloud ERP.';
          type = 'system';
          screen = 'dashboard';
          break;
        case 'broadcast':
        default:
          title = 'Administrative Notice Ready for Dispatch';
          body =
              'Annual National Technical Symposium circular is drafted and ready for campus release.';
          type = 'announcement';
          screen = 'announcements';
          break;
      }
    }

    if (delaySeconds > 0) {
      await triggerBackgroundSimulation(
        title: title,
        body: body,
        delaySeconds: delaySeconds,
        payload: screen,
        type: type,
      );
    } else {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: screen,
        type: type,
      );
    }
  }

  /// Send a real-time broadcast notification from Admin/Faculty to any role
  Future<bool> sendRealtimeNotification({
    required String title,
    required String body,
    required String targetRole,
    String type = 'announcement',
    String priority = 'high',
    String targetScreen = 'announcements',
    String? userId,
    String? senderRole,
    String? senderName,
  }) async {
    try {
      final sRole = senderRole ?? (_currentRole == 'admin' ? 'admin' : 'faculty');
      final sName = senderName ??
          (sRole == 'admin'
              ? 'HITAM Administration'
              : 'Dr. Ramesh Kumar (Faculty)');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'targetRole': targetRole.toLowerCase(),
          'senderRole': sRole,
          'senderName': sName,
          'type': type,
          'priority': priority,
          'targetScreen': targetScreen,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Also show local notification immediately if targeting current role or all
        final normTarget = targetRole.toLowerCase();
        final bool shouldNotifyCurrent = normTarget == 'all' ||
            normTarget == _currentRole ||
            (normTarget.contains('student') && _currentRole == 'student') ||
            (normTarget.contains('parent') && _currentRole == 'parent') ||
            (normTarget.contains('faculty') && _currentRole == 'faculty');

        if (shouldNotifyCurrent) {
          await showNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: title,
            body: body,
            payload: targetScreen,
            type: type,
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('Failed to send real-time notification: $e');
    }
    return false;
  }

  /// Register device token with backend API including role and email
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    String? role,
    String? email,
  }) async {
    try {
      final String platform = kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : defaultTargetPlatform == TargetPlatform.macOS
                  ? 'macos'
                  : 'android';

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'role': (role ?? _currentRole).toLowerCase(),
          'email': email ?? _currentEmail,
          'token': token,
          'platform': platform,
        }),
      );
      debugPrint('Device token registered with backend for role: $role.');
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  void dispose() {
    stopRealtimePulse();
    _payloadStreamController.close();
  }
}
