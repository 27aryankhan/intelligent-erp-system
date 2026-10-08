import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/api_config.dart';
import 'hitam_auth_service.dart';
import 'hitam_scraper_service.dart';

/// Enterprise-grade Notification Service for Intelligent ERP.
/// Handles native local notifications, OS system tray banners,
/// background triggers, sound/vibration channels, exact period alarms,
/// and evening daily summaries that work even when the app is closed or killed.
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

  static const String attendanceChannelId = 'intelligent_erp_attendance_channel_v2';
  static const String attendanceChannelName = 'HITAM Attendance & Academic Alerts';
  static const String attendanceChannelDescription =
      'Real-time notifications for subject attendance (Present/Absent) with faculty and subject details.';

  static const String timetableChannelId = 'intelligent_erp_timetable_channel';
  static const String timetableChannelName = 'HITAM Period & Class Reminders';
  static const String timetableChannelDescription =
      'Timetable period alerts with class schedule, subject, and faculty details.';

  static const String summaryChannelId = 'intelligent_erp_daily_summary_channel';
  static const String summaryChannelName = 'HITAM Daily Attendance Summary';
  static const String summaryChannelDescription =
      'Evening overview of classes conducted, attended, missed, and daily attendance percentage.';

  /// Initialize local and background notification handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize timezone database for exact period and evening alarms
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

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

      // Create Android Notification Channels with maximum priority
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

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            attendanceChannelId,
            attendanceChannelName,
            description: attendanceChannelDescription,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            timetableChannelId,
            timetableChannelName,
            description: timetableChannelDescription,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            summaryChannelId,
            summaryChannelName,
            description: summaryChannelDescription,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully with all channels.');
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
        debugPrint('Android notification permission status: $granted');
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

    final tLower = type.toLowerCase();
    final isAttendance = tLower == 'attendance';
    final isTimetable = tLower == 'timetable' || tLower == 'period';
    final isSummary = tLower == 'summary' || tLower == 'evening';

    String targetChannelId = channelId;
    String targetChannelName = channelName;
    String targetChannelDesc = channelDescription;
    String summaryHeader = 'HITAM ERP • ${type.toUpperCase()}';
    AndroidNotificationCategory category = AndroidNotificationCategory.event;

    if (isAttendance) {
      targetChannelId = attendanceChannelId;
      targetChannelName = attendanceChannelName;
      targetChannelDesc = attendanceChannelDescription;
      summaryHeader = 'HITAM ERP • ATTENDANCE';
      category = AndroidNotificationCategory.status;
    } else if (isTimetable) {
      targetChannelId = timetableChannelId;
      targetChannelName = timetableChannelName;
      targetChannelDesc = timetableChannelDescription;
      summaryHeader = 'HITAM ERP • TIMETABLE';
      category = AndroidNotificationCategory.reminder;
    } else if (isSummary) {
      targetChannelId = summaryChannelId;
      targetChannelName = summaryChannelName;
      targetChannelDesc = summaryChannelDescription;
      summaryHeader = 'HITAM ERP • DAILY SUMMARY';
      category = AndroidNotificationCategory.status;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      targetChannelId,
      targetChannelName,
      channelDescription: targetChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      category: category,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summaryHeader,
      ),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        id: id == 0
            ? DateTime.now().millisecondsSinceEpoch.remainder(100000)
            : id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload ?? (isAttendance ? 'attendance' : type),
      );
      debugPrint('Notification displayed: $title');
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

    // If student session, launch real-time attendance watcher
    if (_currentRole == 'student' && _currentUserId.isNotEmpty) {
      startAttendanceWatcher(_currentUserId);
    } else {
      stopAttendanceWatcher();
    }

    // Restart real-time monitoring for the updated role
    startRealtimePulse();
  }

  // ===========================================================================
  // REAL-TIME STUDENT ATTENDANCE MONITORING & DIFF ENGINE
  // ===========================================================================
  Timer? _attendanceWatcherTimer;
  String _activeWatchingRoll = '';

  /// Start periodic background watcher for student attendance updates.
  /// Runs periodically while app is running, fetching the latest attendance
  /// from WebPros and notifying the student of new Present/Absent marks.
  void startAttendanceWatcher(String rollNo) {
    if (rollNo.isEmpty) return;
    _activeWatchingRoll = rollNo;
    _attendanceWatcherTimer?.cancel();

    // Trigger an immediate background sync on startup
    Future.microtask(() async {
      await syncAttendanceNow();
      await syncTimetableAndReminders();
    });

    // Check periodically every 10 minutes for live attendance updates
    _attendanceWatcherTimer =
        Timer.periodic(const Duration(minutes: 10), (_) async {
      await syncAttendanceNow();
    });
    debugPrint('NotificationService: Attendance watcher active for roll: $rollNo');
  }

  /// Stop attendance watcher
  void stopAttendanceWatcher() {
    _attendanceWatcherTimer?.cancel();
    _attendanceWatcherTimer = null;
  }

  /// Trigger an immediate silent sync and diff of attendance
  Future<void> syncAttendanceNow() async {
    String roll = _activeWatchingRoll.isNotEmpty
        ? _activeWatchingRoll
        : (HitamAuthService().activeUserId ?? '');

    if (roll.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        roll = prefs.getString('hitam_user_id') ?? '';
        if (roll.isNotEmpty) {
          _activeWatchingRoll = roll;
        }
      } catch (_) {}
    }

    if (roll.isEmpty) return;

    try {
      // Ensure authenticated with stored credentials before scraping
      await HitamAuthService().ensureAuthenticated();

      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentAttendanceReport(roll);
      if (report != null && report.subjects.isNotEmpty) {
        await checkAndNotifyAttendance(report);
        await checkShortageWarning(report);
        // Automatically check if evening attendance summary should be pushed
        await checkAndPushEveningSummary(report);
      }
    } catch (e) {
      debugPrint('Background attendance sync error: $e');
    }
  }

  /// Checks whether overall attendance is below the mandatory 75% cutoff
  /// and automatically pushes an urgent notification to the student's status bar.
  Future<void> checkShortageWarning(
    StudentAttendanceReport report, {
    bool force = false,
  }) async {
    if (report.overallPercentage >= 75.0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotifKey = 'last_shortage_notif_time_${report.rollNo}';
      final lastHeldKey = 'last_shortage_held_${report.rollNo}';

      final lastNotifMs = prefs.getInt(lastNotifKey) ?? 0;
      final lastHeld = prefs.getInt(lastHeldKey) ?? -1;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Notify if: forced, OR classes held changed, OR more than 2 hours since last shortage alert
      final bool shouldNotify = force ||
          (report.totalHeld != lastHeld) ||
          (nowMs - lastNotifMs > 2 * 3600 * 1000);

      if (shouldNotify) {
        await prefs.setInt(lastNotifKey, nowMs);
        await prefs.setInt(lastHeldKey, report.totalHeld);

        final int notifId =
            ('shortage_${report.rollNo}'.hashCode).abs().remainder(100000);

        final classesNeeded = report.classesNeeded > 0
            ? 'Need to attend ${report.classesNeeded} consecutive classes to reach 75%.'
            : 'Attend upcoming classes to reach 75%.';

        await showNotification(
          id: notifId,
          title: '🚨 Attendance Shortage: ${report.overallPercentage.toStringAsFixed(1)}% (Below 75%)',
          body: 'Your attendance is ${report.overallPercentage.toStringAsFixed(1)}%, which is below the mandatory 75% cutoff (${report.totalAttended}/${report.totalHeld} classes).\n'
              '$classesNeeded Tap to view subject-wise breakdown.',
          payload: 'attendance',
          type: 'attendance',
        );
        debugPrint('Shortage warning notification pushed for ${report.rollNo}: ${report.overallPercentage}%');
      }
    } catch (e) {
      debugPrint('Error in checkShortageWarning: $e');
    }
  }

  // ===========================================================================
  // FACULTY ALLOCATION CACHING & RESOLUTION
  // ===========================================================================

  /// Cache faculty allocations mapping for a student
  Future<void> cacheFacultyAllocations(
    String rollNo,
    List<SubjectFacultyAllocation> allocations,
  ) async {
    if (rollNo.isEmpty || allocations.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cacheMap = {};
      for (var a in allocations) {
        if (a.code.isNotEmpty) {
          cacheMap[a.code.toLowerCase().trim()] = {
            'code': a.code,
            'name': a.name,
            'faculty': a.facultyName,
          };
        }
        if (a.name.isNotEmpty) {
          cacheMap[a.name.toLowerCase().trim()] = {
            'code': a.code,
            'name': a.name,
            'faculty': a.facultyName,
          };
        }
      }
      await prefs.setString('faculty_allocations_$rollNo', jsonEncode(cacheMap));
      debugPrint('Cached ${allocations.length} faculty allocations for $rollNo');
    } catch (e) {
      debugPrint('Error caching faculty allocations: $e');
    }
  }

  /// Resolves the faculty member assigned to a specific subject code or name
  Future<String> resolveFacultyName(String rollNo, String code, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('faculty_allocations_$rollNo');
      if (raw != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(raw);
        final cKey = code.toLowerCase().trim();
        final nKey = name.toLowerCase().trim();
        if (cacheMap.containsKey(cKey)) {
          final f = cacheMap[cKey]['faculty']?.toString();
          if (f != null && f.trim().isNotEmpty) return f.trim();
        }
        if (cacheMap.containsKey(nKey)) {
          final f = cacheMap[nKey]['faculty']?.toString();
          if (f != null && f.trim().isNotEmpty) return f.trim();
        }
      }
    } catch (_) {}

    // Check memory cache from HitamScraperService
    final tt = HitamScraperService().latestTimeTable;
    if (tt != null && tt.allocations.isNotEmpty) {
      for (var a in tt.allocations) {
        if (a.code.toLowerCase().trim() == code.toLowerCase().trim() ||
            a.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          if (a.facultyName.trim().isNotEmpty) return a.facultyName.trim();
        }
      }
    }

    return 'Subject Faculty';
  }

  // ===========================================================================
  // DAILY ATTENDANCE BASELINE & EVENING SUMMARY ENGINE
  // ===========================================================================

  /// Get or record today's morning baseline for attendance
  /// (used to compute classes conducted today, attended today, missed today)
  Future<Map<String, int>> getOrSetTodayBaseline(
    String rollNo,
    int currentTotalHeld,
    int currentTotalAttended,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final baselineKey = 'day_baseline_${rollNo}_$dateKey';

    final raw = prefs.getString(baselineKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return {
          'held': (decoded['held'] as num?)?.toInt() ?? currentTotalHeld,
          'attended': (decoded['attended'] as num?)?.toInt() ?? currentTotalAttended,
        };
      } catch (_) {}
    }

    // First snapshot recorded today: establish morning baseline
    final baseline = {
      'held': currentTotalHeld,
      'attended': currentTotalAttended,
    };
    await prefs.setString(baselineKey, jsonEncode(baseline));
    return baseline;
  }

  /// Checks and pushes the daily evening attendance summary.
  /// Shows total classes conducted today, attended today, missed today,
  /// and overall attendance percentage.
  Future<void> checkAndPushEveningSummary(
    StudentAttendanceReport report, {
    bool force = false,
  }) async {
    final rollNo = report.rollNo.isNotEmpty
        ? report.rollNo
        : (HitamAuthService().activeUserId ?? 'student');
    if (rollNo.isEmpty) return;

    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sentKey = 'evening_summary_sent_${rollNo}_$dateKey';

    final prefs = await SharedPreferences.getInstance();
    final alreadySent = prefs.getBool(sentKey) ?? false;
    if (!force && alreadySent) return;

    // Evening delivery window: 4:00 PM to 10:00 PM (16:00 to 22:00)
    if (!force && (now.hour < 16 || now.hour >= 22)) return;

    final baseline = await getOrSetTodayBaseline(
      rollNo,
      report.totalHeld,
      report.totalAttended,
    );

    final baselineHeld = baseline['held'] ?? report.totalHeld;
    final baselineAttended = baseline['attended'] ?? report.totalAttended;

    int conductedToday = report.totalHeld - baselineHeld;
    int attendedToday = report.totalAttended - baselineAttended;
    if (conductedToday < 0) conductedToday = 0;
    if (attendedToday < 0) attendedToday = 0;
    int missedToday = conductedToday - attendedToday;
    if (missedToday < 0) missedToday = 0;

    final int notifId =
        ('evening_summary_${rollNo}_$dateKey'.hashCode).abs().remainder(100000);

    String title;
    String body;

    if (conductedToday > 0) {
      title = '📊 Daily Attendance Summary: $attendedToday/$conductedToday Attended';
      body = 'Classes Today: $conductedToday conducted • $attendedToday attended • $missedToday missed.\n'
          'Overall Attendance: ${report.totalAttended}/${report.totalHeld} (${report.overallPercentage.toStringAsFixed(1)}%) • ${report.academicStatus}';
    } else {
      title = '📊 Evening Attendance Summary: ${report.overallPercentage.toStringAsFixed(1)}%';
      body = 'No additional lectures conducted today.\n'
          'Overall Attendance: ${report.totalAttended}/${report.totalHeld} (${report.overallPercentage.toStringAsFixed(1)}%) • ${report.academicStatus}';
    }

    await showNotification(
      id: notifId,
      title: title,
      body: body,
      payload: 'attendance',
      type: 'summary',
    );

    await prefs.setBool(sentKey, true);
    debugPrint(
        'Daily evening attendance summary delivered for $rollNo: $attendedToday/$conductedToday attended.');
  }

  /// Background helper for WorkManager to check evening summary
  Future<void> checkEveningSummaryNow() async {
    final now = DateTime.now();
    if (now.hour < 16 || now.hour >= 22) return;

    final roll = HitamAuthService().activeUserId ?? '';
    if (roll.isEmpty) return;

    try {
      final scraper = HitamScraperService();
      final report = await scraper.fetchStudentAttendanceReport(roll);
      if (report != null && report.subjects.isNotEmpty) {
        await checkAndPushEveningSummary(report);
      }
    } catch (_) {}
  }

  /// Simulate an Evening Attendance Summary Notification
  Future<void> simulateEveningAttendanceSummary({
    int conducted = 6,
    int attended = 5,
    double overall = 84.5,
  }) async {
    final missed = conducted - attended;
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '📊 Daily Attendance Summary: $attended/$conducted Attended',
      body: 'Classes Today: $conducted conducted • $attended attended • $missed missed.\n'
          'Overall Attendance: 142/168 (${overall.toStringAsFixed(1)}%) • GOOD STANDING',
      payload: 'attendance',
      type: 'summary',
    );
  }

  // ===========================================================================
  // TIMETABLE PERIOD & CLASS NOTIFICATIONS ENGINE
  // ===========================================================================

  /// Schedules repeating exact alarms for all timetable periods in the week.
  /// Works even when the app is completely closed or killed!
  Future<void> scheduleTimetablePeriodReminders(
    StudentTimeTableReport report, {
    String? rollNo,
  }) async {
    if (kIsWeb) return;
    if (report.schedules.isEmpty) return;

    final studentId = rollNo ?? HitamAuthService().activeUserId ?? 'student';

    // Cache faculty allocations
    if (report.allocations.isNotEmpty) {
      await cacheFacultyAllocations(studentId, report.allocations);
    }

    final dayMap = {
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };

    // Standard HITAM College Period Timings
    final defaultPeriodTimes = [
      const TimeOfDay(hour: 9, minute: 15),  // Period 1
      const TimeOfDay(hour: 10, minute: 5),  // Period 2
      const TimeOfDay(hour: 11, minute: 5),  // Period 3
      const TimeOfDay(hour: 11, minute: 55), // Period 4
      const TimeOfDay(hour: 13, minute: 25), // Period 5
      const TimeOfDay(hour: 14, minute: 15), // Period 6
      const TimeOfDay(hour: 15, minute: 5),  // Period 7
    ];

    int scheduledCount = 0;

    for (var daySchedule in report.schedules) {
      final dayKey = daySchedule.day.toLowerCase().trim();
      final targetWeekday = dayMap[dayKey];
      if (targetWeekday == null || targetWeekday == DateTime.sunday) continue;

      for (int i = 0; i < daySchedule.subjects.length; i++) {
        final code = daySchedule.subjects[i].trim();
        if (code.isEmpty ||
            code == '-' ||
            code == '&nbsp;' ||
            code.toLowerCase().contains('lunch')) {
          continue;
        }

        // Resolve subject name and faculty name
        String subName = code;
        String facName = 'Faculty Department';
        for (var alloc in report.allocations) {
          if (alloc.code.toLowerCase().trim() == code.toLowerCase().trim()) {
            subName = alloc.name;
            facName = alloc.facultyName;
            break;
          }
        }

        // Determine period start time
        TimeOfDay periodTime = i < defaultPeriodTimes.length
            ? defaultPeriodTimes[i]
            : TimeOfDay(hour: 9 + i, minute: 0);

        if (i + 1 < report.periodHeaders.length) {
          final hText = report.periodHeaders[i + 1];
          final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(hText);
          if (m != null) {
            int h = int.parse(m.group(1)!);
            final min = int.parse(m.group(2)!);
            if (h < 8) h += 12; // PM adjustment
            periodTime = TimeOfDay(hour: h, minute: min);
          }
        }

        final timingStr =
            '${periodTime.hour.toString().padLeft(2, '0')}:${periodTime.minute.toString().padLeft(2, '0')}';
        final periodNum = i + 1;
        final notifId =
            ('period_${targetWeekday}_${periodNum}_$code'.hashCode).abs().remainder(100000);

        try {
          final now = tz.TZDateTime.now(tz.local);
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            periodTime.hour,
            periodTime.minute,
          );

          // Adjust to matching weekday
          while (scheduledDate.weekday != targetWeekday ||
              scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }

          await _localNotifications.zonedSchedule(
            id: notifId,
            title: '🔔 Period $periodNum: $subName',
            body: 'Faculty: $facName • Time: $timingStr\nYour scheduled class is starting. Tap to open timetable.',
            scheduledDate: scheduledDate,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                timetableChannelId,
                timetableChannelName,
                channelDescription: timetableChannelDescription,
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: true,
                playSound: true,
                category: AndroidNotificationCategory.reminder,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'timetable',
          );
          scheduledCount++;
        } catch (e) {
          debugPrint('Could not schedule period $periodNum for $dayKey: $e');
        }
      }
    }

    // Also schedule daily evening summary alarm at 16:45 (4:45 PM)
    try {
      final now = tz.TZDateTime.now(tz.local);
      var eveningTime =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 45);
      if (eveningTime.isBefore(now)) {
        eveningTime = eveningTime.add(const Duration(days: 1));
      }
      await _localNotifications.zonedSchedule(
        id: 88888,
        title: '📊 Daily Attendance Summary',
        body: 'Today\'s lectures are concluded. Tap to see classes attended, missed, and overall percentage.',
        scheduledDate: eveningTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            summaryChannelId,
            summaryChannelName,
            channelDescription: summaryChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            category: AndroidNotificationCategory.status,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'attendance',
      );
    } catch (e) {
      debugPrint('Error scheduling evening summary alarm: $e');
    }

    debugPrint(
        'Scheduled $scheduledCount timetable period reminders + evening summary exact alarm.');
  }

  /// Syncs student timetable and registers period alarms
  Future<void> syncTimetableAndReminders() async {
    try {
      await HitamAuthService().ensureAuthenticated();
      final scraper = HitamScraperService();
      final ttReport = await scraper.fetchStudentTimeTable();
      if (ttReport != null && ttReport.schedules.isNotEmpty) {
        await scheduleTimetablePeriodReminders(ttReport);
      }
    } catch (e) {
      debugPrint('Error syncing timetable and reminders: $e');
    }
  }

  /// Simulate a period / class reminder notification
  Future<void> simulatePeriodReminder({
    String? periodNum,
    String? subject,
    String? faculty,
    String? timing,
  }) async {
    final pNum = periodNum ?? '2';
    final sub = subject ?? 'Compiler Design';
    final fac = faculty ?? 'Dr. P. Anitha (CSE)';
    final tStr = timing ?? '10:05 AM';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '🔔 Period $pNum ($tStr): $sub',
      body: 'Faculty: $fac\nYour lecture is starting now. Tap to view today\'s timetable.',
      payload: 'timetable',
      type: 'timetable',
    );
  }

  // ===========================================================================
  // ATTENDANCE DIFFING ENGINE WITH FACULTY MAPPING
  // ===========================================================================

  /// Compare fresh attendance report against previously stored local snapshot.
  /// Detects whether student was marked PRESENT or ABSENT in any subject,
  /// resolves faculty member name, and pushes heads-up notifications!
  Future<void> checkAndNotifyAttendance(
    StudentAttendanceReport currentReport, {
    bool forceNotifySummary = false,
  }) async {
    if (currentReport.subjects.isEmpty) return;
    final rollNo = currentReport.rollNo.isNotEmpty
        ? currentReport.rollNo
        : (HitamAuthService().activeUserId ?? 'student');

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_attendance_snapshot_$rollNo';
      final prevRaw = prefs.getString(key);

      // Record / maintain daily morning baseline for evening summary
      await getOrSetTodayBaseline(
        rollNo,
        currentReport.totalHeld,
        currentReport.totalAttended,
      );

      // Build new snapshot map for saving
      final Map<String, dynamic> newSnapshot = {
        'timestamp': DateTime.now().toIso8601String(),
        'overallPercentage': currentReport.overallPercentage,
        'totalHeld': currentReport.totalHeld,
        'totalAttended': currentReport.totalAttended,
        'safeBunks': currentReport.safeBunks,
        'classesNeeded': currentReport.classesNeeded,
        'status': currentReport.academicStatus,
        'subjects': <String, dynamic>{},
      };

      for (var s in currentReport.subjects) {
        (newSnapshot['subjects'] as Map<String, dynamic>)[s.subjectCode] = {
          'name': s.subjectName,
          'held': s.classesHeld,
          'attended': s.classesAttended,
          'percentage': s.percentage,
          'safe_bunks': s.safeBunks,
          'classes_needed': s.classesNeeded,
          'status': s.status,
        };
      }

      if (prevRaw == null) {
        // First time seeing attendance: save snapshot
        await prefs.setString(key, jsonEncode(newSnapshot));

        // Automatically push attendance summary notification
        await pushAttendanceSummaryNotification(currentReport);

        // If attendance is below 75%, immediately send shortage warning
        if (currentReport.overallPercentage < 75.0) {
          await checkShortageWarning(currentReport, force: true);
        }
        return;
      }

      // We have previous snapshot - perform diffing!
      final Map<String, dynamic> prev = jsonDecode(prevRaw);
      final Map<String, dynamic> prevSubjects =
          (prev['subjects'] as Map<String, dynamic>?) ?? {};
      final int prevTotalHeld = (prev['totalHeld'] as num?)?.toInt() ?? 0;

      int presentDetected = 0;
      int absentDetected = 0;

      for (var s in currentReport.subjects) {
        final prevSubjectData =
            prevSubjects[s.subjectCode] ?? prevSubjects[s.subjectName];
        if (prevSubjectData != null) {
          final int prevHeld =
              (prevSubjectData['held'] as num?)?.toInt() ?? 0;
          final int prevAttended =
              (prevSubjectData['attended'] as num?)?.toInt() ?? 0;

          final int heldDiff = s.classesHeld - prevHeld;
          final int attendedDiff = s.classesAttended - prevAttended;

          if (heldDiff > 0) {
            // Resolve the faculty member who marked attendance
            final faculty =
                await resolveFacultyName(rollNo, s.subjectCode, s.subjectName);

            if (attendedDiff > 0) {
              // Student was marked PRESENT in this subject
              presentDetected++;
              final int notifId =
                  ('present_${s.subjectCode}_${s.classesHeld}'.hashCode).abs().remainder(100000);
              await showNotification(
                id: notifId,
                title: '🟢 Marked Present: ${s.subjectName}',
                body: 'You were marked PRESENT by $faculty (+$attendedDiff class).\n'
                    'Subject: ${s.classesAttended}/${s.classesHeld} (${s.percentage.toStringAsFixed(1)}%) • Overall: ${currentReport.overallPercentage.toStringAsFixed(1)}%',
                payload: 'attendance',
                type: 'attendance',
              );
            } else {
              // Student was marked ABSENT in this subject
              absentDetected++;
              final int notifId =
                  ('absent_${s.subjectCode}_${s.classesHeld}'.hashCode).abs().remainder(100000);
              await showNotification(
                id: notifId,
                title: '🔴 Marked ABSENT: ${s.subjectName}',
                body: 'You were marked ABSENT by $faculty ($heldDiff missed class).\n'
                    'Subject: ${s.classesAttended}/${s.classesHeld} (${s.percentage.toStringAsFixed(1)}%) • Overall: ${currentReport.overallPercentage.toStringAsFixed(1)}%',
                payload: 'attendance',
                type: 'attendance',
              );
            }
          }
        }
      }

      debugPrint(
          'Attendance check complete for $rollNo: present=$presentDetected, absent=$absentDetected');

      // Check if attendance is below 75%
      if (currentReport.overallPercentage < 75.0) {
        await checkShortageWarning(currentReport);
      }

      // If user explicitly forced a summary notification, or if changes happened and no individual alerts were fired
      if (forceNotifySummary || (presentDetected == 0 && absentDetected == 0 && currentReport.totalHeld > prevTotalHeld)) {
        await pushAttendanceSummaryNotification(currentReport);
      }

      // Update stored snapshot
      await prefs.setString(key, jsonEncode(newSnapshot));
    } catch (e) {
      debugPrint('Error during checkAndNotifyAttendance: $e');
    }
  }

  /// Push an immediate comprehensive attendance status notification to the notification shade.
  Future<void> pushAttendanceSummaryNotification(
    StudentAttendanceReport report,
  ) async {
    final statusEmoji = report.overallPercentage >= 75.0
        ? '✅'
        : (report.overallPercentage >= 65.0 ? '⚠️' : '🚨');

    final standingAdvice = report.safeBunks > 0
        ? 'Safe Bunks Margin: ${report.safeBunks} classes remaining'
        : (report.classesNeeded > 0
            ? 'Need ${report.classesNeeded} consecutive classes to reach 75%'
            : 'Maintain current attendance');

    final int notifId =
        ('summary_${report.rollNo}_${DateTime.now().minute}'.hashCode).abs().remainder(100000);

    await showNotification(
      id: notifId,
      title: '$statusEmoji Total Attendance: ${report.overallPercentage.toStringAsFixed(1)}% (${report.academicStatus})',
      body: 'Classes Attended: ${report.totalAttended} / ${report.totalHeld} (${report.overallPercentage.toStringAsFixed(1)}%)\n'
          '$standingAdvice across ${report.subjects.length} subjects.\n'
          'Tap to view subject-wise breakdown.',
      payload: 'attendance',
      type: 'attendance',
    );
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
        case 'attendance_present':
          title = '🟢 Marked Present: Computer Networks';
          body =
              'You were marked PRESENT by Dr. K. Srinivas (CSE) for today\'s lecture (+1 class).\nSubject: 24/28 (85.7%) • Overall Attendance: 84.6% (SAFE)';
          type = 'attendance';
          screen = 'attendance';
          break;
        case 'attendance_absent':
          title = '🔴 Marked ABSENT: Operating Systems';
          body =
              'You were marked ABSENT by Prof. M. Rajesh for today\'s lecture (1 missed lecture).\nSubject: 18/26 (69.2%) • Overall Attendance: 74.2% (WARNING)';
          type = 'attendance';
          screen = 'attendance';
          break;
        case 'attendance_summary':
        case 'evening_summary':
          title = '📊 Daily Attendance Summary: 5/6 Classes Attended';
          body =
              'Classes Today: 6 conducted • 5 attended • 1 missed.\nOverall Attendance: 142/168 (84.5%) • GOOD STANDING';
          type = 'summary';
          screen = 'attendance';
          break;
        case 'period_reminder':
        case 'period':
          title = '🔔 Period 2 (10:05 AM): Compiler Design';
          body =
              'Faculty: Dr. P. Anitha (CSE) • Room: LH-204\nNext lecture starting soon. Tap to view today\'s timetable.';
          type = 'timetable';
          screen = 'timetable';
          break;
        case 'attendance':
          title = '📊 Total Attendance: 84.6% (GOOD STANDING)';
          body =
              'Classes Attended: 142/168 (84.6%)\nSafe Bunks Margin: 12 classes remaining across 8 subjects.';
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
    stopAttendanceWatcher();
    stopRealtimePulse();
    _payloadStreamController.close();
  }
}
